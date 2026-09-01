import CoreGraphics

public enum OverlayDragRegion {
    public static func contains(
        _ point: CGPoint,
        panelSize: CGSize,
        excludesCenteredSearch: Bool,
        headerHeight: CGFloat = 58,
        searchExclusionSize: CGSize = CGSize(width: 260, height: 42)
    ) -> Bool {
        let effectiveHeaderHeight = min(max(headerHeight, 0), panelSize.height)
        let headerFrame = CGRect(
            x: 0,
            y: panelSize.height - effectiveHeaderHeight,
            width: panelSize.width,
            height: effectiveHeaderHeight
        )

        guard headerFrame.contains(point) else {
            return false
        }

        guard excludesCenteredSearch else {
            return true
        }

        let searchFrame = CGRect(
            x: panelSize.width / 2 - searchExclusionSize.width / 2,
            y: headerFrame.midY - searchExclusionSize.height / 2,
            width: searchExclusionSize.width,
            height: searchExclusionSize.height
        )
        return !searchFrame.contains(point)
    }
}
