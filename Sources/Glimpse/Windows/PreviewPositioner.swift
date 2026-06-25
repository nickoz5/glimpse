import CoreGraphics
import Foundation

/// Pure geometry helpers for placing the floating preview window.
///
/// Separated from AppKit so the positioning rules can be unit tested without a
/// running screen or status item.
enum PreviewPositioner {
    /// Default size of the preview window.
    static let defaultSize = CGSize(width: 320, height: 240)

    /// Computes the default frame: horizontally centred under the status item
    /// and just beneath the menu bar, clamped to stay on screen.
    ///
    /// - Parameters:
    ///   - statusItemMidX: Horizontal centre of the status item, in screen
    ///     coordinates.
    ///   - menuBarBottomY: The y-coordinate of the bottom of the menu bar
    ///     (top of the usable screen area), in screen coordinates.
    ///   - screen: Visible frame of the target screen.
    ///   - size: Desired window size.
    static func defaultFrame(
        statusItemMidX: CGFloat,
        menuBarBottomY: CGFloat,
        screen: CGRect,
        size: CGSize = defaultSize
    ) -> CGRect {
        let originX = statusItemMidX - size.width / 2
        let originY = menuBarBottomY - size.height
        let frame = CGRect(x: originX, y: originY, width: size.width, height: size.height)
        return clamp(frame, to: screen)
    }

    /// Constrains `frame` so it stays fully within `bounds`.
    ///
    /// If the frame is larger than the bounds it is pinned to the origin so the
    /// top-left remains visible.
    static func clamp(_ frame: CGRect, to bounds: CGRect) -> CGRect {
        var result = frame
        if result.maxX > bounds.maxX {
            result.origin.x = bounds.maxX - result.width
        }
        if result.minX < bounds.minX {
            result.origin.x = bounds.minX
        }
        if result.maxY > bounds.maxY {
            result.origin.y = bounds.maxY - result.height
        }
        if result.minY < bounds.minY {
            result.origin.y = bounds.minY
        }
        return result
    }
}
