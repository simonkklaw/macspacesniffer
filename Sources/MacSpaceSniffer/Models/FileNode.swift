import Foundation

final class FileNode: Identifiable, @unchecked Sendable {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    var totalSize: UInt64
    var children: [FileNode]
    weak var parent: FileNode?
    var isFreeSpace: Bool = false
    var isHidden: Bool = false

    init(name: String, url: URL, isDirectory: Bool, size: UInt64 = 0) {
        self.name = name
        self.url = url
        self.isDirectory = isDirectory
        self.totalSize = size
        self.children = []
    }
}
