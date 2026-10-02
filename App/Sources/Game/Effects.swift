import SpriteKit
import FightCore

/// One-shot effects in world space.
@MainActor
enum Effects {
    static func hitSpark(at point: CGPoint, impact: Impact, color: UIColor, in parent: SKNode, blocked: Bool = false) {
        let burst = SKEmitterNode()
        burst.particleTexture = Textures.spark
        let count: Int = switch impact { case .light: 10; case .medium: 16; case .heavy: 24; case .crushing: 36 }
        burst.numParticlesToEmit = count
        burst.particleBirthRate = 2000
        burst.particleLifetime = 0.22
        burst.particleLifetimeRange = 0.1
        burst.emissionAngleRange = .pi * 2
        burst.particleSpeed = blocked ? 260 : 360 + CGFloat(impact.rawValue) * 90
        burst.particleSpeedRange = 160
        burst.particleScale = 0.7 + CGFloat(impact.rawValue) * 0.18
        burst.particleScaleSpeed = -2.2
        burst.particleAlphaSpeed = -3
        burst.particleRotationRange = .pi
        burst.particleColor = blocked ? UIColor(hex: 0xBFE3FF) : color
        burst.particleColorBlendFactor = 1
        burst.particleBlendMode = .add
        burst.position = point
        burst.zPosition = 200
        // Particles point along their direction of travel.
        burst.particleRotation = 0
        parent.addChild(burst)

        let flash = SKSpriteNode(texture: Textures.softDot)
        let size: CGFloat = blocked ? 70 : 60 + CGFloat(impact.rawValue) * 30
        flash.size = CGSize(width: size, height: size)
        flash.color = blocked ? UIColor(hex: 0x9FD0FF) : .white
        flash.colorBlendFactor = 1
        flash.blendMode = .add
        flash.position = point
        flash.zPosition = 201
        parent.addChild(flash)
        flash.run(.sequence([.group([.scale(to: 1.6, duration: 0.12), .fadeOut(withDuration: 0.14)]), .removeFromParent()]))

        if impact >= .heavy && !blocked {
            let ring = SKShapeNode(circleOfRadius: 20)
            ring.strokeColor = color
            ring.lineWidth = 4
            ring.glowWidth = 2
            ring.position = point
            ring.zPosition = 199
            parent.addChild(ring)
            ring.run(.sequence([.group([.scale(to: 3.4, duration: 0.2), .fadeOut(withDuration: 0.2)]), .removeFromParent()]))
        }
        burst.run(.sequence([.wait(forDuration: 0.5), .removeFromParent()]))
    }

    static func dust(at point: CGPoint, in parent: SKNode, amount: Int = 14, color: UIColor = UIColor(white: 0.85, alpha: 1)) {
        let e = SKEmitterNode()
        e.particleTexture = Textures.softDot
        e.numParticlesToEmit = amount
        e.particleBirthRate = 400
        e.particleLifetime = 0.5
        e.particleLifetimeRange = 0.2
        e.particlePositionRange = CGVector(dx: 30, dy: 2)
        e.emissionAngle = .pi / 2
        e.emissionAngleRange = .pi * 0.8
        e.particleSpeed = 70
        e.particleSpeedRange = 40
        e.yAcceleration = -40
        e.particleScale = 0.4
        e.particleScaleSpeed = 0.6
        e.particleAlpha = 0.45
        e.particleAlphaSpeed = -0.9
        e.particleColor = color
        e.particleColorBlendFactor = 1
        e.position = point
        e.zPosition = 50
        parent.addChild(e)
        e.run(.sequence([.wait(forDuration: 0.9), .removeFromParent()]))
    }

    static func floatingText(_ text: String, at point: CGPoint, color: UIColor, in parent: SKNode, size: CGFloat = 26) {
        let label = SKLabelNode(text: text)
        label.fontName = Theme.displayFontName
        label.fontSize = size
        label.fontColor = color
        label.position = point
        label.zPosition = 260
        let shadow = SKLabelNode(text: text)
        shadow.fontName = Theme.displayFontName
        shadow.fontSize = size
        shadow.fontColor = UIColor(white: 0, alpha: 0.6)
        shadow.position = CGPoint(x: 2, y: -2)
        shadow.zPosition = -1
        label.addChild(shadow)
        parent.addChild(label)
        label.setScale(0.5)
        label.run(.sequence([.group([.scale(to: 1, duration: 0.1), .moveBy(x: 0, y: 40, duration: 0.7)]), .fadeOut(withDuration: 0.25), .removeFromParent()]))
    }
}

/// A projectile drawn to match its kind.
final class ProjectileNode: SKNode {
    let id: Int
    private let kind: ProjectileKind
    private var age = 0

