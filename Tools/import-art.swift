// Brings ChatGPT art from art-inbox/ into the app (see docs/chatgpt-art-brief.md):
//
//   swift Tools/import-art.swift
//
// Fighter sheets (art-inbox/fighters/<hero>/<action>.png, a grid of frames)
// are cut into strips the game plays, App/Resources/Fighters/
// fighter-<hero>-<action>.png, with fighter-<hero>.json giving each strip's
// frame size, frame count, loop flag and where the feet stand. Every sheet is
// scaled so the hero stands 360 px tall (twice the 180 points the game draws),
// and every frame is placed by its feet on one ground line so nothing jitters.
// Stage paintings and the icon are resized and copied. Then the Xcode project
// is regenerated so new files are bundled.
import AppKit
import Foundation

let fm = FileManager.default
let inbox = "art-inbox"
let standingHeight = 360.0

struct ActionSpec { let frames: Int; let columns: Int; let rows: Int; let loop: Bool; let fps: Double }
let actions: [String: ActionSpec] = [
    "idle": .init(frames: 4, columns: 2, rows: 2, loop: true, fps: 8),
    "walk": .init(frames: 8, columns: 4, rows: 2, loop: true, fps: 12),
    "guard": .init(frames: 4, columns: 2, rows: 2, loop: true, fps: 8),
    "jump": .init(frames: 4, columns: 2, rows: 2, loop: false, fps: 10),
    "light": .init(frames: 6, columns: 3, rows: 2, loop: false, fps: 24),
    "heavy": .init(frames: 6, columns: 3, rows: 2, loop: false, fps: 16),
    "air": .init(frames: 4, columns: 2, rows: 2, loop: false, fps: 14),
    "throw": .init(frames: 6, columns: 3, rows: 2, loop: false, fps: 14),
    "special": .init(frames: 6, columns: 3, rows: 2, loop: false, fps: 14),
    "super": .init(frames: 8, columns: 4, rows: 2, loop: false, fps: 12),
    "hit": .init(frames: 4, columns: 2, rows: 2, loop: false, fps: 14),
    "ko": .init(frames: 12, columns: 4, rows: 3, loop: false, fps: 12),
    "victory": .init(frames: 6, columns: 3, rows: 2, loop: true, fps: 8),
]

// MARK: Pixels

struct Pixels {
    var width: Int, height: Int
    var data: [UInt8]   // RGBA, premultiplied

