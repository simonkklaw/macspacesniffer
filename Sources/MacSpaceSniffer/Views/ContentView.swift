import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        switch appState.scanState {
        case .idle:
            WelcomeView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .scanning(_):
            ScanningView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .done:
            VStack(spacing: 0) {
                NavigationBarView()
                    .background(.bar)
                Divider()
                TreemapView()
                Divider()
                StatusBarView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .error(let message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
                Text(message)
                    .foregroundStyle(.secondary)
                Button("Try Again") { appState.scanState = .idle }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
