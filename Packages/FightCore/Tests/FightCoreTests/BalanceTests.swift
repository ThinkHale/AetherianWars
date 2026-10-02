import XCTest
@testable import FightCore

/// Round-robin between equal CPUs: every commander should win a fair share.
/// Not proof of balance between people, but it catches a broken move fast.
final class BalanceTests: XCTestCase {
    static func winRates(seeds: Int = 3, difficulty: Difficulty = .champion) -> [HeroID: Double] {
        var wins: [HeroID: Int] = [:], games: [HeroID: Int] = [:]
        for a in HeroID.allCases {
            for b in HeroID.allCases where a != b {
                for seed in 0..<seeds {
                    var match = Match(config: MatchConfig(heroes: [a, b], stage: .crossing, roundsToWin: 2, seed: UInt64(seed * 31 + 7)))
                    var cpuA = CPU(difficulty: difficulty, seed: UInt64(seed * 2 + 1)), cpuB = CPU(difficulty: difficulty, seed: UInt64(seed * 2 + 2))
                    var ticks = 0
                    while !match.isOver && ticks < 60 * 60 * 10 {
                        match.tick([cpuA.controls(for: 0, in: match), cpuB.controls(for: 1, in: match)])
                        ticks += 1
                    }
                    guard case let .matchOver(winner) = match.phase else { continue }
                    let w = winner == 0 ? a : b
                    wins[w, default: 0] += 1
                    games[a, default: 0] += 1; games[b, default: 0] += 1
                }
            }
        }
        return Dictionary(uniqueKeysWithValues: HeroID.allCases.map { ($0, Double(wins[$0] ?? 0) / Double(max(1, games[$0] ?? 1))) })
    }

    func testNoCommanderDominates() {
        let rates = Self.winRates()
        for (hero, rate) in rates.sorted(by: { $0.value > $1.value }) {
            print(String(format: "BALANCE %-14@ %.2f", hero.rawValue as NSString, rate))
        }
        for (hero, rate) in rates {
            XCTAssertGreaterThan(rate, 0.32, "\(hero) wins too rarely")
            XCTAssertLessThan(rate, 0.68, "\(hero) wins too often")
        }
    }
}
