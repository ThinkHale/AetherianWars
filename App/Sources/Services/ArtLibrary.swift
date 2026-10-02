import UIKit
import FightCore

/// Bundled art, looked up by name. Anything generated later (ChatGPT stage
/// paintings, fighter sprite sheets) is found here too when it is present, and
/// the game draws its own stand-in when it is not.
@MainActor
enum ArtLibrary {
    private static var cache: [String: UIImage] = [:]

    static func image(_ name: String, in folder: String) -> UIImage? {
        let key = "\(folder)/\(name)"
        if let cached = cache[key] { return cached }
        for ext in ["jpg", "png", "webp"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: folder) ?? Bundle.main.url(forResource: name, withExtension: ext),
               let image = UIImage(contentsOfFile: url.path) {
                cache[key] = image
                return image
            }
        }
        return nil
    }

    static func portrait(_ hero: HeroID) -> UIImage? { image(hero.rawValue, in: "Portraits") }

    static func backdrop(_ name: String) -> UIImage? { image(name, in: "Backdrops") }

    /// A painted stage layer (`far`, `mid` or `floor`), if one has been made.
    static func stageLayer(_ stage: StageID, _ layer: String) -> UIImage? { image("\(stage.rawValue)-\(layer)", in: "Stages") }

    static func backdropName(for stage: StageID) -> String {
        switch stage {
        case .forum: "founding-rome"
        case .nile: "founding-egypt"
        case .persepolis: "founding-persia"
        case .greatWall: "founding-han"
        case .crossing: "mist-thins"
        }
    }

    static func purge() { cache.removeAll() }
}
