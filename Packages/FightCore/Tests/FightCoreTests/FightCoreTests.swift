import XCTest
@testable import FightCore

final class FightCoreTests: XCTestCase {
    private func fightingMatch(_ a: HeroID = .gaius, _ b: HeroID = .bardiya, training: Bool = false) -> Match {
        var match = Match(config: MatchConfig(heroes: [a, b], stage: .forum, seed: 7, training: training))
        for _ in 0..<Match.introFrames { match.tick([[], []]) }
        XCTAssertEqual(match.phase, .fighting)
        return match
    }

    /// Ticks until a predicate holds (or fails after `limit`).
    private func run(_ match: inout Match, limit: Int = 600, inputs: (Match) -> [Controls], until: (Match) -> Bool) -> Bool {
        for _ in 0..<limit {
            match.tick(inputs(match))
            if until(match) { return true }
        }
        return false
    }

    private func walkTogether(_ match: inout Match) {
        _ = run(&match, limit: 300, inputs: { _ in [[.right], [.left]] }, until: { abs($0.fighters[0].position.x - $0.fighters[1].position.x) < 70 })
        for _ in 0..<4 { match.tick([[], []]) }
    }

    func testRosterIsCompleteAndMatchesTheCatalog() {
        XCTAssertEqual(Roster.all.count, 13)
        XCTAssertEqual(Set(Roster.selectOrder), Set(HeroID.allCases))
        for hero in Roster.all {
            XCTAssertFalse(hero.quote.isEmpty)
            XCTAssertFalse(hero.specialName.isEmpty)
            let moves = MoveSet.forHero(hero)
            for slot in MoveSlot.allCases { XCTAssertNotNil(moves.moves[slot], "\(hero.name) lacks \(slot)") }
        }
        XCTAssertEqual(Set(Roster.all.map(\.empire)), Set(Empire.allCases))
    }

    func testIntroAnnouncesRoundThenFight() {
        var match = Match(config: MatchConfig(heroes: [.livia, .nefru], stage: .forum))
        XCTAssertEqual(match.events, [.roundAnnounced(round: 1, final: false)])
        var sawFight = false
        for _ in 0..<Match.introFrames { match.tick([[.light], [.light]]); if match.events.contains(.fight) { sawFight = true } }
        XCTAssertTrue(sawFight)
        XCTAssertEqual(match.fighters[0].health, match.fighters[0].maxHealth, "nothing lands during the intro")
    }

    func testWalkingAndFacing() {
        var match = fightingMatch()
        let start = match.fighters[0].position.x
        for _ in 0..<30 { match.tick([[.right], []]) }
        XCTAssertGreaterThan(match.fighters[0].position.x, start + 60)
        XCTAssertEqual(match.fighters[0].facing, 1)
        XCTAssertEqual(match.fighters[1].facing, -1)
    }

    func testJabHitsAndDamages() {
        var match = fightingMatch()
        walkTogether(&match)
        let before = match.fighters[1].health
        let landed = run(&match, limit: 30, inputs: { m in m.fighters[0].action == .idle ? [[.light], []] : [[], []] }, until: { $0.fighters[1].health < before })
        XCTAssertTrue(landed)
        XCTAssertEqual(match.fighters[1].action, .hitstun)
    }

    func testGuardBlocksAndChipOnlyFromSpecials() {
        var match = fightingMatch(.gaius, .zhaoLin)
        walkTogether(&match)
        let before = match.fighters[1].health
        var blocked = false
        _ = run(&match, limit: 40, inputs: { m in [m.fighters[0].action == .idle ? [.light] : [], [.guardButton]] }, until: { m in
            if m.events.contains(where: { if case .blocked = $0 { return true }; return false }) { blocked = true }
            return blocked
        })
        XCTAssertTrue(blocked)
        XCTAssertEqual(match.fighters[1].health, before, "a jab does no chip damage")
    }

    func testThrowBeatsGuard() {
        var match = fightingMatch(.weiJian, .livia)
        walkTogether(&match)
        let before = match.fighters[1].health
        let thrown = run(&match, limit: 60, inputs: { m in
            [m.fighters[0].isActionable ? [.guardButton, .light] : [.guardButton], [.guardButton]]
        }, until: { $0.fighters[1].health < before })
        XCTAssertTrue(thrown)
    }

