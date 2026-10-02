public enum FighterAction: Equatable, Sendable {
    case idle
    case walk
    case guarding
    case jumpSquat
    case airborne
    case landing
    case dash(back: Bool)
    case attack(MoveSlot)
    case blockstun
    case hitstun
    /// Knocked into the air; falls to a knockdown.
    case juggle
    case knockdown
    case getUp
    /// Caught in a throw (or throwing), during the window a throw can be broken.
    case throwHold(attacker: Bool)
    case ko
    case victory
    case intro

    public var isAttack: Bool { if case .attack = self { return true } else { return false } }
    public var attackSlot: MoveSlot? { if case let .attack(slot) = self { return slot } else { return nil } }
}

public struct ActiveCondition: Equatable, Codable, Sendable {
    public var frames: Int
    public var magnitude: Double
}

/// Per-fighter numbers for the results screen.
public struct FightStats: Equatable, Codable, Sendable {
    public var damageDealt: Double = 0
    public var hitsLanded = 0
    public var bestCombo = 0
    public var blocks = 0
    public var throwsLanded = 0
    public var specialsUsed = 0
    public var supersUsed = 0
    public var perfectRounds = 0

    public init() {}
}

public struct Fighter: Sendable {
    public let index: Int
    public let hero: Hero
    public let moves: MoveSet
    public let maxHealth: Double

    public var health: Double
    public var meter: Double = 0
    public var position: Vec
    public var velocity: Vec = .zero
    /// +1 facing right, -1 facing left.
    public var facing: Double
    public var action: FighterAction = .intro
    /// Ticks spent in the current action, from 1.
    public var frame = 0
    /// Ticks of hitstun, blockstun, knockdown or landing left.
    public var stun = 0
    public var input = InputBuffer()

    // The move in progress.
    public var moveConnected = false
    public var moveHitsDealt = 0
    public var nextHitFrame = 0
    public var armorLeft = 0
    public var counterTriggeredAt: Int? = nil
    public var airAttackUsed = false
    public var landingLag = 4

    // Taking a combo.
    public var comboTaken = 0
    public var comboDamageTaken: Double = 0
    public var juggleHits = 0
    public var invulnerable = 0

    public var conditions: [Condition: ActiveCondition] = [:]
    public var roundsWon = 0
    public var stats = FightStats()
    /// A mirror-image boss gets an edge; 1 for everyone else.
    public var bossScale: Double = 1

    public init(index: Int, hero: Hero, position: Vec, facing: Double) {
        self.index = index
        self.hero = hero
        self.moves = MoveSet.forHero(hero)
        self.maxHealth = hero.stats.health
        self.health = hero.stats.health
        self.position = position
        self.facing = facing
    }

    public var grounded: Bool { position.y <= 0 }
    public var healthFraction: Double { max(0, health / maxHealth) }
    public var isKO: Bool { action == .ko }
    public var stature: Double { hero.stats.stature }

    public var currentMove: Move? { action.attackSlot.map { moves[$0] } }

    public func condition(_ c: Condition) -> Double { conditions[c].map { $0.magnitude } ?? 0 }

    /// Can start a new action from neutral.
    public var isActionable: Bool {
        switch action {
        case .idle, .walk, .guarding: true
        case .landing: stun <= 0
        default: false
        }
    }

    public var canGuard: Bool {
        switch action {
        case .idle, .walk, .guarding, .blockstun: true
        case .landing: true
        default: false
        }
    }

    /// In the startup of an attack: a hit now is a counter hit.
    public var inStartup: Bool {
        guard let move = currentMove else { return false }
        return frame <= move.startup
    }

    public var isThrowable: Bool {
        guard grounded, invulnerable == 0 else { return false }
        switch action {
        case .idle, .walk, .guarding, .landing, .dash: return true
        case let .attack(slot): return !(moves[slot].invulnerable?.contains(frame) ?? false)
        default: return false
        }
    }

    public var isStrikeInvulnerable: Bool {
        if invulnerable > 0 { return true }
        switch action {
        case .knockdown, .getUp, .ko, .throwHold, .intro, .victory: return true
        case .juggle: return juggleHits >= Match.juggleLimit
        case .dash(back: true): return frame <= 6
        case let .attack(slot): return moves[slot].invulnerable?.contains(frame) ?? false
        default: return false
        }
    }

    /// Where the fighter can be hit, in world space.
    public var hurtboxes: [Box] {
        let s = stature
        switch action {
        case .knockdown, .getUp, .ko: return []
        case .juggle:
            return [Box(local: LocalBox(x: -48 * s, y: 0, width: 96 * s, height: 70 * s), origin: position, facing: facing)]
        case .airborne:
            return [Box(local: LocalBox(x: -26 * s, y: 14 * s, width: 52 * s, height: 140 * s), origin: position, facing: facing)]
        default:
            var boxes = [Box(local: LocalBox(x: -26 * s, y: 0, width: 52 * s, height: 176 * s), origin: position, facing: facing)]
            // A swinging limb can be hit while it is out and coming back.
            if let move = currentMove, move.hitbox.width > 0, frame > move.startup, move.slot != .throwAttempt {
                var reach = move.hitbox
                reach.width *= 0.7
                boxes.append(Box(local: reach, origin: position, facing: facing))
            }
            return boxes
        }
    }

    public var pushWidth: Double { 22 * stature }
}