    init?(path: String) {
        guard let image = NSImage(contentsOfFile: path) else { return nil }
        var rect = CGRect(origin: .zero, size: image.size)
        guard let cg = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { return nil }
        width = cg.width; height = cg.height
        data = [UInt8](repeating: 0, count: width * height * 4)
        let ctx = CGContext(data: &data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        clearMagentaIfOpaque()
    }

    func alpha(_ x: Int, _ y: Int) -> UInt8 { data[(y * width + x) * 4 + 3] }

    /// A sheet made on flat magenta instead of transparency has its magenta
    /// (and the magenta fringe of anti-aliasing) cleared.
    mutating func clearMagentaIfOpaque() {
        var transparent = false
        var i = 3
        while i < data.count { if data[i] < 250 { transparent = true; break }; i += 4 * 97 }
        guard !transparent else { return }
        for p in stride(from: 0, to: data.count, by: 4) {
            let r = Double(data[p]), g = Double(data[p + 1]), b = Double(data[p + 2])
            // How magenta the pixel is: strong red and blue, weak green.
            let magenta = min(r, b) - g
            if magenta > 120 { data[p] = 0; data[p + 1] = 0; data[p + 2] = 0; data[p + 3] = 0 }
            else if magenta > 50 {
                // Anti-aliased edge: fade it out and drop the pink cast.
                let keep = 1 - (magenta - 50) / 70
                let neutral = g * keep
                data[p] = UInt8(neutral); data[p + 1] = UInt8(neutral); data[p + 2] = UInt8(neutral)
                data[p + 3] = UInt8(255 * keep)
            }
        }
    }

    func cgImage() -> CGImage {
        var copy = data
        let ctx = CGContext(data: &copy, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        return ctx.makeImage()!
    }
}

struct Frame { var minX: Int, minY: Int, maxX: Int, maxY: Int, feetX: Double }

/// The figure in one grid cell: its bounds (y down) and where its feet are.
func findFrame(_ p: Pixels, cellX: Int, cellY: Int, cellW: Int, cellH: Int) -> Frame? {
    var minX = Int.max, minY = Int.max, maxX = -1, maxY = -1
    for y in cellY..<min(p.height, cellY + cellH) {
        for x in cellX..<min(p.width, cellX + cellW) where p.alpha(x, y) > 24 {
            minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
        }
    }
    guard maxX >= 0 else { return nil }
    let feetFrom = maxY - max(2, (maxY - minY) * 12 / 100)
    var sum = 0.0, count = 0.0
    for y in feetFrom...maxY { for x in minX...maxX where p.alpha(x, y) > 24 { sum += Double(x); count += 1 } }
    return Frame(minX: minX, minY: minY, maxX: maxX, maxY: maxY, feetX: count > 0 ? sum / count : Double(minX + maxX) / 2)
}

func writePNG(_ image: CGImage, _ path: String) throws {
    let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    try data.write(to: URL(fileURLWithPath: path))
}

// MARK: Fighters

struct StripInfo: Encodable { let frames: Int; let width: Int; let height: Int; let anchor: [Double]; let loop: Bool; let figureHeight: Double; let fps: Double }

func importFighter(_ hero: String) throws -> Int {
    let dir = "\(inbox)/fighters/\(hero)"
    let out = "App/Resources/Fighters"
    try fm.createDirectory(atPath: out, withIntermediateDirectories: true)
    // The standing height comes from the idle sheet (or the reference).
    var scale: Double? = nil
    for source in ["idle", "reference"] {
        guard let p = Pixels(path: "\(dir)/\(source).png") else { continue }
        let spec = actions[source] ?? ActionSpec(frames: 1, columns: 1, rows: 1, loop: false, fps: 1)
        let cw = p.width / spec.columns, ch = p.height / spec.rows
        if let f = findFrame(p, cellX: 0, cellY: 0, cellW: cw, cellH: ch) { scale = standingHeight / Double(f.maxY - f.minY + 1); break }
    }
    guard let scale else {
        if !fm.fileExists(atPath: "\(dir)/parts.png") { print("  \(hero): no idle, reference or parts sheet, skipped") }
        return 0
    }

    var manifest: [String: StripInfo] = [:]
    for (action, spec) in actions.sorted(by: { $0.key < $1.key }) {
        guard let p = Pixels(path: "\(dir)/\(action).png") else { continue }
        let cw = p.width / spec.columns, ch = p.height / spec.rows
        var frames: [(Frame, Int, Int)] = []
        for index in 0..<spec.frames {
            let cx = (index % spec.columns) * cw, cy = (index / spec.columns) * ch
            if let f = findFrame(p, cellX: cx, cellY: cy, cellW: cw, cellH: ch) { frames.append((f, cx, cy)) }
        }
        guard frames.count == spec.frames else { print("  \(hero)/\(action): found \(frames.count) of \(spec.frames) figures, skipped"); continue }
        // One ground line for the sheet: the lowest foot of any frame, per cell row offset.
        let ground = frames.map { Double($0.0.maxY - $0.2) }.max()!
        let pad = 8.0
        let halfWidth = frames.map { max($0.0.feetX - Double($0.0.minX), Double($0.0.maxX) - $0.0.feetX) }.max()! * scale + pad
        let above = frames.map { ground - Double($0.0.minY - $0.2) }.max()! * scale + pad
        let below = frames.map { max(0, Double($0.0.maxY - $0.2) - ground) }.max()! * scale + pad
        let frameW = Int(ceil(halfWidth * 2)), frameH = Int(ceil(above + below))
        let ctx = CGContext(data: nil, width: frameW * spec.frames, height: frameH, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.interpolationQuality = .high
        let sheet = p.cgImage()
        for (index, (f, _, cy)) in frames.enumerated() {
            let crop = sheet.cropping(to: CGRect(x: f.minX, y: f.minY, width: f.maxX - f.minX + 1, height: f.maxY - f.minY + 1))!
            let w = Double(crop.width) * scale, h = Double(crop.height) * scale
            // Feet at the frame's centre line, the sheet's ground at `above`.
            let x = Double(index * frameW) + halfWidth - (f.feetX - Double(f.minX)) * scale
            let topFromTop = above - (ground - Double(f.minY - cy)) * scale
            ctx.draw(crop, in: CGRect(x: x, y: Double(frameH) - topFromTop - h, width: w, height: h))
        }
        let name = "fighter-\(hero)-\(action)"
        try writePNG(ctx.makeImage()!, "\(out)/\(name).png")
        manifest[action] = StripInfo(frames: spec.frames, width: frameW, height: frameH, anchor: [0.5, above / Double(frameH)],
                                     loop: spec.loop, figureHeight: standingHeight, fps: spec.fps)
    }
    guard !manifest.isEmpty else { return 0 }
    guard manifest["idle"] != nil else { print("  \(hero): no idle strip; the game keeps the drawn fighter"); return 0 }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(manifest).write(to: URL(fileURLWithPath: "\(out)/fighter-\(hero).json"))
    print("  \(hero): \(manifest.count) strips")
    return manifest.count
}

// MARK: Parts sheets (cutout animation)

let partNames = ["head", "torso", "upperArm", "forearm", "thigh", "shin", "skirt", "cape", "weapon", "offhand", "backHair", "figure"]
/// Where the hand holds each hero's weapon, as a share of its height from the grip end.
let weaponHold: [String: Double] = [
    "bardiya": 0.32, "atossa": 0.3, "livia": 0.3, "meritamun": 0.34,
    "tahmina": 0.5, "nefru": 0.5, "zhao_lin": 0.28,
]

struct PartInfo: Encodable { let width: Int; let height: Int; let anchor: [Double] }
struct PartsManifest: Encodable { let figureHeight: Int; let parts: [String: PartInfo] }

/// Centre x (in the crop) of the solid pixels in a band of rows.
func centreX(_ p: Pixels, _ f: Frame, rows: ClosedRange<Int>) -> Double {
    var sum = 0.0, count = 0.0
    for y in rows where y >= f.minY && y <= f.maxY {
        for x in f.minX...f.maxX where p.alpha(x, y) > 24 { sum += Double(x); count += 1 }
    }
    return count > 0 ? sum / count - Double(f.minX) : Double(f.maxX - f.minX) / 2
}

func importParts(_ hero: String) throws -> Bool {
    guard let p = Pixels(path: "\(inbox)/fighters/\(hero)/parts.png") else { return false }
    let out = "App/Resources/Fighters"
    try fm.createDirectory(atPath: out, withIntermediateDirectories: true)
    let cw = p.width / 4, ch = p.height / 3
    let sheet = p.cgImage()
    var parts: [String: PartInfo] = [:]
    var figureHeight = 0
    for (index, name) in partNames.enumerated() {
        guard let f = findFrame(p, cellX: (index % 4) * cw, cellY: (index / 4) * ch, cellW: cw, cellH: ch) else { continue }
        let w = f.maxX - f.minX + 1, h = f.maxY - f.minY + 1
        // Ignore specks: a real piece is at least a few percent of its cell.
        guard w * h > cw * ch / 400 else { continue }
        if name == "figure" { figureHeight = h; continue }
        let band = max(2, h / 16)
        let anchor: [Double]
        switch name {
        case "head", "torso":
            anchor = [centreX(p, f, rows: (f.maxY - band)...f.maxY) / Double(w), 0]
        case "weapon":
            let hold = weaponHold[hero] ?? 0.1
            let row = f.maxY - Int(Double(h) * hold)
            anchor = [centreX(p, f, rows: (row - band)...(row + band)) / Double(w), hold]
        case "offhand":
            anchor = [0.5, 0.5]
        default:
            anchor = [centreX(p, f, rows: f.minY...(f.minY + band)) / Double(w), 1]
        }
        let crop = sheet.cropping(to: CGRect(x: f.minX, y: f.minY, width: w, height: h))!
        try writePNG(crop, "\(out)/parts-\(hero)-\(name).png")
        parts[name] = PartInfo(width: w, height: h, anchor: anchor)
    }
    let required = ["head", "torso", "upperArm", "forearm", "thigh", "shin"]
    guard required.allSatisfy({ parts[$0] != nil }) else {
        print("  \(hero): parts sheet is missing \(required.filter { parts[$0] == nil }.joined(separator: ", ")); skipped")
        return false
    }
    if figureHeight == 0 { print("  \(hero): no full figure in cell 12; pieces will be sized to the skeleton") }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(PartsManifest(figureHeight: figureHeight, parts: parts)).write(to: URL(fileURLWithPath: "\(out)/parts-\(hero).json"))
    print("  \(hero): \(parts.count) painted parts")
    return true
}

// MARK: Stages and icon

func resize(_ path: String, to size: CGSize, opaque: Bool, out: String) throws {
    guard let image = NSImage(contentsOfFile: path) else { return }
    var rect = CGRect(origin: .zero, size: image.size)
    let cg = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
    let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: opaque ? CGImageAlphaInfo.noneSkipLast.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.interpolationQuality = .high
    ctx.draw(cg, in: CGRect(origin: .zero, size: size))
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    let data = opaque && out.hasSuffix(".jpg") ? rep.representation(using: .jpeg, properties: [.compressionFactor: 0.85])! : rep.representation(using: .png, properties: [:])!
    try data.write(to: URL(fileURLWithPath: out))
}

var imported = 0
print("Fighters:")
let heroes = (try? fm.contentsOfDirectory(atPath: "\(inbox)/fighters"))?.filter { !$0.hasPrefix(".") }.sorted() ?? []
if heroes.isEmpty { print("  none in \(inbox)/fighters") }
for hero in heroes {
    if try importParts(hero) { imported += 1 }
    imported += try importFighter(hero)
}

print("Stages:")
try fm.createDirectory(atPath: "App/Resources/Stages", withIntermediateDirectories: true)
for stage in ["forum", "nile", "persepolis", "greatWall", "crossing"] {
    for (layer, size, opaque) in [("far", CGSize(width: 2048, height: 1024), true), ("mid", CGSize(width: 2048, height: 1024), false), ("floor", CGSize(width: 2048, height: 256), true)] {
        let source = "\(inbox)/stages/\(stage)-\(layer).png"
        guard fm.fileExists(atPath: source) else { continue }
        // Keep the painting's own proportions at the target width.
        var size = size
        if let image = NSImage(contentsOfFile: source), image.size.width > 0 {
            size.height = (size.width * image.size.height / image.size.width).rounded()
        }
        try resize(source, to: size, opaque: opaque, out: "App/Resources/Stages/\(stage)-\(layer).\(opaque ? "jpg" : "png")")
        print("  \(stage)-\(layer)")
        imported += 1
    }
}

if fm.fileExists(atPath: "\(inbox)/icon.png") {
    try resize("\(inbox)/icon.png", to: CGSize(width: 1024, height: 1024), opaque: true, out: "App/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png")
    print("Icon replaced")
    imported += 1
}
if fm.fileExists(atPath: "\(inbox)/key-art.png") {
    try fm.createDirectory(atPath: "docs/marketing", withIntermediateDirectories: true)
    try resize("\(inbox)/key-art.png", to: CGSize(width: 2732, height: 2048), opaque: true, out: "docs/marketing/key-art.jpg")
    print("Key art copied to docs/marketing")
}

if imported > 0 {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    task.arguments = ["xcodegen", "generate"]
    if (try? task.run()) != nil { task.waitUntilExit(); print("Xcode project regenerated") }
    else { print("Run `xcodegen generate` to bundle the new files") }
}
print("Imported \(imported) item(s)")
