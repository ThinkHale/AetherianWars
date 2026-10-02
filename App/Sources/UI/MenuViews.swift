import SwiftUI
import FightCore

struct TitleView: View {
    @EnvironmentObject private var model: AppModel
    @State private var glow = false

    var body: some View {
        ZStack {
            Backdrop(name: "mist-thins", dim: 0.35)
            VStack(spacing: 6) {
                Spacer()
                Text("AETHERIA RISING")
                    .font(Theme.heading(18))
                    .tracking(8)
                    .foregroundStyle(Theme.parchment.opacity(0.85))
                Text("CLASH OF THE CROSSING")
                    .font(Theme.display(44))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(LinearGradient(colors: [Color(red: 1, green: 0.9, blue: 0.6), Theme.gold], startPoint: .top, endPoint: .bottom))
                    .shadow(color: .black.opacity(0.8), radius: 8, y: 3)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("Thirteen commanders. Four empires. One mist.")
                    .font(Theme.lore(18))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text("TAP TO BEGIN")
                    .font(Theme.heading(16))
                    .tracking(4)
                    .foregroundStyle(Theme.gold)
                    .opacity(glow ? 1 : 0.35)
                    .animation(.easeInOut(duration: 1.1).repeatForever(), value: glow)
                    .padding(.bottom, 28)
            }
            .padding(.horizontal, 32)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            AudioManager.shared.play(.select, volume: 0.8)
            model.go(.menu)
        }
        .onAppear { glow = true }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens the main menu")
    }
}

struct MainMenuView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var store: ProfileStore

    var body: some View {
        ZStack {
            Backdrop(name: "legion", dim: 0.6)
            HStack(spacing: 28) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CLASH OF THE").font(Theme.heading(16)).tracking(4).foregroundStyle(Theme.parchment.opacity(0.8))
                    Text("CROSSING").font(Theme.display(46)).foregroundStyle(Theme.gold)
                    Text("The mist draws commanders out of their own centuries and sets them against one another. Only those who master it walk free.")
                        .font(Theme.lore(17))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(maxWidth: 340, alignment: .leading)
                        .padding(.top, 6)
                    if store.profile.highScore > 0 {
                        Text("HIGH SCORE  \(store.profile.highScore.formatted())")
                            .font(Theme.heading(13)).foregroundStyle(Theme.gold.opacity(0.9)).padding(.top, 10)
                    }
                    if !ControllerInput.shared.hasPad {
                        Label("Game controllers supported", systemImage: "gamecontroller")
                            .font(.caption).foregroundStyle(.white.opacity(0.55)).padding(.top, 4)
                    }
                }
                Spacer(minLength: 0)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        if let run = store.profile.arcadeInProgress {
                            Button("Resume Arcade · \(run.player.hero.name)") { playTap(); model.go(.ladder) }
                                .buttonStyle(GameButtonStyle(prominent: true))
                        }
                        Button("Arcade") { playTap(); model.go(.select(.arcade)) }
                            .buttonStyle(GameButtonStyle(prominent: store.profile.arcadeInProgress == nil))
                        Button("Versus CPU") { playTap(); model.go(.select(.versusCPU)) }.buttonStyle(GameButtonStyle())
                        Button("Two Players") { playTap(); model.go(.select(.versusLocal)) }.buttonStyle(GameButtonStyle())
                        Button("Training") { playTap(); model.go(.select(.training)) }.buttonStyle(GameButtonStyle())
                        Button("Hall of Heroes") { playTap(); model.go(.hall) }.buttonStyle(GameButtonStyle())
                        HStack(spacing: 10) {
                            Button("How to Play") { playTap(); model.go(.howToPlay) }.buttonStyle(GameButtonStyle()).frame(maxWidth: .infinity)
                            Button { playTap(); model.go(.settings) } label: { Image(systemName: "gearshape.fill") }
                                .buttonStyle(GameButtonStyle())
                                .frame(width: 64)
                                .accessibilityLabel("Settings")
                        }
                    }
                    .padding(.vertical, 12)
                }
                .frame(width: 280)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
        }
        .onAppear {
            if !store.profile.seenHowToPlay {
                store.profile.seenHowToPlay = true
                model.go(.howToPlay)
            }
        }
    }
}

/// A row of back/title chrome shared by the menus.
struct ScreenHeader: View {
    let title: String
    var subtitle: String? = nil
    let back: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Button { playTap(); back() } label: {
                Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.gold)
                    .frame(width: 40, height: 36).panel(radius: 8)
            }
            .accessibilityLabel("Back")
            Text(title.uppercased()).font(Theme.display(26)).foregroundStyle(Theme.gold)
            if let subtitle { Text(subtitle).font(Theme.lore(16)).foregroundStyle(.white.opacity(0.7)).lineLimit(1) }
            Spacer()
        }
    }
}
