import SwiftUI
import FightCore

struct HallOfHeroesView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var store: ProfileStore

    private let columns = [GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 12)]

    var body: some View {
        ZStack {
            Backdrop(name: "commanders", dim: 0.75)
            VStack(spacing: 10) {
                ScreenHeader(title: "Hall of Heroes", subtitle: "The commanders of Aetheria") { model.go(.menu) }
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Roster.selectOrder) { id in
                            Button { playTap(); model.go(.hero(id)) } label: {
                                VStack(spacing: 0) {
                                    PortraitView(hero: id).frame(height: 150).clipped()
                                    VStack(spacing: 1) {
                                        Text(id.hero.name.uppercased()).font(Theme.heading(11)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.7)
                                        Text(id.hero.title).font(Theme.lore(12)).foregroundStyle(Theme.gold).lineLimit(1).minimumScaleFactor(0.7)
                                    }
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity)
                                    .background(Theme.empire(id.hero.empire).opacity(0.55))
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.gold.opacity(store.profile.hasAltPalette(id) ? 0.9 : 0.25)))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(id.hero.name), \(id.hero.title)")
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: 1200)
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
    }
}

struct HeroDetailView: View {
    let hero: HeroID
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var store: ProfileStore

    var body: some View {
        let h = hero.hero
        let record = store.profile.record(hero)
        ZStack {
            Backdrop(name: ArtLibrary.backdropName(for: StageID.home(of: h.empire)), dim: 0.78)
            VStack(spacing: 8) {
                ScreenHeader(title: h.name, subtitle: h.title) { model.go(.hall) }
                HStack(alignment: .top, spacing: 20) {
                    PortraitView(hero: hero)
                        .frame(width: 210)
                        .frame(maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.gold.opacity(0.6)))
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Label(h.empire.displayName, systemImage: Theme.empireSymbol(h.empire))
                                Text("·")
                                Text(h.archetype.displayName)
                                Text("·")
                                Text(h.weapon)
                            }
                            .font(Theme.heading(12))
                            .foregroundStyle(Theme.gold)
                            Text("“\(h.quote)”").font(Theme.lore(20)).italic().foregroundStyle(.white)
                            Text(h.bio).font(Theme.lore(17)).foregroundStyle(.white.opacity(0.85))
                            StatBars(stats: h.stats, archetype: h.archetype).frame(maxWidth: 320)
                            MoveListView(hero: hero).padding(12).panel()
                            HStack(spacing: 18) {
                                recordStat("Wins", record.wins)
                                recordStat("Losses", record.losses)
                                recordStat("Arcade clears", record.arcadeClears)
                                if record.bestArcadeScore > 0 { recordStat("Best score", record.bestArcadeScore) }
                            }
                            Text("Signature: \(h.signature)").font(Theme.lore(15)).foregroundStyle(.white.opacity(0.6))
                            if let rival = h.rival {
                                Text("Rival: \(rival.id.hero.name) — “\(rival.line)”").font(Theme.lore(15)).foregroundStyle(.white.opacity(0.7))
                            }
                            if record.arcadeClears > 0 {
                                Text("EPILOGUE").font(Theme.heading(12)).foregroundStyle(Theme.gold).padding(.top, 4)
                                Text(Endings.text(for: hero)).font(Theme.lore(16)).foregroundStyle(.white.opacity(0.85))
                            } else {
                                Text("Clear arcade with \(h.name) to read their epilogue and unlock the mist palette.")
                                    .font(Theme.lore(15)).foregroundStyle(.white.opacity(0.55))
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .frame(maxWidth: 1200)
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
    }

    private func recordStat(_ name: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value.formatted()).font(Theme.display(20)).foregroundStyle(.white)
            Text(name.uppercased()).font(Theme.heading(9)).foregroundStyle(.white.opacity(0.6))
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var store: ProfileStore
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            Backdrop(name: "white-wind", dim: 0.78)
            VStack(spacing: 10) {
                ScreenHeader(title: "Settings") { model.go(.menu) }
                ScrollView {
                    HStack(alignment: .top, spacing: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            section("SOUND")
                            slider("Music", value: $store.profile.settings.musicVolume)
                            slider("Effects", value: $store.profile.settings.effectsVolume)
                            Toggle("Haptics", isOn: $store.profile.settings.haptics)
                            Toggle("Screen shake", isOn: $store.profile.settings.screenShake)
                            section("FIGHTS")
                            Picker("CPU difficulty", selection: $store.profile.settings.difficulty) {
                                ForEach(Difficulty.allCases) { Text($0.name).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            Text(store.profile.settings.difficulty.blurb).font(Theme.lore(14)).foregroundStyle(.white.opacity(0.65))
                            Picker("Rounds to win", selection: $store.profile.settings.roundsToWin) {
                                Text("1 round").tag(1); Text("2 rounds").tag(2); Text("3 rounds").tag(3)
                            }
                            .pickerStyle(.segmented)
                            Picker("Round time", selection: $store.profile.settings.roundSeconds) {
                                Text("60 s").tag(60); Text("99 s").tag(99)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(16).panel().frame(maxWidth: 380)
                        VStack(alignment: .leading, spacing: 14) {
                            section("TOUCH CONTROLS")
                            Toggle("Show button labels", isOn: $store.profile.settings.showInputHints)
                            Toggle("Buttons on the left", isOn: $store.profile.settings.swapControls)
                            slider("Size", value: $store.profile.settings.controlsScale, range: 0.8...1.3)
                            slider("Opacity", value: $store.profile.settings.controlsOpacity, range: 0.35...1)
                            section("PROGRESS")
                            Text("\(store.profile.matchesPlayed) \(store.profile.matchesPlayed == 1 ? "fight" : "fights") · high score \(store.profile.highScore.formatted())")
                                .font(Theme.lore(15)).foregroundStyle(.white.opacity(0.75))
                            Button("Reset progress") { confirmReset = true }.buttonStyle(GameButtonStyle())
                            section("ABOUT")
                            Text("Aetheria Rising: Clash of the Crossing \(appVersion). Your progress is stored only on this device; the game collects no data.")
                                .font(Theme.lore(14)).foregroundStyle(.white.opacity(0.65))
                            Text("Fonts: Cinzel and EB Garamond, SIL Open Font License.").font(Theme.lore(13)).foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(16).panel().frame(maxWidth: 380)
                    }
                    .font(Theme.heading(13))
                    .tint(Theme.gold)
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: 1200)
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
        .onChange(of: store.profile.settings) { _, _ in model.applySettings() }
        .confirmationDialog("Reset all progress?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                let settings = store.profile.settings
                store.profile = Profile()
                store.profile.settings = settings
                store.profile.seenHowToPlay = true
            }
        } message: {
            Text("Wins, arcade clears, unlocked palettes and high scores will be erased. Settings are kept.")
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private func section(_ title: String) -> some View {
        Text(title).font(Theme.heading(12)).tracking(2).foregroundStyle(Theme.gold)
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double> = 0...1) -> some View {
        HStack {
            Text(title).frame(width: 80, alignment: .leading)
            Slider(value: value, in: range)
        }
    }
}

struct HowToPlayView: View {
    @EnvironmentObject private var model: AppModel
    @State private var page = 0

    private let pages: [(title: String, icon: String, body: String)] = [
        ("Move and jump", "dpad",
         "Drag anywhere on the left of the screen for the stick. Push toward your enemy to advance, away to retreat, up to jump. Flick the stick, or tap a direction twice, to dash."),
        ("Strike", "bolt.fill",
         "L is a quick blow; tap it three times for a chain. H is slower and heavier. S is your commander's signature skill. A blow that connects can be cancelled: L into H into S."),
        ("Guard and throw", "shield.lefthalf.filled",
         "Hold G to guard against any blow. A guard cannot stop a throw: press T (or hold G and tap L) up close. Caught in a throw? Press G and L together to break free."),
        ("The Aether", "sparkles",
         "Landing and taking blows fills your Aether meter. When it is full the ✦ button lights: unleash your Crossing Art, a devastating super. It can finish a combo, too."),
        ("The Crossing", "tornado",
         "Arcade sets you against six commanders, your rival among them. At the end, the mist itself will wear your face. Clear it to read your hero's epilogue and earn their mist palette. Controllers and keyboards work too."),
    ]

    var body: some View {
        ZStack {
            Backdrop(name: "mist-thins", dim: 0.75)
            VStack(spacing: 14) {
                ScreenHeader(title: "How to Play") { model.go(.menu) }
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        HStack(spacing: 28) {
                            Image(systemName: pages[i].icon)
                                .font(.system(size: 70, weight: .semibold))
                                .foregroundStyle(Theme.gold)
                                .frame(width: 130)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 10) {
                                Text(pages[i].title.uppercased()).font(Theme.display(28)).foregroundStyle(.white)
                                Text(pages[i].body).font(Theme.lore(20)).foregroundStyle(.white.opacity(0.88)).fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: 480, alignment: .leading)
                        }
                        .padding(24)
                        .panel()
                        .padding(.horizontal, 30)
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                HStack {
                    if page > 0 { Button("Back") { playTap(); withAnimation { page -= 1 } }.buttonStyle(GameButtonStyle()) }
                    Spacer()
                    Button(page == pages.count - 1 ? "To Battle" : "Next") {
                        playTap()
                        if page == pages.count - 1 { model.go(.menu) } else { withAnimation { page += 1 } }
                    }
                    .buttonStyle(GameButtonStyle(prominent: true))
                }
            }
            .frame(maxWidth: 1200)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
    }
}
