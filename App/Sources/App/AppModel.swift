import SwiftUI
import FightCore

enum SelectPurpose: Equatable {
    case arcade, versusCPU, versusLocal, training

    var title: String {
        switch self {
        case .arcade: "Arcade"
        case .versusCPU: "Versus"
        case .versusLocal: "Two Players"
        case .training: "Training"
        }
    }
}

enum Screen: Equatable {
    case title
    case menu
    case select(SelectPurpose)
    case stageSelect(SelectPurpose, [HeroID], [Bool])
    case ladder
    case versus(FightSetup)
    case fight(FightSetup)
    case results(FightResult)
    case ending(HeroID, score: Int, newBest: Bool)
    case hall
    case hero(HeroID)
    case settings
    case howToPlay
}

@MainActor
final class AppModel: ObservableObject {
    @Published var screen: Screen = .title
    @Published var fightID = UUID()
    let store: ProfileStore

    init(store: ProfileStore? = nil) {
        self.store = store ?? ProfileStore()
        if let route = ProcessInfo.processInfo.environment["AETHERIA_START"] { applyLaunchRoute(route) }
    }

    var profile: Profile {
        get { store.profile }
        set { store.profile = newValue }
    }

    var settings: Profile.Settings { store.profile.settings }

    func go(_ screen: Screen) {
        withAnimation(.easeInOut(duration: 0.25)) { self.screen = screen }
    }

    func applySettings() {
        let s = settings
        AudioManager.shared.musicVolume = Float(s.musicVolume)
        AudioManager.shared.effectsVolume = Float(s.effectsVolume)
        Haptics.enabled = s.haptics
    }

    // MARK: Starting fights

    private func seed() -> UInt64 { UInt64.random(in: 1...UInt64.max) }

    func startArcade(_ hero: HeroID, alt: Bool) {
        profile.lastHero = hero
        profile.arcadeInProgress = ArcadeRun(player: hero, difficulty: settings.difficulty, seed: seed(), rung: 0, score: 0, continuesUsed: 0, altPalette: alt)
        go(.ladder)
    }

    func arcadeSetup() -> FightSetup? {
        guard let run = profile.arcadeInProgress, run.rung < ArcadeLadder.length else { return nil }
        let rung = run.ladder.rungs[run.rung]
        let config = MatchConfig(heroes: [run.player, rung.opponent], stage: rung.stage, roundsToWin: settings.roundsToWin,
                                 roundSeconds: settings.roundSeconds, seed: seed(), bosses: rung.isBoss ? [1] : [])
        return FightSetup(match: config, mode: .arcade(rung: run.rung), cpu: rung.difficulty, altPalette: [run.altPalette, false])
    }

    func startVersus(_ purpose: SelectPurpose, heroes: [HeroID], alt: [Bool], stage: StageID) {
        profile.lastHero = heroes[0]
        let training = purpose == .training
        let config = MatchConfig(heroes: heroes, stage: stage, roundsToWin: training ? 1 : settings.roundsToWin,
                                 roundSeconds: settings.roundSeconds, seed: seed(), training: training)
        let mode: FightMode = switch purpose {
        case .training: .training
        case .versusLocal: .versusLocal
        default: .versusCPU
        }
        let setup = FightSetup(match: config, mode: mode, cpu: purpose == .versusLocal ? nil : settings.difficulty, altPalette: alt)
        go(training ? .fight(setup) : .versus(setup))
    }

    func beginFight(_ setup: FightSetup) {
        fightID = UUID()
        go(.fight(setup))
    }

    // MARK: Results

