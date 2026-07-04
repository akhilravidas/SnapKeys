import AppKit
import Foundation

guard CommandLine.arguments.count == 3,
      let size = Int(CommandLine.arguments[1]),
      size > 0 else {
    FileHandle.standardError.write(Data("Usage: swift Tools/generate_icon.swift <size> <output.png>\n".utf8))
    exit(64)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let canvas = CGSize(width: size, height: size)
let image = NSImage(size: canvas)

func color(_ hex: UInt32, alpha: CGFloat = 1.0) -> NSColor {
    NSColor(
        calibratedRed: CGFloat((hex >> 16) & 0xff) / 255.0,
        green: CGFloat((hex >> 8) & 0xff) / 255.0,
        blue: CGFloat(hex & 0xff) / 255.0,
        alpha: alpha
    )
}

func roundedRect(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

image.lockFocus()

let scale = CGFloat(size) / 1024.0
let bounds = CGRect(origin: .zero, size: canvas)

let background = NSGradient(colors: [
    color(0x111827),
    color(0x1f2937),
    color(0x0f172a)
])!
background.draw(in: roundedRect(bounds.insetBy(dx: 64 * scale, dy: 64 * scale), radius: 220 * scale), angle: 135)

color(0x000000, alpha: 0.22).setFill()
roundedRect(CGRect(x: 122 * scale, y: 88 * scale, width: 780 * scale, height: 780 * scale), radius: 196 * scale).fill()

let tileFrame = CGRect(x: 142 * scale, y: 164 * scale, width: 740 * scale, height: 740 * scale)
color(0xf8fafc, alpha: 0.98).setFill()
roundedRect(tileFrame, radius: 180 * scale).fill()

color(0xe5e7eb, alpha: 1.0).setFill()
roundedRect(CGRect(x: 224 * scale, y: 256 * scale, width: 250 * scale, height: 512 * scale), radius: 40 * scale).fill()
roundedRect(CGRect(x: 550 * scale, y: 256 * scale, width: 250 * scale, height: 512 * scale), radius: 40 * scale).fill()

color(0x111827, alpha: 1.0).setFill()
roundedRect(CGRect(x: 224 * scale, y: 256 * scale, width: 250 * scale, height: 512 * scale), radius: 40 * scale).fill()
roundedRect(CGRect(x: 550 * scale, y: 256 * scale, width: 250 * scale, height: 512 * scale), radius: 40 * scale).fill()

color(0x38bdf8, alpha: 1.0).setFill()
roundedRect(CGRect(x: 506 * scale, y: 260 * scale, width: 28 * scale, height: 504 * scale), radius: 14 * scale).fill()

color(0xffffff, alpha: 0.23).setFill()
roundedRect(CGRect(x: 190 * scale, y: 674 * scale, width: 646 * scale, height: 82 * scale), radius: 41 * scale).fill()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("Could not render icon PNG\n".utf8))
    exit(1)
}

try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: outputURL)
