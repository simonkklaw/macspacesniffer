import SwiftUI

private let tooltipText = Color(red: 0.878, green: 0.878, blue: 0.878)  // #E0E0E0

struct TooltipView: View {
    let node: FileNode

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(node.name)
                .font(.caption.bold())
                .foregroundStyle(tooltipText)
                .lineLimit(2)
            Text(ByteFormatter.string(node.totalSize))
                .font(.caption)
                .foregroundStyle(tooltipText.opacity(0.80))
            if node.isDirectory {
                Text("\(node.children.count) items")
                    .font(.caption2)
                    .foregroundStyle(tooltipText.opacity(0.60))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: 200, alignment: .leading)
        .background(Color(red: 0.12, green: 0.12, blue: 0.12).opacity(0.88),
                    in: RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
    }
}
