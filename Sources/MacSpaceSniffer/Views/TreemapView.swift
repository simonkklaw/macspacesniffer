import SwiftUI

struct TreemapView: View {
    @Environment(AppState.self) private var appState
    @State private var mouseLocation: CGPoint = .zero

    var body: some View {
        GeometryReader { geo in
            TreemapCanvas(
                layoutNodes: appState.layout,
                hoveredNodeID: appState.hoveredNode?.id
            )
            .onTapGesture { location in
                guard let tapped = appState.layout.first(where: { $0.rect.contains(location) }) else { return }
                appState.drillDown(into: tapped.node)
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    mouseLocation = location
                    appState.hoveredNode = appState.layout.first(where: { $0.rect.contains(location) })?.node
                case .ended:
                    appState.hoveredNode = nil
                    mouseLocation = .zero
                }
            }
            .onChange(of: geo.size) { _, newSize in
                appState.updateRect(CGRect(origin: .zero, size: newSize))
            }
            .onAppear {
                appState.updateRect(CGRect(origin: .zero, size: geo.size))
            }
            .overlay(alignment: .topLeading) {
                if let hovered = appState.hoveredNode {
                    TooltipView(node: hovered)
                        .offset(
                            x: min(mouseLocation.x + 14, geo.size.width - 215),
                            y: min(mouseLocation.y + 14, geo.size.height - 80)
                        )
                        .allowsHitTesting(false)
                }
            }
        }
    }
}
