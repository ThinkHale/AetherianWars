import SpriteKit
import FightCore

/// A fighting stage in parallax layers. Each layer is drawn in code in the
/// stage's empire style; a painted layer (`Stages/<stage>-far.png`, `-mid`,
/// `-floor`) replaces the drawn one when it is bundled.
final class StageNode: SKNode {
    let stage: StageID
    private let sky = SKNode()
    private let far = SKNode()
    private let mid = SKNode()
    private let ground = SKNode()
    private let front = SKNode()
    private var flames: [SKEmitterNode] = []

    /// Width of the playable floor plus margins beyond the walls.
    static let span: CGFloat = 1700

    init(stage: StageID) {
        self.stage = stage
        super.init()
        for (layer, z) in [(sky, -400.0), (far, -300.0), (mid, -200.0), (ground, -100.0), (front, 400.0)] {
            layer.zPosition = z
            addChild(layer)
        }
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// Moves the background layers for a camera centred on `x`.
    func parallax(cameraX: CGFloat) {
        sky.position.x = cameraX * 0.92
        far.position.x = cameraX * 0.7
        mid.position.x = cameraX * 0.35
        front.position.x = -cameraX * 0.25
    }

    // MARK: Palette

    private struct Palette {
        var skyTop: UIColor, skyBottom: UIColor, sun: UIColor
        var far: UIColor, mid: UIColor, midLight: UIColor, ground: UIColor, groundLine: UIColor, accent: UIColor
    }

    private var palette: Palette {
        switch stage {
        case .forum:
            Palette(skyTop: UIColor(hex: 0x2B2346), skyBottom: UIColor(hex: 0xE58B4B), sun: UIColor(hex: 0xFFC77A),
                    far: UIColor(hex: 0x5A3F52), mid: UIColor(hex: 0x8C6E62), midLight: UIColor(hex: 0xD9B48F),
                    ground: UIColor(hex: 0x6E5A4E), groundLine: UIColor(hex: 0x4E3F37), accent: UIColor(hex: 0xA3201E))
        case .nile:
            Palette(skyTop: UIColor(hex: 0x1F5F7A), skyBottom: UIColor(hex: 0xF2C27A), sun: UIColor(hex: 0xFFE2A0),
                    far: UIColor(hex: 0xC99A5E), mid: UIColor(hex: 0xA97A45), midLight: UIColor(hex: 0xE8C88F),
                    ground: UIColor(hex: 0xC59A62), groundLine: UIColor(hex: 0xA27A48), accent: UIColor(hex: 0x24519E))
        case .persepolis:
            Palette(skyTop: UIColor(hex: 0x23314F), skyBottom: UIColor(hex: 0xE0A867), sun: UIColor(hex: 0xFFD08A),
                    far: UIColor(hex: 0x5D5770), mid: UIColor(hex: 0x9C8169), midLight: UIColor(hex: 0xD8BE98),
                    ground: UIColor(hex: 0x8E7963), groundLine: UIColor(hex: 0x6C5B4A), accent: UIColor(hex: 0x23807A))
        case .greatWall:
            Palette(skyTop: UIColor(hex: 0x1A1E3A), skyBottom: UIColor(hex: 0xC2533E), sun: UIColor(hex: 0xFF9E6B),
                    far: UIColor(hex: 0x3A2E4A), mid: UIColor(hex: 0x5E4A48), midLight: UIColor(hex: 0x9C7A62),
                    ground: UIColor(hex: 0x5A4A3E), groundLine: UIColor(hex: 0x3F342C), accent: UIColor(hex: 0xC0261C))
        case .crossing:
            Palette(skyTop: UIColor(hex: 0x27324A), skyBottom: UIColor(hex: 0x8EA0B8), sun: UIColor(hex: 0xDDEBFA),
                    far: UIColor(hex: 0x5E6D86), mid: UIColor(hex: 0x4A5870), midLight: UIColor(hex: 0xB8C4D4),
                    ground: UIColor(hex: 0x4B5566), groundLine: UIColor(hex: 0x3A4250), accent: UIColor(hex: 0x9FD8FF))
        }
    }

    // MARK: Building

    private func fill(_ path: CGPath, _ color: UIColor, stroke: UIColor? = nil, line: CGFloat = 0) -> SKShapeNode {
        let node = SKShapeNode(path: path)
        node.fillColor = color
        node.strokeColor = stroke ?? .clear
        node.lineWidth = line
        node.isAntialiased = true
        return node
    }

    private func gradientTexture(top: UIColor, bottom: UIColor, height: CGFloat = 256) -> SKTexture {
        let size = CGSize(width: 4, height: height)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [top.cgColor, bottom.cgColor] as CFArray, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: height), options: [])
        }
        return SKTexture(image: image)
    }

    private func build() {
        let p = palette
        let span = Self.span

        // Sky.
        let skyNode = SKSpriteNode(texture: gradientTexture(top: p.skyTop, bottom: p.skyBottom))
        skyNode.size = CGSize(width: span * 2.2, height: 900)
        skyNode.position = CGPoint(x: 0, y: 330)
        sky.addChild(skyNode)
        let sun = SKSpriteNode(texture: Textures.softDot)
        sun.color = p.sun; sun.colorBlendFactor = 1; sun.blendMode = .add
        sun.size = CGSize(width: 320, height: 320)
        sun.position = CGPoint(x: stage == .greatWall ? 260 : -180, y: stage == .crossing ? 420 : 150)
        // In the Crossing the beacon is the light; the sky only glows faintly.
        if stage == .crossing { sun.alpha = 0.35; sun.position = CGPoint(x: 0, y: 520) }
        sky.addChild(sun)
        let disc = SKShapeNode(circleOfRadius: stage == .crossing ? 0 : 34)
        disc.fillColor = p.sun; disc.strokeColor = .clear; disc.position = sun.position
        sky.addChild(disc)

        if let painted = ArtLibrary.stageLayer(stage, "far") {
            let node = SKSpriteNode(texture: SKTexture(image: painted))
            node.size = CGSize(width: span * 1.4, height: span * 1.4 * painted.size.height / painted.size.width)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.12)
            far.addChild(node)
        } else {
            buildFar(p)
        }
        if let painted = ArtLibrary.stageLayer(stage, "mid") {
            let node = SKSpriteNode(texture: SKTexture(image: painted))
            node.size = CGSize(width: span * 1.2, height: span * 1.2 * painted.size.height / painted.size.width)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.08)
            mid.addChild(node)
        } else {
            buildMid(p)
        }
        if let painted = ArtLibrary.stageLayer(stage, "floor") {
            let node = SKSpriteNode(texture: SKTexture(image: painted))
            node.size = CGSize(width: span * 1.1, height: 220)
            node.anchorPoint = CGPoint(x: 0.5, y: 1)
            node.position = CGPoint(x: 0, y: 4)
            ground.addChild(node)
        } else {
            buildGround(p)
        }
        buildFront(p)
        buildAtmosphere(p)
    }

    private func ridge(from x0: CGFloat, to x1: CGFloat, base: CGFloat, height: CGFloat, bumps: Int, seed: Int, jagged: Bool = false) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: x0, y: base - 300))
        path.addLine(to: CGPoint(x: x0, y: base))
        let step = (x1 - x0) / CGFloat(bumps)
        for i in 0..<bumps {
            let n = sin(CGFloat(i * 7 + seed) * 1.7) * 0.5 + 0.5
            let peak = base + height * (0.45 + 0.55 * n)
            let x = x0 + step * (CGFloat(i) + 0.5)
            if jagged {
                path.addLine(to: CGPoint(x: x, y: peak))
                path.addLine(to: CGPoint(x: x0 + step * CGFloat(i + 1), y: base + height * 0.3 * n))
            } else {
                path.addQuadCurve(to: CGPoint(x: x0 + step * CGFloat(i + 1), y: base + height * 0.25 * n), control: CGPoint(x: x, y: peak * 1.05))
            }
        }
        path.addLine(to: CGPoint(x: x1, y: base - 300))
        path.closeSubpath()
        return path
    }

    private func column(x: CGFloat, base: CGFloat, height: CGFloat, width: CGFloat, color: UIColor, light: UIColor, capital: UIColor? = nil) -> SKNode {
        let node = SKNode()
        node.addChild(fill(CGPath(rect: CGRect(x: x - width / 2, y: base, width: width, height: height), transform: nil), color))
        // Fluting.
        let flutes = CGMutablePath()
        for i in 1..<4 { let fx = x - width / 2 + width * CGFloat(i) / 4; flutes.move(to: CGPoint(x: fx, y: base + 8)); flutes.addLine(to: CGPoint(x: fx, y: base + height - 8)) }
        let f = SKShapeNode(path: flutes); f.strokeColor = light.withAlphaComponent(0.35); f.lineWidth = 2
        node.addChild(f)
        node.addChild(fill(CGPath(rect: CGRect(x: x - width * 0.75, y: base + height - 4, width: width * 1.5, height: 14), transform: nil), capital ?? light))
        node.addChild(fill(CGPath(rect: CGRect(x: x - width * 0.7, y: base - 6, width: width * 1.4, height: 10), transform: nil), light))
        return node
    }

    private func buildFar(_ p: Palette) {
        let span = Self.span
        switch stage {
        case .forum:
            far.addChild(fill(ridge(from: -span, to: span, base: 40, height: 140, bumps: 7, seed: 1), p.far))
            // A distant temple on the hill and an aqueduct.
            let temple = SKNode()
            for i in 0..<6 { temple.addChild(column(x: -330 + CGFloat(i) * 26, base: 150, height: 70, width: 11, color: p.far.lighter(0.15), light: p.far.lighter(0.3))) }
            let pediment = CGMutablePath()
            pediment.move(to: CGPoint(x: -352, y: 232)); pediment.addLine(to: CGPoint(x: -191, y: 232)); pediment.addLine(to: CGPoint(x: -271, y: 270)); pediment.closeSubpath()
            temple.addChild(fill(pediment, p.far.lighter(0.25)))
            far.addChild(temple)
            // An aqueduct: a channel on piers, with round arches between them.
            let aqueduct = CGMutablePath()
            aqueduct.addRect(CGRect(x: 80, y: 196, width: 700, height: 26))
            for i in 0...12 {
                let x = 80 + CGFloat(i) * 58
                aqueduct.addRect(CGRect(x: x, y: 60, width: 18, height: 140))
                if i < 12 {
                    aqueduct.move(to: CGPoint(x: x + 18, y: 200))
                    aqueduct.addArc(center: CGPoint(x: x + 38, y: 176), radius: 20, startAngle: .pi, endAngle: 0, clockwise: true)
                    aqueduct.addLine(to: CGPoint(x: x + 58, y: 200))
                    aqueduct.closeSubpath()
                }
            }
            far.addChild(fill(aqueduct, p.far.lighter(0.1)))
        case .nile:
            for (x, h) in [(-420.0, 260.0), (-180.0, 340.0), (60.0, 220.0)] {
                let pyramid = CGMutablePath()
                pyramid.move(to: CGPoint(x: x - h * 0.9, y: 60)); pyramid.addLine(to: CGPoint(x: x, y: 60 + h)); pyramid.addLine(to: CGPoint(x: x + h * 0.9, y: 60)); pyramid.closeSubpath()
                far.addChild(fill(pyramid, p.far))
                let shade = CGMutablePath()
                shade.move(to: CGPoint(x: x, y: 60 + h)); shade.addLine(to: CGPoint(x: x + h * 0.9, y: 60)); shade.addLine(to: CGPoint(x: x + h * 0.15, y: 60)); shade.closeSubpath()
                far.addChild(fill(shade, p.far.darker(0.18)))
            }
            far.addChild(fill(CGPath(rect: CGRect(x: -span, y: -200, width: span * 2, height: 262), transform: nil), p.far.darker(0.1)))
        case .persepolis:
            far.addChild(fill(ridge(from: -span, to: span, base: 60, height: 300, bumps: 9, seed: 3, jagged: true), p.far))
            far.addChild(fill(ridge(from: -span, to: span, base: 30, height: 170, bumps: 6, seed: 8), p.far.lighter(0.12)))
        case .greatWall:
            far.addChild(fill(ridge(from: -span, to: span, base: 40, height: 320, bumps: 8, seed: 5), p.far))
            // The wall along the ridges.
            let wall = CGMutablePath()
            wall.move(to: CGPoint(x: -span, y: 140))
            for i in 0...16 {
                let x = -span + CGFloat(i) * span / 8
                wall.addLine(to: CGPoint(x: x, y: 150 + sin(CGFloat(i) * 0.9) * 70))
            }
            let w = SKShapeNode(path: wall); w.strokeColor = p.far.lighter(0.25); w.lineWidth = 7
            far.addChild(w)
            for i in stride(from: 1, to: 16, by: 3) {
                let x = -span + CGFloat(i) * span / 8
                let y = 150 + sin(CGFloat(i) * 0.9) * 70
                far.addChild(fill(CGPath(rect: CGRect(x: x - 9, y: y, width: 18, height: 24), transform: nil), p.far.lighter(0.25)))
            }
        case .crossing:
            // The white tower of Aeterna with its beacon.
            let tower = CGMutablePath()
            tower.addRect(CGRect(x: -60, y: 120, width: 120, height: 420))
            tower.addRect(CGRect(x: -74, y: 520, width: 148, height: 26))
            far.addChild(fill(tower, p.far.lighter(0.2)))
            for i in 0..<6 {
                far.addChild(fill(CGPath(rect: CGRect(x: -40 + CGFloat(i % 3) * 30, y: 200 + CGFloat(i / 3) * 140, width: 12, height: 40), transform: nil), p.far.darker(0.2)))
            }
            let beacon = SKSpriteNode(texture: Textures.softDot)
            beacon.size = CGSize(width: 260, height: 260); beacon.color = p.accent; beacon.colorBlendFactor = 1; beacon.blendMode = .add
            beacon.position = CGPoint(x: 0, y: 580)
            beacon.run(.repeatForever(.sequence([.fadeAlpha(to: 0.6, duration: 1.6), .fadeAlpha(to: 1, duration: 1.6)])))
            far.addChild(beacon)
            far.addChild(fill(ridge(from: -span, to: span, base: 60, height: 120, bumps: 10, seed: 2, jagged: true), p.far))
            for x in [-520.0, -380.0, 360.0, 520.0] {
                far.addChild(fill(CGPath(rect: CGRect(x: x, y: 100, width: 70, height: 220 + CGFloat(Int(x) % 7) * 10), transform: nil), p.far.lighter(0.1)))
            }
        }
        // Haze between the far layer and the fight.
        let haze = SKSpriteNode(texture: gradientTexture(top: p.skyBottom.withAlphaComponent(0), bottom: p.skyBottom.withAlphaComponent(0.6)))
        haze.size = CGSize(width: span * 2.4, height: 300)
        haze.position = CGPoint(x: 0, y: 110)
        far.addChild(haze)
    }

    private func buildMid(_ p: Palette) {
        let span = Self.span
        switch stage {
        case .forum:
            // A colonnade with an architrave and statues between.
            let colonnade = SKNode()
            for i in 0..<14 {
                colonnade.addChild(column(x: -span * 0.75 + CGFloat(i) * 105, base: 30, height: 230, width: 30, color: p.mid, light: p.midLight))
            }
            colonnade.addChild(fill(CGPath(rect: CGRect(x: -span * 0.8, y: 270, width: span * 1.6, height: 36), transform: nil), p.mid.lighter(0.1)))
            let frieze = CGMutablePath()
            for i in 0..<60 { frieze.addRect(CGRect(x: -span * 0.8 + CGFloat(i) * 46, y: 282, width: 20, height: 12)) }
            colonnade.addChild(fill(frieze, p.mid.darker(0.15)))
            mid.addChild(colonnade)
            for x in [-430.0, 430.0] {
                let banner = CGMutablePath()
                banner.addRect(CGRect(x: x - 26, y: 120, width: 52, height: 140))
                banner.move(to: CGPoint(x: x - 26, y: 120)); banner.addLine(to: CGPoint(x: x, y: 96)); banner.addLine(to: CGPoint(x: x + 26, y: 120))
                mid.addChild(fill(banner, p.accent, stroke: UIColor(hex: 0xD9A635), line: 2))
                let eagle = SKShapeNode(circleOfRadius: 12); eagle.fillColor = UIColor(hex: 0xD9A635); eagle.strokeColor = .clear
                eagle.position = CGPoint(x: x, y: 200)
                mid.addChild(eagle)
            }
            addBraziers(at: [-250, 250], base: 30, color: p.midLight)
        case .nile:
            // The river, then obelisks and palms on the near bank.
            let river = SKSpriteNode(texture: gradientTexture(top: UIColor(hex: 0x2A7AA0), bottom: UIColor(hex: 0x1C4F6C)))
            river.size = CGSize(width: span * 2, height: 70)
            river.position = CGPoint(x: 0, y: 66)
            mid.addChild(river)
            let shimmer = SKEmitterNode()
            shimmer.particleTexture = Textures.spark
            shimmer.particleBirthRate = 10; shimmer.particleLifetime = 1.4
            shimmer.particlePositionRange = CGVector(dx: span * 1.6, dy: 50)
            shimmer.particleAlpha = 0.5; shimmer.particleAlphaSpeed = -0.35; shimmer.particleScale = 0.8
            shimmer.particleColor = UIColor(hex: 0xFFE2A0); shimmer.particleColorBlendFactor = 1; shimmer.particleBlendMode = .add
            shimmer.position = CGPoint(x: 0, y: 66)
            mid.addChild(shimmer)
            for x in [-520.0, 520.0] {
                let obelisk = CGMutablePath()
                obelisk.move(to: CGPoint(x: x - 20, y: 30)); obelisk.addLine(to: CGPoint(x: x - 13, y: 300)); obelisk.addLine(to: CGPoint(x: x, y: 322))
                obelisk.addLine(to: CGPoint(x: x + 13, y: 300)); obelisk.addLine(to: CGPoint(x: x + 20, y: 30)); obelisk.closeSubpath()
                mid.addChild(fill(obelisk, p.mid))
                let glyphs = CGMutablePath()
                for i in 0..<8 { glyphs.addRect(CGRect(x: x - 4, y: 60 + CGFloat(i) * 28, width: 8, height: 12)) }
                mid.addChild(fill(glyphs, p.mid.darker(0.25)))
                mid.addChild(fill(CGPath(rect: CGRect(x: x - 9, y: 300, width: 18, height: 8), transform: nil), UIColor(hex: 0xD9A635)))
            }
            for (x, h) in [(-300.0, 230.0), (-220.0, 190.0), (260.0, 240.0), (340.0, 180.0)] { mid.addChild(palm(x: x, height: h, color: p.mid.darker(0.35))) }
        case .persepolis:
            // The Gate of All Nations: towering columns with bull capitals.
            for x in stride(from: -span * 0.7, through: span * 0.7, by: 170) {
                let col = column(x: x, base: 30, height: 300, width: 26, color: p.mid, light: p.midLight, capital: p.mid.lighter(0.2))
                mid.addChild(col)
                let bull = CGMutablePath()
                bull.addRoundedRect(in: CGRect(x: x - 40, y: 330, width: 80, height: 26), cornerWidth: 10, cornerHeight: 10)
                bull.addEllipse(in: CGRect(x: x - 50, y: 336, width: 18, height: 18))
                bull.addEllipse(in: CGRect(x: x + 32, y: 336, width: 18, height: 18))
                mid.addChild(fill(bull, p.mid.lighter(0.1)))
            }
            let relief = CGMutablePath()
            relief.addRect(CGRect(x: -span, y: 30, width: span * 2, height: 46))
            mid.addChild(fill(relief, p.mid.darker(0.1)))
            let figures = CGMutablePath()
            for i in 0..<40 { let x = -span + CGFloat(i) * 85; figures.addRoundedRect(in: CGRect(x: x, y: 38, width: 12, height: 32), cornerWidth: 5, cornerHeight: 5) }
            mid.addChild(fill(figures, p.mid.darker(0.3)))
            addBraziers(at: [-340, 340], base: 30, color: p.midLight)
        case .greatWall:
            // A low run of crenellated wall, a watchtower, and lanterns on a rope.
            let wall = CGMutablePath()
            wall.addRect(CGRect(x: -span, y: 30, width: span * 2, height: 56))
            for i in 0..<70 { wall.addRect(CGRect(x: -span + CGFloat(i) * 50, y: 86, width: 28, height: 18)) }
            mid.addChild(fill(wall, p.mid))
            let courses = CGMutablePath()
            for row in 0..<3 { let y = 44 + CGFloat(row) * 14; courses.move(to: CGPoint(x: -span, y: y)); courses.addLine(to: CGPoint(x: span, y: y)) }
            let c = SKShapeNode(path: courses); c.strokeColor = p.mid.darker(0.25); c.lineWidth = 1.5
            mid.addChild(c)
            let tower = CGMutablePath()
            tower.addRect(CGRect(x: 320, y: 30, width: 150, height: 250))
            tower.move(to: CGPoint(x: 296, y: 280)); tower.addQuadCurve(to: CGPoint(x: 395, y: 336), control: CGPoint(x: 360, y: 290))
            tower.addQuadCurve(to: CGPoint(x: 494, y: 280), control: CGPoint(x: 430, y: 290)); tower.closeSubpath()
            mid.addChild(fill(tower, p.mid.darker(0.1)))
            mid.addChild(fill(CGPath(rect: CGRect(x: 375, y: 170, width: 40, height: 56), transform: nil), UIColor(hex: 0xFFB060).withAlphaComponent(0.8)))
            let rope = CGMutablePath()
            rope.move(to: CGPoint(x: -660, y: 300)); rope.addQuadCurve(to: CGPoint(x: 320, y: 270), control: CGPoint(x: -170, y: 220))
            let r = SKShapeNode(path: rope); r.strokeColor = p.mid.darker(0.4); r.lineWidth = 2
            mid.addChild(r)
            mid.addChild(fill(CGPath(rect: CGRect(x: -666, y: 30, width: 12, height: 276), transform: nil), p.mid.darker(0.2)))
            for x in [-480.0, -240.0, 40.0] {
                // Where the rope sags at this x.
                let t = (x + 660) / 980
                let ropeY = (1 - t) * (1 - t) * 300 + 2 * (1 - t) * t * 220 + t * t * 270
                let hanger = SKNode()
                hanger.position = CGPoint(x: x, y: ropeY)
                let string = SKShapeNode(path: { let p = CGMutablePath(); p.move(to: .zero); p.addLine(to: CGPoint(x: 0, y: -26)); return p }())
                string.strokeColor = p.mid.darker(0.4); string.lineWidth = 1.5
                hanger.addChild(string)
                let lantern = SKShapeNode(ellipseOf: CGSize(width: 22, height: 30))
                lantern.fillColor = p.accent; lantern.strokeColor = UIColor(hex: 0xD9A635); lantern.lineWidth = 2
                lantern.position = CGPoint(x: 0, y: -40)
                hanger.addChild(lantern)
                let glow = SKSpriteNode(texture: Textures.softDot)
                glow.size = CGSize(width: 90, height: 90); glow.color = UIColor(hex: 0xFF8A4A); glow.colorBlendFactor = 1; glow.blendMode = .add; glow.alpha = 0.6
                glow.position = lantern.position
                hanger.addChild(glow)
                hanger.run(.repeatForever(.sequence([.rotate(toAngle: 0.07, duration: 1.4), .rotate(toAngle: -0.07, duration: 1.4)])))
                mid.addChild(hanger)
            }
        case .crossing:
            // Broken stones adrift in the mist.
            for (x, y, w, h) in [(-480.0, 80.0, 90.0, 140.0), (-260.0, 200.0, 50.0, 60.0), (300.0, 160.0, 70.0, 110.0), (500.0, 60.0, 110.0, 180.0)] {
                let stone = fill(CGPath(roundedRect: CGRect(x: -w / 2, y: -h / 2, width: w, height: h), cornerWidth: 8, cornerHeight: 8, transform: nil), p.mid)
                stone.position = CGPoint(x: x, y: y + h / 2)
                stone.run(.repeatForever(.sequence([.moveBy(x: 0, y: 10, duration: 3 + x.truncatingRemainder(dividingBy: 3)), .moveBy(x: 0, y: -10, duration: 3)])))
                mid.addChild(stone)
            }
        }
    }

    private func palm(x: CGFloat, height: CGFloat, color: UIColor) -> SKNode {
        let node = SKNode()
        let trunk = CGMutablePath()
        trunk.move(to: CGPoint(x: x - 7, y: 30)); trunk.addQuadCurve(to: CGPoint(x: x + 10, y: 30 + height), control: CGPoint(x: x - 20, y: 30 + height * 0.5))
        trunk.addLine(to: CGPoint(x: x + 16, y: 30 + height)); trunk.addQuadCurve(to: CGPoint(x: x + 7, y: 30), control: CGPoint(x: x - 8, y: 30 + height * 0.5))
        node.addChild(fill(trunk, color))
        for i in 0..<7 {
            let a = CGFloat(i) / 6 * .pi
            let leaf = CGMutablePath()
            let top = CGPoint(x: x + 13, y: 30 + height)
            let end = CGPoint(x: top.x + cos(a) * 80, y: top.y + sin(a) * 30 - 20)
            leaf.move(to: top); leaf.addQuadCurve(to: end, control: CGPoint(x: (top.x + end.x) / 2, y: top.y + 30))
            leaf.addQuadCurve(to: top, control: CGPoint(x: (top.x + end.x) / 2, y: top.y + 6))
            node.addChild(fill(leaf, color))
        }
        node.run(.repeatForever(.sequence([.rotate(toAngle: 0.012, duration: 2), .rotate(toAngle: -0.012, duration: 2)])))
        return node
    }

    private func addBraziers(at xs: [CGFloat], base: CGFloat, color: UIColor) {
        for x in xs {
            let stand = CGMutablePath()
            stand.move(to: CGPoint(x: x - 18, y: base + 70)); stand.addLine(to: CGPoint(x: x + 18, y: base + 70)); stand.addLine(to: CGPoint(x: x + 10, y: base + 56))
            stand.addLine(to: CGPoint(x: x + 4, y: base)); stand.addLine(to: CGPoint(x: x - 4, y: base)); stand.addLine(to: CGPoint(x: x - 10, y: base + 56)); stand.closeSubpath()
            mid.addChild(fill(stand, UIColor(hex: 0x6B4A2A), stroke: UIColor(hex: 0x3A2414), line: 2))
            let flame = SKEmitterNode()
            flame.particleTexture = Textures.softDot
            flame.particleBirthRate = 50; flame.particleLifetime = 0.7; flame.particleLifetimeRange = 0.3
            flame.particlePositionRange = CGVector(dx: 18, dy: 4)
            flame.emissionAngle = .pi / 2; flame.particleSpeed = 60; flame.particleSpeedRange = 25
            flame.particleScale = 0.55; flame.particleScaleSpeed = -0.6
            flame.particleAlpha = 0.9; flame.particleAlphaSpeed = -1.2
            flame.particleColorSequence = SKKeyframeSequence(keyframeValues: [UIColor(hex: 0xFFE6A0), UIColor(hex: 0xFF8A2A), UIColor(hex: 0x8A2A10)], times: [0, 0.4, 1])
            flame.particleBlendMode = .add
            flame.position = CGPoint(x: x, y: base + 74)
            mid.addChild(flame)
            flames.append(flame)
            let glow = SKSpriteNode(texture: Textures.softDot)
            glow.size = CGSize(width: 180, height: 180); glow.color = UIColor(hex: 0xFF9A40); glow.colorBlendFactor = 1; glow.blendMode = .add; glow.alpha = 0.45
            glow.position = CGPoint(x: x, y: base + 90)
            glow.run(.repeatForever(.sequence([.fadeAlpha(to: 0.3, duration: 0.25), .fadeAlpha(to: 0.5, duration: 0.3)])))
            mid.addChild(glow)
        }
    }

    private func buildGround(_ p: Palette) {
        let span = Self.span
        let floor = SKSpriteNode(texture: gradientTexture(top: p.ground, bottom: p.ground.darker(0.45), height: 128))
        floor.size = CGSize(width: span * 2, height: 260)
        floor.anchorPoint = CGPoint(x: 0.5, y: 1)
        floor.position = CGPoint(x: 0, y: 4)
        ground.addChild(floor)
        // Paving or furrows receding toward the viewer.
        let lines = CGMutablePath()
        let stone = stage == .forum || stage == .persepolis || stage == .crossing || stage == .greatWall
        for row in 0..<6 {
            let y = 4 - pow(CGFloat(row), 1.6) * 9
            lines.move(to: CGPoint(x: -span, y: y)); lines.addLine(to: CGPoint(x: span, y: y))
            if stone {
                let width = 80 + CGFloat(row) * 24
                var x = -span + CGFloat(row % 2) * width / 2
                while x < span {
                    let nextY = 4 - pow(CGFloat(row + 1), 1.6) * 9
                    lines.move(to: CGPoint(x: x, y: y)); lines.addLine(to: CGPoint(x: x * 1.04, y: nextY))
                    x += width
                }
            }
        }
        let l = SKShapeNode(path: lines)
        l.strokeColor = p.groundLine.withAlphaComponent(0.7); l.lineWidth = 1.5
        ground.addChild(l)
        let edge = SKShapeNode(path: { let path = CGMutablePath(); path.move(to: CGPoint(x: -span, y: 4)); path.addLine(to: CGPoint(x: span, y: 4)); return path }())
        edge.strokeColor = p.ground.lighter(0.25); edge.lineWidth = 3
        ground.addChild(edge)
    }

    private func buildFront(_ p: Palette) {
        // Foreground props at the far edges, dark against the light.
        let dark = p.ground.darker(0.65)
        switch stage {
        case .nile:
            for x in [-760.0, 780.0] {
                let reeds = CGMutablePath()
                for i in 0..<9 { let rx = x + CGFloat(i) * 9 - 40; reeds.move(to: CGPoint(x: rx, y: -80)); reeds.addQuadCurve(to: CGPoint(x: rx + 14, y: 70 + CGFloat(i % 3) * 20), control: CGPoint(x: rx - 6, y: 10)) }
                let r = SKShapeNode(path: reeds); r.strokeColor = dark; r.lineWidth = 4
                front.addChild(r)
            }
        case .crossing:
            break
        default:
            break
        }
    }

    private func buildAtmosphere(_ p: Palette) {
        let mist = SKEmitterNode.mist(color: stage == .crossing ? UIColor(hex: 0xC8D6E8) : p.skyBottom.lighter(0.3), rate: stage == .crossing ? 18 : 6, spread: Self.span)
        mist.position = CGPoint(x: 0, y: 40)
        mist.particlePositionRange = CGVector(dx: Self.span * 1.8, dy: 60)
        mist.emissionAngle = 0
        mist.particleSpeed = 18
        mist.particleScale = stage == .crossing ? 3 : 2
        mist.particleAlpha = stage == .crossing ? 0.16 : 0.12
        mist.zPosition = 300
        addChild(mist)
        mist.advanceSimulationTime(5)

        // Motes drifting in the light.
        let motes = SKEmitterNode()
        motes.particleTexture = Textures.softDot
        motes.particleBirthRate = 4
        motes.particleLifetime = 8
        motes.particlePositionRange = CGVector(dx: Self.span * 1.4, dy: 300)
        motes.particleSpeed = 10; motes.emissionAngle = .pi / 2; motes.emissionAngleRange = .pi
        motes.particleScale = 0.08; motes.particleScaleRange = 0.05
        motes.particleAlpha = 0.6; motes.particleAlphaRange = 0.3
        motes.particleColor = p.sun; motes.particleColorBlendFactor = 1; motes.particleBlendMode = .add
        motes.position = CGPoint(x: 0, y: 200)
        motes.zPosition = -150
        addChild(motes)
        motes.advanceSimulationTime(8)
    }
}
