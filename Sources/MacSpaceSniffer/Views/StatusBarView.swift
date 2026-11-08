import SwiftUI

struct StatusBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack {
            if let root = appState.currentRoot {
                Text(folderLabel(root))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer()

            if appState.driveTotalCapacity > 0 {
                Text("Disk total: \(ByteFormatter.string(appState.driveTotalCapacity))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(.bar)
    }

    private func folderLabel(_ root: FileNode) -> String {
        "\(root.name): \(ByteFormatter.string(root.totalSize))"
    }
}
