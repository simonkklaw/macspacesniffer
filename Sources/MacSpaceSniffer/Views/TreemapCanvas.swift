import SwiftUI

struct TreemapCanvas: View {
    let layoutNodes: [LayoutNode]
    let hoveredNodeID: UUID?

    var body: some View {
        Canvas { context, _ in
            for layoutNode in layoutNodes {
                let r = layoutNode.rect
                guard r.width > 0, r.height > 0 else { continue }

                let path = Path(roundedRect: r, cornerRadius: 2)
                let fill = ColorAssigner.color(for: layoutNode.node)

                context.fill(path, with: .color(fill))
                context.stroke(path, with: .color(.black.opacity(0.18)), lineWidth: 0.5)

                if layoutNode.node.id == hoveredNodeID {
                    context.fill(path, with: .color(.white.opacity(0.22)))
                }

                // Need room for at least one text row (name) at top-left
                guard r.width > 40, r.height > 20 else { continue }

                let node = layoutNode.node
                let textX = r.minX + 6
                let nameY = r.minY + 8
                // Two rows fit when there's room below the name for a second line
                let showSize = r.height > 34

                let nameLabel = context.resolve(
                    Text(node.name)
                        .font(.caption2)
                        .foregroundStyle(Color.black.opacity(0.75))
                )
                let textSize = nameLabel.measure(in: CGSize(width: r.width - 12, height: r.height - 10))
                guard textSize.width <= r.width - 12 else { continue }

                context.draw(nameLabel, at: CGPoint(x: textX, y: nameY), anchor: .topLeading)

                if showSize {
                    let sizeLabel = context.resolve(
                        Text(ByteFormatter.string(node.totalSize))
                            .font(.caption2)
                            .foregroundStyle(Color.black.opacity(0.50))
                    )
                    let sizeWidth = sizeLabel.measure(in: CGSize(width: r.width - 12, height: 20)).width
                    if sizeWidth <= r.width - 12 {
                        context.draw(sizeLabel, at: CGPoint(x: textX, y: r.minY + 22), anchor: .topLeading)
                    }
                    // If size doesn't fit width-wise, name alone is already drawn above
                }
            }
        }
        .drawingGroup()
    }
}
