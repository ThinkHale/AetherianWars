public enum StageID: String, CaseIterable, Codable, Sendable, Identifiable {
    case forum, nile, persepolis, greatWall, crossing

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .forum: "The Forum at Dusk"
        case .nile: "Banks of the Nile"
        case .persepolis: "Gate of All Nations"
        case .greatWall: "Juyan Watchtower"
        case .crossing: "The Crossing"
        }
    }

    public var empire: Empire? {
        switch self {
        case .forum: .rome
        case .nile: .egypt
        case .persepolis: .persia
        case .greatWall: .han
        case .crossing: nil
        }
    }

    public static func home(of empire: Empire) -> StageID {
        switch empire {
        case .rome: .forum
        case .egypt: .nile
        case .persia: .persepolis
        case .han: .greatWall
        }
    }
}

public struct MatchConfig: Sendable, Equatable {
    public var heroes: [HeroID]
    public var stage: StageID
    public var roundsToWin: Int
    public var roundSeconds: Int
    public var seed: UInt64
    /// Fighter indices that are mirror bosses (the Echo of the Crossing).
    public var bosses: Set<Int>
    /// Training: health and meter refill, no timer, no KO.
    public var training: Bool

    public init(heroes: [HeroID], stage: StageID, roundsToWin: Int = 2, roundSeconds: Int = 99, seed: UInt64 = 1, bosses: Set<Int> = [], training: Bool = false) {
        precondition(heroes.count == 2)
        self.heroes = heroes; self.stage = stage; self.roundsToWin = roundsToWin
        self.roundSeconds = roundSeconds; self.seed = seed; self.bosses = bosses; self.training = training
    }
}

public enum MatchPhase: Equatable, Sendable {
    case intro(remaining: Int)
    case fighting
    case roundOver(remaining: Int, winner: Int?)
    case matchOver(winner: Int)
}

public enum MatchEvent: Equatable, Sendable {
    case roundAnnounced(round: Int, final: Bool)
    case fight
    case hit(attacker: Int, impact: Impact, at: Vec, damage: Double, counter: Bool, combo: Int)
    case blocked(defender: Int, at: Vec, impact: Impact)
    case armorAbsorbed(defender: Int, at: Vec)
    case counterTriggered(defender: Int)
    case whiff(attacker: Int, slot: MoveSlot)
    case special(attacker: Int, name: String)
    case superFlash(attacker: Int, name: String)
    case projectileLaunched(owner: Int, kind: ProjectileKind)
    case projectileClash(at: Vec)
    case thrown(attacker: Int)
    case throwBroken(at: Vec)
    case jumped(fighter: Int)
    case landed(fighter: Int, hard: Bool)
    case dashed(fighter: Int, back: Bool)
    case conditionGained(fighter: Int, condition: Condition)
    case healed(fighter: Int, amount: Double)
    case ko(loser: Int)
    case timeOver
    case roundWon(winner: Int?, perfect: Bool)
    case matchWon(winner: Int)
}

public struct Projectile: Identifiable, Sendable {
    public let id: Int
    public let owner: Int
    public let spec: ProjectileSpec
    public var position: Vec
    public var velocity: Vec
    public let facing: Double
    public var age = 0
    public var hitsLeft: Int
    public var cooldown = 0
    public var alive = true

    public var box: Box { Box(local: spec.box, origin: position, facing: facing) }
    public var armed: Bool { age > spec.armingDelay }
}

/// One fight between two commanders: best of three rounds by default. The
/// match is a value; `tick` advances it by one sixtieth of a second, and the
/// same inputs from the same seed always produce the same fight.
public struct Match: Sendable {
    public static let tickRate = 60
    public static let gravity = 0.85
    public static let stageHalfWidth = 700.0
    public static let maxSeparation = 600.0
    public static let juggleLimit = 4
    public static let introFrames = 150
    public static let roundOverFrames = 210
    public static let maxRounds = 9
    /// Ticks a caught fighter has to break a throw.
    public static let throwBreakWindow = 12

    public let config: MatchConfig
    public private(set) var fighters: [Fighter]
    public private(set) var projectiles: [Projectile] = []
    public private(set) var phase: MatchPhase
    public private(set) var round = 1
    public private(set) var timer: Int
    public private(set) var hitstop = 0
    public private(set) var superFreeze = 0
    public private(set) var superOwner: Int? = nil
    public private(set) var frameCount = 0
    public private(set) var events: [MatchEvent] = []
    public private(set) var suddenDeath = false
    /// Who has knocked out whom at least once, for "perfect" calls.
    private var damageTakenThisRound = [0.0, 0.0]
    private var nextProjectileID = 1
    private var rng: SeededRandom

    public init(config: MatchConfig) {
        self.config = config
        self.rng = SeededRandom(seed: config.seed)
        var a = Fighter(index: 0, hero: config.heroes[0].hero, position: Vec(-180, 0), facing: 1)
        var b = Fighter(index: 1, hero: config.heroes[1].hero, position: Vec(180, 0), facing: -1)
        for index in config.bosses {
            if index == 0 { a.bossScale = 1.18 } else { b.bossScale = 1.18 }
        }
        if config.bosses.contains(0) { a.health *= 1.25 }
        if config.bosses.contains(1) { b.health *= 1.25 }
        fighters = [a, b]
        timer = config.roundSeconds * Self.tickRate
        phase = .intro(remaining: Self.introFrames)
        events = [.roundAnnounced(round: 1, final: false)]
    }

