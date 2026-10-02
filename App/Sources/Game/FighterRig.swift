import SpriteKit
import FightCore

/// A commander drawn as a jointed figure: vector parts on a skeleton, posed
/// each tick from the simulation. Faces right; the node's xScale flips it.
final class FighterRig: SKNode {
    let look: HeroLook
    let s: CGFloat

    // Proportions at stature 1.
    private var thigh: CGFloat { 46 * s }
    private var shin: CGFloat { 46 * s }
    private var torsoLength: CGFloat { 58 * s }
    private var upperArm: CGFloat { 31 * s }
    private var foreArm: CGFloat { 29 * s }
    private var headRadius: CGFloat { 12.5 * s }
    var hipHeight: CGFloat { thigh + shin }

    private let body = SKNode()
    private let torso = SKNode()
    private let head = SKNode()
    private let thighF = SKNode(), shinF = SKNode(), thighB = SKNode(), shinB = SKNode()
    private let upperF = SKNode(), foreF = SKNode(), upperB = SKNode(), foreB = SKNode()
    private let weapon = SKNode()
    private let skirt = SKShapeNode()
    private let cape = SKShapeNode()
    private let aura = SKShapeNode()
    private let trail = SKShapeNode()
    private var weaponTip = CGPoint.zero
    private var weaponLength: CGFloat = 40
    private var trailPoints: [(tip: CGPoint, base: CGPoint)] = []
    private var weaponShapes: [SKShapeNode] = []
    private var tintables: [(SKShapeNode, UIColor)] = []
    private var paintedSprites: [SKSpriteNode] = []
    private var paintedCape: SKSpriteNode?
    private var paintedSkirt: SKSpriteNode?
    private(set) var isPainted = false