    func testThrowCanBeBroken() {
        var match = fightingMatch()
        walkTogether(&match)
        var broken = false
        var step = 0
        _ = run(&match, limit: 60, inputs: { m in
            step += 1
            let p1: Controls = step == 1 ? [.guardButton, .light] : []
            let caught: Bool = { if case .throwHold(attacker: false) = m.fighters[1].action { return true }; return false }()
            return [p1, caught && m.fighters[1].frame == 3 ? [.guardButton, .light] : (caught ? [.guardButton] : [])]
        }, until: { m in
            if m.events.contains(where: { if case .throwBroken = $0 { return true }; return false }) { broken = true }
            return broken
        })
        XCTAssertTrue(broken)
        XCTAssertEqual(match.fighters[1].health, match.fighters[1].maxHealth)
    }

    func testLightChainComboScalesDamage() {
        var match = fightingMatch(.marcusVarro, .gaius)
        walkTogether(&match)
        var hits: [Double] = []
        var tick = 0
        _ = run(&match, limit: 90, inputs: { _ in
            tick += 1
            return [tick % 4 == 1 ? [.light] : [], []]
        }, until: { m in
            for event in m.events { if case let .hit(attacker: 0, _, _, damage, _, _) = event { hits.append(damage) } }
            return hits.count >= 3
        })
        XCTAssertEqual(hits.count, 3, "jab, follow and finisher chain")
        XCTAssertEqual(match.fighters[0].stats.bestCombo, 3)
    }

    func testProjectileTravelsAndHits() {
        var match = fightingMatch(.zhaoLin, .gaius)
        let before = match.fighters[1].health
        var launched = false
        let hit = run(&match, limit: 120, inputs: { m in [m.fighters[0].isActionable && !launched ? [.special] : [], []] }, until: { m in
            if m.events.contains(where: { if case .projectileLaunched = $0 { return true }; return false }) { launched = true }
            return m.fighters[1].health < before
        })
        XCTAssertTrue(launched)
        XCTAssertTrue(hit)
    }

    func testCounterStanceAnswersAStrike() {
        var match = fightingMatch(.bardiya, .gaius)
        walkTogether(&match)
        // Gaius raises the shield; Bardiya jabs into it.
        match.tick([[], [.special]])
        for _ in 0..<5 { match.tick([[], []]) }
        var countered = false
        let before = match.fighters[0].health
        _ = run(&match, limit: 60, inputs: { m in [m.fighters[0].isActionable ? [.light] : [], []] }, until: { m in
            if m.events.contains(.counterTriggered(defender: 1)) { countered = true }
            return countered && m.fighters[0].health < before
        })
        XCTAssertTrue(countered)
        XCTAssertLessThan(match.fighters[0].health, before)
    }

    func testArmorAbsorbsAHit() {
        var match = fightingMatch(.gaius, .bardiya)
        walkTogether(&match)
        match.tick([[], [.special]])
        for _ in 0..<3 { match.tick([[], []]) }
        var absorbed = false
        _ = run(&match, limit: 30, inputs: { m in [m.fighters[0].isActionable ? [.light] : [], []] }, until: { m in
            absorbed = absorbed || m.events.contains(where: { if case .armorAbsorbed = $0 { return true }; return false })
            return absorbed
        })
        XCTAssertTrue(absorbed)
        XCTAssertEqual(match.fighters[1].action, .attack(.special), "the advance carries on")
    }

    func testSuperNeedsAFullMeter() {
        var match = fightingMatch(.atossa, .meiLin)
        match.tick([[.superArt], []])
        match.tick([[], []])
        XCTAssertNotEqual(match.fighters[0].action, .attack(.superArt))
        var training = fightingMatch(.atossa, .meiLin, training: true)
        training.tick([[], []])
        training.tick([[.superArt], []])
        XCTAssertEqual(training.fighters[0].action, .attack(.superArt))
        XCTAssertGreaterThan(training.superFreeze, 0)
    }

    func testJumpLandsAndAirAttack() {
        var match = fightingMatch()
        _ = run(&match, limit: 10, inputs: { _ in [[.up], []] }, until: { $0.fighters[0].action == .airborne })
        XCTAssertFalse(match.fighters[0].grounded)
        match.tick([[.heavy], []])
        XCTAssertEqual(match.fighters[0].action, .attack(.airHeavy))
        let landed = run(&match, limit: 90, inputs: { _ in [[], []] }, until: { $0.fighters[0].grounded && $0.fighters[0].action == .idle })
        XCTAssertTrue(landed)
    }