    init(_ p: Projectile, color: UIColor) {
        id = p.id
        kind = p.spec.kind
        super.init()
        zPosition = 120
        xScale = CGFloat(p.facing)
        switch p.spec.kind {
        case .bolt, .arrow:
            let shaft = SKShapeNode(path: { let path = CGMutablePath(); path.move(to: CGPoint(x: -24, y: 0)); path.addLine(to: CGPoint(x: 20, y: 0)); return path }())
            shaft.strokeColor = UIColor(hex: 0x6B4A2A); shaft.lineWidth = p.spec.kind == .bolt ? 3.5 : 2.5
            addChild(shaft)
            let head = SKShapeNode(path: { let path = CGMutablePath(); path.move(to: CGPoint(x: 28, y: 0)); path.addLine(to: CGPoint(x: 18, y: 5)); path.addLine(to: CGPoint(x: 18, y: -5)); path.closeSubpath(); return path }())
            head.fillColor = UIColor(hex: 0xC9CED6); head.strokeColor = .clear
            addChild(head)
            let fletch = SKShapeNode(path: { let path = CGMutablePath(); path.move(to: CGPoint(x: -24, y: 0)); path.addLine(to: CGPoint(x: -30, y: 6)); path.addLine(to: CGPoint(x: -16, y: 0)); path.addLine(to: CGPoint(x: -30, y: -6)); path.closeSubpath(); return path }())
            fletch.fillColor = color; fletch.strokeColor = .clear
            addChild(fletch)
            let streak = SKSpriteNode(texture: Textures.spark)
            streak.size = CGSize(width: 90, height: 10); streak.position = CGPoint(x: -40, y: 0)
            streak.color = color; streak.colorBlendFactor = 1; streak.blendMode = .add; streak.alpha = 0.6
            addChild(streak)
        case .fallingArrow:
            let arrow = SKShapeNode(path: { let path = CGMutablePath(); path.move(to: CGPoint(x: 0, y: 30)); path.addLine(to: CGPoint(x: 0, y: -26)); return path }())
            arrow.strokeColor = UIColor(hex: 0x6B4A2A); arrow.lineWidth = 2.5
            addChild(arrow)
            let tip = SKShapeNode(path: { let path = CGMutablePath(); path.move(to: CGPoint(x: 0, y: -34)); path.addLine(to: CGPoint(x: 5, y: -24)); path.addLine(to: CGPoint(x: -5, y: -24)); path.closeSubpath(); return path }())
            tip.fillColor = UIColor(hex: 0xFFD36E); tip.strokeColor = .clear
            addChild(tip)
            let glow = SKSpriteNode(texture: Textures.spark)
            glow.size = CGSize(width: 110, height: 14); glow.zRotation = .pi / 2; glow.position = CGPoint(x: 0, y: 50)
            glow.color = color; glow.colorBlendFactor = 1; glow.blendMode = .add
            addChild(glow)
        case .orb:
            let core = SKSpriteNode(texture: Textures.softDot)
            core.size = CGSize(width: 70, height: 70); core.color = color; core.colorBlendFactor = 1; core.blendMode = .add
            addChild(core)
            let eye = SKShapeNode(ellipseOf: CGSize(width: 26, height: 14))
            eye.strokeColor = UIColor(hex: 0x24519E); eye.lineWidth = 2.5; eye.fillColor = UIColor(hex: 0xFFF3C4)
            addChild(eye)
            let pupil = SKShapeNode(circleOfRadius: 4); pupil.fillColor = UIColor(hex: 0x24519E); pupil.strokeColor = .clear
            addChild(pupil)
            core.run(.repeatForever(.sequence([.scale(to: 1.15, duration: 0.25), .scale(to: 0.95, duration: 0.25)])))
        case .dust:
            let cloud = SKEmitterNode()
            cloud.particleTexture = Textures.softDot
            cloud.particleBirthRate = 70
            cloud.particleLifetime = 1.0
            cloud.particlePositionRange = CGVector(dx: 150, dy: 60)
            cloud.particleSpeed = 20; cloud.emissionAngleRange = .pi * 2
            cloud.particleScale = 1.2; cloud.particleScaleSpeed = 0.6
            cloud.particleAlpha = 0.4; cloud.particleAlphaSpeed = -0.35
            cloud.particleColor = UIColor(hex: 0xD9B98A); cloud.particleColorBlendFactor = 1
            cloud.position = CGPoint(x: 0, y: 60)
            addChild(cloud)
            run(.sequence([.wait(forDuration: Double(p.spec.lifetime) / 60 - 0.4), .run { cloud.particleBirthRate = 0 }]))
        case .cavalry:
            addChild(Self.spectralRider(color: color))
        case .seal:
            let ring = SKShapeNode(ellipseOf: CGSize(width: 120, height: 28))
            ring.strokeColor = color; ring.lineWidth = 3; ring.glowWidth = 3; ring.fillColor = color.withAlphaComponent(0.15)
            addChild(ring)
            let glyph = SKLabelNode(text: "計")
            glyph.fontName = "PingFangSC-Semibold"; glyph.fontSize = 22; glyph.fontColor = color
            glyph.verticalAlignmentMode = .center
            glyph.yScale = 0.4
            addChild(glyph)
            ring.setScale(0.3)
            ring.run(.scale(to: 1, duration: Double(p.spec.armingDelay) / 60))
            run(.sequence([.wait(forDuration: Double(p.spec.armingDelay) / 60), .run { [weak self] in self?.burst(color) }]))
        case .sunbeam:
            let beam = SKSpriteNode(texture: Textures.spark)
            beam.size = CGSize(width: 260, height: 110); beam.color = color; beam.colorBlendFactor = 1; beam.blendMode = .add
            addChild(beam)
            let core = SKSpriteNode(texture: Textures.spark)
            core.size = CGSize(width: 240, height: 40); core.color = .white; core.colorBlendFactor = 1; core.blendMode = .add
            addChild(core)
            let trail = SKEmitterNode()
            trail.particleTexture = Textures.softDot
            trail.particleBirthRate = 120; trail.particleLifetime = 0.5
            trail.particlePositionRange = CGVector(dx: 40, dy: 70)
            trail.particleScale = 0.5; trail.particleScaleSpeed = -0.8; trail.particleAlphaSpeed = -1.6
            trail.particleColor = color; trail.particleColorBlendFactor = 1; trail.particleBlendMode = .add
            trail.targetNode = self.parent
            addChild(trail)
        case .wave:
            let w = SKShapeNode(ellipseOf: CGSize(width: 40, height: 90))
            w.strokeColor = color; w.lineWidth = 4
            addChild(w)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    private func burst(_ color: UIColor) {
        let pillar = SKSpriteNode(texture: Textures.spark)
        pillar.size = CGSize(width: 220, height: 60)
        pillar.zRotation = .pi / 2
        pillar.position = CGPoint(x: 0, y: 90)
        pillar.color = color; pillar.colorBlendFactor = 1; pillar.blendMode = .add
        addChild(pillar)
        pillar.run(.sequence([.group([.scaleX(to: 1.4, duration: 0.15), .fadeOut(withDuration: 0.35)]), .removeFromParent()]))
    }

    /// A horse and rider made of light, galloping.
    static func spectralRider(color: UIColor) -> SKNode {
        let node = SKNode()
        let horse = CGMutablePath()
        horse.addEllipse(in: CGRect(x: -50, y: 50, width: 100, height: 46))
        horse.move(to: CGPoint(x: 38, y: 82)); horse.addLine(to: CGPoint(x: 70, y: 120)); horse.addLine(to: CGPoint(x: 86, y: 112)); horse.addLine(to: CGPoint(x: 60, y: 70)); horse.closeSubpath()
        let body = SKShapeNode(path: horse)
        body.fillColor = color.withAlphaComponent(0.55); body.strokeColor = color; body.lineWidth = 2; body.glowWidth = 4
        node.addChild(body)
        var legs: [SKShapeNode] = []
        for (i, x) in [-36.0, -20.0, 22.0, 38.0].enumerated() {
            let leg = SKShapeNode(rectOf: CGSize(width: 7, height: 52), cornerRadius: 3)
            leg.fillColor = color.withAlphaComponent(0.55); leg.strokeColor = color; leg.lineWidth = 1.5
            leg.position = CGPoint(x: x, y: 32)
            node.addChild(leg)
            legs.append(leg)
            let swing = SKAction.sequence([.rotate(toAngle: i % 2 == 0 ? 0.6 : -0.6, duration: 0.12), .rotate(toAngle: i % 2 == 0 ? -0.6 : 0.6, duration: 0.12)])
            leg.run(.repeatForever(swing))
        }
        let rider = CGMutablePath()
        rider.addRoundedRect(in: CGRect(x: -12, y: 92, width: 22, height: 44), cornerWidth: 8, cornerHeight: 8)
        rider.addEllipse(in: CGRect(x: -10, y: 136, width: 18, height: 18))
        let r = SKShapeNode(path: rider)
        r.fillColor = color.withAlphaComponent(0.6); r.strokeColor = color; r.lineWidth = 2
        node.addChild(r)
        let spear = SKShapeNode(path: { let p = CGMutablePath(); p.move(to: CGPoint(x: -10, y: 110)); p.addLine(to: CGPoint(x: 92, y: 128)); return p }())
        spear.strokeColor = color; spear.lineWidth = 3
        node.addChild(spear)
        node.run(.repeatForever(.sequence([.moveBy(x: 0, y: 6, duration: 0.12), .moveBy(x: 0, y: -6, duration: 0.12)])))
        return node
    }

    func update(_ p: Projectile) {
        age += 1
        position = CGPoint(x: p.position.x, y: p.position.y)
        if kind == .orb { zRotation = sin(CGFloat(age) * 0.2) * 0.1 }
        if kind == .seal {
            alpha = p.armed ? 1 : 0.6 + 0.4 * CGFloat(age % 10) / 10
        }
    }
}
