import UIKit
import FightCore

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
    }

    func mixed(with other: UIColor, _ amount: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(red: r1 + (r2 - r1) * amount, green: g1 + (g2 - g1) * amount, blue: b1 + (b2 - b1) * amount, alpha: a1 + (a2 - a1) * amount)
    }

    func darker(_ amount: CGFloat = 0.3) -> UIColor { mixed(with: .black, amount) }
    func lighter(_ amount: CGFloat = 0.3) -> UIColor { mixed(with: .white, amount) }
}

enum Headgear { case romanCrest, plumedHelm, laurelBun, scoutBand, immortalBand, guanHat, vultureCrown, nubianCrown, feltCap, tallCap, diademVeil, topknot, hairPins }
enum Weapon { case gladius, spatha, khopesh, jian, akinaka, spear, lance, standard, crossbow, bow, sistrumStaff, fan }
enum Offhand { case none, scutum, wickerShield, quiver }
enum Garment { case armouredTunic, scaleCoat, robe, kilt, ridingCoat, lamellar, stola }

/// How a commander looks in the fight: colours and gear drawn from the
/// strategy game's portrait descriptions (heroCatalog.js `appearance`).
struct HeroLook {
    var skin: UIColor
    var hair: UIColor
    var cloth: UIColor
    var trim: UIColor
    var metal: UIColor
    var accent: UIColor
    var headgear: Headgear
    var weapon: Weapon
    var offhand: Offhand
    var garment: Garment
    var cape: Bool
    var beard: Bool
    var braid: Bool
    /// The glow of the hero's special and super.
    var energy: UIColor

    static let outline = UIColor(hex: 0x1A1210)
    static let bronze = UIColor(hex: 0xB0793A)
    static let gold = UIColor(hex: 0xD9A635)
    static let steel = UIColor(hex: 0xA9B0B8)

    static func of(_ hero: HeroID, alt: Bool = false) -> HeroLook {
        var look = base(hero)
        if alt {
            // The palette earned by clearing arcade: the hero in the mist's colours.
            look.cloth = look.cloth.mixed(with: UIColor(hex: 0x2B3550), 0.65)
            look.accent = look.accent.mixed(with: UIColor(hex: 0xE8E2D0), 0.55)
            look.trim = UIColor(hex: 0xC8D2E0)
            look.energy = UIColor(hex: 0x9FD8FF)
        }
        return look
    }

    /// The Echo of the Crossing: the player's own hero, made of mist.
    static func echo(of hero: HeroID) -> HeroLook {
        var look = base(hero)
        let mist = UIColor(hex: 0x8FA6C4)
        look.skin = UIColor(hex: 0x5C6B82)
        look.hair = UIColor(hex: 0x262E3D)
        look.cloth = mist.darker(0.5)
        look.trim = mist.lighter(0.4)
        look.metal = UIColor(hex: 0xC9D6EA)
        look.accent = UIColor(hex: 0x3B4D6E)
        look.energy = UIColor(hex: 0xB9E4FF)
        return look
    }

