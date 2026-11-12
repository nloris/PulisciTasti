import AppKit
let folder = CommandLine.arguments[1]
let image = NSImage(size: NSSize(width: 1024, height: 1024))
image.lockFocus()
NSColor(calibratedRed: 0.93, green: 0.95, blue: 0.93, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 20, y: 20, width: 984, height: 984), xRadius: 220, yRadius: 220).fill()
NSColor(calibratedRed: 0.15, green: 0.40, blue: 0.29, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 166, y: 290, width: 692, height: 430), xRadius: 68, yRadius: 68).fill()
NSColor(calibratedWhite: 0.98, alpha: 1).setFill()
for row in 0..<3 {
    for column in 0..<8 {
        NSBezierPath(roundedRect: NSRect(x: 216 + column * 76, y: 530 - row * 78, width: 50, height: 50), xRadius: 12, yRadius: 12).fill()
    }
}
NSBezierPath(roundedRect: NSRect(x: 367, y: 322, width: 288, height: 28), xRadius: 10, yRadius: 10).fill()
let star = NSBezierPath()
star.move(to: NSPoint(x: 790, y: 865))
star.curve(to: NSPoint(x: 900, y: 755), controlPoint1: NSPoint(x: 810, y: 780), controlPoint2: NSPoint(x: 815, y: 775))
star.curve(to: NSPoint(x: 790, y: 645), controlPoint1: NSPoint(x: 815, y: 735), controlPoint2: NSPoint(x: 810, y: 730))
star.curve(to: NSPoint(x: 680, y: 755), controlPoint1: NSPoint(x: 770, y: 730), controlPoint2: NSPoint(x: 765, y: 735))
star.curve(to: NSPoint(x: 790, y: 865), controlPoint1: NSPoint(x: 765, y: 775), controlPoint2: NSPoint(x: 770, y: 780))
NSColor(calibratedRed: 0.50, green: 0.79, blue: 0.56, alpha: 1).setFill()
star.fill()
image.unlockFocus()
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
        NSGraphicsContext.restoreGraphicsState()
        let suffix = scale == 2 ? "@2x" : ""
        try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: folder + "/icon_\(size)x\(size)\(suffix).png"))
    }
}