    public var secondsLeft: Int { config.training ? 99 : Int((Double(timer) / Double(Self.tickRate)).rounded(.up)) }

    public func maxHealth(_ index: Int) -> Double {
        fighters[index].maxHealth * (config.bosses.contains(index) ? 1.25 : 1)
    }

    public func healthFraction(_ index: Int) -> Double { max(0, fighters[index].health / maxHealth(index)) }

    public var isOver: Bool { if case .matchOver = phase { return true } else { return false } }

    // MARK: Tick

    public mutating func tick(_ inputs: [Controls]) {
        events.removeAll(keepingCapacity: true)
        frameCount += 1
        for i in 0..<2 { fighters[i].input.record(inputs.count > i ? inputs[i] : []) }

        switch phase {
        case let .intro(remaining):
            if remaining == Self.introFrames {
                for i in 0..<2 { fighters[i].action = .intro; fighters[i].frame = 0 }
            }
            stepFreeMovement()
            if remaining <= 1 {
                phase = .fighting
                for i in 0..<2 { setAction(i, .idle) ; fighters[i].input.clear() }
                events.append(.fight)
            } else {
                phase = .intro(remaining: remaining - 1)
            }
        case .fighting:
            stepFight()
        case let .roundOver(remaining, winner):
            stepFreeMovement()
            if remaining <= 1 { finishRound(winner: winner) } else { phase = .roundOver(remaining: remaining - 1, winner: winner) }
        case .matchOver:
            stepFreeMovement()
        }
    }

    /// Movement with no fighting: falling bodies land, victors pose.
    private mutating func stepFreeMovement() {
        for i in 0..<2 {
            fighters[i].frame += 1
            if fighters[i].stun > 0 { fighters[i].stun -= 1 }
            applyPhysics(i)
            if fighters[i].grounded {
                switch fighters[i].action {
                case .juggle, .airborne: setAction(i, fighters[i].health <= 0 ? .ko : .knockdown); fighters[i].stun = 40
                case .knockdown where fighters[i].stun == 0 && fighters[i].health > 0: setAction(i, .getUp); fighters[i].stun = 18
                case .getUp where fighters[i].stun == 0: setAction(i, .idle)
                case .hitstun where fighters[i].stun == 0, .blockstun where fighters[i].stun == 0: setAction(i, .idle)
                case .attack, .dash, .landing, .jumpSquat, .walk, .guarding, .throwHold:
                    if case .roundOver = phase { setAction(i, .idle) }
                    if case .matchOver = phase { setAction(i, .idle) }
                default: break
                }
            }
        }
        if case let .roundOver(remaining, winner) = phase, let w = winner, remaining < Self.roundOverFrames - 60,
           fighters[w].action == .idle {
            setAction(w, .victory)
        }
        if case let .matchOver(winner) = phase, fighters[winner].action == .idle { setAction(winner, .victory) }
        separate()
    }

    private mutating func stepFight() {
        if superFreeze > 0 {
            // The whole fight holds still while the super is announced.
            superFreeze -= 1
            return
        }
        if hitstop > 0 { hitstop -= 1; return }

        for i in 0..<2 { readInput(i) }
        for i in 0..<2 { advance(i) }
        for i in 0..<2 { applyPhysics(i); land(i) }
        separate()
        resolveStrikes()
        stepProjectiles()
        for i in 0..<2 { tickConditions(i) }
        faceEachOther()

        if config.training {
            for i in 0..<2 where fighters[i].isActionable {
                if fighters[i].health < maxHealth(i) && fighters[i].comboTaken == 0 { fighters[i].health = min(maxHealth(i), fighters[i].health + maxHealth(i) * 0.02) }
                fighters[i].meter = 100
            }
            return
        }
        timer -= 1
        checkRoundEnd()
    }

    // MARK: Actions

    private mutating func setAction(_ i: Int, _ action: FighterAction) {
        fighters[i].action = action
        fighters[i].frame = 0
        if case .attack = action {} else {
            fighters[i].moveConnected = false
            fighters[i].moveHitsDealt = 0
            fighters[i].counterTriggeredAt = nil
        }
    }

    private mutating func startMove(_ i: Int, _ slot: MoveSlot) {
        let move = fighters[i].moves[slot]
        if move.meterCost > 0 {
            guard fighters[i].meter >= move.meterCost else { return }
            fighters[i].meter -= move.meterCost
        }
        fighters[i].action = .attack(slot)
        fighters[i].frame = 0
        fighters[i].moveConnected = false
        fighters[i].moveHitsDealt = 0
        fighters[i].nextHitFrame = move.firstActive
        fighters[i].armorLeft = move.armorHits
        fighters[i].counterTriggeredAt = nil
        if fighters[i].grounded { fighters[i].velocity.x = 0 }
        switch slot {
        case .special:
            fighters[i].stats.specialsUsed += 1
            events.append(.special(attacker: i, name: move.name))
        case .superArt:
            fighters[i].stats.supersUsed += 1
            superFreeze = 36
            superOwner = i
            events.append(.superFlash(attacker: i, name: move.name))
        default: break
        }
    }

