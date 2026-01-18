#!/usr/bin/swift

import Cocoa

// Pixel art icon generator - creates a retro-style animated wallpaper icon
func createPixelArtIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    
    image.lockFocus()
    
    let pixelSize = size / 16
    
    // Background gradient - deep purple to blue
    let gradient = NSGradient(colors: [
        NSColor(red: 0.15, green: 0.05, blue: 0.3, alpha: 1.0),
        NSColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 1.0)
    ])
    
    // Draw rounded rect background
    let bgPath = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: size, height: size), 
                               xRadius: CGFloat(size) / 5, 
                               yRadius: CGFloat(size) / 5)
    gradient?.draw(in: bgPath, angle: -45)
    
    // Draw pixel grid pattern (subtle)
    NSColor(white: 1.0, alpha: 0.03).setFill()
    for x in stride(from: 0, to: size, by: pixelSize * 2) {
        for y in stride(from: 0, to: size, by: pixelSize * 2) {
            NSRect(x: x, y: y, width: pixelSize, height: pixelSize).fill()
        }
    }
    
    // Draw a pixelated monitor/screen shape
    let screenColor = NSColor(red: 0.2, green: 0.8, blue: 0.9, alpha: 1.0)
    let screenGlow = NSColor(red: 0.3, green: 0.9, blue: 1.0, alpha: 0.5)
    let frameColor = NSColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0)
    
    // Monitor frame (outer)
    frameColor.setFill()
    let frameRect = NSRect(x: pixelSize * 2, y: pixelSize * 4, width: pixelSize * 12, height: pixelSize * 9)
    NSBezierPath(roundedRect: frameRect, xRadius: CGFloat(pixelSize), yRadius: CGFloat(pixelSize)).fill()
    
    // Monitor stand
    frameColor.setFill()
    NSRect(x: pixelSize * 6, y: pixelSize * 2, width: pixelSize * 4, height: pixelSize * 2).fill()
    NSRect(x: pixelSize * 5, y: pixelSize * 1, width: pixelSize * 6, height: pixelSize * 2).fill()
    
    // Screen (inner) with gradient
    let screenGradient = NSGradient(colors: [
        NSColor(red: 0.1, green: 0.6, blue: 0.7, alpha: 1.0),
        NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
    ])
    let screenRect = NSRect(x: pixelSize * 3, y: pixelSize * 5, width: pixelSize * 10, height: pixelSize * 7)
    let screenPath = NSBezierPath(roundedRect: screenRect, xRadius: CGFloat(pixelSize / 2), yRadius: CGFloat(pixelSize / 2))
    screenGradient?.draw(in: screenPath, angle: -30)
    
    // Animated wave lines on screen (pixel style)
    NSColor(red: 0.4, green: 0.9, blue: 1.0, alpha: 0.8).setFill()
    
    // Wave pattern
    for i in 0..<3 {
        let y = pixelSize * (6 + i * 2)
        for x in stride(from: pixelSize * 4, to: pixelSize * 12, by: pixelSize) {
            let offset = (x / pixelSize + i) % 3
            let yOffset = offset == 1 ? pixelSize : 0
            NSRect(x: x, y: y + yOffset, width: pixelSize, height: pixelSize).fill()
        }
    }
    
    // Play button triangle (pixelated)
    NSColor.white.setFill()
    let playX = pixelSize * 7
    let playY = pixelSize * 7
    NSRect(x: playX, y: playY + pixelSize * 2, width: pixelSize, height: pixelSize).fill()
    NSRect(x: playX, y: playY + pixelSize, width: pixelSize * 2, height: pixelSize).fill()
    NSRect(x: playX, y: playY, width: pixelSize * 3, height: pixelSize).fill()
    NSRect(x: playX, y: playY - pixelSize, width: pixelSize * 2, height: pixelSize).fill()
    NSRect(x: playX, y: playY - pixelSize * 2, width: pixelSize, height: pixelSize).fill()
    
    // Corner shine pixels
    NSColor(white: 1.0, alpha: 0.6).setFill()
    NSRect(x: pixelSize * 3, y: pixelSize * 11, width: pixelSize, height: pixelSize).fill()
    NSRect(x: pixelSize * 4, y: pixelSize * 11, width: pixelSize, height: pixelSize / 2).fill()
    
    image.unlockFocus()
    
    return image
}

func savePNG(image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG data")
        return
    }
    
    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Saved: \(path)")
    } catch {
        print("Failed to save \(path): \(error)")
    }
}

// Main
let basePath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let iconsetPath = "\(basePath)/AppIcon.iconset"

// Create iconset directory
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

// Generate icons at all required sizes
let sizes: [(name: String, size: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024)
]

for (name, size) in sizes {
    let icon = createPixelArtIcon(size: size)
    savePNG(image: icon, to: "\(iconsetPath)/\(name).png")
}

print("Iconset created at: \(iconsetPath)")
print("Run: iconutil -c icns \(iconsetPath)")
