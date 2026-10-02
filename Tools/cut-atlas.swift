// Cuts the founders' portrait atlas (2 x 2) into one JPEG per hero:
// swift Tools/cut-atlas.swift <atlas> <out-dir>
import AppKit

let args = CommandLine.arguments
guard args.count == 3, let image = NSImage(contentsOfFile: args[1]) else { fatalError("usage: cut-atlas <atlas> <out-dir>") }
var rect = CGRect(origin: .zero, size: image.size)
let atlas = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
let half = atlas.width / 2
// CGImage cropping is from the top-left corner.
let cells = [("livia", 0, 0), ("nefru", half, 0), ("wei_jian", 0, half), ("atossa", half, half)]
for (name, x, y) in cells {
    let cell = atlas.cropping(to: CGRect(x: x, y: y, width: half, height: half))!
    let data = NSBitmapImageRep(cgImage: cell).representation(using: .jpeg, properties: [.compressionFactor: 0.84])!
    try! data.write(to: URL(fileURLWithPath: "\(args[2])/\(name).jpg"))
}
print("Cut \(cells.count) portraits")
