// Draws the app icon (1024 px, opaque) and the launch-screen mark (transparent)
// into the asset catalog: run `swift Tools/make-icon.swift` from the repo root.
// The look follows Aetheria Rising's icon (gold laurel on crimson) with the
// castle replaced by a Roman gladius crossed with a Han jian.
import AppKit
import CoreGraphics

func color(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

func render(size: Int, opaque: Bool, to path: String) {
    let s = CGFloat(size)
    let space = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                        bitmapInfo: opaque ? CGImageAlphaInfo.noneSkipLast.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high
    let c = CGPoint(x: s / 2, y: s / 2)

    if opaque {
        let bg = CGGradient(colorsSpace: space, colors: [color(0xA82424), color(0x5E1010), color(0x2A0606)] as CFArray, locations: [0, 0.6, 1])!
        ctx.drawRadialGradient(bg, startCenter: CGPoint(x: c.x, y: c.y + s * 0.08), startRadius: 0, endCenter: c, endRadius: s * 0.75, options: [.drawsAfterEndLocation])
        // Faint mist rising from below.
        let mist = CGGradient(colorsSpace: space, colors: [color(0xBFD6F2, 0.28), color(0xBFD6F2, 0)] as CFArray, locations: [0, 1])!
        ctx.drawRadialGradient(mist, startCenter: CGPoint(x: c.x, y: s * 0.18), startRadius: 0, endCenter: CGPoint(x: c.x, y: s * 0.18), endRadius: s * 0.55, options: [])
    }

    let goldLight = color(0xF6D98A), goldMid = color(0xD9A635), goldDark = color(0x8A5A14)

    func goldFill(_ path: CGPath, from: CGPoint, to: CGPoint) {
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        let g = CGGradient(colorsSpace: space, colors: [goldLight, goldMid, goldDark] as CFArray, locations: [0, 0.5, 1])!
        ctx.drawLinearGradient(g, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
        ctx.addPath(path)
        ctx.setStrokeColor(color(0x4A2E08, 0.8))
        ctx.setLineWidth(s * 0.004)
        ctx.strokePath()
    }

    // Laurel: two branches of leaves around the lower three-quarters.
    let radius = s * 0.36
    for side in [-1.0, 1.0] {
        let stem = CGMutablePath()
        for i in 0...40 {
            let t = CGFloat(i) / 40
            let a = -CGFloat.pi / 2 - CGFloat(side) * (0.25 + t * 2.35)
            let p = CGPoint(x: c.x + cos(a) * radius, y: c.y + sin(a) * radius)
            if i == 0 { stem.move(to: p) } else { stem.addLine(to: p) }
        }
        ctx.addPath(stem)
        ctx.setStrokeColor(goldMid)
        ctx.setLineWidth(s * 0.012)
        ctx.strokePath()
        for i in 0..<15 {
            let t = CGFloat(i) / 14
            let a = -CGFloat.pi / 2 - CGFloat(side) * (0.32 + t * 2.2)
            let base = CGPoint(x: c.x + cos(a) * radius, y: c.y + sin(a) * radius)
            let leafLength = s * (0.105 - t * 0.03)
            for outward in [true, false] {
                let dir = a + CGFloat(side) * (outward ? -0.9 : -2.3) * -1
                let tip = CGPoint(x: base.x + cos(dir) * leafLength, y: base.y + sin(dir) * leafLength)
                let normal = CGPoint(x: -sin(dir) * leafLength * 0.42, y: cos(dir) * leafLength * 0.42)
                let mid = CGPoint(x: (base.x + tip.x) / 2, y: (base.y + tip.y) / 2)
                let leaf = CGMutablePath()
                leaf.move(to: base)
                leaf.addQuadCurve(to: tip, control: CGPoint(x: mid.x + normal.x, y: mid.y + normal.y))
                leaf.addQuadCurve(to: base, control: CGPoint(x: mid.x - normal.x, y: mid.y - normal.y))
                goldFill(leaf, from: CGPoint(x: tip.x, y: tip.y + leafLength), to: CGPoint(x: base.x, y: base.y - leafLength))
            }
        }
    }
    // A berry where the branches meet.
    let berry = CGPath(ellipseIn: CGRect(x: c.x - s * 0.028, y: c.y - radius - s * 0.03, width: s * 0.056, height: s * 0.056), transform: nil)
    goldFill(berry, from: CGPoint(x: c.x, y: c.y - radius + s * 0.03), to: CGPoint(x: c.x, y: c.y - radius - s * 0.03))

    // Two blades crossed.
    func blade(angle: CGFloat, length: CGFloat, width: CGFloat, guardWidth: CGFloat, jian: Bool) {
        ctx.saveGState()
        ctx.translateBy(x: c.x, y: c.y - s * 0.02)
        ctx.rotate(by: angle)
        let tipY = length * 0.55, hiltY = -length * 0.45
        let b = CGMutablePath()
        b.move(to: CGPoint(x: -width / 2, y: hiltY + length * 0.12))
        b.addLine(to: CGPoint(x: -width / 2 * (jian ? 1 : 0.85), y: tipY - width * 1.4))
        b.addLine(to: CGPoint(x: 0, y: tipY))
        b.addLine(to: CGPoint(x: width / 2 * (jian ? 1 : 0.85), y: tipY - width * 1.4))
        b.addLine(to: CGPoint(x: width / 2, y: hiltY + length * 0.12))
        b.closeSubpath()
        ctx.saveGState()
        ctx.addPath(b)
        ctx.clip()
        let steel = CGGradient(colorsSpace: space, colors: [color(0xF4F7FA), color(0xA9B3BF), color(0x6C7682)] as CFArray, locations: [0, 0.45, 1])!
        ctx.drawLinearGradient(steel, start: CGPoint(x: -width / 2, y: 0), end: CGPoint(x: width / 2, y: 0), options: [])
        ctx.restoreGState()
        ctx.addPath(b)
        ctx.setStrokeColor(color(0x1C1410, 0.9))
        ctx.setLineWidth(s * 0.005)
        ctx.strokePath()
        // Fuller down the middle.
        ctx.move(to: CGPoint(x: 0, y: hiltY + length * 0.14))
        ctx.addLine(to: CGPoint(x: 0, y: tipY - width * 2))
        ctx.setStrokeColor(color(0x5A6470, 0.6))
        ctx.setLineWidth(s * 0.004)
        ctx.strokePath()
        let guardPath = CGPath(roundedRect: CGRect(x: -guardWidth / 2, y: hiltY + length * 0.08, width: guardWidth, height: width * 0.6), cornerWidth: width * 0.2, cornerHeight: width * 0.2, transform: nil)
        goldFill(guardPath, from: CGPoint(x: 0, y: hiltY + length * 0.16), to: CGPoint(x: 0, y: hiltY + length * 0.06))
        let grip = CGPath(roundedRect: CGRect(x: -width * 0.28, y: hiltY - length * 0.04, width: width * 0.56, height: length * 0.13), cornerWidth: width * 0.2, cornerHeight: width * 0.2, transform: nil)
        ctx.addPath(grip)
        ctx.setFillColor(jian ? color(0x2A1E18) : color(0x6E4A2A))
        ctx.fillPath()
        let pommel = CGPath(ellipseIn: CGRect(x: -width * 0.45, y: hiltY - length * 0.075, width: width * 0.9, height: width * 0.9), transform: nil)
        goldFill(pommel, from: CGPoint(x: 0, y: hiltY), to: CGPoint(x: 0, y: hiltY - length * 0.08))
        if jian {
            // A red tassel on the jian.
            ctx.move(to: CGPoint(x: 0, y: hiltY - length * 0.07))
            ctx.addQuadCurve(to: CGPoint(x: width * 0.9, y: hiltY - length * 0.2), control: CGPoint(x: width * 0.9, y: hiltY - length * 0.08))
            ctx.setStrokeColor(color(0xC0261C))
            ctx.setLineWidth(s * 0.012)
            ctx.strokePath()
        }
        ctx.restoreGState()
    }
    // A glow where the blades cross.
    let glow = CGGradient(colorsSpace: space, colors: [color(0xFFE2A0, 0.55), color(0xFFB347, 0.0)] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(glow, startCenter: CGPoint(x: c.x, y: c.y + s * 0.02), startRadius: 0, endCenter: CGPoint(x: c.x, y: c.y + s * 0.02), endRadius: s * 0.3, options: [])
    // Shadow under the blades.
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.01), blur: s * 0.03, color: color(0x000000, 0.55))
    blade(angle: 0.66, length: s * 0.6, width: s * 0.088, guardWidth: s * 0.2, jian: false)
    blade(angle: -0.66, length: s * 0.64, width: s * 0.066, guardWidth: s * 0.18, jian: true)

    let image = ctx.makeImage()!
    let rep = NSBitmapImageRep(cgImage: image)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

let catalog = "App/Resources/Assets.xcassets"
render(size: 1024, opaque: true, to: "\(catalog)/AppIcon.appiconset/icon-1024.png")
render(size: 600, opaque: false, to: "\(catalog)/LaunchMark.imageset/launch-mark.png")
render(size: 1024, opaque: true, to: "docs/marketing/icon-1024.png")
print("Icon and launch mark written")