    func testKnockoutEndsRoundAndMatch() {
        var match = Match(config: MatchConfig(heroes: [.nefru, .tahmina], stage: .nile, roundsToWin: 1, seed: 3))
        var cpu = CPU(difficulty: .legend, seed: 1)
        var dummyWon = false
        for _ in 0..<(60 * 200) {
            let p2 = cpu.controls(for: 1, in: match)
            match.tick([[], p2])
            if match.events.contains(.matchWon(winner: 1)) { dummyWon = true; break }
        }
        XCTAssertTrue(dummyWon, "a CPU beats an idle opponent")
        XCTAssertTrue(match.isOver)
    }

    func testTimeOverGoesToHealthLead() {
        var match = Match(config: MatchConfig(heroes: [.gaius, .livia], stage: .forum, roundsToWin: 1, roundSeconds: 3))
        for _ in 0..<Match.introFrames { match.tick([[], []]) }
        walkTogether(&match)
        match.tick([[.light], []])
        var timeOver = false
        for _ in 0..<(60 * 5 + Match.roundOverFrames) {
            match.tick([[], []])
            if match.events.contains(.timeOver) { timeOver = true }
        }
        XCTAssertTrue(timeOver)
        XCTAssertEqual(match.phase, .matchOver(winner: 0))
    }

    func testCPUsFightToAResultForEveryHero() {
        // Every commander can finish a match against every class without the
        // simulation stalling or going out of bounds.
        for (index, hero) in HeroID.allCases.enumerated() {
            let foe = HeroID.allCases[(index + 5) % HeroID.allCases.count]
            var match = Match(config: MatchConfig(heroes: [hero, foe], stage: .crossing, seed: UInt64(index + 1)))
            var a = CPU(difficulty: .champion, seed: UInt64(index * 2 + 1))
            var b = CPU(difficulty: .champion, seed: UInt64(index * 2 + 2))
            var ticks = 0
            while !match.isOver && ticks < 60 * 60 * 8 {
                let inputs = [a.controls(for: 0, in: match), b.controls(for: 1, in: match)]
                match.tick(inputs)
                ticks += 1
                for f in match.fighters {
                    XCTAssertLessThanOrEqual(abs(f.position.x), Match.stageHalfWidth + 0.001)
                    XCTAssertGreaterThanOrEqual(f.position.y, 0)
                }
                XCTAssertLessThanOrEqual(abs(match.fighters[0].position.x - match.fighters[1].position.x), Match.maxSeparation + 30)
            }
            XCTAssertTrue(match.isOver, "\(hero) vs \(foe) never finished")
            let landed = match.fighters.map(\.stats.hitsLanded).reduce(0, +)
            XCTAssertGreaterThan(landed, 5, "\(hero) vs \(foe): the CPUs barely fought")
        }
    }

    func testDeterministic() {
        func play() -> [Double] {
            var match = Match(config: MatchConfig(heroes: [.khepri, .meritamun], stage: .nile, seed: 99))
            var a = CPU(difficulty: .soldier, seed: 5), b = CPU(difficulty: .legend, seed: 6)
            for _ in 0..<3000 { match.tick([a.controls(for: 0, in: match), b.controls(for: 1, in: match)]) }
            return match.fighters.map(\.health) + match.fighters.map(\.position.x)
        }
        XCTAssertEqual(play(), play())
    }

    func testArcadeLadder() {
        let ladder = ArcadeLadder(player: .bardiya, base: .soldier, seed: 42)
        XCTAssertEqual(ladder.rungs.count, ArcadeLadder.length)
        XCTAssertEqual(ladder.rungs[5].opponent, .atossa, "the rival waits second to last")
        XCTAssertTrue(ladder.rungs[5].isRival)
        XCTAssertTrue(ladder.rungs[6].isBoss)
        XCTAssertEqual(ladder.rungs[6].opponent, .bardiya)
        XCTAssertEqual(ladder.rungs[6].stage, .crossing)
        XCTAssertEqual(Set(ladder.rungs.prefix(6).map(\.opponent)).count, 6, "no repeats")
        XCTAssertFalse(ladder.rungs.prefix(6).contains { $0.opponent == .bardiya })
    }

    func testInputBufferDoubleTapDash() {
        var match = fightingMatch()
        match.tick([[.right], []]); match.tick([[], []]); match.tick([[.right], []])
        XCTAssertEqual(match.fighters[0].action, .dash(back: false))
    }
}
