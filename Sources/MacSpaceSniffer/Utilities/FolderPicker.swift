import AppKit

enum FolderPicker {
    @MainActor
    static func pick() async -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder to analyze disk usage"
        panel.prompt = "Analyze"
        return panel.runModal() == .OK ? panel.url : nil
    }
}
