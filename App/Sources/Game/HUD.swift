import SpriteKit
import FightCore

/// The fight's heads-up display, in screen space: health, meter, rounds,
/// timer, combo counts and the announcer's calls.
final class HUDNode: SKNode {
    private var size: CGSize
    private let safe: UIEdgeInsets
    private var bars: [SideBar] = []
    private let timerLabel = SKLabelNode()
    private let timerPlate = SKShapeNode()
    private let banner = SKNode()
    private let bannerText = SKLabelNode()
    private let bannerSub = SKLabelNode()
    private var comboLabels: [SKLabelNode] = []
    private var comboHideAt: [Int] = [0, 0]
    private var tick = 0
    private let training: Bool

    init(size: CGSize, safe: UIEdgeInsets, heroes: [HeroID], names: [String], echoes: Set<Int> = [], roundsToWin: Int, training: Bool) {
        self.size = size
        self.safe = safe
        self.training = training
        super.init()
        zPosition = 1000
        let width = max(240, min(size.width * 0.36, 380))
        // A shade across the top so the bars read on any stage.
        let shade = SKSpriteNode(texture: HUDNode.shadeTexture)
        shade.name = "shade"
        shade.zPosition = -1
        addChild(shade)
        for i in 0..<2 {
            let bar = SideBar(index: i, hero: heroes[i], name: names[i], echo: echoes.contains(i), width: width, roundsToWin: roundsToWin)
            bars.append(bar)
            addChild(bar)
        }
        timerPlate.path = CGPath(roundedRect: CGRect(x: -30, y: -24, width: 60, height: 48), cornerWidth: 10, cornerHeight: 10, transform: nil)
        timerPlate.fillColor = UIColor(white: 0.05, alpha: 0.7)
        timerPlate.strokeColor = Theme.goldUI
        timerPlate.lineWidth = 1.5
        addChild(timerPlate)
        timerLabel.fontName = Theme.displayFontName
        timerLabel.fontSize = 30
        timerLabel.fontColor = .white
        timerLabel.verticalAlignmentMode = .center
        timerPlate.addChild(timerLabel)
        timerPlate.isHidden = training

        for i in 0..<2 {
            let combo = SKLabelNode()
            combo.fontName = Theme.displayFontName
            combo.fontSize = 30
            combo.fontColor = Theme.goldUI
            combo.horizontalAlignmentMode = i == 0 ? .left : .right
            combo.alpha = 0
            addChild(combo)
            comboLabels.append(combo)
        }

        addChild(banner)
        bannerText.fontName = Theme.displayFontName
        bannerText.fontSize = 64
        bannerText.fontColor = .white
        bannerText.verticalAlignmentMode = .center
        banner.addChild(bannerText)
        bannerSub.fontName = Theme.bodyFontName
        bannerSub.fontSize = 18
        bannerSub.fontColor = Theme.goldUI
        bannerSub.verticalAlignmentMode = .center
        bannerSub.position = CGPoint(x: 0, y: -44)
        banner.addChild(bannerSub)
        banner.alpha = 0
        layout(size: size)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    private static let shadeTexture: SKTexture = {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 128)).image { ctx in
            let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [UIColor(white: 0, alpha: 0.55).cgColor, UIColor(white: 0, alpha: 0).cgColor] as CFArray, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: 128), options: [])
        }
        return SKTexture(image: image)
    }()

    /// Larger on iPad, so the bars keep their presence on a big screen.
    private var uiScale: CGFloat { max(1, min(1.6, size.height / 420)) }

    func layout(size: CGSize) {
        self.size = size
        let k = uiScale
        for node in bars as [SKNode] + [timerPlate, banner] + comboLabels { node.setScale(k) }
        if let shade = childNode(withName: "shade") as? SKSpriteNode {
            shade.size = CGSize(width: size.width + 40, height: 150)
            shade.position = CGPoint(x: 0, y: size.height / 2 - 75)
        }
        let top = size.height / 2 - max(safe.top, 10) - 34 * k
        let edge = size.width / 2 - max(safe.left, safe.right, 16) - 8 * k
        bars[0].position = CGPoint(x: -edge, y: top)
        bars[1].position = CGPoint(x: edge, y: top)
        timerPlate.position = CGPoint(x: 0, y: top - 2)
        comboLabels[0].position = CGPoint(x: -edge + 6, y: top - 100 * k)
        comboLabels[1].position = CGPoint(x: edge - 6, y: top - 100 * k)
        banner.position = CGPoint(x: 0, y: 40)
    }

    func update(_ match: Match) {
        tick += 1
        for i in 0..<2 { bars[i].update(match.fighters[i], fraction: match.healthFraction(i), tick: tick) }
        timerLabel.text = "\(match.secondsLeft)"
        timerLabel.fontColor = match.secondsLeft <= 10 && tick % 30 < 15 ? UIColor(hex: 0xFF6A5A) : .white
        for i in 0..<2 where tick > comboHideAt[i] && comboLabels[i].alpha > 0 {
            comboLabels[i].run(.fadeOut(withDuration: 0.25))
            comboHideAt[i] = Int.max
        }
    }

    func showCombo(attacker: Int, count: Int, damage: Double) {
        guard count >= 2 else { return }
        let label = comboLabels[attacker]
        label.text = "\(count) HITS"
        label.removeAllActions()
        label.alpha = 1
        label.setScale(1.35)
        label.run(.scale(to: 1, duration: 0.12))
        comboHideAt[attacker] = tick + 70
    }

    /// The announcer: a big word, an optional line under it.
    func announce(_ text: String, sub: String? = nil, color: UIColor = .white, hold: TimeInterval = 1.1, size fontSize: CGFloat = 64) {
        bannerText.text = text
        bannerText.fontSize = fontSize
        bannerText.fontColor = color
        bannerSub.text = sub
        banner.removeAllActions()
        banner.setScale(1.6)
        banner.alpha = 0
        banner.run(.sequence([
            .group([.fadeIn(withDuration: 0.12), .scale(to: 1, duration: 0.18)]),
            .wait(forDuration: hold),
            .group([.fadeOut(withDuration: 0.25), .scale(to: 1.15, duration: 0.25)]),
        ]))
    }

    func flashMeter(_ index: Int) { bars[index].pulseMeter() }
}

