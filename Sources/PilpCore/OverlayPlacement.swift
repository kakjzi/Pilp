import CoreGraphics

public enum OverlayPlacement {
    public static func bottomCenterOrigin(
        visibleFrame: CGRect,
        panelSize: CGSize,
        bottomInset: CGFloat = 24
    ) -> CGPoint {
        let preferredX = visibleFrame.midX - panelSize.width / 2
        let maximumX = visibleFrame.maxX - panelSize.width
        let x = maximumX >= visibleFrame.minX
            ? min(max(preferredX, visibleFrame.minX), maximumX)
            : visibleFrame.minX

        let preferredY = visibleFrame.minY + bottomInset
        let maximumY = visibleFrame.maxY - panelSize.height
        let y = maximumY >= visibleFrame.minY
            ? min(preferredY, maximumY)
            : visibleFrame.minY

        return CGPoint(x: x, y: y)
    }
}
