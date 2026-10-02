import SwiftUI
import SpriteKit
import FightCore

/// Hosts the SpriteKit fight and the SwiftUI pause menu over it.
struct FightView: View {
    let setup: FightSetup
    @EnvironmentObject private var model: AppModel
    @State private var scene: FightScene?
    @State private var paused = false
    @State private var showMoves = false
    @State private var dummy: TrainingDummy = .stand
    @State private var hitboxes = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let scene {
                    SpriteSceneView(scene: scene, label: "Fight between \(setup.match.heroes[0].hero.name) and \(setup.match.heroes[1].hero.name)")
                        .ignoresSafeArea()
                }
                if paused { pauseMenu.transition(.opacity) }
            }
            .onAppear { makeScene(size: geo.size) }
        }
        .ignoresSafeArea()
        .onChange(of: scenePhase) { _, phase in
            if phase != .active, !paused { pause(true) }
        }
        .onDisappear { scene?.setPaused(true) }
    }

    private func makeScene(size: CGSize) {
        guard scene == nil else { return }
        let scene = FightScene(setup: setup, size: size, settings: model.settings)
        scene.onPause = { pause(true) }
        scene.onFinish = { result in
            DispatchQueue.main.async { model.fightFinished(result) }
        }
        self.scene = scene
    }

    private func pause(_ value: Bool) {
        withAnimation(.easeOut(duration: 0.15)) { paused = value }
        scene?.setPaused(value)
        if !value { showMoves = false }
    }

    private var pauseMenu: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            HStack(alignment: .top, spacing: 24) {
                VStack(spacing: 12) {
                    Text("PAUSED").font(Theme.display(34)).foregroundStyle(Theme.gold)
                    Button("Resume") { playTap(); pause(false) }.buttonStyle(GameButtonStyle(prominent: true))
                    Button(showMoves ? "Hide Moves" : "Move List") { playTap(); showMoves.toggle() }.buttonStyle(GameButtonStyle())
                    if setup.mode == .versusCPU || setup.mode == .versusLocal {
                        Button("Restart") { playTap(); model.beginFight(setup) }.buttonStyle(GameButtonStyle())
                    }
                    if case .arcade = setup.mode {
                        Button("Retire from Arcade") { playTap(); model.abandonArcade() }.buttonStyle(GameButtonStyle())
                    }
                    Button(setup.mode == .training ? "Leave Training" : "Quit to Menu") {
                        playTap()
                        model.go(.menu)
                    }
                    .buttonStyle(GameButtonStyle())
                }
                if setup.mode == .training || showMoves {
                    VStack(alignment: .leading, spacing: 10) {
                        if setup.mode == .training {
                            Text("TRAINING").font(Theme.heading(16)).foregroundStyle(Theme.gold)
                            Picker("Dummy", selection: $dummy) {
                                ForEach(TrainingDummy.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: dummy) { _, value in scene?.trainingDummy = value }
                            Toggle("Show hitboxes", isOn: $hitboxes)
                                .font(Theme.heading(13))
                                .tint(Theme.gold)
                                .onChange(of: hitboxes) { _, value in scene?.showHitboxes = value }
                        }
                        if showMoves || setup.mode == .training {
                            MoveListView(hero: setup.match.heroes[0])
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: 380)
                    .panel()
                }
            }
            .padding(24)
        }
    }
}

/// The SKView bridge. Keeps the scene running at 60 fps.
struct SpriteSceneView: UIViewRepresentable {
    let scene: SKScene
    var label = ""

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.preferredFramesPerSecond = 60
        view.ignoresSiblingOrder = false
        view.isMultipleTouchEnabled = true
        view.shouldCullNonVisibleNodes = true
        // One accessibility element whose value reports both fighters' health.
        view.isAccessibilityElement = true
        view.accessibilityIdentifier = "fight"
        view.accessibilityLabel = label
        view.accessibilityTraits = [.allowsDirectInteraction, .updatesFrequently]
        #if DEBUG
        view.showsFPS = ProcessInfo.processInfo.arguments.contains("-showFPS")
        view.showsNodeCount = ProcessInfo.processInfo.arguments.contains("-showFPS")
        #endif
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        if view.scene !== scene { view.presentScene(scene) }
    }
}

/// Every command, and the hero's own special and super.
struct MoveListView: View {
    let hero: HeroID

    var body: some View {
        let h = hero.hero
        VStack(alignment: .leading, spacing: 6) {
            Text("\(h.name.uppercased()) · MOVES").font(Theme.heading(14)).foregroundStyle(Theme.gold)
            row("Light chain", "L, L, L")
            row("Heavy", "H")
            row(h.specialName, "S", detail: h.specialDescription)
            row(h.superName, "✦ with a full Aether meter", detail: h.superDescription)
            row("Throw", "T, or hold G and tap L — breaks a guard")
            row("Break a throw", "G + L as you are caught")
            row("Guard", "hold G")
            row("Jump / dash", "stick up · flick or double-tap the stick")
            row("Cancels", "L chain → H → S → ✦ when a blow connects")
        }
    }

    private func row(_ name: String, _ input: String, detail: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack {
                Text(name).font(Theme.heading(12)).foregroundStyle(.white)
                Spacer()
                Text(input).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Theme.gold)
            }
            if let detail { Text(detail).font(Theme.lore(13)).foregroundStyle(.white.opacity(0.75)).fixedSize(horizontal: false, vertical: true) }
        }
    }
}
