import SwiftUI
import FightCore

@main
struct AetheriaClashApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .environmentObject(model.store)
                .preferredColorScheme(.dark)
                .persistentSystemOverlays(.hidden)
                .statusBarHidden()
                .onAppear {
                    AudioManager.shared.start()
                    model.applySettings()
                    Haptics.prepare()
                    _ = ControllerInput.shared
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { AudioManager.shared.resume() }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch model.screen {
            case .title: TitleView().transition(.opacity)
            case .menu: MainMenuView().transition(.opacity)
            case let .select(purpose): CharacterSelectView(purpose: purpose).transition(.opacity)
            case let .stageSelect(purpose, heroes, alt): StageSelectView(purpose: purpose, heroes: heroes, alt: alt).transition(.opacity)
            case .ladder: LadderView().transition(.opacity)
            case let .versus(setup): VersusView(setup: setup).transition(.opacity)
            case let .fight(setup): FightView(setup: setup).id(model.fightID).transition(.opacity)
            case let .results(result): ResultsView(result: result).transition(.opacity)
            case let .ending(hero, score, newBest): EndingView(hero: hero, score: score, newBest: newBest).transition(.opacity)
            case .hall: HallOfHeroesView().transition(.opacity)
            case let .hero(hero): HeroDetailView(hero: hero).transition(.opacity)
            case .settings: SettingsView().transition(.opacity)
            case .howToPlay: HowToPlayView().transition(.opacity)
            }
        }
        .onChange(of: model.screen) { _, screen in
            switch screen {
            case .title, .menu, .settings, .howToPlay: AudioManager.shared.playMusic(.title)
            case .select, .stageSelect, .ladder, .hall, .hero, .versus: AudioManager.shared.playMusic(.select)
            case .ending: AudioManager.shared.playMusic(.title)
            default: break
            }
        }
        .onAppear { AudioManager.shared.playMusic(.title) }
    }
}
