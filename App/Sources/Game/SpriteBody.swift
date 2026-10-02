import SpriteKit
import FightCore

/// A fighter drawn from painted sprite strips (made in ChatGPT and cut by
/// Tools/import-fighter-art.mjs). Each strip is one action, frames side by
/// side; `fighter-<hero>.json` gives each strip's frame size, count, where the
/// feet stand and the figure's standing height in pixels.
final class SpriteBody: SKNode {
    struct Strip: Decodable {
        let frames: Int
        let width: Int
        let height: Int
        let anchor: [Double]
        let loop: Bool
        let figureHeight: Double
        let fps: Double?
    }

    private let node = SKSpriteNode()
    private var textures: [String: [SKTexture]] = [:]
    private var strips: [String: Strip] = [:]
    private var scaleFactor: CGFloat = 1
    private var tick = 0

    /// Returns nil when this hero has no sheets bundled (the rig is used).
    static func load(hero: HeroID) -> SpriteBody? {
        guard let url = Bundle.main.url(forResource: "fighter-\(hero.rawValue)", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let strips = try? JSONDecoder().decode([String: Strip].self, from: data),
              strips["idle"] != nil else { return nil }
        let body = SpriteBody()
        for (action, strip) in strips {
            guard let image = UIImage(named: "fighter-\(hero.rawValue)-\(action)") ?? Bundle.main.url(forResource: "fighter-\(hero.rawValue)-\(action)", withExtension: "png").flatMap({ UIImage(contentsOfFile: $0.path) }) else { continue }
            let sheet = SKTexture(image: image)
            sheet.filteringMode = .linear
            let w = 1 / CGFloat(strip.frames)
            body.textures[action] = (0..<strip.frames).map { SKTexture(rect: CGRect(x: CGFloat($0) * w, y: 0, width: w, height: 1), in: sheet) }
            body.strips[action] = strip
        }
        guard let idle = body.strips["idle"], body.textures["idle"] != nil else { return nil }
        body.scaleFactor = CGFloat(180 * hero.hero.stats.stature / idle.figureHeight)
        body.addChild(body.node)
        return body
    }

    private func strip(_ names: String...) -> String {
        names.first { textures[$0] != nil } ?? "idle"
    }

    func show(_ f: Fighter) {
        tick += 1
        let action: String
        var progress: Double? = nil
        var reverse = false
        switch f.action {
        case .idle, .intro: action = "idle"
        case .walk: action = strip("walk", "idle")
        case .dash: action = strip("dash", "walk", "idle")
        case .guarding, .blockstun: action = strip("guard", "idle")
        case .jumpSquat, .landing, .airborne: action = strip("jump", "idle")
        case let .attack(slot):
            let move = f.moves[slot]
            progress = Double(f.frame) / Double(max(1, move.total))
            switch slot {
            case .light1: action = strip("light")
            case .light2: action = strip("light2", "light")
            case .light3: action = strip("light3", "heavy", "light")
            case .heavy: action = strip("heavy", "light")
            case .airLight, .airHeavy: action = strip("air", "heavy", "jump")
            case .throwAttempt: action = strip("throw", "heavy")
            case .special: action = strip("special", "heavy")
            case .superArt: action = strip("super", "special", "heavy")
            }
        case .throwHold(attacker: true): action = strip("throw", "heavy"); progress = 0.4
        case .hitstun, .throwHold(attacker: false), .juggle: action = strip("hit", "idle")
        case .knockdown, .ko: action = strip("ko", "hit"); progress = f.action == .ko ? min(1, Double(f.frame) / 30) : 1
        case .getUp: action = strip("ko", "idle"); progress = Double(f.frame) / 20; reverse = true
        case .victory: action = strip("victory", "idle")
        }
        guard let frames = textures[action], let info = strips[action] else { return }
        let index: Int
        if var p = progress {
            if reverse { p = 1 - p }
            index = min(frames.count - 1, max(0, Int(p * Double(frames.count))))
        } else {
            let fps = info.fps ?? (info.loop ? 10 : 12)
            let i = Int(Double(tick) * fps / 60)
            index = info.loop ? i % frames.count : min(frames.count - 1, i)
        }
        node.texture = frames[index]
        node.size = CGSize(width: CGFloat(info.width) * scaleFactor, height: CGFloat(info.height) * scaleFactor)
        node.anchorPoint = CGPoint(x: info.anchor[0], y: 1 - info.anchor[1])
        node.zRotation = f.action == .juggle ? CGFloat(min(1.2, Double(f.frame) * 0.08)) : 0
    }

    func flash(_ on: Bool) {
        node.colorBlendFactor = on ? 0.7 : 0
        node.color = .white
    }
}
