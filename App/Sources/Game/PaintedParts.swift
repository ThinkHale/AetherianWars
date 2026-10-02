import SpriteKit
import FightCore

/// A hero's painted body pieces (cut from a ChatGPT parts sheet by
/// Tools/import-art.swift), ready to hang on the rig's skeleton.
struct PaintedParts {
    struct Part {
        let texture: SKTexture
        let size: CGSize
        /// Where the joint (or the grip) is, in SpriteKit anchor space.
        let anchor: CGPoint
    }

    let parts: [String: Part]
    /// Height in pixels of the full figure on the sheet (0 if not drawn).
    let figureHeight: CGFloat

    subscript(name: String) -> Part? { parts[name] }

    private struct Manifest: Decodable {
        struct Info: Decodable { let width: Int; let height: Int; let anchor: [Double] }
        let figureHeight: Int
        let parts: [String: Info]
    }

    @MainActor
    static func load(hero: HeroID) -> PaintedParts? {
        guard let url = Bundle.main.url(forResource: "parts-\(hero.rawValue)", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: data) else { return nil }
        var parts: [String: Part] = [:]
        for (name, info) in manifest.parts {
            let file = "parts-\(hero.rawValue)-\(name)"
            guard let path = Bundle.main.path(forResource: file, ofType: "png"), let image = UIImage(contentsOfFile: path) else { continue }
            let texture = SKTexture(image: image)
            texture.filteringMode = .linear
            parts[name] = Part(texture: texture, size: CGSize(width: info.width, height: info.height),
                               anchor: CGPoint(x: info.anchor[0], y: info.anchor[1]))
        }
        guard ["head", "torso", "upperArm", "forearm", "thigh", "shin"].allSatisfy({ parts[$0] != nil }) else { return nil }
        return PaintedParts(parts: parts, figureHeight: CGFloat(manifest.figureHeight))
    }
}
