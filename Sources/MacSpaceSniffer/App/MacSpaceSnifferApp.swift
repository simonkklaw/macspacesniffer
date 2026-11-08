import SwiftUI

@main
struct MacSpaceSnifferApp: App {
    var body: some Scene {
        WindowGroup("Mac Space Sniffer", id: "main") {
            AppWindowView()
        }
        .defaultSize(width: 1000, height: 700)
        .commands {
            MacSpaceSnifferCommands()
        }
    }
}
