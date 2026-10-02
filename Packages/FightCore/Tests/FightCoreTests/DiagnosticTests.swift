import XCTest
@testable import FightCore

final class DiagnosticTests: XCTestCase {
    func testArcherDiagnostics() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["DIAG"] != nil)
        for (a, b) in [(HeroID.meritamun, HeroID.gaius), (.nefru, .weiJian), (.meiLin, .khepri)] {
            var projectileHits = 0, projectileBlocked = 0, launched = 0, meleeHits = [0, 0], distanceSum = 0.0, ticksTotal = 0
            var stats: [FightStats] = []
            for seed in 0..<6 {
                var m = Match(config: MatchConfig(heroes: [a, b], stage: .crossing, seed: UInt64(seed + 1)))
                var ca = CPU(difficulty: .champion, seed: UInt64(seed * 3 + 1)), cb = CPU(difficulty: .champion, seed: UInt64(seed * 3 + 2))
                while !m.isOver {
                    let projBefore = m.projectiles.filter { $0.owner == 0 }.map(\.id)
                    m.tick([ca.controls(for: 0, in: m), cb.controls(for: 1, in: m)])
                    ticksTotal += 1
                    distanceSum += abs(m.fighters[0].position.x - m.fighters[1].position.x)
                    for e in m.events {
                        switch e {
                        case .projectileLaunched(owner: 0, _): launched += 1
                        case let .hit(attacker, _, _, _, _, _):
                            if attacker == 0 && !projBefore.isEmpty && m.fighters[0].currentMove?.slot != .light1 { projectileHits += 0 }
                            meleeHits[attacker] += 1
                        case .blocked(defender: 1, _, _): projectileBlocked += 1
                        default: break
                        }
                    }
                }
                stats.append(contentsOf: m.fighters.map(\.stats))
            }
            let a0 = stats.enumerated().filter { $0.offset % 2 == 0 }.map(\.element)
            let b0 = stats.enumerated().filter { $0.offset % 2 == 1 }.map(\.element)
            print("DIAG \(a)-vs-\(b): launched \(launched) blocksByB \(projectileBlocked) hits A \(meleeHits[0]) B \(meleeHits[1]) avgDist \(Int(distanceSum / Double(ticksTotal)))",
                  "dmgA \(Int(a0.map(\.damageDealt).reduce(0, +))) dmgB \(Int(b0.map(\.damageDealt).reduce(0, +)))",
                  "specialsA \(a0.map(\.specialsUsed).reduce(0, +)) specialsB \(b0.map(\.specialsUsed).reduce(0, +)) blocksA \(a0.map(\.blocks).reduce(0,+)) blocksB \(b0.map(\.blocks).reduce(0,+)) throwsA \(a0.map(\.throwsLanded).reduce(0,+)) throwsB \(b0.map(\.throwsLanded).reduce(0,+))")
        }
    }
}