    func fightFinished(_ result: FightResult) {
        let heroes = result.setup.match.heroes
        let playerWon = result.winner == 0
        profile.matchesPlayed += 1
        profile.totalKOs += result.stats[0].hitsLanded > 0 && playerWon ? result.rounds[0] : 0
        if result.setup.mode != .training {
            profile.update(heroes[0]) { playerWon ? ($0.wins += 1) : ($0.losses += 1) }
            if result.setup.mode == .versusLocal {
                profile.update(heroes[1]) { playerWon ? ($0.losses += 1) : ($0.wins += 1) }
            }
        }

        if case let .arcade(rungIndex) = result.setup.mode, var run = profile.arcadeInProgress {
            if playerWon {
                let rung = run.ladder.rungs[rungIndex]
                run.score += ArcadeLadder.score(winnerHealth: result.healthLeft[0], secondsLeft: result.secondsLeft,
                                                perfectRounds: result.stats[0].perfectRounds, bestCombo: result.stats[0].bestCombo,
                                                rungIndex: rungIndex, difficulty: rung.difficulty)
                run.rung += 1
                if run.rung >= ArcadeLadder.length {
                    let finalScore = max(0, run.score - run.continuesUsed * 20_000)
                    let newBest = finalScore > profile.highScore
                    profile.highScore = max(profile.highScore, finalScore)
                    profile.update(run.player) {
                        $0.arcadeClears += 1
                        $0.bestArcadeScore = max($0.bestArcadeScore, finalScore)
                        if run.difficulty.rawValue >= Difficulty.champion.rawValue { $0.clearedOnChampion = true }
                    }
                    profile.arcadeInProgress = nil
                    AudioManager.shared.play(.reward)
                    go(.ending(run.player, score: finalScore, newBest: newBest))
                    return
                }
                profile.arcadeInProgress = run
            }
        }
        go(.results(result))
    }

    func continueArcade() {
        guard var run = profile.arcadeInProgress else { go(.menu); return }
        run.continuesUsed += 1
        profile.arcadeInProgress = run
        go(.ladder)
    }

    func abandonArcade() {
        profile.arcadeInProgress = nil
        go(.menu)
    }

    // MARK: UI tests and screenshots

    /// `AETHERIA_START=fight:<hero>:<hero>:<stage>` opens straight into a fight
    /// (for UI tests and store screenshots); `menu`, `hall` and `select` open
    /// those screens.
    private func applyLaunchRoute(_ route: String) {
        let parts = route.split(separator: ":").map(String.init)
        switch parts.first {
        case "menu": screen = .menu
        case "hall": screen = .hall
        case "select": screen = .select(.versusCPU)
        case "settings": screen = .settings
        case "hero" where parts.count >= 2:
            if let hero = HeroID(rawValue: parts[1]) { screen = .hero(hero) }
        case "ladder":
            let hero = parts.count >= 2 ? HeroID(rawValue: parts[1]) ?? .gaius : .gaius
            store.profile.arcadeInProgress = ArcadeRun(player: hero, difficulty: .soldier, seed: 42, rung: parts.count >= 3 ? Int(parts[2]) ?? 0 : 0,
                                                       score: 48_250, continuesUsed: 0, altPalette: false)
            screen = .ladder
        case "ending" where parts.count >= 2:
            if let hero = HeroID(rawValue: parts[1]) { screen = .ending(hero, score: 412_900, newBest: true) }
        case "versus" where parts.count >= 3:
            if let a = HeroID(rawValue: parts[1]), let b = HeroID(rawValue: parts[2]) {
                let config = MatchConfig(heroes: [a, b], stage: StageID.home(of: b.hero.empire), seed: 3)
                screen = .versus(FightSetup(match: config, mode: .versusCPU, cpu: .soldier))
            }
        case "results" where parts.count >= 3:
            if let a = HeroID(rawValue: parts[1]), let b = HeroID(rawValue: parts[2]) {
                let config = MatchConfig(heroes: [a, b], stage: StageID.home(of: a.hero.empire), seed: 3)
                var stats = FightStats(); stats.damageDealt = 1840; stats.hitsLanded = 42; stats.bestCombo = 7; stats.blocks = 11; stats.throwsLanded = 2; stats.supersUsed = 1; stats.perfectRounds = 1
                screen = .results(FightResult(setup: FightSetup(match: config, mode: .versusCPU, cpu: .soldier), winner: 0, stats: [stats, FightStats()],
                                              healthLeft: [0.62, 0], secondsLeft: 41, rounds: [2, 0]))
            }
        case "fight" where parts.count >= 4:
            if let a = HeroID(rawValue: parts[1]), let b = HeroID(rawValue: parts[2]), let stage = StageID(rawValue: parts[3]) {
                let config = MatchConfig(heroes: [a, b], stage: stage, roundsToWin: 2, roundSeconds: 99, seed: 7, bosses: parts.count > 4 && parts[4] == "boss" ? [1] : [])
                var setup = FightSetup(match: config, mode: .versusCPU, cpu: .champion)
                setup.demo = parts.contains("demo")
                screen = .fight(setup)
            }
        default: break
        }
    }
}