    private mutating func readInput(_ i: Int) {
        var f = fighters[i]
        defer { fighters[i] = f }
        let held = f.input.held
        let forward: Controls = f.facing > 0 ? .right : .left
        let back: Controls = f.facing > 0 ? .left : .right

        // Breaking a throw: guard and light together while being caught.
        if case .throwHold(attacker: false) = f.action, held.contains(.guardButton), f.input.buffered(.light) {
            f.input.consume(.light)
            fighters[i] = f
            breakThrow()
            f = fighters[i]
            return
        }

        // Cancels from a move that connected (and light chains, which also
        // run on a whiff once the swing is over).
        if case let .attack(slot) = f.action {
            let move = f.moves[slot]
            let swingDone = f.frame > move.lastActive
            func want(_ next: MoveSlot) -> Bool {
                switch next {
                case .light2, .light3: f.input.buffered(.light)
                case .heavy: f.input.buffered(.heavy)
                case .special: f.input.buffered(.special)
                case .superArt: f.input.buffered(.superArt) && f.meter >= 100
                case .airHeavy: f.input.buffered(.heavy)
                default: false
                }
            }
            let order: [MoveSlot] = [.superArt, .special, .heavy, .light3, .light2, .airHeavy]
            for next in order where move.cancelsInto.contains(next) && want(next) {
                let isChain = next == .light2 || next == .light3
                guard f.moveConnected || (isChain && swingDone) else { continue }
                guard f.frame > move.startup else { continue }
                let button: Controls = switch next {
                case .heavy, .airHeavy: .heavy
                case .special: .special
                case .superArt: .superArt
                default: .light
                }
                f.input.consume(button)
                fighters[i] = f
                startMove(i, next)
                f = fighters[i]
                return
            }
            return
        }

        if case .airborne = f.action, !f.airAttackUsed {
            if f.input.buffered(.heavy) { f.input.consume(.heavy); f.airAttackUsed = true; fighters[i] = f; startMove(i, .airHeavy); f = fighters[i]; return }
            if f.input.buffered(.light) { f.input.consume(.light); f.airAttackUsed = true; fighters[i] = f; startMove(i, .airLight); f = fighters[i]; return }
            return
        }

        guard f.isActionable else { return }

        if f.input.buffered(.superArt), f.meter >= 100 {
            f.input.consume(.superArt); fighters[i] = f; startMove(i, .superArt); f = fighters[i]; return
        }
        if held.contains(.guardButton), f.input.buffered(.light) {
            f.input.consume(.light); fighters[i] = f; startMove(i, .throwAttempt); f = fighters[i]; return
        }
        if f.input.buffered(.special) {
            f.input.consume(.special); fighters[i] = f; startMove(i, .special); f = fighters[i]; return
        }
        if f.input.buffered(.heavy) {
            f.input.consume(.heavy); fighters[i] = f; startMove(i, .heavy); f = fighters[i]; return
        }
        if f.input.buffered(.light) {
            f.input.consume(.light); fighters[i] = f; startMove(i, .light1); f = fighters[i]; return
        }
        if held.contains(.up) {
            f.action = .jumpSquat; f.frame = 0; f.velocity.x = 0
            return
        }
        let dashForward = f.input.doubleTapped.contains(forward) || (f.input.buffered(.dash) && !held.contains(back))
        let dashBack = f.input.doubleTapped.contains(back) || (f.input.buffered(.dash) && held.contains(back))
        if dashForward || dashBack {
            f.input.consume(.dash)
            f.action = .dash(back: dashBack && !dashForward); f.frame = 0
            events.append(.dashed(fighter: i, back: dashBack && !dashForward))
            return
        }
        if held.contains(.guardButton) {
            if f.action != .guarding { f.action = .guarding; f.frame = 0 }
            f.velocity.x = 0
            return
        }
        let slow = 1 - f.condition(.dusted)
        if held.contains(forward) {
            if f.action != .walk { f.action = .walk; f.frame = 0 }
            f.velocity.x = f.hero.stats.walkSpeed * f.facing * slow
        } else if held.contains(back) {
            if f.action != .walk { f.action = .walk; f.frame = 0 }
            f.velocity.x = -f.hero.stats.walkSpeed * 0.82 * f.facing * slow
        } else {
            if f.action != .idle { f.action = .idle; f.frame = 0 }
            f.velocity.x = 0
        }
    }

