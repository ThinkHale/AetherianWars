import SwiftUI
import UIKit
import FightCore

enum Theme {
    static let displayFontName = "Cinzel-Black"
    static let bodyFontName = "Cinzel-Bold"
    static let loreFontName = "EBGaramond-Regular"

    static let goldUI = UIColor(hex: 0xE0B44C)
    static let gold = Color(red: 0.88, green: 0.71, blue: 0.30)
    static let goldDim = Color(red: 0.62, green: 0.49, blue: 0.22)
    static let ink = Color(red: 0.06, green: 0.05, blue: 0.05)
    static let parchment = Color(red: 0.93, green: 0.89, blue: 0.80)
    static let panel = Color(red: 0.08, green: 0.07, blue: 0.07).opacity(0.86)
    static let crimson = Color(red: 0.62, green: 0.12, blue: 0.12)

    static func display(_ size: CGFloat) -> Font { .custom(displayFontName, size: size, relativeTo: .title) }
    static func heading(_ size: CGFloat) -> Font { .custom(bodyFontName, size: size, relativeTo: .headline) }
    static func lore(_ size: CGFloat) -> Font { .custom(loreFontName, size: size, relativeTo: .body) }

    static func empire(_ empire: Empire) -> Color {
        switch empire {
        case .rome: Color(red: 0.62, green: 0.12, blue: 0.12)
        case .egypt: Color(red: 0.14, green: 0.32, blue: 0.62)
        case .persia: Color(red: 0.14, green: 0.50, blue: 0.48)
        case .han: Color(red: 0.66, green: 0.15, blue: 0.11)
        }
    }

    static func empireSymbol(_ empire: Empire) -> String {
        switch empire {
        case .rome: "laurel.leading"
        case .egypt: "sun.max.fill"
        case .persia: "crown.fill"
        case .han: "building.columns.fill"
        }
    }
}

/// A dark panel edged in gold, used across the menus.
struct PanelBackground: ViewModifier {
    var radius: CGFloat = 14
    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: radius).fill(Theme.panel))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(Theme.gold.opacity(0.55), lineWidth: 1))
    }
}

extension View {
    func panel(radius: CGFloat = 14) -> some View { modifier(PanelBackground(radius: radius)) }
}

/// The game's primary button: gold lettering on a dark plate.
struct GameButtonStyle: ButtonStyle {
    var prominent = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.heading(prominent ? 20 : 16))
            .tracking(1.5)
            .foregroundStyle(prominent ? Theme.ink : Theme.gold)
            .padding(.horizontal, 18)
            .padding(.vertical, prominent ? 13 : 10)
            .frame(minWidth: 130)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(prominent ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.96, green: 0.82, blue: 0.45), Theme.goldDim], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(Theme.panel))
            )
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.gold.opacity(prominent ? 0.9 : 0.6), lineWidth: 1.2))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// A painting filling the screen behind a menu, darkened for legibility.
struct Backdrop: View {
    let name: String
    var dim: Double = 0.55

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                if let image = ArtLibrary.backdrop(name) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                LinearGradient(colors: [.black.opacity(dim * 0.6), .black.opacity(dim), .black.opacity(min(1, dim + 0.3))], startPoint: .top, endPoint: .bottom)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// A hero's painted portrait, cropped to a frame.
struct PortraitView: View {
    let hero: HeroID
    var echo = false

    var body: some View {
        GeometryReader { geo in
            if let image = ArtLibrary.portrait(hero) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                    .clipped()
                    .saturation(echo ? 0 : 1)
                    .colorMultiply(echo ? Color(red: 0.65, green: 0.75, blue: 0.95) : .white)
            } else {
                Theme.empire(hero.hero.empire)
            }
        }
        .accessibilityLabel(Text(hero.hero.name))
    }
}

@MainActor
func playTap() {
    AudioManager.shared.play(.tap, volume: 0.6)
    Haptics.tick()
}
