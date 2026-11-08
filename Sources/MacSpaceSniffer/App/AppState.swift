import SwiftUI
import Observation

@MainActor
@Observable
final class AppState {
    var scanState: ScanState = .idle
    var navigationStack: [FileNode] = []
    var layout: [LayoutNode] = []
    var hoveredNode: FileNode? = nil
    var includeFreeSpace: Bool = false {
        didSet { recomputeLayout() }
    }

    private var currentRect: CGRect = .zero
    private let scanner = DiskScanner()
    private var scanTask: Task<Void, Never>?
    private var freeSpaceNode: FileNode? = nil
    var driveTotalCapacity: UInt64 = 0

    var currentRoot: FileNode? { navigationStack.last }
    var canGoBack: Bool { navigationStack.count > 1 }
    var isDone: Bool { if case .done = scanState { return true }; return false }

    // Free-space toggle is only meaningful when showing the filesystem root.
    var canToggleFreeSpace: Bool {
        isDone && navigationStack.first?.url.path == "/"
    }

    // MARK: - New-window handoff

    private static var pendingURL: URL? = nil

    static func setPendingURL(_ url: URL) { pendingURL = url }

    static func consumePendingURL() -> URL? {
        defer { pendingURL = nil }
        return pendingURL
    }

    // MARK: - Scanning

    func refresh() {
        guard let url = currentRoot?.url else { return }
        startScan(url: url)
    }

    func startScan(url: URL) {
        scanTask?.cancel()
        navigationStack = []
        layout = []
        computeDriveInfo(for: url)
        scanState = .scanning(ScanProgress())

        scanTask = Task {
            for await snapshot in await scanner.scan(url: url) {
                guard !Task.isCancelled else { return }
                navigationStack = [snapshot]
                layout = currentRect.isEmpty ? [] : TreemapLayout.layout(node: effectiveRoot(snapshot), in: currentRect)
                scanState = .scanning(ScanProgress(filesScanned: snapshot.children.count, bytesFound: snapshot.totalSize))
            }
            guard !Task.isCancelled, let root = navigationStack.first else { return }
            layout = currentRect.isEmpty ? [] : TreemapLayout.layout(node: effectiveRoot(root), in: currentRect)
            scanState = .done
        }
    }

    // MARK: - Navigation

    func drillDown(into node: FileNode) {
        guard node.isDirectory, !node.children.isEmpty else { return }
        navigationStack.append(node)
        recomputeLayout()
    }

    func navigateBack() {
        guard canGoBack else { return }
        navigationStack.removeLast()
        recomputeLayout()
    }

    func navigateTo(stackIndex index: Int) {
        guard index < navigationStack.count else { return }
        navigationStack = Array(navigationStack.prefix(index + 1))
        recomputeLayout()
    }

    func updateRect(_ rect: CGRect) {
        guard rect.width > 0, rect.height > 0, rect != currentRect else { return }
        currentRect = rect
        recomputeLayout()
    }

    // MARK: - Layout

    private func recomputeLayout() {
        guard let root = currentRoot, !currentRect.isEmpty else { return }
        layout = TreemapLayout.layout(node: effectiveRoot(root), in: currentRect)
    }

    // Injects the free-space node as a sibling of real children when at top level.
    private func effectiveRoot(_ base: FileNode) -> FileNode {
        guard includeFreeSpace,
              navigationStack.count == 1,
              navigationStack.first?.url.path == "/",
              let freeNode = freeSpaceNode else {
            return base
        }
        let synthetic = FileNode(name: base.name, url: base.url, isDirectory: true)
        synthetic.totalSize = base.totalSize + freeNode.totalSize
        synthetic.children = base.children + [freeNode]
        return synthetic
    }

    // volumeAvailableCapacityForImportantUsage matches what Finder shows as "Available"
    // (includes purgeable space). NSFileSystemFreeSize excludes purgeable, hence the ~30 GB gap.
    private func computeDriveInfo(for url: URL) {
        let keys: Set<URLResourceKey> = [
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeTotalCapacityKey
        ]
        guard let values = try? url.resourceValues(forKeys: keys) else {
            freeSpaceNode = nil
            driveTotalCapacity = 0
            return
        }

        if let total = values.volumeTotalCapacity, total > 0 {
            driveTotalCapacity = UInt64(total)
        }

        guard let free = values.volumeAvailableCapacityForImportantUsage, free > 0 else {
            freeSpaceNode = nil
            return
        }
        let node = FileNode(
            name: "Free Space",
            url: url.appendingPathComponent(".free_space_sentinel"),
            isDirectory: false,
            size: UInt64(free)
        )
        node.isFreeSpace = true
        freeSpaceNode = node
    }
}