    /// Runs one tick of whatever each fighter is doing.
    private mutating func advance(_ i: Int) {
        fighters[i].frame += 1
        if fighters[i].invulnerable > 0 { fighters[i].invulnerable -= 1 }
        let frame = fighters[i].frame

        switch fighters[i].action {
        case .jumpSquat:
            if frame >= 3 {
                let held = fighters[i].input.held
                let speed = fighters[i].hero.stats.walkSpeed * 1.45 * (1 - fighters[i].condition(.dusted))
                fighters[i].velocity = Vec(held.contains(.right) ? speed : held.contains(.left) ? -speed : 0, fighters[i].hero.stats.jumpVelocity)
                fighters[i].position.y = 0.01
                fighters[i].airAttackUsed = false
                setAction(i, .airborne)
                events.append(.jumped(fighter: i))
            }
        case let .dash(back):
            let total = back ? 18 : 16
            let speed = fighters[i].hero.stats.dashSpeed * (1 - fighters[i].condition(.dusted) * 0.5)
            let progress = Double(frame) / Double(total)
            fighters[i].velocity.x = (back ? -speed * 0.85 : speed) * fighters[i].facing * max(0.15, 1 - progress * progress)
            if frame >= total { fighters[i].velocity.x = 0; setAction(i, .idle) }
        case .landing:
            if fighters[i].stun > 0 { fighters[i].stun -= 1 } else { setAction(i, .idle) }
        case .hitstun, .blockstun:
            fighters[i].velocity.x *= 0.86
            if fighters[i].stun > 0 { fighters[i].stun -= 1 }
            if fighters[i].stun <= 0 {
                fighters[i].comboTaken = 0; fighters[i].comboDamageTaken = 0
                setAction(i, fighters[i].grounded ? .idle : .juggle)
            }
        case .knockdown:
            fighters[i].velocity.x *= 0.8
            if fighters[i].stun > 0 { fighters[i].stun -= 1 } else {
                setAction(i, .getUp); fighters[i].stun = 20
            }
        case .getUp:
            if fighters[i].stun > 0 { fighters[i].stun -= 1 } else {
                fighters[i].invulnerable = 4
                fighters[i].comboTaken = 0; fighters[i].comboDamageTaken = 0; fighters[i].juggleHits = 0
                setAction(i, .idle)
            }
        case let .throwHold(attacker):
            if attacker, frame >= Self.throwBreakWindow { completeThrow(i) }
        case let .attack(slot):
            advanceMove(i, fighters[i].moves[slot])
        default:
            break
        }
    }

    private mutating func advanceMove(_ i: Int, _ move: Move) {
        let frame = fighters[i].frame
        let f = fighters[i]

        // Motion along the ground (or air).
        var moving = false
        for motion in move.motions where (motion.from...motion.to).contains(frame) {
            fighters[i].velocity.x = motion.velocity.x * f.facing * (1 - f.condition(.dusted) * 0.4)
            if motion.velocity.y != 0 { fighters[i].velocity.y = motion.velocity.y }
            moving = true
        }
        if !moving && f.grounded { fighters[i].velocity.x = 0 }

        for (spawnFrame, spec) in move.projectiles where spawnFrame == frame {
            spawn(spec, owner: i)
        }
        if let (grantFrame, grant, heal) = move.selfGrant, grantFrame == frame {
            fighters[i].conditions[grant.condition] = ActiveCondition(frames: grant.frames, magnitude: grant.magnitude)
            events.append(.conditionGained(fighter: i, condition: grant.condition))
            if heal > 0 {
                let amount = min(heal, maxHealth(i) - fighters[i].health)
                fighters[i].health += amount
                if amount > 0 { events.append(.healed(fighter: i, amount: amount)) }
            }
        }

        // A counter stance that was struck answers within a few frames.
        if let struck = f.counterTriggeredAt {
            if frame >= struck + 10 + move.recovery { endMove(i) }
            return
        }

        if frame == move.lastActive + 1, !f.moveConnected, move.hitbox.width > 0 {
            events.append(.whiff(attacker: i, slot: move.slot))
        }
        if frame >= move.total {
            if move.slot == .special && move.hitbox.width == 0 && move.projectiles.isEmpty == false && !f.moveConnected {
                fighters[i].meter = min(100, fighters[i].meter + 2)
            }
            endMove(i)
        }
    }

    private mutating func endMove(_ i: Int) {
        if fighters[i].grounded {
            setAction(i, .idle)
        } else {
            setAction(i, .airborne)
            fighters[i].airAttackUsed = true
        }
    }

    // MARK: Physics

    private mutating func applyPhysics(_ i: Int) {
        var f = fighters[i]
        let airborneAction: Bool = {
            switch f.action {
            case .airborne, .juggle: return true
            case .attack: return !f.grounded
            case .hitstun, .ko: return !f.grounded
            default: return false
            }
        }()
        if airborneAction || f.position.y > 0 {
            f.velocity.y -= Self.gravity
        } else {
            f.velocity.y = max(0, f.velocity.y)
        }
        f.position.x += f.velocity.x
        f.position.y += f.velocity.y
        if f.position.y < 0 { f.position.y = 0 }
        if f.position.y == 0 {
            switch f.action {
            case .knockdown, .getUp, .ko, .victory, .intro: f.velocity.x *= 0.78
            default: break
            }
        }
        f.position.x = min(Self.stageHalfWidth, max(-Self.stageHalfWidth, f.position.x))
        fighters[i] = f
    }

