import SwiftUI

// Each window owns its own AppState. AppWindowView is the per-window container.
struct AppWindowView: View {
    @State private var appState = AppState()

    var body: some View {
        ContentView()
            .environment(appState)
            .frame(minWidth: 600, minHeight: 400)
            .focusedSceneValue(\.appState, appState)
            .onAppear {
                // Pick up a URL queued by "Select Folder in New Window".
                if let url = AppState.consumePendingURL() {
                    appState.startScan(url: url)
                }
            }
    }
}
