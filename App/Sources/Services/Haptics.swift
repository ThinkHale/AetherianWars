import UIKit
import FightCore

@MainActor
enum Haptics {
    static var enabled = true

    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let notify = UINotificationFeedbackGenerator()
    private static let selection = UISelectionFeedbackGenerator()

    static func prepare() {
        [light, medium, heavy, rigid].forEach { $0.prepare() }
    }

    static func impact(_ impact: Impact, blocked: Bool = false) {
        guard enabled else { return }
        if blocked { rigid.impactOccurred(intensity: 0.6); return }
        switch impact {
        case .light: light.impactOccurred()
        case .medium: medium.impactOccurred()
        case .heavy: heavy.impactOccurred()
        case .crushing: heavy.impactOccurred(intensity: 1)
        }
    }

    static func knockout() {
        guard enabled else { return }
        notify.notificationOccurred(.error)
    }

    static func success() {
        guard enabled else { return }
        notify.notificationOccurred(.success)
    }

    static func tick() {
        guard enabled else { return }
        selection.selectionChanged()
    }
}
