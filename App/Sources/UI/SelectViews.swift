import SwiftUI
import FightCore

struct CharacterSelectView: View {
    let purpose: SelectPurpose
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var store: ProfileStore
    @State private var highlighted: HeroID = .gaius
    @State private var picks: [HeroID] = []
    @State private var alts: [Bool] = []
    @State private var useAlt = false
    @Environment(\.verticalSizeClass) private var verticalSize
    private var compact: Bool { verticalSize == .compact }

    private var choosingSecond: Bool { picks.count == 1 }
    private var needsTwo: Bool { purpose != .arcade }

    private var prompt: String {
        switch purpose {
        case .arcade: "Choose your commander"
        case .versusCPU: choosingSecond ? "Choose your opponent" : "Choose your commander"
        case .versusLocal: choosingSecond ? "Player two, choose" : "Player one, choose"
        case .training: choosingSecond ? "Choose a sparring partner" : "Choose your commander"
        }
    }

    var body: some View {
        ZStack {
            Backdrop(name: "commanders", dim: 0.72)
            VStack(spacing: compact ? 6 : 10) {
                ScreenHeader(title: purpose.title, subtitle: prompt) {
                    if picks.isEmpty { model.go(.menu) } else { picks.removeLast(); alts.removeLast() }
                }
                HStack(alignment: .top, spacing: 16) {
                    preview
                    grid
                }
                .frame(maxHeight: .infinity)
                if purpose == .versusLocal && ControllerInput.shared.padCount == 0 {
                    Label("Two players need a game controller for player two.", systemImage: "gamecontroller")
                        .font(.footnote).foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, compact ? 6 : 12)
        }
        .onAppear { highlighted = store.profile.lastHero ?? .gaius }
    }

    private var preview: some View {
        let hero = highlighted.hero
        let record = store.profile.record(highlighted)
        return HStack(spacing: 0) {
            PortraitView(hero: highlighted, echo: false)
                .frame(width: 150)
                .overlay(alignment: .bottomLeading) {
                    if store.profile.hasAltPalette(highlighted) {
                        Image(systemName: "seal.fill").foregroundStyle(Theme.gold).padding(6).accessibilityLabel("Arcade cleared")
                    }
                }
            VStack(alignment: .leading, spacing: 6) {
                Text(hero.name.uppercased()).font(Theme.display(compact ? 19 : 22)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.6)
                Text(hero.title).font(Theme.lore(17)).foregroundStyle(Theme.gold)
                HStack(spacing: 6) {
                    tag(hero.empire.displayName, color: Theme.empire(hero.empire))
                    tag(hero.archetype.displayName, color: .gray.opacity(0.6))
                }
                if !compact {
                    Text("“\(hero.quote)”").font(Theme.lore(15)).italic().foregroundStyle(.white.opacity(0.85)).lineLimit(4).fixedSize(horizontal: false, vertical: true)
                    Divider().overlay(Theme.gold.opacity(0.4))
                }
                Text("SPECIAL · \(hero.specialName.uppercased())").font(Theme.heading(11)).foregroundStyle(Theme.gold)
                Text(hero.specialDescription).font(Theme.lore(compact ? 13 : 14)).foregroundStyle(.white.opacity(0.8)).lineLimit(compact ? 2 : 3)
                StatBars(stats: hero.stats, archetype: hero.archetype).padding(.top, 2)
                Spacer(minLength: 0)
                if store.profile.hasAltPalette(highlighted) {
                    Toggle("Mist palette", isOn: $useAlt).font(Theme.heading(12)).tint(Theme.gold)
                }
                HStack {
                    Button(choosingSecond || !needsTwo ? "Fight" : "Choose") { confirm() }
                        .buttonStyle(GameButtonStyle(prominent: true))
                        .disabled(purpose == .versusLocal && choosingSecond && ControllerInput.shared.padCount == 0)
                    if record.wins + record.losses > 0 {
                        Text("\(record.wins)W · \(record.losses)L").font(Theme.heading(12)).foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .padding(14)
        }
        .frame(maxWidth: 470, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .panel()
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text.uppercased()).font(Theme.heading(10)).foregroundStyle(.white)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(color))
    }

    private var grid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: compact ? 4 : 10) {
                ForEach(Empire.allCases, id: \.self) { empire in
                    VStack(alignment: .leading, spacing: compact ? 2 : 4) {
                        Text(empire.displayName.uppercased()).font(Theme.heading(11)).tracking(2).foregroundStyle(Theme.parchment.opacity(0.75))
                        HStack(spacing: 8) {
                            ForEach(Roster.selectOrder.filter { $0.hero.empire == empire }) { id in
                                tile(id)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func tile(_ id: HeroID) -> some View {
        let selected = highlighted == id
        let taken = picks.first == id
        return Button {
            if highlighted == id { confirm() } else {
                Haptics.tick()
                AudioManager.shared.play(.tap, volume: 0.5)
                highlighted = id
                useAlt = false
            }
        } label: {
            PortraitView(hero: id)
                .frame(width: compact ? 54 : 66, height: compact ? 62 : 82)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(selected ? Theme.gold : .white.opacity(0.15), lineWidth: selected ? 3 : 1))
                .overlay(alignment: .topTrailing) {
                    if taken { Text("P1").font(Theme.heading(10)).padding(3).background(Theme.crimson).clipShape(RoundedRectangle(cornerRadius: 4)).padding(3) }
                }
                .scaleEffect(selected ? 1.06 : 1)
                .animation(.spring(duration: 0.2), value: selected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(id.hero.name), \(id.hero.title)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func confirm() {
        AudioManager.shared.play(.select, volume: 0.8)
        Haptics.impact(.medium)
        picks.append(highlighted)
        alts.append(useAlt)
        useAlt = false
        if purpose == .arcade {
            model.startArcade(highlighted, alt: alts[0])
        } else if picks.count == 2 {
            if purpose == .training {
                model.startVersus(.training, heroes: picks, alt: alts, stage: .crossing)
            } else {
                model.go(.stageSelect(purpose, picks, alts))
            }
        }
    }
}

struct StatBars: View {
    let stats: HeroStats
    let archetype: Archetype

    var body: some View {
        let values: [(String, Double)] = [
            ("Vigour", (stats.health - 850) / 350),
            ("Power", (stats.power - 0.9) / 0.25),
            ("Speed", (stats.walkSpeed - 2.6) / 2.0),
            ("Reach", archetype == .archer ? 0.95 : archetype == .rider ? 0.6 : 0.35),
        ]
        VStack(spacing: 3) {
            ForEach(values, id: \.0) { name, value in
                HStack(spacing: 6) {
                    Text(name.uppercased()).font(Theme.heading(9)).foregroundStyle(.white.opacity(0.65)).frame(width: 52, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.1))
                            Capsule().fill(Theme.gold).frame(width: geo.size.width * max(0.08, min(1, value)))
                        }
                    }
                    .frame(height: 5)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Vigour, power, speed and reach ratings")
    }
}

struct StageSelectView: View {
    let purpose: SelectPurpose
    let heroes: [HeroID]
    let alt: [Bool]
    @EnvironmentObject private var model: AppModel
    @State private var stage: StageID = .crossing

    var body: some View {
        ZStack {
            Backdrop(name: ArtLibrary.backdropName(for: stage), dim: 0.45)
                .animation(.easeInOut, value: stage)
            VStack(spacing: 14) {
                ScreenHeader(title: "Choose the Field", subtitle: "\(heroes[0].hero.name) vs \(heroes[1].hero.name)") {
                    model.go(.select(purpose))
                }
                Spacer()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(StageID.allCases) { s in
                            Button {
                                playTap()
                                if stage == s { go() } else { stage = s }
                            } label: {
                                VStack(spacing: 6) {
                                    Group {
                                        if let image = ArtLibrary.backdrop(ArtLibrary.backdropName(for: s)) {
                                            Image(uiImage: image).resizable().scaledToFill()
                                        } else { Color.gray }
                                    }
                                    .frame(width: 150, height: 92)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(stage == s ? Theme.gold : .white.opacity(0.2), lineWidth: stage == s ? 3 : 1))
                                    Text(s.name).font(Theme.heading(12)).foregroundStyle(stage == s ? Theme.gold : .white)
                                    Text(s.empire?.displayName ?? "Aetheria").font(Theme.lore(13)).foregroundStyle(.white.opacity(0.6))
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(s.name)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                HStack {
                    Button("Random") {
                        playTap()
                        stage = StageID.allCases.randomElement() ?? .crossing
                        go()
                    }
                    .buttonStyle(GameButtonStyle())
                    Button("Fight Here") { go() }.buttonStyle(GameButtonStyle(prominent: true))
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .onAppear { stage = StageID.home(of: heroes[1].hero.empire) }
    }

    private func go() {
        AudioManager.shared.play(.select, volume: 0.8)
        model.startVersus(purpose, heroes: heroes, alt: alt, stage: stage)
    }
}
