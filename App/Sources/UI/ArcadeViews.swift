import SwiftUI
import FightCore

struct LadderView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var store: ProfileStore

    var body: some View {
        ZStack {
            Backdrop(name: "far-beacon", dim: 0.6)
            if let run = store.profile.arcadeInProgress {
                let ladder = run.ladder
                VStack(spacing: 12) {
                    ScreenHeader(title: "Arcade", subtitle: "\(run.player.hero.name) · \(run.difficulty.name)") { model.go(.menu) }
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(ladder.rungs) { rung in
                                    rungCard(rung, current: rung.id == run.rung, beaten: rung.id < run.rung)
                                        .id(rung.id)
                                }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 6)
                        }
                        .onAppear { proxy.scrollTo(run.rung, anchor: .center) }
                    }
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SCORE").font(Theme.heading(11)).foregroundStyle(.white.opacity(0.6))
                            Text(run.score.formatted()).font(Theme.display(24)).foregroundStyle(Theme.gold)
                        }
                        if run.continuesUsed > 0 {
                            Text("Continues: \(run.continuesUsed)").font(Theme.heading(12)).foregroundStyle(.white.opacity(0.6))
                        }
                        Spacer()
                        Button("Retire") { playTap(); model.abandonArcade() }.buttonStyle(GameButtonStyle())
                        Button(run.rung == ArcadeLadder.length - 1 ? "Face the Echo" : "Next Battle") {
                            AudioManager.shared.play(.select, volume: 0.8)
                            if let setup = model.arcadeSetup() { model.go(.versus(setup)) }
                        }
                        .buttonStyle(GameButtonStyle(prominent: true))
                    }
                }
                .frame(maxWidth: 1200)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            } else {
                VStack {
                    Text("No arcade run in progress.").font(Theme.lore(18))
                    Button("Back") { model.go(.menu) }.buttonStyle(GameButtonStyle())
                }
            }
        }
    }

    private func rungCard(_ rung: ArcadeLadder.Rung, current: Bool, beaten: Bool) -> some View {
        VStack(spacing: 6) {
            PortraitView(hero: rung.opponent, echo: rung.isBoss)
                .frame(width: 112, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(current ? Theme.gold : .white.opacity(0.15), lineWidth: current ? 3 : 1))
                .overlay {
                    if beaten {
                        ZStack {
                            Color.black.opacity(0.55)
                            Image(systemName: "checkmark.seal.fill").font(.system(size: 34)).foregroundStyle(Theme.gold)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            Text(rung.isBoss ? "THE ECHO" : rung.opponent.hero.name.uppercased())
                .font(Theme.heading(11)).foregroundStyle(current ? Theme.gold : .white).lineLimit(1).minimumScaleFactor(0.7)
            Text(rung.isBoss ? "Final battle" : rung.isRival ? "Rival" : rung.stage.name)
                .font(Theme.lore(12)).foregroundStyle(rung.isRival || rung.isBoss ? Color(red: 1, green: 0.55, blue: 0.4) : .white.opacity(0.6))
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(width: 118)
        .scaleEffect(current ? 1.05 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(rung.isBoss ? "The Echo of the Crossing" : rung.opponent.hero.name), \(beaten ? "defeated" : current ? "next" : "ahead")")
    }
}

/// The face-off before a fight: both commanders and what they say.
struct VersusView: View {
    let setup: FightSetup
    @EnvironmentObject private var model: AppModel
    @State private var shown = false

    var body: some View {
        let a = setup.match.heroes[0].hero, b = setup.match.heroes[1].hero
        let boss = setup.match.bosses.contains(1)
        let rivalLine = a.rival?.id == b.id ? a.rival?.line : nil
        ZStack {
            Backdrop(name: ArtLibrary.backdropName(for: setup.match.stage), dim: 0.55)
            HStack(spacing: 0) {
                side(a.id, line: rivalLine ?? a.intro, leading: true, echo: false)
                    .offset(x: shown ? 0 : -400)
                side(b.id, line: boss ? "You have fought your way here. Now fight yourself." : (b.rival?.id == a.id ? b.rival!.line : b.intro), leading: false, echo: boss)
                    .offset(x: shown ? 0 : 400)
            }
            Text("VS")
                .font(Theme.display(84))
                .foregroundStyle(LinearGradient(colors: [.white, Theme.gold], startPoint: .top, endPoint: .bottom))
                .shadow(color: .black, radius: 10)
                .scaleEffect(shown ? 1 : 3)
                .opacity(shown ? 1 : 0)
            VStack {
                Text(setup.match.stage.name.uppercased()).font(Theme.heading(14)).tracking(3).foregroundStyle(Theme.parchment)
                    .shadow(color: .black, radius: 4)
                    .padding(.top, 14)
                Spacer()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { start() }
        .onAppear {
            AudioManager.shared.play(.gong, volume: 0.7)
            withAnimation(.spring(duration: 0.5, bounce: 0.25)) { shown = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { start() }
        }
    }

    @State private var started = false

    private func start() {
        guard !started else { return }
        started = true
        model.beginFight(setup)
    }

    private func side(_ id: HeroID, line: String, leading: Bool, echo: Bool) -> some View {
        let hero = id.hero
        return ZStack(alignment: leading ? .bottomLeading : .bottomTrailing) {
            PortraitView(hero: id, echo: echo)
                .mask(LinearGradient(colors: [.black, .black, .clear], startPoint: leading ? .leading : .trailing, endPoint: leading ? .trailing : .leading))
                .overlay(LinearGradient(colors: [.clear, .clear, .black.opacity(0.85)], startPoint: .top, endPoint: .bottom))
            VStack(alignment: leading ? .leading : .trailing, spacing: 4) {
                Text(echo ? "ECHO OF \(hero.name.uppercased())" : hero.name.uppercased()).font(Theme.display(26)).foregroundStyle(.white)
                Text(echo ? "The Crossing, wearing a familiar face" : hero.title).font(Theme.lore(17)).foregroundStyle(Theme.gold)
                Text("“\(line)”").font(Theme.lore(16)).italic().foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(leading ? .leading : .trailing)
                    .frame(maxWidth: 300, alignment: leading ? .leading : .trailing)
            }
            .padding(24)
            .shadow(color: .black, radius: 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

struct ResultsView: View {
    let result: FightResult
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var store: ProfileStore

    var body: some View {
        let setup = result.setup
        let winner = setup.match.heroes[result.winner].hero
        let loser = setup.match.heroes[1 - result.winner].hero
        let playerWon = result.winner == 0
        let echoWon = setup.match.bosses.contains(result.winner)
        ZStack {
            Backdrop(name: ArtLibrary.backdropName(for: setup.match.stage), dim: 0.7)
            HStack(spacing: 24) {
                PortraitView(hero: winner.id, echo: echoWon)
                    .frame(width: 230)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.gold.opacity(0.6)))
                VStack(alignment: .leading, spacing: 10) {
                    Text(headline(playerWon: playerWon, winner: winner, echoWon: echoWon)).font(Theme.display(34)).foregroundStyle(Theme.gold)
                        .lineLimit(2).minimumScaleFactor(0.6)
                    Text("“\(echoWon ? "The mist does not tire. Neither should you." : winner.victory)”")
                        .font(Theme.lore(18)).italic().foregroundStyle(.white.opacity(0.9))
                    if !echoWon {
                        Text("\(loser.name): “\(loser.defeat)”").font(Theme.lore(15)).foregroundStyle(.white.opacity(0.6))
                    }
                    statsGrid
                    Spacer(minLength: 0)
                    buttons(playerWon: playerWon)
                }
                .frame(maxWidth: 440, alignment: .leading)
            }
            .padding(28)
        }
        .onAppear { AudioManager.shared.play(playerWon ? .reward : .error, volume: 0.6) }
    }

    private func headline(playerWon: Bool, winner: Hero, echoWon: Bool) -> String {
        switch result.setup.mode {
        case .versusLocal: return "\(result.winner == 0 ? "PLAYER ONE" : "PLAYER TWO") WINS"
        default: return echoWon ? "THE ECHO PREVAILS" : (playerWon ? "VICTORY" : "DEFEAT")
        }
    }

    private var statsGrid: some View {
        let s = result.stats[0]
        return Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 4) {
            GridRow { stat("Damage", "\(Int(s.damageDealt))"); stat("Best combo", "\(s.bestCombo)") }
            GridRow { stat("Hits", "\(s.hitsLanded)"); stat("Guarded", "\(s.blocks)") }
            GridRow { stat("Throws", "\(s.throwsLanded)"); stat("Crossing Arts", "\(s.supersUsed)") }
            if s.perfectRounds > 0 { GridRow { stat("Perfect rounds", "\(s.perfectRounds)") } }
        }
        .padding(12)
        .panel()
    }

    private func stat(_ name: String, _ value: String) -> some View {
        HStack {
            Text(name.uppercased()).font(Theme.heading(11)).foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value).font(Theme.heading(15)).foregroundStyle(.white)
        }
        .frame(width: 180)
    }

    @ViewBuilder private func buttons(playerWon: Bool) -> some View {
        HStack(spacing: 10) {
            switch result.setup.mode {
            case .arcade:
                if playerWon {
                    Button("Onward") { playTap(); model.go(.ladder) }.buttonStyle(GameButtonStyle(prominent: true))
                } else {
                    Button("Continue") { playTap(); model.continueArcade() }.buttonStyle(GameButtonStyle(prominent: true))
                    Button("Retire") { playTap(); model.abandonArcade() }.buttonStyle(GameButtonStyle())
                }
            default:
                Button("Rematch") {
                    playTap()
                    var setup = result.setup
                    setup.match.seed &+= 1
                    model.beginFight(setup)
                }
                .buttonStyle(GameButtonStyle(prominent: true))
                Button("Fighters") { playTap(); model.go(.select(purpose)) }.buttonStyle(GameButtonStyle())
                Button("Menu") { playTap(); model.go(.menu) }.buttonStyle(GameButtonStyle())
            }
        }
    }

    private var purpose: SelectPurpose {
        switch result.setup.mode {
        case .versusLocal: .versusLocal
        case .training: .training
        case .arcade: .arcade
        case .versusCPU: .versusCPU
        }
    }
}

struct EndingView: View {
    let hero: HeroID
    let score: Int
    let newBest: Bool
    @EnvironmentObject private var model: AppModel
    @State private var revealed = false

    var body: some View {
        let h = hero.hero
        ZStack {
            Backdrop(name: "aeterna", dim: 0.55)
            HStack(spacing: 28) {
                PortraitView(hero: hero)
                    .frame(width: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.gold))
                    .shadow(color: Theme.gold.opacity(0.4), radius: 20)
                VStack(alignment: .leading, spacing: 12) {
                    Text("THE MIST THINS").font(Theme.heading(14)).tracking(4).foregroundStyle(.white.opacity(0.7))
                    Text(h.name.uppercased()).font(Theme.display(36)).foregroundStyle(Theme.gold)
                    ScrollView {
                        Text(Endings.text(for: hero))
                            .font(Theme.lore(17))
                            .foregroundStyle(.white.opacity(0.92))
                            .opacity(revealed ? 1 : 0)
                            .animation(.easeIn(duration: 2), value: revealed)
                    }
                    .frame(maxHeight: 210)
                    HStack {
                        Text("FINAL SCORE \(score.formatted())").font(Theme.heading(16)).foregroundStyle(Theme.gold)
                        if newBest { Text("NEW BEST").font(Theme.heading(11)).padding(4).background(Theme.crimson).clipShape(RoundedRectangle(cornerRadius: 4)) }
                    }
                    Text("Mist palette unlocked for \(h.name).").font(Theme.lore(15)).foregroundStyle(.white.opacity(0.7))
                    Button("Return to Aeterna") { playTap(); model.go(.menu) }.buttonStyle(GameButtonStyle(prominent: true))
                }
                .frame(maxWidth: 460, alignment: .leading)
            }
            .padding(28)
        }
        .onAppear { revealed = true; Haptics.success() }
    }
}

/// What each commander does when the mist lets them go: an epilogue in their
/// own voice, true to their lore.
enum Endings {
    static func text(for hero: HeroID) -> String {
        switch hero {
        case .gaius:
            "The Echo fell, and for a moment Gaius saw his own face in the mist: a boy proving himself to a father who never watched. He let it go. Rome did not need another victory from him. Aetheria needed someone who knew what victories cost, and he finally knew what his strength was for."
        case .zhaoLin:
            "Forty paces, wind from the east, the last bolt true. When the mist parted Zhao Lin counted what was left: grain, roads, villages, people. All of it, he decided, was the Han. He set his crossbow down beside the watchtower door and began, again, to keep the ledgers honestly."
        case .tahmina:
            "She rode the Echo down the way she rode down every fear, laughing. When the mist cleared, a white stallion was standing at the edge of the field, as if it had always been waiting. Tahmina did not call him. He came anyway. Loyalty, she reminded the empty plain, has to be earned."
        case .marcusVarro:
            "Marcus knelt by the fallen Echo and offered it his hand, because that is what you do. It dissolved like breath on cold armour. Rome would have called the day a triumph. Judea would have asked who paid for it. He carried both answers home to the Compact, and found that they fit."
        case .khepri:
            "Kepri walked the ground of his last battle until he knew every stone of it, then drew a map that anyone could read: water here, shade there, the road the chariots should take. The battlefield belongs to whoever knows it better. He meant to make sure that was everyone."
        case .bardiya:
            "The Echo knelt. Bardiya did not. He stood over his own reflection and felt, for the first time in years, nothing to fear. It unsettled him more than any blade. The ten thousand still stood behind him. He wondered, briefly, whether any of them had ever wanted to."
        case .weiJian:
            "Wei Jian sheathed the jian and said nothing for a long time. Then he walked to the nearest village and asked what they needed. The people there did not flinch when his soldiers passed. That, he decided, was the only victory worth reporting."
        case .meritamun:
            "The scales settled, and Meritamun weighed the heart of the Crossing itself. It was heavy with old wars and lighter than she expected. She did not rule it. She kept it from falling, which was all she had ever wanted to do, and the river rose on time that year."
        case .arsames:
            "“What happens after the victory?” Arsamis asked the dissolving Echo, and for once there was an answer: terms, trade, a border nobody needed to die on. He wrote them down before anyone could object. An empire of friends, he reflected, is a great deal cheaper to run."
        case .livia:
            "Livia regarded the place where the Echo had stood, adjusted the laurel, and said, “Agreed.” Rome had never learned to stop arguing with itself. Aetheria, perhaps, could be taught. She had always been patient, and she had a very long time."
        case .nefru:
            "Nefru lowered the golden bow and let the sun find her. Her ancestors had given her a name. Today, she thought, she had given it something worth remembering. Then she went to find Kepri, because he still owed her for the chariot."
        case .atossa:
            "The Echo wore a crown. Atossa did not. When it fell, she knelt and set her diadem on the grass beside it, then rode back to the people who had followed her into the mist. The crown exists for them. She meant to spend the rest of her reign proving it."
        case .meiLin:
            "Every seal burst at once, and the Echo with them. Mei Lin wrote the plan down in her own hand, signed it, and nailed it to the gate of Aeterna where no one could miss it. For years they had used her ideas and remembered their own names. Not this one."
        }
    }
}
