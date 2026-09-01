import Foundation
import Testing
@testable import PilpCore

@Suite("Overlay drag region")
struct OverlayDragRegionTests {
    @Test("uses the header as a drag region without stealing search input")
    func identifiesDraggableHeaderPoints() {
        let panelSize = CGSize(width: 920, height: 340)

        #expect(OverlayDragRegion.contains(
            CGPoint(x: 180, y: 310),
            panelSize: panelSize,
            excludesCenteredSearch: true
        ))
        #expect(!OverlayDragRegion.contains(
            CGPoint(x: 460, y: 310),
            panelSize: panelSize,
            excludesCenteredSearch: true
        ))
        #expect(OverlayDragRegion.contains(
            CGPoint(x: 460, y: 310),
            panelSize: panelSize,
            excludesCenteredSearch: false
        ))
        #expect(!OverlayDragRegion.contains(
            CGPoint(x: 180, y: 250),
            panelSize: panelSize,
            excludesCenteredSearch: false
        ))
    }
}
