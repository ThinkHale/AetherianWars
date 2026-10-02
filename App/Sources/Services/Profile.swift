import Foundation
import FightCore

/// Everything the game remembers between launches, saved as JSON in
/// UserDefaults. Small, local, and never sent anywhere.
struct Profile: Codable, Equatable {
    struct Settings: Codable, Equatable {
        var musicVolume = 0.7
        var effectsVolume = 0.9
        var haptics = true
        var screenShake = true
        var difficulty: Difficulty = .soldier
        var roundsToWin = 2
        var roundSeconds = 99
        var showInputHints = true
        /// Puts the attack buttons on the left and the stick on the right.
        var swapControls = false
        var controlsScale = 1.0
        var controlsOpacity = 0.85
    }

    struct HeroRecord: Codable, Equatable {
        var wins = 0
        var losses = 0
        var arcadeClears = 0
        var bestArcadeScore = 0
        /// Cleared arcade on Champion or higher; unlocks the alternate palette.
        var clearedOnChampion = false
    }

    var settings = Settings()
    var heroes: [String: HeroRecord] = [:]
    var highScore = 0
    var totalKOs = 0
    var matchesPlayed = 0
    var seenHowToPlay = false
    var lastHero: HeroID? = nil
    var arcadeInProgress: ArcadeRun? = nil

    func record(_ hero: HeroID) -> HeroRecord { heroes[hero.rawValue] ?? HeroRecord() }

    mutating func update(_ hero: HeroID, _ change: (inout HeroRecord) -> Void) {
        var record = record(hero)
        change(&record)
        heroes[hero.rawValue] = record
    }

    /// The palette unlocked for a hero by clearing arcade with them.
    func hasAltPalette(_ hero: HeroID) -> Bool { record(hero).arcadeClears > 0 }
}

/// An arcade run in progress, so quitting mid-ladder can be resumed.
struct ArcadeRun: Codable, Equatable {
    var player: HeroID
    var difficulty: Difficulty
    var seed: UInt64
    var rung: Int
    var score: Int
    var continuesUsed: Int
    var altPalette: Bool

    var ladder: ArcadeLadder { ArcadeLadder(player: player, base: difficulty, seed: seed) }
}

@MainActor
final class ProfileStore: ObservableObject {
    static let key = "aetheria.clash.profile.v1"

    @Published var profile: Profile {
        didSet { save() }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if ProcessInfo.processInfo.arguments.contains("-resetProfile") {
            defaults.removeObject(forKey: Self.key)
        }
        if let data = defaults.data(forKey: Self.key), let saved = try? JSONDecoder().decode(Profile.self, from: data) {
            profile = saved
        } else {
            profile = Profile()
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