    private mutating func land(_ i: Int) {
        guard fighters[i].position.y <= 0, fighters[i].velocity.y <= 0 else { return }
        switch fighters[i].action {
        case .airborne:
            fighters[i].velocity = .zero
            setAction(i, .landing); fighters[i].stun = 3
            events.append(.landed(fighter: i, hard: false))
        case let .attack(slot) where fighters[i].moves[slot].endsOnLanding:
            let lag = fighters[i].moveConnected ? 3 : 9
            fighters[i].velocity = .zero
            setAction(i, .landing); fighters[i].stun = lag
            events.append(.landed(fighter: i, hard: false))
        case .juggle:
            fighters[i].velocity = Vec(fighters[i].velocity.x * 0.3, 0)
            if fighters[i].health <= 0 { setAction(i, .ko) } else { setAction(i, .knockdown); fighters[i].stun = 34 }
            events.append(.landed(fighter: i, hard: true))
        case .hitstun where fighters[i].frame > 1:
            fighters[i].velocity.y = 0
        default:
            break
        }
    }

    /// Pushes overlapping fighters apart and keeps both on camera.
    private mutating func separate() {
        var a = fighters[0], b = fighters[1]
        let passing = [a, b].contains { f in
            guard let move = f.currentMove, move.passesThrough else { return false }
            return f.frame >= move.startup - 2 && f.frame <= move.lastActive + 2
        }
        let overlapY = a.position.y < b.position.y + 150 * b.stature && b.position.y < a.position.y + 150 * a.stature
        let bodiesSolid = ![a.action, b.action].contains(where: { $0 == .knockdown || $0 == .ko || $0 == .getUp })
        if !passing && overlapY && bodiesSolid {
            let minGap = a.pushWidth + b.pushWidth
            let gap = b.position.x - a.position.x
            if abs(gap) < minGap {
                let push = (minGap - abs(gap)) / 2
                let dir: Double = gap == 0 ? (a.facing > 0 ? 1 : -1) : (gap > 0 ? 1 : -1)
                // Whoever is at the wall stays; the other takes the whole push.
                var aShift = -push * dir, bShift = push * dir
                if abs(a.position.x + aShift) > Self.stageHalfWidth { bShift += aShift.magnitude * dir; aShift = 0 }
                if abs(b.position.x + bShift) > Self.stageHalfWidth { aShift -= bShift.magnitude * dir; bShift = 0 }
                a.position.x += aShift; b.position.x += bShift
            }
        }
        // Neither can walk off the camera.
        let separation = b.position.x - a.position.x
        if abs(separation) > Self.maxSeparation {
            let excess = abs(separation) - Self.maxSeparation
            let sign: Double = separation > 0 ? 1 : -1
            let aMoving = abs(a.velocity.x) > abs(b.velocity.x)
            if aMoving { a.position.x += excess * sign } else { b.position.x -= excess * sign }
        }
        for f in [0, 1] {
            var x = f == 0 ? a.position.x : b.position.x
            x = min(Self.stageHalfWidth, max(-Self.stageHalfWidth, x))
            if f == 0 { a.position.x = x } else { b.position.x = x }
        }
        fighters[0] = a; fighters[1] = b
    }

    private mutating func faceEachOther() {
        for i in 0..<2 {
            let other = fighters[1 - i]
            switch fighters[i].action {
            case .idle, .walk, .guarding, .landing, .jumpSquat, .getUp, .blockstun:
                let dx = other.position.x - fighters[i].position.x
                if abs(dx) > 1 { fighters[i].facing = dx > 0 ? 1 : -1 }
            default: break
            }
        }
    }

    private mutating func tickConditions(_ i: Int) {
        for (condition, var state) in fighters[i].conditions {
            state.frames -= 1
            fighters[i].conditions[condition] = state.frames > 0 ? state : nil
        }
    }

    // MARK: Strikes

    private func hitbox(_ i: Int) -> (Move, Box)? {
        let f = fighters[i]
        guard let move = f.currentMove, move.hitbox.width > 0 else { return nil }
        if move.counterWindow != nil {
            guard let struck = f.counterTriggeredAt, f.frame > struck + 3, f.frame <= struck + 9, f.moveHitsDealt == 0 else { return nil }
            return (move, Box(local: move.hitbox, origin: f.position, facing: f.facing))
        }
        guard f.frame >= move.firstActive, f.frame <= move.lastActive, f.moveHitsDealt < move.hits, f.frame >= f.nextHitFrame else { return nil }
        return (move, Box(local: move.hitbox, origin: f.position, facing: f.facing))
    }

    private mutating func resolveStrikes() {
        let candidates = [hitbox(0), hitbox(1)]
        var landed: [(attacker: Int, move: Move)] = []
        for i in 0..<2 {
            guard let (move, box) = candidates[i] else { continue }
            let defender = fighters[1 - i]
            if move.slot == .throwAttempt {
                if defender.isThrowable, defender.hurtboxes.first.map({ box.intersects($0) }) == true {
                    landed.append((i, move))
                }
                continue
            }
            guard !defender.isStrikeInvulnerable else { continue }
            if defender.hurtboxes.contains(where: { box.intersects($0) }) { landed.append((i, move)) }
        }
        // Two throws at once cancel out; two strikes at once both land (a trade).
        if landed.count == 2, landed.allSatisfy({ $0.move.slot == .throwAttempt }) {
            breakThrow()
            return
        }
        for (attacker, move) in landed {
            if move.slot == .throwAttempt { beginThrow(attacker) } else {
                let at = contactPoint(attacker: attacker, box: candidates[attacker]!.1)
                strike(attacker: attacker, damage: move.damage / Double(move.hits), hitstun: move.hitstun, blockstun: move.blockstun,
                       knockback: move.knockback, impact: move.impact, launches: move.launches, knocksDown: move.knocksDown,
                       chip: move.chip, unblockable: move.unblockable, grant: move.onHitGrant, at: at, fromProjectile: nil,
                       finalHit: fighters[attacker].moveHitsDealt + 1 >= move.hits)
                fighters[attacker].moveHitsDealt += 1
                fighters[attacker].nextHitFrame = fighters[attacker].frame + max(1, move.active / max(1, move.hits))
            }
        }
    }

