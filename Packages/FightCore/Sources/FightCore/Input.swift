/// The buttons held on one tick. Touch controls, game controllers and the CPU
/// all produce these; the match turns them into actions.
public struct Controls: OptionSet, Hashable, Codable, Sendable {
    public let rawValue: UInt16
    public init(rawValue: UInt16) { self.rawValue = rawValue }

    public static let left = Controls(rawValue: 1 << 0)
    public static let right = Controls(rawValue: 1 << 1)
    public static let up = Controls(rawValue: 1 << 2)
    public static let down = Controls(rawValue: 1 << 3)
    public static let light = Controls(rawValue: 1 << 4)
    public static let heavy = Controls(rawValue: 1 << 5)
    public static let special = Controls(rawValue: 1 << 6)
    public static let guardButton = Controls(rawValue: 1 << 7)
    public static let superArt = Controls(rawValue: 1 << 8)
    /// A dash, for controls that offer one directly (a flick of the touch
    /// stick). Holding a direction with it picks forward or back.
    public static let dash = Controls(rawValue: 1 << 9)

    public static let buttons: [Controls] = [.light, .heavy, .special, .superArt, .dash]
}

/// Remembers presses for a few ticks, so a button tapped just before a move
/// ends still comes out — the leniency that makes combos feel fair on glass.
public struct InputBuffer: Sendable, Equatable {
    public static let window = 8
    public static let dashWindow = 12

    public private(set) var held: Controls = []
    private var previous: Controls = []
    private var age: [UInt16: Int] = [:]
    /// Ticks since each direction was last pressed, for double-tap dashes.
    private var tapAge: [UInt16: Int] = [:]
    private var lastTap: Controls = []
    public private(set) var doubleTapped: Controls = []

    public init() {}

    public mutating func record(_ controls: Controls) {
        let pressed = controls.subtracting(previous)
        for key in Array(age.keys) {
            let next = age[key]! + 1
            age[key] = next > Self.window ? nil : next
        }
        for button in Controls.buttons where pressed.contains(button) { age[button.rawValue] = 0 }

        doubleTapped = []
        for key in Array(tapAge.keys) { tapAge[key]! += 1 }
        for direction in [Controls.left, .right] where pressed.contains(direction) {
            if let since = tapAge[direction.rawValue], since <= Self.dashWindow, lastTap == direction {
                doubleTapped.insert(direction)
                tapAge[direction.rawValue] = nil
            } else {
                tapAge[direction.rawValue] = 0
            }
            lastTap = direction
        }
        previous = controls
        held = controls
    }

    public func buffered(_ button: Controls) -> Bool { age[button.rawValue] != nil }

    /// Spends a buffered press so one tap makes one move.
    public mutating func consume(_ button: Controls) { age[button.rawValue] = nil }

    public mutating func clear() { age = [:]; doubleTapped = [] }

    public static func == (a: InputBuffer, b: InputBuffer) -> Bool { a.held == b.held && a.age == b.age }
}
