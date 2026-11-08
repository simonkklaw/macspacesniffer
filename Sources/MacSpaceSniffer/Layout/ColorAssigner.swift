import SwiftUI

enum ColorAssigner {
    static func color(for node: FileNode) -> Color {
        if node.isFreeSpace {
            return Color(red: 0.8,  green: 0.8,  blue: 0.8)   // #CCCCCC
        } else if node.isDirectory {
            return node.isHidden
                ? Color(red: 0.8,  green: 0.6,  blue: 0.4)   // #CC9966
                : Color(red: 1.0,  green: 0.8,  blue: 0.6)   // #FFCC99
        } else {
            return node.isHidden
                ? Color(red: 0.4,  green: 0.6,  blue: 0.8)   // #6699CC
                : Color(red: 0.6,  green: 0.8,  blue: 1.0)   // #99CCFF
        }
    }
}