    init(look: HeroLook, stature: Double, parts: PaintedParts? = nil) {
        self.look = look
        self.s = CGFloat(stature)
        super.init()
        build()
        if let parts { paint(with: parts) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    // MARK: Building

    private func shape(_ path: CGPath, fill: UIColor, stroke: UIColor = HeroLook.outline, line: CGFloat = 1.6) -> SKShapeNode {
        let node = SKShapeNode(path: path)
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = line
        node.isAntialiased = true
        node.lineJoin = .round
        tintables.append((node, fill))
        return node
    }

    /// A limb hanging from its joint: a rounded capsule from (0,0) down.
    private func limb(length: CGFloat, top: CGFloat, bottom: CGFloat, fill: UIColor) -> SKShapeNode {
        // One smooth outline: rounded at the joint and at the far end, so
        // limbs meet without visible seams.
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: top / 2, startAngle: 0, endAngle: .pi, clockwise: false)
        path.addLine(to: CGPoint(x: -bottom / 2, y: -length))
        path.addArc(center: CGPoint(x: 0, y: -length), radius: bottom / 2, startAngle: .pi, endAngle: 0, clockwise: false)
        path.closeSubpath()
        let node = shape(path, fill: fill, stroke: fill.darker(0.55), line: 1.2)
        return node
    }

    private func build() {
        let look = self.look
        // The shadow lives on the ground and is placed by the scene.
        addChild(aura)
        aura.lineWidth = 0
        aura.blendMode = .add
        aura.alpha = 0
        aura.zPosition = -20
        aura.path = CGPath(ellipseIn: CGRect(x: -60 * s, y: -10, width: 120 * s, height: 210 * s), transform: nil)
        aura.fillColor = look.energy.withAlphaComponent(0.35)

        addChild(trail)
        trail.zPosition = 30
        trail.lineWidth = 0
        trail.blendMode = .add
        trail.fillColor = look.energy.withAlphaComponent(0.55)

        addChild(body)
        body.position = CGPoint(x: 0, y: hipHeight)

        let legCloth = trousered ? look.cloth.darker(0.25) : look.skin
        // Back leg, then torso, then the front leg and skirt over it.
        body.addChild(thighB)
        thighB.zPosition = -4
        thighB.addChild(limb(length: thigh, top: 15 * s, bottom: 11 * s, fill: legCloth.darker(0.18)))
        thighB.addChild(shinB)
        shinB.position = CGPoint(x: 0, y: -thigh)
        shinB.addChild(limb(length: shin, top: 11 * s, bottom: 9 * s, fill: look.skin.darker(0.18)))
        shinB.addChild(boot(back: true))

        body.addChild(thighF)
        thighF.zPosition = 1
        thighF.addChild(limb(length: thigh, top: 15 * s, bottom: 11 * s, fill: legCloth))
        thighF.addChild(shinF)
        shinF.position = CGPoint(x: 0, y: -thigh)
        shinF.addChild(limb(length: shin, top: 11 * s, bottom: 9 * s, fill: look.skin))
        shinF.addChild(boot(back: false))

        body.addChild(skirt)
        skirt.zPosition = 2
        skirt.fillColor = garmentSkirtColor
        skirt.strokeColor = HeroLook.outline
        skirt.lineWidth = 1.6
        tintables.append((skirt, garmentSkirtColor))

        body.addChild(torso)
        torso.zPosition = 3

        // Cape hangs behind everything on the torso.
        if look.cape {
            torso.addChild(cape)
            cape.zPosition = -9
            cape.position = CGPoint(x: -6 * s, y: torsoLength - 4 * s)
            cape.fillColor = look.accent.darker(0.15)
            cape.strokeColor = HeroLook.outline
            cape.lineWidth = 1.6
            tintables.append((cape, look.accent.darker(0.15)))
        }
        if look.offhand == .quiver {
            let quiver = CGMutablePath()
            quiver.addRoundedRect(in: CGRect(x: -16 * s, y: 18 * s, width: 9 * s, height: 40 * s), cornerWidth: 3, cornerHeight: 3)
            let q = shape(quiver, fill: UIColor(hex: 0x6B4426))
            q.zRotation = -0.35
            q.zPosition = -6
            torso.addChild(q)
            for i in 0..<3 {
                let fletch = shape(CGPath(rect: CGRect(x: -13 * s + CGFloat(i) * 2.5 * s, y: 56 * s, width: 2 * s, height: 9 * s), transform: nil), fill: look.trim, line: 0.8)
                fletch.zRotation = -0.35
                fletch.zPosition = -6
                torso.addChild(fletch)
            }
        }

        // Back arm.
        torso.addChild(upperB)
        upperB.position = CGPoint(x: -1 * s, y: torsoLength - 6 * s)
        upperB.zPosition = -5
        upperB.addChild(limb(length: upperArm, top: 12 * s, bottom: 10 * s, fill: sleeve.darker(0.2)))
        upperB.addChild(foreB)
        foreB.position = CGPoint(x: 0, y: -upperArm)
        foreB.addChild(limb(length: foreArm, top: 10 * s, bottom: 9 * s, fill: look.skin.darker(0.2)))
        let handB = shape(CGPath(ellipseIn: CGRect(x: -5.5 * s, y: -foreArm - 5.5 * s, width: 11 * s, height: 11 * s), transform: nil), fill: look.skin.darker(0.2))
        foreB.addChild(handB)
        if look.offhand == .scutum || look.offhand == .wickerShield {
            let shield = shieldNode()
            shield.position = CGPoint(x: 4 * s, y: -foreArm + 4 * s)
            // Carried on the near arm, so it is drawn in front of the body.
            shield.zPosition = 14
            foreB.addChild(shield)
        }

        torso.addChild(torsoShape())

        // Neck and head.
        let neck = shape(CGPath(roundedRect: CGRect(x: -4.5 * s, y: torsoLength - 4 * s, width: 9 * s, height: 12 * s), cornerWidth: 3, cornerHeight: 3, transform: nil), fill: look.skin)
        neck.zPosition = 0.5
        torso.addChild(neck)
        torso.addChild(head)
        head.position = CGPoint(x: 2 * s, y: torsoLength + 6 * s)
        head.zPosition = 2
        buildHead()

        // Front arm and weapon.
        torso.addChild(upperF)
        upperF.position = CGPoint(x: 2 * s, y: torsoLength - 6 * s)
        upperF.zPosition = 6
        upperF.addChild(limb(length: upperArm, top: 12 * s, bottom: 10 * s, fill: sleeve))
        upperF.addChild(foreF)
        foreF.position = CGPoint(x: 0, y: -upperArm)
        foreF.addChild(limb(length: foreArm, top: 10 * s, bottom: 9 * s, fill: look.skin))
        foreF.addChild(weapon)
        weapon.position = CGPoint(x: 0, y: -foreArm)
        weapon.zPosition = 2
        buildWeapon()
        let handF = shape(CGPath(ellipseIn: CGRect(x: -5.5 * s, y: -foreArm - 5.5 * s, width: 11 * s, height: 11 * s), transform: nil), fill: look.skin)
        handF.zPosition = 3
        foreF.addChild(handF)
        if look.trim != look.skin {
            let bracer = shape(CGPath(roundedRect: CGRect(x: -5.5 * s, y: -foreArm + 3 * s, width: 11 * s, height: 8 * s), cornerWidth: 2, cornerHeight: 2, transform: nil), fill: look.trim, line: 1)
            foreF.addChild(bracer)
        }
    }

    private var trousered: Bool { [.ridingCoat, .lamellar].contains(look.garment) }

    private var sleeve: UIColor {
        switch look.garment {
        case .robe, .ridingCoat, .lamellar: look.cloth
        case .stola: look.cloth.darker(0.05)
        default: look.skin
        }
    }

    private var garmentSkirtColor: UIColor {
        switch look.garment {
        case .armouredTunic, .scaleCoat: look.cloth
        case .lamellar: look.metal.mixed(with: look.cloth, 0.5)
        default: look.cloth
        }
    }

    private func boot(back: Bool) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -6 * s, y: -shin + 8 * s))
        path.addLine(to: CGPoint(x: 6 * s, y: -shin + 8 * s))
        path.addLine(to: CGPoint(x: 17 * s, y: -shin - 2 * s))
        path.addQuadCurve(to: CGPoint(x: 14 * s, y: -shin - 6 * s), control: CGPoint(x: 19 * s, y: -shin - 6 * s))
        path.addLine(to: CGPoint(x: -7 * s, y: -shin - 6 * s))
        path.closeSubpath()
        let color = UIColor(hex: 0x4A3424)
        return shape(path, fill: back ? color.darker(0.2) : color)
    }

    private func torsoShape() -> SKNode {
        let node = SKNode()
        let w = s
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -12 * w, y: -2 * w))
        path.addLine(to: CGPoint(x: 11 * w, y: -2 * w))
        path.addQuadCurve(to: CGPoint(x: 14 * w, y: torsoLength - 6 * w), control: CGPoint(x: 17 * w, y: torsoLength * 0.55))
        path.addQuadCurve(to: CGPoint(x: -13 * w, y: torsoLength - 4 * w), control: CGPoint(x: 0, y: torsoLength + 3 * w))
        path.addQuadCurve(to: CGPoint(x: -12 * w, y: -2 * w), control: CGPoint(x: -16 * w, y: torsoLength * 0.4))
        path.closeSubpath()
        let armoured = [.armouredTunic, .scaleCoat, .lamellar].contains(look.garment)
        let fill = armoured ? look.metal : look.cloth
        node.addChild(shape(path, fill: fill))
        // Detail: bands of a lorica, scales, lamellae, or a sash.
        let detail = CGMutablePath()
        switch look.garment {
        case .armouredTunic:
            for i in 1...4 {
                let y = CGFloat(i) * 9 * w
                detail.move(to: CGPoint(x: -12 * w, y: y)); detail.addQuadCurve(to: CGPoint(x: 13 * w, y: y + 2 * w), control: CGPoint(x: 0, y: y - 3 * w))
            }
        case .scaleCoat, .lamellar:
            for row in 0..<6 {
                for col in 0..<4 {
                    let x = -9 * w + CGFloat(col) * 6 * w + (row % 2 == 0 ? 0 : 3 * w)
                    let y = 4 * w + CGFloat(row) * 7.5 * w
                    detail.addArc(center: CGPoint(x: x, y: y), radius: 3 * w, startAngle: .pi, endAngle: 0, clockwise: true)
                }
            }
        case .robe, .stola, .ridingCoat:
            detail.move(to: CGPoint(x: -8 * w, y: torsoLength - 6 * w)); detail.addLine(to: CGPoint(x: 10 * w, y: 6 * w))
        case .kilt:
            break
        }
        let lines = SKShapeNode(path: detail)
        lines.strokeColor = (armoured ? look.metal.darker(0.35) : look.trim).withAlphaComponent(0.9)
        lines.lineWidth = armoured ? 1.2 : 3 * w
        node.addChild(lines)
        // A belt at the hip.
        let belt = shape(CGPath(roundedRect: CGRect(x: -13 * w, y: -3 * w, width: 26 * w, height: 7 * w), cornerWidth: 2, cornerHeight: 2, transform: nil), fill: look.trim.darker(0.1), line: 1.2)
        node.addChild(belt)
        // A collar for the Egyptians, a scarf for Gaius.
        if look.headgear == .vultureCrown || look.headgear == .nubianCrown || look.headgear == .scoutBand {
            let collar = CGMutablePath()
            collar.addArc(center: CGPoint(x: 1 * w, y: torsoLength - 2 * w), radius: 13 * w, startAngle: .pi * 1.05, endAngle: -0.05, clockwise: false)
            collar.addArc(center: CGPoint(x: 1 * w, y: torsoLength - 2 * w), radius: 5 * w, startAngle: -0.05, endAngle: .pi * 1.05, clockwise: true)
            collar.closeSubpath()
            node.addChild(shape(collar, fill: HeroLook.gold, line: 1))
            let band = SKShapeNode(path: { let p = CGMutablePath(); p.addArc(center: CGPoint(x: 1 * w, y: torsoLength - 2 * w), radius: 9 * w, startAngle: .pi * 1.05, endAngle: -0.05, clockwise: false); return p }())
            band.strokeColor = look.accent; band.lineWidth = 2.5 * w
            node.addChild(band)
        }
        if look.headgear == .romanCrest {
            let scarf = CGMutablePath()
            scarf.addEllipse(in: CGRect(x: -12 * w, y: torsoLength - 10 * w, width: 26 * w, height: 12 * w))
            node.addChild(shape(scarf, fill: look.accent, line: 1.2))
        }
        return node
    }

    private func buildHead() {
        let r = headRadius, w = s
        let look = self.look
        // Hair or veil behind the head.
        if look.braid {
            let braid = CGMutablePath()
            braid.move(to: CGPoint(x: -8 * w, y: 2 * w))
            braid.addQuadCurve(to: CGPoint(x: -14 * w, y: -34 * w), control: CGPoint(x: -20 * w, y: -12 * w))
            braid.addQuadCurve(to: CGPoint(x: -4 * w, y: 0), control: CGPoint(x: -10 * w, y: -14 * w))
            let node = shape(braid, fill: look.hair)
            node.zPosition = -3
            head.addChild(node)
        }
        if look.headgear == .diademVeil || look.headgear == .vultureCrown || look.headgear == .nubianCrown {
            let veil = CGMutablePath()
            veil.move(to: CGPoint(x: -2 * w, y: r + 2 * w))
            veil.addQuadCurve(to: CGPoint(x: -14 * w, y: -30 * w), control: CGPoint(x: -24 * w, y: 0))
            veil.addLine(to: CGPoint(x: -2 * w, y: -24 * w))
            veil.addQuadCurve(to: CGPoint(x: 2 * w, y: -2 * w), control: CGPoint(x: -6 * w, y: -10 * w))
            veil.closeSubpath()
            let color = look.headgear == .diademVeil ? look.accent : look.accent
            let node = shape(veil, fill: color)
            node.zPosition = -3
            head.addChild(node)
            if look.headgear != .diademVeil {
                // Nemes-like stripes.
                let stripes = CGMutablePath()
                for i in 0..<4 { let y = -CGFloat(i) * 7 * w - 2 * w; stripes.move(to: CGPoint(x: -18 * w, y: y)); stripes.addLine(to: CGPoint(x: -3 * w, y: y - 4 * w)) }
                let lines = SKShapeNode(path: stripes)
                lines.strokeColor = HeroLook.gold; lines.lineWidth = 2 * w; lines.zPosition = -2.5
                head.addChild(lines)
            }
        }

        let face = shape(CGPath(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2.05), transform: nil), fill: look.skin)
        head.addChild(face)
        // Nose and jaw toward the enemy.
        let nose = CGMutablePath()
        nose.move(to: CGPoint(x: r - 1, y: 3 * w)); nose.addLine(to: CGPoint(x: r + 3 * w, y: -1 * w)); nose.addLine(to: CGPoint(x: r - 1, y: -2 * w))
        let noseNode = SKShapeNode(path: nose); noseNode.fillColor = look.skin; noseNode.strokeColor = HeroLook.outline; noseNode.lineWidth = 1.2
        head.addChild(noseNode)
        let eye = SKShapeNode(ellipseOf: CGSize(width: 3.2 * w, height: 2.4 * w))
        eye.fillColor = HeroLook.outline; eye.strokeColor = .clear
        eye.position = CGPoint(x: r * 0.5, y: 2.5 * w)
        head.addChild(eye)
        let brow = SKShapeNode(path: { let p = CGMutablePath(); p.move(to: CGPoint(x: r * 0.2, y: 6 * w)); p.addLine(to: CGPoint(x: r * 0.95, y: 5 * w)); return p }())
        brow.strokeColor = look.hair.darker(0.2); brow.lineWidth = 1.6 * w
        head.addChild(brow)
        if [.scoutBand, .vultureCrown, .nubianCrown].contains(look.headgear) {
            let kohl = SKShapeNode(path: { let p = CGMutablePath(); p.move(to: CGPoint(x: r * 0.25, y: 2.5 * w)); p.addLine(to: CGPoint(x: r * 0.95, y: 1.5 * w)); return p }())
            kohl.strokeColor = HeroLook.outline; kohl.lineWidth = 1.1
            head.addChild(kohl)
        }
        if look.beard {
            let beard = CGMutablePath()
            beard.move(to: CGPoint(x: -r * 0.5, y: -2 * w))
            beard.addQuadCurve(to: CGPoint(x: r * 0.9, y: -4 * w), control: CGPoint(x: r * 0.2, y: -r * 1.9))
            beard.addLine(to: CGPoint(x: r * 0.95, y: -1 * w))
            beard.addQuadCurve(to: CGPoint(x: -r * 0.5, y: -2 * w), control: CGPoint(x: r * 0.2, y: -r * 0.6))
            head.addChild(shape(beard, fill: look.hair, line: 1.2))
        }

        // Hair cap for anyone not wearing a full helmet.
        if ![.romanCrest, .plumedHelm, .vultureCrown, .nubianCrown, .tallCap].contains(look.headgear) {
            let hair = CGMutablePath()
            hair.addArc(center: .zero, radius: r + 1, startAngle: .pi * 0.15, endAngle: .pi * 1.25, clockwise: false)
            hair.addQuadCurve(to: CGPoint(x: -r * 0.2, y: r * 0.3), control: CGPoint(x: -r * 0.3, y: -r * 0.2))
            hair.closeSubpath()
            head.addChild(shape(hair, fill: look.hair, line: 1.2))
        }

        let gear = CGMutablePath()
        var gearFill = look.metal
        var extra: [(CGPath, UIColor)] = []
        switch look.headgear {
        case .romanCrest, .plumedHelm:
            gear.addArc(center: CGPoint(x: 0, y: 1 * w), radius: r + 2 * w, startAngle: -0.15, endAngle: .pi + 0.35, clockwise: false)
            gear.addLine(to: CGPoint(x: -r - 6 * w, y: -4 * w))
            gear.addLine(to: CGPoint(x: -r + 2 * w, y: -2 * w))
            gear.closeSubpath()
            gearFill = look.metal
            let crest = CGMutablePath()
            if look.headgear == .romanCrest {
                crest.addEllipse(in: CGRect(x: -r - 2 * w, y: r - 1 * w, width: 2 * r + 2 * w, height: 10 * w))
            } else {
                crest.move(to: CGPoint(x: r * 0.5, y: r + 1 * w))
                crest.addQuadCurve(to: CGPoint(x: -r - 18 * w, y: -6 * w), control: CGPoint(x: -r, y: r + 22 * w))
                crest.addQuadCurve(to: CGPoint(x: -r * 0.6, y: r * 0.8), control: CGPoint(x: -r - 4 * w, y: r + 6 * w))
                crest.closeSubpath()
            }
            extra.append((crest, look.headgear == .romanCrest ? UIColor(hex: 0xB3201F) : UIColor(hex: 0xC42B2B)))
            let cheek = CGPath(roundedRect: CGRect(x: 1 * w, y: -r + 1 * w, width: 7 * w, height: 12 * w), cornerWidth: 3, cornerHeight: 3, transform: nil)
            extra.append((cheek, look.metal.darker(0.1)))
        case .laurelBun:
            extra.append((CGPath(ellipseIn: CGRect(x: -r - 7 * w, y: -2 * w, width: 12 * w, height: 12 * w), transform: nil), look.hair))
            let laurel = CGMutablePath()
            for i in 0..<6 {
                let a = CGFloat.pi * (0.15 + CGFloat(i) * 0.14)
                let c = CGPoint(x: cos(a) * (r + 1), y: sin(a) * (r + 1) - 1 * w)
                laurel.addEllipse(in: CGRect(x: c.x - 3 * w, y: c.y - 1.6 * w, width: 6 * w, height: 3.2 * w))
            }
            extra.append((laurel, HeroLook.gold))
        case .scoutBand:
            gear.addRect(CGRect(x: -r, y: 3 * w, width: 2 * r, height: 4 * w))
            gearFill = HeroLook.gold
        case .immortalBand:
            gear.addRect(CGRect(x: -r, y: 4 * w, width: 2 * r, height: 4.5 * w))
            gearFill = look.trim
        case .guanHat:
            gear.addRoundedRect(in: CGRect(x: -6 * w, y: r - 2 * w, width: 12 * w, height: 9 * w), cornerWidth: 3, cornerHeight: 3)
            gearFill = UIColor(hex: 0x1C1C1C)
            extra.append((CGPath(rect: CGRect(x: -10 * w, y: r + 3 * w, width: 20 * w, height: 2 * w), transform: nil), HeroLook.gold))
        case .vultureCrown, .nubianCrown:
            gear.addArc(center: CGPoint(x: 0, y: 1 * w), radius: r + 2 * w, startAngle: -0.1, endAngle: .pi + 0.6, clockwise: false)
            gear.closeSubpath()
            gearFill = look.accent
            extra.append((CGPath(rect: CGRect(x: -r - 1 * w, y: 4 * w, width: 2 * r + 2 * w, height: 3.5 * w), transform: nil), HeroLook.gold))
            let uraeus = CGMutablePath()
            uraeus.move(to: CGPoint(x: r - 2 * w, y: 7 * w)); uraeus.addQuadCurve(to: CGPoint(x: r + 3 * w, y: 15 * w), control: CGPoint(x: r + 5 * w, y: 8 * w))
            uraeus.addLine(to: CGPoint(x: r, y: 9 * w)); uraeus.closeSubpath()
            extra.append((uraeus, HeroLook.gold))
        case .feltCap:
            gear.addArc(center: CGPoint(x: -1 * w, y: 2 * w), radius: r + 2 * w, startAngle: -0.05, endAngle: .pi + 0.2, clockwise: false)
            gear.addQuadCurve(to: CGPoint(x: -r - 8 * w, y: -8 * w), control: CGPoint(x: -r - 6 * w, y: 0))
            gear.addLine(to: CGPoint(x: -r + 2 * w, y: 0))
            gear.closeSubpath()
            gearFill = UIColor(hex: 0x7B5B3A)
            extra.append((CGPath(rect: CGRect(x: -r - 1 * w, y: 3 * w, width: 2 * r + 2 * w, height: 3 * w), transform: nil), look.trim))
        case .tallCap:
            gear.move(to: CGPoint(x: -r - 1 * w, y: 2 * w))
            gear.addLine(to: CGPoint(x: -r + 1 * w, y: r + 14 * w))
            gear.addQuadCurve(to: CGPoint(x: r - 2 * w, y: r + 12 * w), control: CGPoint(x: 0, y: r + 18 * w))
            gear.addLine(to: CGPoint(x: r + 1 * w, y: 2 * w))
            gear.closeSubpath()
            gearFill = look.cloth.lighter(0.1)
            extra.append((CGPath(rect: CGRect(x: -r - 1 * w, y: 2 * w, width: 2 * r + 2 * w, height: 4 * w), transform: nil), HeroLook.gold))
        case .diademVeil:
            let diadem = CGMutablePath()
            diadem.addRect(CGRect(x: -r * 0.6, y: r - 3 * w, width: r * 1.6, height: 3.5 * w))
            extra.append((diadem, HeroLook.gold))
            extra.append((CGPath(ellipseIn: CGRect(x: r * 0.3, y: r - 2.5 * w, width: 4.5 * w, height: 4.5 * w), transform: nil), UIColor(hex: 0x2FB3A5)))
        case .topknot:
            extra.append((CGPath(ellipseIn: CGRect(x: -6 * w, y: r - 3 * w, width: 10 * w, height: 9 * w), transform: nil), look.hair))
            extra.append((CGPath(rect: CGRect(x: -5 * w, y: r - 1 * w, width: 8 * w, height: 2.5 * w), transform: nil), UIColor(hex: 0xC0261C)))
        case .hairPins:
            extra.append((CGPath(ellipseIn: CGRect(x: -9 * w, y: r - 4 * w, width: 13 * w, height: 11 * w), transform: nil), look.hair))
            let pins = CGMutablePath()
            pins.move(to: CGPoint(x: -14 * w, y: r + 8 * w)); pins.addLine(to: CGPoint(x: 6 * w, y: r))
            pins.move(to: CGPoint(x: -12 * w, y: r + 1 * w)); pins.addLine(to: CGPoint(x: 4 * w, y: r + 9 * w))
            let p = SKShapeNode(path: pins); p.strokeColor = UIColor(hex: 0x9FE3B8); p.lineWidth = 1.8 * w
            head.addChild(p)
        }
        if !gear.isEmpty { head.addChild(shape(gear, fill: gearFill)) }
        for (path, color) in extra { head.addChild(shape(path, fill: color, line: 1.1)) }
    }

    private func shieldNode() -> SKNode {
        let node = SKNode()
        let w = s
        if look.offhand == .scutum {
            let path = CGPath(roundedRect: CGRect(x: -6 * w, y: -38 * w, width: 18 * w, height: 70 * w), cornerWidth: 6 * w, cornerHeight: 10 * w, transform: nil)
            node.addChild(shape(path, fill: UIColor(hex: 0xA3201E)))
            let boss = shape(CGPath(ellipseIn: CGRect(x: -2 * w, y: -8 * w, width: 10 * w, height: 12 * w), transform: nil), fill: HeroLook.bronze, line: 1)
            node.addChild(boss)
            let rim = SKShapeNode(path: CGPath(roundedRect: CGRect(x: -4 * w, y: -35 * w, width: 14 * w, height: 64 * w), cornerWidth: 5 * w, cornerHeight: 8 * w, transform: nil))
            rim.strokeColor = HeroLook.gold.withAlphaComponent(0.85); rim.lineWidth = 1.4; rim.fillColor = .clear
            node.addChild(rim)
        } else {
            let path = CGMutablePath()
            path.addEllipse(in: CGRect(x: -6 * w, y: -40 * w, width: 18 * w, height: 72 * w))
            node.addChild(shape(path, fill: UIColor(hex: 0xC9A66B)))
            let weave = CGMutablePath()
            for i in 0..<8 { let y = -34 * w + CGFloat(i) * 8.5 * w; weave.move(to: CGPoint(x: -4 * w, y: y)); weave.addLine(to: CGPoint(x: 10 * w, y: y)) }
            let lines = SKShapeNode(path: weave); lines.strokeColor = UIColor(hex: 0x8A6A3A); lines.lineWidth = 1
            node.addChild(lines)
        }
        return node
    }

    private func buildWeapon() {
        let w = s
        let blade = look.metal == HeroLook.gold || look.metal == look.trim ? HeroLook.steel.lighter(0.15) : HeroLook.steel.lighter(0.1)
        let wood = UIColor(hex: 0x6E4A2A)
        var parts: [(CGPath, UIColor)] = []
        func bladePath(length: CGFloat, width: CGFloat, tip: CGFloat = 8) -> CGPath {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: -width / 2, y: -4 * w))
            p.addLine(to: CGPoint(x: -width / 2, y: -length + tip))
            p.addLine(to: CGPoint(x: 0, y: -length))
            p.addLine(to: CGPoint(x: width / 2, y: -length + tip))
            p.addLine(to: CGPoint(x: width / 2, y: -4 * w))
            p.closeSubpath()
            return p
        }
        func grip(_ length: CGFloat) -> CGPath { CGPath(roundedRect: CGRect(x: -2.5 * w, y: -2 * w, width: 5 * w, height: length), cornerWidth: 2, cornerHeight: 2, transform: nil) }
        func guardBar(_ width: CGFloat) -> CGPath { CGPath(roundedRect: CGRect(x: -width / 2, y: -6 * w, width: width, height: 4 * w), cornerWidth: 1.5, cornerHeight: 1.5, transform: nil) }

        switch look.weapon {
        case .gladius:
            weaponLength = 44 * w
            parts = [(bladePath(length: 44 * w, width: 8 * w, tip: 10 * w), blade), (guardBar(14 * w), HeroLook.bronze), (grip(10 * w), wood)]
        case .spatha:
            weaponLength = 58 * w
            parts = [(bladePath(length: 58 * w, width: 6.5 * w), blade), (guardBar(13 * w), HeroLook.bronze), (grip(10 * w), wood)]
        case .jian:
            weaponLength = 62 * w
            parts = [(bladePath(length: 62 * w, width: 5 * w, tip: 9 * w), blade), (guardBar(14 * w), HeroLook.gold), (grip(12 * w), UIColor(hex: 0x2A2A2A))]
        case .akinaka:
            weaponLength = 36 * w
            parts = [(bladePath(length: 36 * w, width: 7 * w, tip: 9 * w), blade), (guardBar(12 * w), HeroLook.gold), (grip(9 * w), HeroLook.gold)]
        case .khopesh:
            weaponLength = 48 * w
            let p = CGMutablePath()
            p.move(to: CGPoint(x: -2.5 * w, y: -4 * w))
            p.addLine(to: CGPoint(x: -2.5 * w, y: -26 * w))
            p.addQuadCurve(to: CGPoint(x: 14 * w, y: -48 * w), control: CGPoint(x: -10 * w, y: -46 * w))
            p.addQuadCurve(to: CGPoint(x: 3 * w, y: -26 * w), control: CGPoint(x: 2 * w, y: -36 * w))
            p.addLine(to: CGPoint(x: 2.5 * w, y: -4 * w))
            p.closeSubpath()
            parts = [(p, HeroLook.bronze.lighter(0.2)), (grip(10 * w), wood)]
        case .spear, .lance:
            let long: CGFloat = look.weapon == .lance ? 128 : 112
            weaponLength = long * w
            parts = [(CGPath(roundedRect: CGRect(x: -2.5 * w, y: -long * w + 14 * w, width: 5 * w, height: long * w + 18 * w), cornerWidth: 2, cornerHeight: 2, transform: nil), wood),
                     (bladePath(length: long * w, width: 9 * w, tip: 14 * w).copy(using: [CGAffineTransform(translationX: 0, y: 0)])!, blade)]
            let head = CGMutablePath()
            head.move(to: CGPoint(x: 0, y: -long * w - 4 * w)); head.addQuadCurve(to: CGPoint(x: 0, y: -long * w + 18 * w), control: CGPoint(x: 9 * w, y: -long * w + 6 * w))
            head.addQuadCurve(to: CGPoint(x: 0, y: -long * w - 4 * w), control: CGPoint(x: -9 * w, y: -long * w + 6 * w))
            parts[1] = (head, blade)
            if look.weapon == .spear {
                // The Immortals' pomegranate butt.
                parts.append((CGPath(ellipseIn: CGRect(x: -5 * w, y: 12 * w, width: 10 * w, height: 10 * w), transform: nil), HeroLook.gold))
            } else {
                let pennant = CGMutablePath()
                pennant.move(to: CGPoint(x: 0, y: -long * w + 22 * w)); pennant.addLine(to: CGPoint(x: -16 * w, y: -long * w + 30 * w)); pennant.addLine(to: CGPoint(x: 0, y: -long * w + 38 * w))
                pennant.closeSubpath()
                parts.append((pennant, look.accent))
            }
        case .standard:
            weaponLength = 96 * w
            parts = [(CGPath(roundedRect: CGRect(x: -2.5 * w, y: -96 * w, width: 5 * w, height: 112 * w), cornerWidth: 2, cornerHeight: 2, transform: nil), wood)]
            let eagle = CGMutablePath()
            eagle.move(to: CGPoint(x: 0, y: -96 * w))
            eagle.addLine(to: CGPoint(x: -16 * w, y: -112 * w)); eagle.addLine(to: CGPoint(x: -6 * w, y: -106 * w))
            eagle.addLine(to: CGPoint(x: 0, y: -118 * w)); eagle.addLine(to: CGPoint(x: 6 * w, y: -106 * w))
            eagle.addLine(to: CGPoint(x: 16 * w, y: -112 * w)); eagle.closeSubpath()
            parts.append((eagle, HeroLook.gold))
            parts.append((CGPath(roundedRect: CGRect(x: -9 * w, y: -92 * w, width: 18 * w, height: 22 * w), cornerWidth: 2, cornerHeight: 2, transform: nil), UIColor(hex: 0xA3201E)))
            weaponLength = 118 * w
        case .bow:
            weaponLength = 40 * w
            let bow = CGMutablePath()
            bow.move(to: CGPoint(x: 0, y: 38 * w))
            bow.addQuadCurve(to: CGPoint(x: 0, y: -38 * w), control: CGPoint(x: 26 * w, y: 0))
            let limbNode = SKShapeNode(path: bow); limbNode.strokeColor = look.weapon == .bow && look.metal == HeroLook.gold ? HeroLook.gold : UIColor(hex: 0x5C3A1E); limbNode.lineWidth = 4.5 * w; limbNode.lineCap = .round
            let string = SKShapeNode(path: { let p = CGMutablePath(); p.move(to: CGPoint(x: 0, y: 38 * w)); p.addLine(to: CGPoint(x: 0, y: -38 * w)); return p }())
            string.strokeColor = UIColor(white: 0.9, alpha: 0.8); string.lineWidth = 1
            // Drawn sideways: the bow's long axis runs along the weapon direction.
            let holder = SKNode(); holder.zRotation = .pi / 2
            holder.addChild(string); holder.addChild(limbNode)
            weapon.addChild(holder)
            weaponShapes.append(limbNode)
        case .crossbow:
            weaponLength = 44 * w
            parts = [(CGPath(roundedRect: CGRect(x: -3.5 * w, y: -44 * w, width: 7 * w, height: 52 * w), cornerWidth: 2, cornerHeight: 2, transform: nil), wood)]
            let prod = CGMutablePath()
            prod.move(to: CGPoint(x: -22 * w, y: -36 * w)); prod.addQuadCurve(to: CGPoint(x: 22 * w, y: -36 * w), control: CGPoint(x: 0, y: -50 * w))
            let prodNode = SKShapeNode(path: prod); prodNode.strokeColor = HeroLook.bronze; prodNode.lineWidth = 4 * w; prodNode.lineCap = .round
            weapon.addChild(prodNode)
            parts.append((CGPath(rect: CGRect(x: -4 * w, y: 0, width: 8 * w, height: 5 * w), transform: nil), HeroLook.bronze))
        case .sistrumStaff:
            weaponLength = 100 * w
            parts = [(CGPath(roundedRect: CGRect(x: -2.5 * w, y: -86 * w, width: 5 * w, height: 104 * w), cornerWidth: 2, cornerHeight: 2, transform: nil), HeroLook.gold.darker(0.2))]
            let loop = CGMutablePath()
            loop.addEllipse(in: CGRect(x: -10 * w, y: -106 * w, width: 20 * w, height: 24 * w))
            let loopNode = SKShapeNode(path: loop); loopNode.strokeColor = HeroLook.gold; loopNode.lineWidth = 3.5 * w; loopNode.fillColor = .clear
            weapon.addChild(loopNode)
            parts.append((CGPath(ellipseIn: CGRect(x: -6 * w, y: -100 * w, width: 12 * w, height: 12 * w), transform: nil), UIColor(hex: 0xFFE9A3)))
        case .fan:
            weaponLength = 34 * w
            let fan = CGMutablePath()
            fan.move(to: .zero)
            fan.addArc(center: .zero, radius: 34 * w, startAngle: -.pi / 2 - 0.75, endAngle: -.pi / 2 + 0.75, clockwise: false)
            fan.closeSubpath()
            parts = [(fan, UIColor(hex: 0xEDE3C8))]
            let ribs = CGMutablePath()
            for i in 0...6 { let a = -CGFloat.pi / 2 - 0.75 + CGFloat(i) * 0.25; ribs.move(to: .zero); ribs.addLine(to: CGPoint(x: cos(a) * 34 * w, y: sin(a) * 34 * w)) }
            let ribNode = SKShapeNode(path: ribs); ribNode.strokeColor = UIColor(hex: 0x3A5A44); ribNode.lineWidth = 1
            weapon.addChild(ribNode)
        }
        for (index, (path, color)) in parts.enumerated() {
            let node = shape(path, fill: color, line: 1.2)
            node.zPosition = CGFloat(index) * 0.01 - 0.5
            weapon.addChild(node)
            weaponShapes.append(node)
        }
        weaponTip = CGPoint(x: 0, y: -weaponLength)
    }

    // MARK: Painted parts

    /// Swaps the drawn shapes for a hero's painted pieces. Torso and limbs are
    /// sized to the skeleton so every joint lines up; the head, weapon, cape and
    /// the rest keep the painting's own proportions.
    private func paint(with parts: PaintedParts) {
        isPainted = true
        // Everything drawn so far, except the effects layers, goes.
        func strip(_ node: SKNode) {
            for child in node.children {
                if child === trail || child === aura { continue }
                if child is SKShapeNode || child.name == "decor" { child.removeFromParent() } else { strip(child) }
            }
        }
        strip(self)

        let torsoPart = parts["torso"]!
        // Scale for the free pieces: from the full figure, or failing that the torso.
        let k: CGFloat = parts.figureHeight > 0
            ? 180 * s / parts.figureHeight
            : (torsoLength + 10 * s) / torsoPart.size.height

        func sprite(_ part: PaintedParts.Part, height: CGFloat? = nil, scale: CGFloat? = nil, dim: Bool = false) -> SKSpriteNode {
            let node = SKSpriteNode(texture: part.texture)
            let f = height.map { $0 / part.size.height } ?? (scale ?? k)
            node.size = CGSize(width: part.size.width * f, height: part.size.height * f)
            node.anchorPoint = part.anchor
            if dim { node.color = .black; node.colorBlendFactor = 0.32 }
            node.userData = ["dim": dim ? CGFloat(0.32) : CGFloat(0)]
            paintedSprites.append(node)
            return node
        }

        let torsoSprite = sprite(torsoPart, height: torsoLength + 12 * s)
        torsoSprite.position = CGPoint(x: 0, y: -5 * s)
        torso.addChild(torsoSprite)

        let headSprite = sprite(parts["head"]!)
        headSprite.position = CGPoint(x: -2 * s, y: -headRadius - 8 * s)
        headSprite.zPosition = 1
        head.addChild(headSprite)
        if let hair = parts["backHair"] {
            let node = sprite(hair)
            node.position = CGPoint(x: -6 * s, y: 6 * s)
            node.zPosition = -3
            head.addChild(node)
        }

        for (bone, part, length, dim) in [(upperF, "upperArm", upperArm + 9 * s, false), (foreF, "forearm", foreArm + 12 * s, false),
                                          (upperB, "upperArm", upperArm + 9 * s, true), (foreB, "forearm", foreArm + 12 * s, true),
                                          (thighF, "thigh", thigh + 9 * s, false), (shinF, "shin", shin + 15 * s, false),
                                          (thighB, "thigh", thigh + 9 * s, true), (shinB, "shin", shin + 15 * s, true)] {
            let node = sprite(parts[part]!, height: length, dim: dim)
            node.position = CGPoint(x: 0, y: 3 * s)
            node.zPosition = 0.5
            bone.addChild(node)
        }

        if let skirt = parts["skirt"] {
            let node = sprite(skirt)
            node.position = CGPoint(x: 0, y: 8 * s)
            node.zPosition = 2
            body.addChild(node)
            paintedSkirt = node
        }
        if let cape = parts["cape"] {
            let node = sprite(cape)
            node.position = CGPoint(x: -6 * s, y: torsoLength - 2 * s)
            node.zPosition = -9
            torso.addChild(node)
            paintedCape = node
        }
        if let weaponPart = parts["weapon"] {
            let node = sprite(weaponPart)
            // Painted point-up; the rig's weapon points down its arm.
            node.zRotation = .pi
            weapon.addChild(node)
            weaponLength = node.size.height * (1 - weaponPart.anchor.y)
            weaponTip = CGPoint(x: 0, y: -weaponLength)
        }
        if let offhand = parts["offhand"] {
            let node = sprite(offhand)
            if look.offhand == .quiver {
                node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                node.position = CGPoint(x: -12 * s, y: torsoLength * 0.6)
                node.zRotation = -0.35
                node.zPosition = -6
                torso.addChild(node)
            } else {
                node.position = CGPoint(x: 4 * s, y: -foreArm + 2 * s)
                node.zPosition = 14
                foreB.addChild(node)
            }
        }
    }

    // MARK: Posing

    /// Applies a pose. `velocity` sways the cape; `energy` lights the aura.
    func apply(_ pose: Pose, velocity: CGFloat) {
        body.position = CGPoint(x: pose.hipX, y: hipHeight + pose.hipY)
        body.zRotation = pose.spin
        torso.zRotation = pose.torso
        head.zRotation = pose.head
        upperF.zRotation = pose.shoulderF
        foreF.zRotation = pose.elbowF
        upperB.zRotation = pose.shoulderB
        foreB.zRotation = pose.elbowB
        thighF.zRotation = pose.hipF
        shinF.zRotation = pose.kneeF
        thighB.zRotation = pose.hipB
        shinB.zRotation = pose.kneeB
        weapon.zRotation = pose.weapon - (pose.torso + pose.shoulderF + pose.elbowF)

        if isPainted {
            // A painted skirt swings with the legs; a painted cape trails.
            paintedSkirt?.zRotation = (pose.hipF + pose.hipB) * 0.22
            paintedSkirt?.xScale = 1 + min(0.25, abs(pose.hipF - pose.hipB) * 0.12)
            if let cape = paintedCape {
                let sway = max(-0.6, min(0.9, -velocity * 0.05 - pose.torso * 0.6)) + sin(CGFloat(CACurrentMediaTime()) * 2.2) * 0.04
                cape.zRotation = -sway - 0.1
            }
        } else {
            updateSkirt(pose)
            if look.cape { updateCape(pose, velocity: velocity) }
        }

        aura.alpha = pose.glow * 0.9
        if pose.glow > 0.05 { aura.setScale(1 + 0.04 * sin(CGFloat(CACurrentMediaTime()) * 18)) }

        // The weapon's trail, kept in the rig's own space.
        let tip = weapon.convert(weaponTip, to: self)
        let mid = weapon.convert(CGPoint(x: 0, y: -weaponLength * 0.62), to: self)
        if pose.trail > 0.05 && !look.isRanged {
            trailPoints.append((tip, mid))
            if trailPoints.count > 5 { trailPoints.removeFirst() }
        } else if !trailPoints.isEmpty {
            trailPoints.removeFirst(min(2, trailPoints.count))
        }
        if trailPoints.count >= 2 {
            let path = CGMutablePath()
            path.move(to: trailPoints[0].tip)
            for point in trailPoints.dropFirst() { path.addLine(to: point.tip) }
            for point in trailPoints.reversed() { path.addLine(to: point.base) }
            path.closeSubpath()
            trail.path = path
            trail.alpha = max(0.15, pose.trail * 0.7)
        } else {
            trail.path = nil
        }
    }

    private func updateSkirt(_ pose: Pose) {
        let length: CGFloat
        let flare: CGFloat
        switch look.garment {
        case .robe, .stola: length = 78 * s; flare = 12 * s
        case .ridingCoat: length = 54 * s; flare = 8 * s
        case .lamellar: length = 46 * s; flare = 6 * s
        case .armouredTunic, .scaleCoat: length = 32 * s; flare = 5 * s
        case .kilt: length = 34 * s; flare = 6 * s
        }
        let spread = abs(pose.hipF - pose.hipB)
        let front = sin(max(pose.hipF, pose.hipB)) * length * 0.75 + 12 * s
        let back = sin(min(pose.hipF, pose.hipB)) * length * 0.75 - 12 * s
        let bottom = -length * cos(min(1.2, spread * 0.35))
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -13 * s, y: 4 * s))
        path.addLine(to: CGPoint(x: 12 * s, y: 4 * s))
        path.addLine(to: CGPoint(x: front + flare * 0.3, y: bottom))
        path.addQuadCurve(to: CGPoint(x: back - flare, y: bottom + 2 * s), control: CGPoint(x: (front + back) / 2, y: bottom - 4 * s))
        path.closeSubpath()
        if look.garment == .armouredTunic {
            // Leather strips (pteruges) at the hem.
            for i in 0..<5 {
                let x = back + (front - back) * CGFloat(i) / 4.5
                path.addRect(CGRect(x: x - 2.5 * s, y: bottom - 6 * s, width: 5 * s, height: 8 * s))
            }
        }
        skirt.path = path
    }

    private func updateCape(_ pose: Pose, velocity: CGFloat) {
        let sway = max(-0.6, min(0.9, -velocity * 0.05 - pose.torso * 0.6)) + sin(CGFloat(CACurrentMediaTime()) * 2.2) * 0.04
        let length = 76 * s
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 6 * s, y: 2 * s))
        path.addLine(to: CGPoint(x: -4 * s, y: 4 * s))
        let endX = -sin(sway + 0.15) * length - 8 * s
        let endY = -cos(sway + 0.15) * length
        path.addQuadCurve(to: CGPoint(x: endX - 10 * s, y: endY), control: CGPoint(x: -18 * s, y: -length * 0.4))
        path.addLine(to: CGPoint(x: endX + 14 * s, y: endY + 4 * s))
        path.addQuadCurve(to: CGPoint(x: 6 * s, y: 2 * s), control: CGPoint(x: 4 * s, y: -length * 0.45))
        path.closeSubpath()
        cape.path = path
    }

    /// Washes every part toward a colour for a moment (a hit, a super).
    func flash(_ color: UIColor, amount: CGFloat) {
        if isPainted {
            for node in paintedSprites {
                // Back limbs keep their shade between flashes.
                if amount <= 0 { node.color = .black; node.colorBlendFactor = node.userData?["dim"] as? CGFloat ?? 0 }
                else { node.color = color; node.colorBlendFactor = amount }
            }
            return
        }
        for (node, base) in tintables { node.fillColor = amount <= 0 ? base : base.mixed(with: color, amount) }
    }

    /// World position (in the rig's parent space) of the weapon tip.
    var weaponTipPosition: CGPoint { weapon.convert(weaponTip, to: parent ?? self) }
}