    private static func base(_ hero: HeroID) -> HeroLook {
        let tan = UIColor(hex: 0xC48A62), olive = UIColor(hex: 0xB5835A), deep = UIColor(hex: 0x7A4E32), dark = UIColor(hex: 0x5A3826)
        let light = UIColor(hex: 0xD9A57E), fair = UIColor(hex: 0xE2B48F)
        let black = UIColor(hex: 0x1E1A18), grey = UIColor(hex: 0x8F8C88), brown = UIColor(hex: 0x3D2A1E)
        let romanRed = UIColor(hex: 0x9E1F1F), linen = UIColor(hex: 0xEDE4CC), lapis = UIColor(hex: 0x24519E)
        let teal = UIColor(hex: 0x23807A), purple = UIColor(hex: 0x5E2C7A), hanRed = UIColor(hex: 0xA8261C), jade = UIColor(hex: 0x3F8F63)
        switch hero {
        case .gaius:
            return HeroLook(skin: olive, hair: grey, cloth: romanRed, trim: bronze, metal: bronze.darker(0.1), accent: romanRed.lighter(0.1),
                            headgear: .romanCrest, weapon: .gladius, offhand: .scutum, garment: .armouredTunic,
                            cape: false, beard: false, braid: false, energy: UIColor(hex: 0xFFB347))
        case .zhaoLin:
            return HeroLook(skin: light, hair: black, cloth: UIColor(hex: 0x5A3A22), trim: hanRed, metal: bronze, accent: hanRed,
                            headgear: .topknot, weapon: .crossbow, offhand: .quiver, garment: .lamellar,
                            cape: false, beard: false, braid: false, energy: UIColor(hex: 0xFF8A5C))
        case .tahmina:
            return HeroLook(skin: tan, hair: black, cloth: UIColor(hex: 0x8C5A2B), trim: teal, metal: steel, accent: teal,
                            headgear: .feltCap, weapon: .bow, offhand: .quiver, garment: .ridingCoat,
                            cape: false, beard: false, braid: true, energy: UIColor(hex: 0x7FE0C9))
        case .marcusVarro:
            return HeroLook(skin: olive, hair: brown, cloth: romanRed, trim: steel, metal: steel, accent: UIColor(hex: 0xB32D2D),
                            headgear: .plumedHelm, weapon: .spatha, offhand: .none, garment: .scaleCoat,
                            cape: true, beard: true, braid: false, energy: UIColor(hex: 0xE6EEF7))
        case .khepri:
            return HeroLook(skin: deep, hair: black, cloth: linen, trim: gold, metal: bronze, accent: lapis,
                            headgear: .scoutBand, weapon: .khopesh, offhand: .none, garment: .kilt,
                            cape: false, beard: false, braid: false, energy: UIColor(hex: 0xF2C14E))
        case .bardiya:
            return HeroLook(skin: tan, hair: black, cloth: UIColor(hex: 0x6B2348), trim: gold, metal: gold.darker(0.15), accent: UIColor(hex: 0xC8A951),
                            headgear: .immortalBand, weapon: .spear, offhand: .wickerShield, garment: .robe,
                            cape: false, beard: true, braid: false, energy: UIColor(hex: 0xE05A3A))
        case .weiJian:
            return HeroLook(skin: light, hair: black, cloth: hanRed, trim: gold, metal: UIColor(hex: 0x2C2622), accent: hanRed.lighter(0.1),
                            headgear: .guanHat, weapon: .jian, offhand: .none, garment: .lamellar,
                            cape: true, beard: true, braid: false, energy: UIColor(hex: 0xFF5D4A))
        case .meritamun:
            return HeroLook(skin: dark.lighter(0.1), hair: black, cloth: linen, trim: gold, metal: gold, accent: lapis,
                            headgear: .vultureCrown, weapon: .sistrumStaff, offhand: .none, garment: .stola,
                            cape: false, beard: false, braid: false, energy: UIColor(hex: 0xFFE27A))
        case .arsames:
            return HeroLook(skin: tan, hair: brown, cloth: purple, trim: gold, metal: gold, accent: UIColor(hex: 0x7A3C9E),
                            headgear: .tallCap, weapon: .akinaka, offhand: .none, garment: .ridingCoat,
                            cape: true, beard: true, braid: false, energy: UIColor(hex: 0xD9A635))
        case .livia:
            return HeroLook(skin: fair, hair: brown, cloth: UIColor(hex: 0xF1EADB), trim: gold, metal: gold, accent: romanRed,
                            headgear: .laurelBun, weapon: .standard, offhand: .none, garment: .stola,
                            cape: true, beard: false, braid: false, energy: UIColor(hex: 0xFFD36E))
        case .nefru:
            return HeroLook(skin: dark, hair: black, cloth: linen, trim: gold, metal: gold, accent: lapis,
                            headgear: .nubianCrown, weapon: .bow, offhand: .quiver, garment: .kilt,
                            cape: false, beard: false, braid: true, energy: UIColor(hex: 0xFFC94A))
        case .atossa:
            return HeroLook(skin: tan, hair: black, cloth: UIColor(hex: 0x1F6E6A), trim: gold, metal: gold.darker(0.1), accent: teal.lighter(0.15),
                            headgear: .diademVeil, weapon: .lance, offhand: .none, garment: .scaleCoat,
                            cape: true, beard: false, braid: true, energy: UIColor(hex: 0x6FE3E0))
        case .meiLin:
            return HeroLook(skin: light, hair: black, cloth: jade, trim: UIColor(hex: 0xE7D9A8), metal: steel, accent: jade.lighter(0.2),
                            headgear: .hairPins, weapon: .fan, offhand: .none, garment: .robe,
                            cape: false, beard: false, braid: false, energy: UIColor(hex: 0x8CF0B0))
        }
    }

    var isRanged: Bool { weapon == .bow || weapon == .crossbow }
}
