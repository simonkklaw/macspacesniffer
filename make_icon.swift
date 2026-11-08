#!/usr/bin/env swift
// Generates Resources/AppIcon.icns — run with: swift make_icon.swift
import Foundation
import AppKit

// ── Helpers ───────────────────────────────────────────────────────────────

func color(_ hex: UInt32, a: CGFloat = 1) -> CGColor {
    CGColor(red:   CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >>  8) & 0xFF) / 255,
            blue:  CGFloat( hex        & 0xFF) / 255,
            alpha: a)
}

func poly(_ ctx: CGContext, _ pts: [CGPoint], fill: CGColor) {
    ctx.beginPath()
    ctx.move(to: pts[0])
    pts.dropFirst().forEach { ctx.addLine(to: $0) }
    ctx.closePath()
    ctx.setFillColor(fill)
    ctx.fillPath()
}

// ── Isometric projection ──────────────────────────────────────────────────
// All coordinates are in 512-space.
// CG origin = bottom-left, y increases up.
// Table origin (TL) placed at screen (226, 342).
// Table x-axis → screen (+0.70, −0.35), Table y-axis → screen (−0.70, −0.35)
// So:  proj(0,0)=(226,342)  proj(260,0)=(408,251)
//      proj(0,160)=(114,286) proj(260,160)=(296,195)

func proj(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
    CGPoint(x:  0.70 * x - 0.70 * y + 226,
            y: -0.35 * x - 0.35 * y + 342)
}

// Filled parallelogram for one defrag block
func defragBlock(_ ctx: CGContext,
                 x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                 fill: CGColor) {
    poly(ctx, [proj(x,y), proj(x+w,y), proj(x+w,y+h), proj(x,y+h)], fill: fill)
    // Subtle top-edge highlight
    let hiPts = [proj(x,y), proj(x+w,y)]
    ctx.beginPath()
    ctx.move(to: hiPts[0]); ctx.addLine(to: hiPts[1])
    ctx.setStrokeColor(color(0xFFFFFF, a: 0.18))
    ctx.setLineWidth(0.8)
    ctx.strokePath()
}

// ── Main drawing (always in 512×512 space) ────────────────────────────────

