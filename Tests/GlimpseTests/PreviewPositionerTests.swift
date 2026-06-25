import XCTest
@testable import Glimpse

final class PreviewPositionerTests: XCTestCase {
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

    func testDefaultFrameCentersUnderStatusItem() {
        let frame = PreviewPositioner.defaultFrame(
            statusItemMidX: 720,
            menuBarBottomY: 900,
            screen: screen,
            size: CGSize(width: 320, height: 240)
        )
        XCTAssertEqual(frame.midX, 720, accuracy: 0.001)
    }

    func testDefaultFrameSitsBeneathMenuBar() {
        let frame = PreviewPositioner.defaultFrame(
            statusItemMidX: 720,
            menuBarBottomY: 900,
            screen: screen
        )
        XCTAssertEqual(frame.maxY, 900, accuracy: 0.001)
    }

    func testDefaultFrameClampedWhenIconNearRightEdge() {
        let frame = PreviewPositioner.defaultFrame(
            statusItemMidX: 1435,
            menuBarBottomY: 900,
            screen: screen,
            size: CGSize(width: 320, height: 240)
        )
        XCTAssertLessThanOrEqual(frame.maxX, screen.maxX)
        XCTAssertGreaterThanOrEqual(frame.minX, screen.minX)
    }

    func testClampPushesFrameFullyOnScreen() {
        let offscreen = CGRect(x: -100, y: -100, width: 200, height: 200)
        let clamped = PreviewPositioner.clamp(offscreen, to: screen)
        XCTAssertGreaterThanOrEqual(clamped.minX, screen.minX)
        XCTAssertGreaterThanOrEqual(clamped.minY, screen.minY)
    }

    func testClampLeavesContainedFrameUnchanged() {
        let inside = CGRect(x: 100, y: 100, width: 200, height: 200)
        XCTAssertEqual(PreviewPositioner.clamp(inside, to: screen), inside)
    }
}
