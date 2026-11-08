import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "internaldrive")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Mac Space Sniffer")
                .font(.largeTitle.bold())
            Text("Visualize disk space usage")
                .foregroundStyle(.secondary)
            Button("Choose Folder…") {
                Task {
                    if let url = await FolderPicker.pick() {
                        appState.startScan(url: url)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}
