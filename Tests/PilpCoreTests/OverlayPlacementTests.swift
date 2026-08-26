import Foundation
import Testing
@testable import PilpCore

@Suite("Overlay placement")
struct OverlayPlacementTests {
    @Test("places the overlay above the bottom edge and centers it horizontally")
    func placesOverlayAtBottomCenter() {
        let origin = OverlayPlacement.bottomCenterOrigin(
            visibleFrame: CGRect(x: 100, y: 80, width: 1_440, height: 900),
            panelSize: CGSize(width: 920, height: 340),
            bottomInset: 24
        )

        #expect(origin == CGPoint(x: 360, y: 104))
    }
}
