import Foundation
import CoreGraphics

enum TreemapLayout {

    private typealias Item = (node: FileNode, size: UInt64)

    // Returns LayoutNodes for the direct children of `node` only —
    // grandchildren are computed on demand when the user drills in.
    static func layout(node: FileNode, in rect: CGRect, depth: Int = 0) -> [LayoutNode] {
        guard rect.width > 4, rect.height > 4 else { return [] }
        let children = node.children.filter { $0.totalSize > 0 }
        guard !children.isEmpty else { return [] }

        let sorted = children.sorted { $0.totalSize > $1.totalSize }
        guard sorted.first!.totalSize > 0 else { return [] }

        // Use natural log of byte count as the layout weight so extreme size ratios
        // (e.g. 800:1 linear) compress to a visually manageable range (~1.5:1 log).
        // Multiply by 1_000_000 to retain fractional precision in UInt64 arithmetic.
        let logScale: Double = 1_000_000
        let items: [Item] = sorted.map { node in
            let w = UInt64(max(1.0, log(Double(node.totalSize) + 1) * logScale))
            return (node: node, size: w)
        }
        let logTotal = items.reduce(UInt64(0)) { $0 + $1.size }
        guard logTotal > 0 else { return [] }

        // Minimum strip thickness to be visible: 8 logical pixels in the longer axis.
        let minPx: Double = 8.0
        let longer = Double(max(rect.width, rect.height))

        // Split items into those with enough log-proportion (main) and those too
        // small to appear at proportional scale (tiny). Tiny items are placed in a
        // reserved sidebar strip so they always remain visible regardless of size ratio.
        var main: [Item] = []
        var tiny: [Item] = []
        for item in items {
            if Double(item.size) / Double(logTotal) * longer >= minPx {
                main.append(item)
            } else {
                tiny.append(item)
            }
        }

        if tiny.isEmpty {
            return squarify(items, total: logTotal, in: rect, depth: depth)
        }

        // Sidebar: one minPx-wide slot per tiny item, capped at 20% of the display.
        let sidebarThickness = min(Double(tiny.count) * minPx, longer * 0.20)
        let isLandscape = rect.width >= rect.height

        let mainRect: CGRect
        let sideRect: CGRect

        if isLandscape {
            mainRect = CGRect(x: rect.minX, y: rect.minY,
                              width: rect.width - sidebarThickness, height: rect.height)
            sideRect = CGRect(x: rect.maxX - sidebarThickness, y: rect.minY,
                              width: sidebarThickness, height: rect.height)
        } else {
            mainRect = CGRect(x: rect.minX, y: rect.minY,
                              width: rect.width, height: rect.height - sidebarThickness)
            sideRect = CGRect(x: rect.minX, y: rect.maxY - sidebarThickness,
                              width: rect.width, height: sidebarThickness)
        }

        var result: [LayoutNode] = []

        if !main.isEmpty {
            let mainTotal = main.reduce(UInt64(0)) { $0 + $1.size }
            result += squarify(main, total: mainTotal, in: mainRect, depth: depth)
        }

        // Stack tiny items in the sidebar with equal allocation; cap at what actually fits.
        let sidebarLong = isLandscape ? sideRect.height : sideRect.width
        let minItemLen = 6.0
        let maxShown = max(1, Int(sidebarLong / minItemLen))
        let shownTiny = Array(tiny.prefix(maxShown))
        let eachLen = sidebarLong / Double(shownTiny.count)

        for (i, item) in shownTiny.enumerated() {
            let raw: CGRect = isLandscape
                ? CGRect(x: sideRect.minX, y: sideRect.minY + Double(i) * eachLen,
                         width: sideRect.width, height: eachLen)
                : CGRect(x: sideRect.minX + Double(i) * eachLen, y: sideRect.minY,
                         width: eachLen, height: sideRect.height)
            let inset = raw.insetBy(dx: 1, dy: 1)
            if inset.width > 2, inset.height > 2 {
                result.append(LayoutNode(node: item.node, rect: inset, depth: depth))
            }
        }

        return result
    }

