import SwiftUI

struct ScanningView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            if case .scanning(let progress) = appState.scanState {
                Text("\(progress.filesScanned) items — \(ByteFormatter.string(progress.bytesFound))")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .font(.callout)
            }
        }
    }
}
