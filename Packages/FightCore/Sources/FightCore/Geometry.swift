// World space: x runs along the stage in points, y is height above the ground.
// A fighter's position is the point between their feet.

public struct Vec: Equatable, Codable, Sendable {
    public var x: Double
    public var y: Double
    public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
    public static let zero = Vec(0, 0)
}

public struct Box: Equatable, Codable, Sendable {
    public var minX: Double, minY: Double, maxX: Double, maxY: Double

    public init(minX: Double, minY: Double, maxX: Double, maxY: Double) {
        self.minX = minX; self.minY = minY; self.maxX = maxX; self.maxY = maxY
    }

    /// A box given relative to a fighter facing right, placed for a fighter
    /// at `origin` facing `facing` (+1 right, -1 left).
    public init(local: LocalBox, origin: Vec, facing: Double) {
        let a = origin.x + local.x * facing
        let b = origin.x + (local.x + local.width) * facing
        self.minX = min(a, b); self.maxX = max(a, b)
        self.minY = origin.y + local.y; self.maxY = origin.y + local.y + local.height
    }

    public func intersects(_ other: Box) -> Bool {
        minX < other.maxX && other.minX < maxX && minY < other.maxY && other.minY < maxY
    }

    public var midX: Double { (minX + maxX) / 2 }
    public var midY: Double { (minY + maxY) / 2 }
}

/// A box in a fighter's own space: `x` forward from the feet, `y` up.
public struct LocalBox: Equatable, Codable, Sendable {
    public var x: Double, y: Double, width: Double, height: Double
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }
}

/// A small deterministic generator, so a seeded match (and the CPU in it)
/// plays out the same way every time — what the tests and replays rely on.
public struct SeededRandom: Sendable {
    private var state: UInt64
    public init(seed: UInt64) { state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed }

    public mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    /// Uniform in [0, 1).
    public mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }

    public mutating func chance(_ p: Double) -> Bool { unit() < p }

    public mutating func int(_ range: ClosedRange<Int>) -> Int {
        range.lowerBound + Int(next() % UInt64(range.count))
    }
}
