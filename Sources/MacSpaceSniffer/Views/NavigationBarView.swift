import SwiftUI

struct NavigationBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 6) {
            Button {
                appState.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderless)
            .disabled(!appState.isDone)
            .keyboardShortcut("r", modifiers: .command)
            .help("Refresh")

            Button {
                appState.navigateBack()
            } label: {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderless)
            .disabled(!appState.canGoBack)
            .keyboardShortcut("[", modifiers: .command)

            breadcrumb

            Spacer(minLength: 0)

            Button {
                Task {
                    if let url = await FolderPicker.pick() {
                        appState.startScan(url: url)
                    }
                }
            } label: {
                Image(systemName: "folder")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("o", modifiers: .command)
            .help("Open another folder")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var breadcrumb: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(Array(appState.navigationStack.enumerated()), id: \.offset) { index, node in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Button(node.name) {
                        appState.navigateTo(stackIndex: index)
                    }
                    .buttonStyle(.borderless)
                    .font(index == appState.navigationStack.count - 1 ? .body.bold() : .body)
                    .foregroundStyle(index == appState.navigationStack.count - 1 ? .primary : .secondary)
                }
            }
        }
    }
}
