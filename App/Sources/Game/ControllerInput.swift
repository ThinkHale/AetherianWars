import GameController
import FightCore

/// Game controllers and hardware keyboards. Pad 1 drives player one (alongside
/// touch); a second pad, in versus, drives player two.
@MainActor
final class ControllerInput {
    static let shared = ControllerInput()

    private(set) var pads: [GCController] = []
    var onPause: (() -> Void)?
    var onChange: (() -> Void)?

    private init() {
        NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        refresh()
    }

    func refresh() {
        pads = GCController.controllers().filter { $0.extendedGamepad != nil }
        for (i, pad) in pads.enumerated() {
            pad.playerIndex = GCControllerPlayerIndex(rawValue: i) ?? .indexUnset
            pad.extendedGamepad?.buttonMenu.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { Task { @MainActor in self?.onPause?() } }
            }
        }
        onChange?()
    }

    var hasPad: Bool { !pads.isEmpty }
    /// A pad has actually been used since the last touch (a paired but idle
    /// controller should not hide the touch controls).
    var padInUse = false
    var padCount: Int { pads.count }

    /// Buttons held on pad `index` (0 or 1).
    func controls(pad index: Int) -> Controls {
        guard index < pads.count, let g = pads[index].extendedGamepad else { return [] }
        var c: Controls = []
        let x = g.leftThumbstick.xAxis.value, y = g.leftThumbstick.yAxis.value
        if x > 0.4 || g.dpad.right.isPressed { c.insert(.right) }
        if x < -0.4 || g.dpad.left.isPressed { c.insert(.left) }
        if y > 0.6 || g.dpad.up.isPressed { c.insert(.up) }
        if y < -0.6 || g.dpad.down.isPressed { c.insert(.down) }
        if g.buttonA.isPressed { c.insert(.light) }
        if g.buttonB.isPressed { c.insert(.heavy) }
        if g.buttonX.isPressed { c.insert(.special) }
        if g.buttonY.isPressed { c.formUnion([.guardButton, .light]) }
        if g.rightShoulder.isPressed || g.rightTrigger.isPressed { c.insert(.guardButton) }
        if g.leftShoulder.isPressed || g.leftTrigger.isPressed { c.insert(.superArt) }
        if !c.isEmpty { padInUse = true }
        return c
    }

    /// Buttons held on a hardware keyboard (WASD or arrows; J K L, Space, U, I).
    func keyboardControls() -> Controls {
        guard let k = GCKeyboard.coalesced?.keyboardInput else { return [] }
        var c: Controls = []
        func down(_ key: GCKeyCode) -> Bool { k.button(forKeyCode: key)?.isPressed ?? false }
        if down(.keyD) || down(.rightArrow) { c.insert(.right) }
        if down(.keyA) || down(.leftArrow) { c.insert(.left) }
        if down(.keyW) || down(.upArrow) { c.insert(.up) }
        if down(.keyS) || down(.downArrow) { c.insert(.down) }
        if down(.keyJ) { c.insert(.light) }
        if down(.keyK) { c.insert(.heavy) }
        if down(.keyL) { c.insert(.special) }
        if down(.spacebar) || down(.leftShift) { c.insert(.guardButton) }
        if down(.keyU) { c.formUnion([.guardButton, .light]) }
        if down(.keyI) { c.insert(.superArt) }
        if down(.keyO) { c.insert(.dash) }
        return c
    }

    var keyboardPausePressed: Bool {
        guard let k = GCKeyboard.coalesced?.keyboardInput else { return false }
        return (k.button(forKeyCode: .escape)?.isPressed ?? false) || (k.button(forKeyCode: .keyP)?.isPressed ?? false)
    }

    func rumble(_ strength: Float) {
        // Light haptics on supported pads.
        guard let haptics = pads.first?.haptics, let engine = haptics.createEngine(withLocality: .default) else { return }
        try? engine.start()
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: strength)], relativeTime: 0)
        if let pattern = try? CHHapticPattern(events: [event], parameters: []), let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: 0)
        }
    }
}

import CoreHaptics
