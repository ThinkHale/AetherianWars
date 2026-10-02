/// One arcade run: a ladder of commanders drawn through the mist of the
/// Crossing, the player's rival second to last, and at the top the Echo of the
/// Crossing — the mist wearing the player's own face.
public struct ArcadeLadder: Sendable, Equatable {
    public struct Rung: Sendable, Equatable, Identifiable {
        public let id: Int
        public let opponent: HeroID
        public let stage: StageID
        public let isRival: Bool
        public let isBoss: Bool
        public let difficulty: Difficulty
    }

    public static let length = 7

    public let player: HeroID
    public let rungs: [Rung]

    public init(player: HeroID, base: Difficulty, seed: UInt64) {
        self.player = player
        var rng = SeededRandom(seed: seed)
        let rival = player.hero.rival?.id
        var pool = HeroID.allCases.filter { $0 != player && $0 != rival }
        for index in stride(from: pool.count - 1, to: 0, by: -1) {
            pool.swapAt(index, rng.int(0...index))
        }
        var opponents = Array(pool.prefix(Self.length - 2))
        opponents.append(rival ?? pool[Self.length - 2])
        var rungs: [Rung] = []
        for (index, opponent) in opponents.enumerated() {
            // The ladder climbs one difficulty step through its second half.
            let step = index >= 3 ? 1 : 0
            let difficulty = Difficulty(rawValue: min(Difficulty.legend.rawValue, base.rawValue + step)) ?? base
            rungs.append(Rung(id: index, opponent: opponent, stage: StageID.home(of: opponent.hero.empire),
                              isRival: opponent == rival, isBoss: false, difficulty: difficulty))
        }
        let bossDifficulty = Difficulty(rawValue: min(Difficulty.legend.rawValue, base.rawValue + 1)) ?? base
        rungs.append(Rung(id: Self.length - 1, opponent: player, stage: .crossing, isRival: false, isBoss: true, difficulty: bossDifficulty))
        self.rungs = rungs
    }

    /// Score for a won fight, for the arcade high score.
    public static func score(winnerHealth: Double, secondsLeft: Int, perfectRounds: Int, bestCombo: Int, rungIndex: Int, difficulty: Difficulty) -> Int {
        let base = 10_000 + Int(winnerHealth * 20_000) + secondsLeft * 100 + perfectRounds * 15_000 + bestCombo * 500
        return base * (rungIndex + 1) * (difficulty.rawValue + 2) / 2
    }
}
