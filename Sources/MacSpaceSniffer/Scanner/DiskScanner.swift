import Foundation

actor DiskScanner {

    func scan(url: URL) -> AsyncStream<FileNode> {
        AsyncStream { continuation in
            Task.detached(priority: .userInitiated) { [self] in
                let root = await self.scanImpl(url: url, continuation: continuation)
                continuation.yield(root)
                continuation.finish()
            }
        }
    }

    private func scanImpl(url: URL, continuation: AsyncStream<FileNode>.Continuation) -> FileNode {
        let rootName = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
        let root = FileNode(name: rootName, url: url, isDirectory: true)
        var nodeMap: [URL: FileNode] = [url.standardized: root]
        var lastYieldTime = Date()

        let resourceKeys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .isDirectoryKey, .isHiddenKey]

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: resourceKeys,
            options: []
        ) else {
            return root
        }

        for case let fileURL as URL in enumerator {
            do {
                let values = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                let isDir = values.isDirectory ?? false
                let allocatedSize = UInt64(values.totalFileAllocatedSize ?? 0)
                let isHidden = values.isHidden ?? fileURL.lastPathComponent.hasPrefix(".")

                let node = FileNode(
                    name: fileURL.lastPathComponent,
                    url: fileURL,
                    isDirectory: isDir,
                    size: isDir ? 0 : allocatedSize
                )
                node.isHidden = isHidden

                let parentURL = fileURL.deletingLastPathComponent().standardized
                if let parent = nodeMap[parentURL] {
                    node.parent = parent
                    parent.children.append(node)

                    if !isDir {
                        var ancestor: FileNode? = parent
                        while let current = ancestor {
                            current.totalSize += allocatedSize
                            ancestor = current.parent
                        }
                    }
                }

                if isDir {
                    nodeMap[fileURL.standardized] = node
                }

                let now = Date()
                if now.timeIntervalSince(lastYieldTime) > 0.5 {
                    continuation.yield(root)
                    lastYieldTime = now
                }
            } catch {
                continue
            }
        }

        return root
    }
}