func drawIcon(_ ctx: CGContext) {

    // Background — dark navy rounded square
    let S: CGFloat = 512
    let bgPath = CGPath(roundedRect: CGRect(x:0, y:0, width:S, height:S),
                        cornerWidth: 115, cornerHeight: 115, transform: nil)
    ctx.setFillColor(color(0x0d1b2a))
    ctx.addPath(bgPath); ctx.fillPath()

    // Subtle radial glow (upper-right)
    ctx.saveGState()
    ctx.addPath(bgPath); ctx.clip()
    let cs = CGColorSpaceCreateDeviceRGB()
    let glowGrad = CGGradient(
        colorsSpace: cs,
        colors: [color(0x1a5590, a: 0.55), color(0x0d1b2a, a: 0)] as CFArray,
        locations: [0.0, 1.0])!
    ctx.drawRadialGradient(glowGrad,
        startCenter: CGPoint(x: 390, y: 130), startRadius: 0,
        endCenter:   CGPoint(x: 390, y: 130), endRadius: 310,
        options: .drawsAfterEndLocation)
    ctx.restoreGState()

    // ── Slab depth faces ──────────────────────────────────────────────────
    let TL = proj(0,   0);   let TR = proj(260,   0)
    let BL = proj(0, 160);   let BR = proj(260, 160)
    let d: CGFloat = 40      // slab thickness in CG-y (downward = subtract)
    func dn(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x, y: p.y - d) }

    poly(ctx, [TL, BL, dn(BL), dn(TL)], fill: color(0x08131e))  // left face
    poly(ctx, [BL, BR, dn(BR), dn(BL)], fill: color(0x050d15))  // front-bottom face
    poly(ctx, [TR, BR, dn(BR), dn(TR)], fill: color(0x091620))  // right face

    // ── Table top surface ─────────────────────────────────────────────────
    poly(ctx, [TL, TR, BR, BL], fill: color(0x111d2b))

    // Grid lines
    ctx.setStrokeColor(color(0x1c3650, a: 0.60))
    ctx.setLineWidth(0.6)
    stride(from: CGFloat(20), through: 240, by: 20).forEach { x in
        ctx.move(to: proj(x,0)); ctx.addLine(to: proj(x,160)) }
    stride(from: CGFloat(20), through: 140, by: 20).forEach { y in
        ctx.move(to: proj(0,y)); ctx.addLine(to: proj(260,y)) }
    ctx.strokePath()

    // ── Defrag blocks ──────────────────────────────────────────────────────
    // Layout mimics Windows Disk Defragmenter: dense coloured rows showing
    // folders (#FFCC99), files (#99CCFF), hidden variants, free space (#CCC),
    // and a bottom "progress" band in blue.

    struct B { let x,y,w,h: CGFloat; let hex: UInt32; let a: CGFloat }
    let blocks: [B] = [
        // Row 1  y 5..24
        B(x:  4,y:  5,w:60,h:20, hex:0xFFCC99,a:0.92),
        B(x: 68,y:  5,w:26,h:20, hex:0x99CCFF,a:0.92),
        B(x: 98,y:  5,w:16,h:20, hex:0x6699CC,a:0.92),
        B(x:118,y:  5,w:76,h:20, hex:0xFFCC99,a:0.92),
        B(x:198,y:  5,w:20,h:20, hex:0xCCCCCC,a:0.40),
        B(x:222,y:  5,w:34,h:20, hex:0xCC9966,a:0.92),
        // Row 2  y 29..48
        B(x:  4,y: 29,w:14,h:20, hex:0x99CCFF,a:0.92),
        B(x: 22,y: 29,w:48,h:20, hex:0xFFCC99,a:0.92),
        B(x: 74,y: 29,w:22,h:20, hex:0xCC9966,a:0.92),
        B(x:100,y: 29,w:86,h:20, hex:0x99CCFF,a:0.92),
        B(x:190,y: 29,w:66,h:20, hex:0xCCCCCC,a:0.38),
        // Row 3  y 53..72
        B(x:  4,y: 53,w:96,h:20, hex:0xFFCC99,a:0.92),
        B(x:104,y: 53,w:34,h:20, hex:0x6699CC,a:0.92),
        B(x:142,y: 53,w:14,h:20, hex:0x99CCFF,a:0.92),
        B(x:160,y: 53,w:54,h:20, hex:0xFFCC99,a:0.92),
        B(x:218,y: 53,w:38,h:20, hex:0xCCCCCC,a:0.38),
        // Row 4  y 77..96
        B(x:  4,y: 77,w:18,h:20, hex:0xCC9966,a:0.92),
        B(x: 26,y: 77,w:76,h:20, hex:0x99CCFF,a:0.92),
        B(x:106,y: 77,w:12,h:20, hex:0xCCCCCC,a:0.38),
        B(x:122,y: 77,w:46,h:20, hex:0xFFCC99,a:0.92),
        B(x:172,y: 77,w:84,h:20, hex:0xCCCCCC,a:0.38),
        // Row 5  y 101..120 — "defragmented" (clean blue band)
        B(x:  4,y:101,w:118,h:20, hex:0x2e6fba,a:0.90),
        B(x:126,y:101,w: 36,h:20, hex:0x99CCFF,a:0.92),
        B(x:166,y:101,w: 30,h:20, hex:0xFFCC99,a:0.92),
        B(x:200,y:101,w: 56,h:20, hex:0xCCCCCC,a:0.32),
        // Row 6  y 125..140 — progress bar
        B(x:  4,y:125,w:176,h:16, hex:0x1f5fa8,a:0.94),
        B(x:184,y:125,w: 72,h:16, hex:0xCCCCCC,a:0.25),
    ]

    for b in blocks {
        defragBlock(ctx, x: b.x, y: b.y, w: b.w, h: b.h, fill: color(b.hex, a: b.a))
    }

    // Surface border
    ctx.beginPath()
    ctx.move(to: TL); ctx.addLine(to: TR); ctx.addLine(to: BR); ctx.addLine(to: BL)
    ctx.closePath()
    ctx.setStrokeColor(color(0x4a7a9b, a: 0.65))
    ctx.setLineWidth(1.2)
    ctx.strokePath()

    // Bright front-top edge (gives the 3D "lip" effect)
    ctx.beginPath()
    ctx.move(to: TL); ctx.addLine(to: TR)
    ctx.setStrokeColor(color(0x80c4f0, a: 0.85))
    ctx.setLineWidth(2.2)
    ctx.strokePath()

    ctx.beginPath()
    ctx.move(to: TL); ctx.addLine(to: BL)
    ctx.setStrokeColor(color(0x5899cc, a: 0.55))
    ctx.setLineWidth(1.5)
    ctx.strokePath()
}

// ── Render all icon sizes into .iconset then convert to .icns ─────────────

let iconsetPath = "Resources/AppIcon.iconset"
try! FileManager.default.createDirectory(atPath: iconsetPath,
     withIntermediateDirectories: true, attributes: nil)

let targets: [(Int, String)] = [
    (16,   "icon_16x16.png"),
    (32,   "icon_16x16@2x.png"),
    (32,   "icon_32x32.png"),
    (64,   "icon_32x32@2x.png"),
    (128,  "icon_128x128.png"),
    (256,  "icon_128x128@2x.png"),
    (256,  "icon_256x256.png"),
    (512,  "icon_256x256@2x.png"),
    (512,  "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

for (px, name) in targets {
    guard let ctx = CGContext(
            data: nil, width: px, height: px,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue
                      | CGImageAlphaInfo.premultipliedFirst.rawValue)
    else { fputs("⚠ ctx failed: \(name)\n", stderr); continue }

    ctx.scaleBy(x: CGFloat(px) / 512, y: CGFloat(px) / 512)
    drawIcon(ctx)

    guard let img  = ctx.makeImage() else { continue }
    let rep  = NSBitmapImageRep(cgImage: img)
    guard let png  = rep.representation(using: .png, properties: [:]) else { continue }
    try! png.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(name)"))
    print("✓ \(name)")
}

// Convert to .icns
let result = Process()
result.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
result.arguments = ["-c", "icns", iconsetPath, "-o", "Resources/AppIcon.icns"]
try! result.run(); result.waitUntilExit()

if result.terminationStatus == 0 {
    try? FileManager.default.removeItem(atPath: iconsetPath)
    print("\n✅  Resources/AppIcon.icns created")
} else {
    print("\n⚠  iconutil failed — .iconset left in place")
}