/// One side's bar: portrait medallion, name, health with a trailing damage
/// bar, the Aether meter and round pips.
private final class SideBar: SKNode {
    private let index: Int
    private let width: CGFloat
    private let healthFill = SKSpriteNode(color: .white, size: .zero)
    private let damageFill = SKSpriteNode(color: UIColor(hex: 0xE8D9A0), size: .zero)
    private let meterFill = SKSpriteNode(color: .white, size: .zero)
    private let meterGlow = SKShapeNode()
    private let meterLabel = SKLabelNode()
    private var pips: [SKShapeNode] = []
    private var trailing: CGFloat = 1
    private var trailingDelay = 0
    private var lastFraction: CGFloat = 1
    private let conditionLabel = SKLabelNode()
    private let healthWidth: CGFloat
    private let meterWidth: CGFloat

    init(index: Int, hero: HeroID, name: String, echo: Bool, width: CGFloat, roundsToWin: Int) {
        self.index = index
        self.width = width
        healthWidth = width - 70
        meterWidth = (width - 70) * 0.62
        super.init()
        let dir: CGFloat = index == 0 ? 1 : -1
        let medallion = Self.medallion(hero: hero, radius: 30, echo: echo)
        medallion.position = CGPoint(x: 30 * dir, y: -16)
        medallion.xScale = index == 0 ? 1 : -1
        addChild(medallion)

        let barX: CGFloat = 66 * dir
        // Frame and empty bar.
        let frame = SKShapeNode(rect: CGRect(x: index == 0 ? barX - 2 : barX - healthWidth - 2, y: -10, width: healthWidth + 4, height: 20), cornerRadius: 4)
        frame.fillColor = UIColor(white: 0.05, alpha: 0.75)
        frame.strokeColor = Theme.goldUI
        frame.lineWidth = 1.5
        addChild(frame)
        for (node, z) in [(damageFill, 1.0), (healthFill, 2.0)] {
            node.anchorPoint = CGPoint(x: index == 0 ? 0 : 1, y: 0.5)
            node.position = CGPoint(x: barX, y: 0)
            node.zPosition = z
            node.size = CGSize(width: healthWidth, height: 16)
            addChild(node)
        }
        healthFill.color = UIColor(hex: 0xE0B44C)

        let nameLabel = SKLabelNode(text: name.uppercased())
        nameLabel.fontName = Theme.bodyFontName
        nameLabel.fontSize = 13
        nameLabel.fontColor = .white
        nameLabel.horizontalAlignmentMode = index == 0 ? .left : .right
        nameLabel.position = CGPoint(x: barX, y: 15)
        addChild(nameLabel)

        // Round pips beside the name.
        for r in 0..<roundsToWin {
            let pip = SKShapeNode(circleOfRadius: 5)
            pip.fillColor = UIColor(white: 0.1, alpha: 0.8)
            pip.strokeColor = Theme.goldUI
            pip.lineWidth = 1.2
            pip.position = CGPoint(x: barX + dir * (healthWidth - 8 - CGFloat(r) * 16), y: 20)
            addChild(pip)
            pips.append(pip)
        }

        // Meter.
        let meterFrame = SKShapeNode(rect: CGRect(x: index == 0 ? barX - 2 : barX - meterWidth - 2, y: -29, width: meterWidth + 4, height: 11), cornerRadius: 3)
        meterFrame.fillColor = UIColor(white: 0.05, alpha: 0.75)
        meterFrame.strokeColor = Theme.goldUI.withAlphaComponent(0.6)
        meterFrame.lineWidth = 1
        addChild(meterFrame)
        meterFill.anchorPoint = CGPoint(x: index == 0 ? 0 : 1, y: 0.5)
        meterFill.position = CGPoint(x: barX, y: -23.5)
        meterFill.size = CGSize(width: 0, height: 7)
        meterFill.zPosition = 2
        addChild(meterFill)
        meterGlow.path = meterFrame.path
        meterGlow.strokeColor = UIColor(hex: 0x9FD8FF)
        meterGlow.lineWidth = 2
        meterGlow.glowWidth = 4
        meterGlow.alpha = 0
        addChild(meterGlow)
        meterLabel.fontName = Theme.bodyFontName
        meterLabel.fontSize = 10
        meterLabel.fontColor = UIColor(hex: 0x9FD8FF)
        meterLabel.horizontalAlignmentMode = index == 0 ? .left : .right
        meterLabel.verticalAlignmentMode = .center
        meterLabel.position = CGPoint(x: barX + dir * (meterWidth + 8), y: -23.5)
        meterLabel.text = "AETHER"
        addChild(meterLabel)

        conditionLabel.fontName = Theme.bodyFontName
        conditionLabel.fontSize = 11
        conditionLabel.horizontalAlignmentMode = index == 0 ? .left : .right
        conditionLabel.position = CGPoint(x: barX, y: -46)
        addChild(conditionLabel)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    static func medallion(hero: HeroID, radius: CGFloat, echo: Bool = false) -> SKNode {
        let node = SKNode()
        let crop = SKCropNode()
        let mask = SKShapeNode(circleOfRadius: radius)
        mask.fillColor = .white
        crop.maskNode = mask
        if let image = ArtLibrary.portrait(hero) {
            let texture = SKTexture(image: image)
            let sprite = SKSpriteNode(texture: texture)
            let scale = radius * 2.6 / image.size.width
            sprite.size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            // Faces sit in the upper part of the portraits.
            sprite.position = CGPoint(x: 0, y: -sprite.size.height * 0.12)
            if echo { sprite.color = UIColor(hex: 0x6F86A8); sprite.colorBlendFactor = 0.75 }
            crop.addChild(sprite)
        }
        node.addChild(crop)
        if echo {
            let mist = SKShapeNode(circleOfRadius: radius)
            mist.fillColor = UIColor(hex: 0x6F86A8, alpha: 0.55)
            mist.strokeColor = .clear
            mist.blendMode = .alpha
            node.addChild(mist)
        }
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.strokeColor = Theme.goldUI
        ring.lineWidth = 2.5
        ring.fillColor = .clear
        node.addChild(ring)
        return node
    }

    func update(_ f: Fighter, fraction: Double, tick: Int) {
        let frac = CGFloat(max(0, min(1, fraction)))
        if frac < lastFraction { trailingDelay = 36 }
        lastFraction = frac
        if trailingDelay > 0 { trailingDelay -= 1 } else { trailing = max(frac, trailing - 0.012) }
        if frac > trailing { trailing = frac }
        healthFill.size.width = healthWidth * frac
        damageFill.size.width = healthWidth * trailing
        healthFill.color = frac < 0.25 ? (tick % 20 < 10 ? UIColor(hex: 0xE0533C) : UIColor(hex: 0xC2412E)) : UIColor(hex: 0xE0B44C)
        let meter = CGFloat(f.meter / 100)
        meterFill.size.width = meterWidth * meter
        meterFill.color = meter >= 1 ? UIColor(hex: 0x9FD8FF) : UIColor(hex: 0x4F8FD0)
        meterGlow.alpha = meter >= 1 ? 0.6 + 0.4 * sin(CGFloat(tick) * 0.15) : 0
        meterLabel.text = meter >= 1 ? "CROSSING ART" : "AETHER"
        for (r, pip) in pips.enumerated() { pip.fillColor = r < f.roundsWon ? Theme.goldUI : UIColor(white: 0.1, alpha: 0.8) }
        var tags: [String] = []
        if f.condition(.empowered) > 0 { tags.append("EMPOWERED") }
        if f.condition(.fortified) > 0 { tags.append("FORTIFIED") }
        if f.condition(.marked) > 0 { tags.append("MARKED") }
        if f.condition(.dusted) > 0 { tags.append("SLOWED") }
        conditionLabel.text = tags.joined(separator: "  ")
        conditionLabel.fontColor = f.condition(.marked) > 0 || f.condition(.dusted) > 0 ? UIColor(hex: 0xFF9C7A) : UIColor(hex: 0x9FE3B8)
    }

    func pulseMeter() {
        meterFill.run(.sequence([.scaleY(to: 1.8, duration: 0.08), .scaleY(to: 1, duration: 0.12)]))
    }
}