    private func contactPoint(attacker: Int, box: Box) -> Vec {
        let defender = fighters[1 - attacker]
        let body = defender.hurtboxes.first ?? box
        let x = (max(box.minX, body.minX) + min(box.maxX, body.maxX)) / 2
        let y = (max(box.minY, body.minY) + min(box.maxY, body.maxY)) / 2
        return Vec(x, y)
    }

    /// Lands one blow (from a move or a projectile) on the attacker's enemy.
    private mutating func strike(attacker: Int, damage baseDamage: Double, hitstun: Int, blockstun: Int, knockback: Vec, impact: Impact,
                                 launches: Bool, knocksDown: Bool, chip: Double, unblockable: Bool, grant: ConditionGrant?,
                                 at: Vec, fromProjectile: ProjectileKind?, finalHit: Bool) {
        let d = 1 - attacker
        let a = fighters[attacker]
        var def = fighters[d]
        fighters[attacker].moveConnected = fromProjectile == nil ? true : fighters[attacker].moveConnected
        let away: Double = def.position.x >= a.position.x ? 1 : -1
        let direction = fromProjectile == nil ? (abs(def.position.x - a.position.x) < 1 ? a.facing : away) : away

        // A counter stance catches the blow and answers.
        if let move = def.currentMove, let window = move.counterWindow, window.contains(def.frame), def.counterTriggeredAt == nil, !unblockable {
            fighters[d].counterTriggeredAt = def.frame
            fighters[d].facing = -direction
            hitstop = 10
            events.append(.counterTriggered(defender: d))
            return
        }

        let outgoing = a.hero.stats.power * a.bossScale * (1 + a.condition(.empowered))
        let incoming = def.hero.stats.toughness * (1 + def.condition(.marked)) * (1 - def.condition(.fortified))

        // Guarded.
        if !unblockable, def.canGuard, def.input.held.contains(.guardButton), def.grounded {
            let chipDamage = baseDamage * chip * outgoing * incoming
            def.health -= chipDamage
            if def.health <= 0 { def.health = chip > 0 && !config.training ? 0 : 1 }
            def.action = .blockstun; def.frame = 0; def.stun = blockstun
            def.velocity.x = knockback.x * 1.15 * direction
            def.meter = min(100, def.meter + 2)
            def.stats.blocks += 1
            fighters[d] = def
            fighters[attacker].meter = min(100, fighters[attacker].meter + baseDamage * 0.03)
            // At the wall, the attacker is pushed back instead.
            if abs(def.position.x) >= Self.stageHalfWidth - 4, fromProjectile == nil {
                fighters[attacker].velocity.x = -knockback.x * direction * 0.8
            }
            damageTakenThisRound[d] += chipDamage
            hitstop = max(hitstop, 5)
            events.append(.blocked(defender: d, at: at, impact: impact))
            if def.health <= 0 { koLanded(d) }
            return
        }

        // Armour takes the blow without flinching.
        if let move = def.currentMove, let armor = move.armor, armor.contains(def.frame), def.armorLeft > 0, !unblockable {
            let absorbed = baseDamage * outgoing * incoming * 0.5
            fighters[d].armorLeft -= 1
            fighters[d].health -= absorbed
            damageTakenThisRound[d] += absorbed
            hitstop = max(hitstop, 7)
            events.append(.armorAbsorbed(defender: d, at: at))
            if fighters[d].health <= 0 { koLanded(d) }
            return
        }

        let counterHit = def.inStartup
        let scale = max(0.35, 1 - 0.1 * Double(def.comboTaken))
        var damage = baseDamage * outgoing * incoming * scale * (counterHit ? 1.2 : 1)
        // A blow from behind (a flanking charge that got round) hits harder.
        let behind = def.facing > 0 ? a.position.x < def.position.x : a.position.x > def.position.x
        if behind, a.action == .attack(.special), a.hero.special == .flankingCharge { damage *= 1.15 }
        if config.training { damage = min(damage, max(0, def.health - 1)) }
        def.health -= damage
        def.comboTaken += 1
        def.comboDamageTaken += damage
        def.meter = min(100, def.meter + damage * 0.05)
        if let grant {
            def.conditions[grant.condition] = ActiveCondition(frames: grant.frames, magnitude: grant.magnitude)
            events.append(.conditionGained(fighter: d, condition: grant.condition))
        }

        let airborne = !def.grounded || def.action == .juggle
        if launches || knocksDown || airborne || def.health <= 0 {
            if def.action == .juggle { def.juggleHits += 1 }
            def.action = .juggle; def.frame = 0
            let lift = launches ? knockback.y : knocksDown ? max(6, knockback.y) : (airborne ? 6 : 4)
            def.velocity = Vec(knockback.x * direction * (launches ? 0.6 : 0.8), lift)
            def.position.y = max(def.position.y, 1)
        } else {
            def.action = .hitstun; def.frame = 0
            def.stun = hitstun + (counterHit ? 6 : 0)
            def.velocity.x = knockback.x * direction
        }
        let combo = def.comboTaken
        fighters[d] = def
        if !(a.currentMove?.slot == .superArt) || fromProjectile != nil {
            fighters[attacker].meter = min(100, fighters[attacker].meter + damage * 0.09)
        }
        if abs(def.position.x) >= Self.stageHalfWidth - 4, fromProjectile == nil, !launches {
            fighters[attacker].velocity.x = -knockback.x * direction * 0.6
        }
        fighters[attacker].stats.damageDealt += damage
        fighters[attacker].stats.hitsLanded += 1
        fighters[attacker].stats.bestCombo = max(fighters[attacker].stats.bestCombo, combo)
        damageTakenThisRound[d] += damage
        let stop: Int = switch impact { case .light: 6; case .medium: 8; case .heavy: 11; case .crushing: finalHit ? 16 : 6 }
        hitstop = max(hitstop, stop)
        events.append(.hit(attacker: attacker, impact: impact, at: at, damage: damage, counter: counterHit, combo: combo))
        if fighters[d].health <= 0 { koLanded(d) }
    }