    // MARK: - Squarified treemap (Bruls, Huizing, van Wijk 2000)

    private static func squarify(
        _ items: [Item], total: UInt64, in rect: CGRect, depth: Int
    ) -> [LayoutNode] {
        var result: [LayoutNode] = []
        var remaining = items[...]
        var currentRect = rect
        var remainingTotal = total
        var strip: [Item] = []

        while !remaining.isEmpty {
            let candidate = remaining.first!
            let newStrip = strip + [candidate]

            if strip.isEmpty
                || worstRatio(newStrip, in: currentRect, of: remainingTotal)
                <= worstRatio(strip, in: currentRect, of: remainingTotal) {
                strip.append(candidate)
                remaining = remaining.dropFirst()
            } else {
                let sum = stripTotal(strip)
                result += commitStrip(strip, stripSum: sum, total: remainingTotal, in: currentRect, depth: depth)
                currentRect = shrink(currentRect, by: sum, of: remainingTotal)
                remainingTotal -= sum
                strip = []
            }
        }

        if !strip.isEmpty {
            let sum = stripTotal(strip)
            result += commitStrip(strip, stripSum: sum, total: remainingTotal, in: currentRect, depth: depth)
        }

        return result
    }

    // Worst aspect ratio of any rectangle in `strip` given the current layout rect.
    // `total` is the combined size of all items not yet committed (strip + remaining).
    private static func worstRatio(_ strip: [Item], in rect: CGRect, of total: UInt64) -> Double {
        let shorter = Double(min(rect.width, rect.height))
        let longer  = Double(max(rect.width, rect.height))
        guard shorter > 0, longer > 0, total > 0 else { return .infinity }

        let sSum = Double(stripTotal(strip))
        let t = sSum / Double(total) * longer   // strip thickness

        guard t > 0 else { return .infinity }
        var worst = 0.0
        for item in strip {
            let len = Double(item.size) / sSum * shorter
            guard len > 0 else { continue }
            worst = max(worst, max(t, len) / min(t, len))
        }
        return worst
    }

    // Emit LayoutNodes for the committed strip and apply the 1pt inset border.
    private static func commitStrip(
        _ strip: [Item], stripSum: UInt64, total: UInt64,
        in rect: CGRect, depth: Int
    ) -> [LayoutNode] {
        let shorter = Double(min(rect.width, rect.height))
        let longer  = Double(max(rect.width, rect.height))
        guard shorter > 0, longer > 0, total > 0 else { return [] }

        let isLandscape = rect.width >= rect.height
        let t = Double(stripSum) / Double(total) * longer

        var nodes: [LayoutNode] = []
        var offset = 0.0

        for item in strip {
            let len = Double(item.size) / Double(stripSum) * shorter
            let raw: CGRect = isLandscape
                ? CGRect(x: rect.minX,          y: rect.minY + offset, width: t,   height: len)
                : CGRect(x: rect.minX + offset, y: rect.minY,          width: len, height: t)

            let inset = raw.insetBy(dx: 1, dy: 1)
            if inset.width > 2, inset.height > 2 {
                nodes.append(LayoutNode(node: item.node, rect: inset, depth: depth))
            }
            offset += len
        }

        return nodes
    }

    // Remove the just-committed strip's area from the working rect.
    private static func shrink(_ rect: CGRect, by stripSum: UInt64, of total: UInt64) -> CGRect {
        let longer = Double(max(rect.width, rect.height))
        let t = Double(stripSum) / Double(total) * longer
        return rect.width >= rect.height
            ? CGRect(x: rect.minX + t, y: rect.minY, width: rect.width - t, height: rect.height)
            : CGRect(x: rect.minX, y: rect.minY + t, width: rect.width, height: rect.height - t)
    }

    private static func stripTotal(_ strip: [Item]) -> UInt64 {
        strip.reduce(UInt64(0)) { $0 + $1.size }
    }
}
