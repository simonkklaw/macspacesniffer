import SwiftUI

struct MacSpaceSnifferCommands: Commands {
    @FocusedValue(\.appState) private var focusedAppState
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        // MARK: File menu
        CommandGroup(replacing: .newItem) {
            Button("Select Folder in Current Window") {
                Task { @MainActor in
                    guard let state = focusedAppState else { return }
                    if let url = await FolderPicker.pick() {
                        state.startScan(url: url)
                    }
                }
            }
            .keyboardShortcut("o", modifiers: .command)
            .disabled(focusedAppState == nil)

            Button("Select Folder in New Window") {
                Task { @MainActor in
                    if let url = await FolderPicker.pick() {
                        AppState.setPendingURL(url)
                        openWindow(id: "main")
                    }
                }
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        // MARK: View menu — appended to the system View menu (avoids a duplicate "View" entry)
        CommandGroup(after: .toolbar) {
            Toggle(isOn: Binding(
                get: { focusedAppState?.includeFreeSpace ?? false },
                set: { focusedAppState?.includeFreeSpace = $0 }
            )) {
                Text("Include Free Space")
            }
            .disabled(!(focusedAppState?.canToggleFreeSpace ?? false))
        }
    }
}