    // MARK: Throws

    private mutating func beginThrow(_ attacker: Int) {
        let d = 1 - attacker
        setAction(attacker, .throwHold(attacker: true))
        setAction(d, .throwHold(attacker: false))
        fighters[attacker].velocity = .zero
        fighters[d].velocity = .zero
    }

    private mutating func completeThrow(_ attacker: Int) {
        let d = 1 - attacker
        let move = fighters[attacker].moves[.throwAttempt]
        let direction = fighters[attacker].facing
        let damage = move.damage * fighters[attacker].hero.stats.power * fighters[attacker].bossScale * fighters[d].hero.stats.toughness
            * (1 + fighters[attacker].condition(.empowered)) * (1 - fighters[d].condition(.fortified))
        fighters[d].health -= config.training ? min(damage, fighters[d].health - 1) : damage
        fighters[d].action = .juggle; fighters[d].frame = 0
        fighters[d].velocity = Vec(move.knockback.x * direction, move.knockback.y)
        fighters[d].position.y = 1
        fighters[d].juggleHits = Self.juggleLimit
        fighters[attacker].meter = min(100, fighters[attacker].meter + 8)
        fighters[attacker].stats.throwsLanded += 1
        fighters[attacker].stats.damageDealt += damage
        damageTakenThisRound[d] += damage
        setAction(attacker, .attack(.throwAttempt))
        fighters[attacker].frame = move.lastActive + 4
        fighters[attacker].moveConnected = true
        hitstop = 10
        events.append(.thrown(attacker: attacker))
        events.append(.hit(attacker: attacker, impact: .heavy, at: Vec(fighters[d].position.x, 90), damage: damage, counter: false, combo: 1))
        if fighters[d].health <= 0 { koLanded(d) }
    }

    private mutating func breakThrow() {
        let mid = Vec((fighters[0].position.x + fighters[1].position.x) / 2, 100)
        for i in 0..<2 {
            setAction(i, .blockstun)
            fighters[i].stun = 14
            let away: Double = fighters[i].position.x < fighters[1 - i].position.x ? -1 : 1
            fighters[i].velocity.x = 7 * away
        }
        events.append(.throwBroken(at: mid))
    }

    // MARK: Projectiles

    private mutating func spawn(_ spec: ProjectileSpec, owner: Int) {
        let f = fighters[owner]
        var origin = Vec(f.position.x + spec.origin.x * f.facing, f.position.y + spec.origin.y)
        if spec.targetsEnemy {
            let enemy = fighters[1 - owner]
            origin = Vec(enemy.position.x + enemy.velocity.x * 8, spec.origin.y)
        }
        if spec.kind == .seal || spec.kind == .dust { origin.y = 0 }
        origin.x = min(Self.stageHalfWidth, max(-Self.stageHalfWidth, origin.x))
        let p = Projectile(id: nextProjectileID, owner: owner, spec: spec, position: origin,
                           velocity: Vec(spec.velocity.x * f.facing, spec.velocity.y), facing: f.facing, hitsLeft: spec.hits)
        nextProjectileID += 1
        projectiles.append(p)
        events.append(.projectileLaunched(owner: owner, kind: spec.kind))
    }

