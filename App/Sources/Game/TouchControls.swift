import SpriteKit
import FightCore

/// On-screen controls: a floating stick on one side, attack buttons on the
/// other. Produces the buttons held this tick.
final class TouchControls: SKNode {
    private struct Button {
        let control: Controls
        let node: SKShapeNode
        let label: SKLabelNode
        let radius: CGFloat
        var center: CGPoint
    }

    private var size: CGSize
    private let safe: UIEdgeInsets
    private let swap: Bool
    private let scale: CGFloat
    private let restAlpha: CGFloat
    private var buttons: [Button] = []
    private let stickBase = SKShapeNode(circleOfRadius: 62)
    private let stickKnob = SKShapeNode(circleOfRadius: 28)
    private var stickTouch: UITouch?
    private var stickOrigin: CGPoint = .zero
    private var stickVector: CGVector = .zero
    private var lastStickX: CGFloat = 0
    private var flickTicks = 0
    private var buttonTouches: [UITouch: Int] = [:]
    private var pauseButton = SKShapeNode()
    var onPause: (() -> Void)?
    private(set) var superReady = false

    init(size: CGSize, safe: UIEdgeInsets, swap: Bool, scale: CGFloat, opacity: CGFloat, showHints: Bool) {
        self.size = size
        self.safe = safe
        self.swap = swap
        self.scale = scale
        self.restAlpha = opacity
        super.init()
        zPosition = 1100
        isUserInteractionEnabled = false

        stickBase.fillColor = UIColor(white: 0, alpha: 0.25)
        stickBase.strokeColor = UIColor(white: 1, alpha: 0.35)
        stickBase.lineWidth = 2
        stickKnob.fillColor = UIColor(white: 1, alpha: 0.35)
        stickKnob.strokeColor = Theme.goldUI.withAlphaComponent(0.8)
        stickKnob.lineWidth = 2
        stickBase.addChild(stickKnob)
        stickBase.setScale(scale)
        stickBase.alpha = opacity * 0.6
        addChild(stickBase)

        let specs: [(Controls, String, CGFloat, UIColor)] = [
            (.light, "L", 38, UIColor(hex: 0xE0B44C)),
            (.heavy, "H", 36, UIColor(hex: 0xD2563C)),
            (.special, "S", 34, UIColor(hex: 0x4F8FD0)),
            (.guardButton, "G", 34, UIColor(hex: 0x8A9AA8)),
            ([.guardButton, .light], "T", 26, UIColor(hex: 0xA77BC9)),
            (.superArt, "✦", 30, UIColor(hex: 0x9FD8FF)),
        ]
        for (control, title, radius, color) in specs {
            let r = radius * scale
            let node = SKShapeNode(circleOfRadius: r)
            node.fillColor = color.withAlphaComponent(0.32)
            node.strokeColor = color.lighter(0.3)
            node.lineWidth = 2.5
            node.alpha = opacity
            let label = SKLabelNode(text: title)
            label.fontName = Theme.displayFontName
            label.fontSize = r * 0.8
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            node.addChild(label)
            if showHints {
                let hint = SKLabelNode(text: Self.hint(control))
                hint.fontName = Theme.bodyFontName
                hint.fontSize = 9
                hint.fontColor = UIColor(white: 1, alpha: 0.7)
                hint.position = CGPoint(x: 0, y: -r - 11)
                node.addChild(hint)
            }
            addChild(node)
            buttons.append(Button(control: control, node: node, label: label, radius: r, center: .zero))
        }

        pauseButton = SKShapeNode(rectOf: CGSize(width: 44, height: 30), cornerRadius: 8)
        pauseButton.fillColor = UIColor(white: 0, alpha: 0.35)
        pauseButton.strokeColor = UIColor(white: 1, alpha: 0.4)
        let bars = SKLabelNode(text: "II")
        bars.fontName = Theme.displayFontName
        bars.fontSize = 16
        bars.verticalAlignmentMode = .center
        pauseButton.addChild(bars)
        pauseButton.name = "pause"
        addChild(pauseButton)
        layout(size: size)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    private static func hint(_ control: Controls) -> String {
        switch control {
        case .light: "LIGHT"
        case .heavy: "HEAVY"
        case .special: "SPECIAL"
        case .guardButton: "GUARD"
        case .superArt: "ART"
        default: "THROW"
        }
    }

    func layout(size: CGSize) {
        self.size = size
        let side: CGFloat = swap ? -1 : 1
        let bottom = -size.height / 2 + max(safe.bottom, 12) + 54 * scale
        let edge = size.width / 2 - max(safe.right, safe.left, 18) - 56 * scale
        let anchor = CGPoint(x: side * edge, y: bottom)
        // Offsets from the corner, for the right-hand layout.
        let offsets: [CGPoint] = [
            CGPoint(x: -70, y: -6),    // L
            CGPoint(x: 6, y: 50),      // H
            CGPoint(x: -150, y: 30),   // S
            CGPoint(x: -84, y: 92),    // G
            CGPoint(x: 18, y: 138),    // T
            CGPoint(x: -168, y: 112),  // super
        ]
        for i in buttons.indices {
            let o = offsets[i]
            let center = CGPoint(x: anchor.x + o.x * scale * side, y: anchor.y + o.y * scale)
            buttons[i].center = center
            buttons[i].node.position = center
        }
        stickBase.position = restingStick
        pauseButton.position = CGPoint(x: 0, y: size.height / 2 - max(safe.top, 8) - 76)
    }

    private var restingStick: CGPoint {
        let side: CGFloat = swap ? 1 : -1
        return CGPoint(x: side * (size.width / 2 - max(safe.left, safe.right, 18) - 110 * scale), y: -size.height / 2 + max(safe.bottom, 12) + 90 * scale)
    }

    private func isStickSide(_ point: CGPoint) -> Bool { swap ? point.x > 0 : point.x < 0 }

    /// Shows the super button lit when the meter is full.
    func setSuperReady(_ ready: Bool) {
        guard ready != superReady else { return }
        superReady = ready
        let node = buttons[5].node
        node.removeAllActions()
        if ready {
            node.alpha = 1
            node.run(.repeatForever(.sequence([.scale(to: 1.12, duration: 0.35), .scale(to: 1, duration: 0.35)])))
            node.glowWidth = 6
        } else {
            node.alpha = restAlpha * 0.45
            node.setScale(1)
            node.glowWidth = 0
        }
    }

    // MARK: Touches (forwarded by the scene, in this node's space)

    func touchesBegan(_ touches: Set<UITouch>, in scene: SKScene) {
        for touch in touches {
            let point = touch.location(in: self)
            if pauseButton.contains(point) { onPause?(); continue }
            if let index = buttonIndex(at: point) {
                buttonTouches[touch] = index
                press(index, true)
            } else if stickTouch == nil, isStickSide(point) {
                stickTouch = touch
                stickOrigin = point
                stickBase.position = point
                stickBase.alpha = restAlpha
                stickVector = .zero
                stickKnob.position = .zero
            }
        }
    }

    func touchesMoved(_ touches: Set<UITouch>, in scene: SKScene) {
        for touch in touches {
            let point = touch.location(in: self)
            if touch == stickTouch {
                let dx = point.x - stickOrigin.x, dy = point.y - stickOrigin.y
                let radius = 62 * scale
                let length = max(1, hypot(dx, dy))
                let clamped = min(length, radius)
                stickVector = CGVector(dx: dx / radius, dy: dy / radius)
                stickKnob.position = CGPoint(x: dx / length * clamped / scale, y: dy / length * clamped / scale)
                // A thumb that runs far past the base drags the base along.
                if length > radius * 1.6 {
                    stickOrigin = CGPoint(x: point.x - dx / length * radius, y: point.y - dy / length * radius)
                    stickBase.position = stickOrigin
                }
            } else if let held = buttonTouches[touch] {
                // Sliding between buttons (light into heavy) is allowed.
                if let index = buttonIndex(at: point), index != held {
                    press(held, false)
                    buttonTouches[touch] = index
                    press(index, true)
                }
            }
        }
    }

    func touchesEnded(_ touches: Set<UITouch>, in scene: SKScene) {
        for touch in touches {
            if touch == stickTouch {
                stickTouch = nil
                stickVector = .zero
                stickKnob.position = .zero
                stickBase.run(.move(to: restingStick, duration: 0.12))
                stickBase.alpha = restAlpha * 0.6
            }
            if let index = buttonTouches.removeValue(forKey: touch) { press(index, false) }
        }
    }

    private func buttonIndex(at point: CGPoint) -> Int? {
        var best: (Int, CGFloat)? = nil
        for (i, b) in buttons.enumerated() {
            let d = hypot(point.x - b.center.x, point.y - b.center.y)
            // Generous hit areas; the nearest wins.
            if d < b.radius * 1.35, best == nil || d < best!.1 { best = (i, d) }
        }
        return best?.0
    }

    private func press(_ index: Int, _ down: Bool) {
        let node = buttons[index].node
        node.setScale(down ? 0.9 : 1)
        node.fillColor = node.strokeColor.withAlphaComponent(down ? 0.7 : 0.32)
    }

    /// The buttons held right now.
    func currentControls(facing: Double) -> Controls {
        var c: Controls = []
        let dx = stickVector.dx, dy = stickVector.dy
        if dx > 0.38 { c.insert(.right) }
        if dx < -0.38 { c.insert(.left) }
        if dy > 0.55 { c.insert(.up) }
        if dy < -0.6 { c.insert(.down) }
        // A sharp flick reads as a dash.
        if abs(dx - lastStickX) > 0.85, abs(dx) > 0.8, flickTicks == 0 { c.insert(.dash); flickTicks = 12 }
        if flickTicks > 0 { flickTicks -= 1 }
        lastStickX = dx
        for index in Set(buttonTouches.values) { c.formUnion(buttons[index].control) }
        return c
    }

    func reset() {
        stickTouch = nil
        stickVector = .zero
        stickKnob.position = .zero
        for index in Set(buttonTouches.values) { press(index, false) }
        buttonTouches.removeAll()
    }
}