    private mutating func stepProjectiles() {
        for index in projectiles.indices {
            var p = projectiles[index]
            p.age += 1
            p.velocity.y -= p.spec.gravity
            p.position.x += p.velocity.x
            p.position.y += p.velocity.y
            if p.cooldown > 0 { p.cooldown -= 1 }
            if p.age > p.spec.lifetime || abs(p.position.x) > Self.stageHalfWidth + 260 || p.position.y < -60 { p.alive = false }
            if p.spec.kind == .fallingArrow && p.position.y <= 0 { p.alive = false }
            projectiles[index] = p
        }

        // Projectiles meeting in the air.
        for i in projectiles.indices {
            for j in projectiles.indices where j > i {
                let a = projectiles[i], b = projectiles[j]
                guard a.alive, b.alive, a.owner != b.owner, a.armed, b.armed, a.spec.priority > 0, b.spec.priority > 0, a.box.intersects(b.box) else { continue }
                if a.spec.priority <= b.spec.priority { projectiles[i].alive = false }
                if b.spec.priority <= a.spec.priority { projectiles[j].alive = false }
                events.append(.projectileClash(at: Vec((a.position.x + b.position.x) / 2, (a.position.y + b.position.y) / 2)))
            }
        }

        for index in projectiles.indices where projectiles[index].alive && projectiles[index].armed && projectiles[index].cooldown == 0 {
            let p = projectiles[index]
            let target = fighters[1 - p.owner]
            guard !target.isStrikeInvulnerable, target.hurtboxes.contains(where: { p.box.intersects($0) }) else { continue }
            let at = Vec(p.position.x, min(p.position.y + 20, target.position.y + 100 * target.stature))
            strike(attacker: p.owner, damage: p.spec.damage / Double(p.spec.hits), hitstun: p.spec.hitstun, blockstun: p.spec.blockstun,
                   knockback: p.spec.knockback, impact: p.spec.impact, launches: p.spec.launches, knocksDown: p.spec.knocksDown,
                   chip: 0.12, unblockable: false, grant: p.spec.onHit, at: at, fromProjectile: p.spec.kind, finalHit: p.hitsLeft <= 1)
            projectiles[index].hitsLeft -= 1
            projectiles[index].cooldown = p.spec.hitInterval
            if projectiles[index].hitsLeft <= 0 { projectiles[index].alive = false }
        }
        projectiles.removeAll { !$0.alive }
    }

    // MARK: Rounds

    private mutating func koLanded(_ loser: Int) {
        guard !config.training else { fighters[loser].health = 1; return }
        fighters[loser].health = 0
        if fighters[loser].action != .juggle {
            fighters[loser].action = .juggle; fighters[loser].frame = 0
            fighters[loser].velocity = Vec(6 * (fighters[loser].position.x >= fighters[1 - loser].position.x ? 1 : -1), 9)
            fighters[loser].position.y = max(1, fighters[loser].position.y)
        }
    }

    private mutating func checkRoundEnd() {
        guard case .fighting = phase else { return }
        let down = (0..<2).filter { fighters[$0].health <= 0 }
        if !down.isEmpty {
            let winner: Int? = down.count == 2 ? nil : 1 - down[0]
            for loser in down { events.append(.ko(loser: loser)) }
            endRound(winner: winner)
        } else if timer <= 0 {
            events.append(.timeOver)
            let a = healthFraction(0), b = healthFraction(1)
            endRound(winner: abs(a - b) < 0.0001 ? nil : (a > b ? 0 : 1))
        }
    }

    private mutating func endRound(winner: Int?) {
        projectiles.removeAll()
        hitstop = 0; superFreeze = 0
        let perfect = winner.map { damageTakenThisRound[$0] == 0 } ?? false
        if let w = winner {
            fighters[w].roundsWon += 1
            if perfect { fighters[w].stats.perfectRounds += 1 }
        } else if !suddenDeath {
            fighters[0].roundsWon += 1; fighters[1].roundsWon += 1
        }
        events.append(.roundWon(winner: winner, perfect: perfect))
        phase = .roundOver(remaining: Self.roundOverFrames, winner: winner)
    }

    private mutating func finishRound(winner: Int?) {
        let need = config.roundsToWin
        let a = fighters[0].roundsWon, b = fighters[1].roundsWon
        var matchWinner: Int? = nil
        if suddenDeath, let w = winner { matchWinner = w }
        else if a >= need && b >= need { suddenDeath = true }
        else if a >= need { matchWinner = 0 }
        else if b >= need { matchWinner = 1 }
        if matchWinner == nil && round >= Self.maxRounds {
            matchWinner = healthFraction(0) >= healthFraction(1) ? 0 : 1
        }
        if let w = matchWinner {
            phase = .matchOver(winner: w)
            events.append(.matchWon(winner: w))
            return
        }
        round += 1
        resetRound()
    }

    private mutating func resetRound() {
        for i in 0..<2 {
            fighters[i].health = maxHealth(i)
            fighters[i].position = Vec(i == 0 ? -180 : 180, 0)
            fighters[i].velocity = .zero
            fighters[i].facing = i == 0 ? 1 : -1
            fighters[i].conditions = [:]
            fighters[i].comboTaken = 0; fighters[i].comboDamageTaken = 0; fighters[i].juggleHits = 0
            fighters[i].invulnerable = 0
            fighters[i].input.clear()
            setAction(i, .intro)
        }
        damageTakenThisRound = [0, 0]
        timer = config.roundSeconds * Self.tickRate
        phase = .intro(remaining: Self.introFrames)
        events.append(.roundAnnounced(round: round, final: suddenDeath))
    }
}
