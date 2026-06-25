import XCTest
@testable import Glimpse

final class CameraErrorTests: XCTestCase {
    func testEveryErrorHasTitleAndMessage() {
        for error in [CameraError.accessDenied, .noDevicesFound, .deviceUnavailable] {
            XCTAssertFalse(error.title.isEmpty)
            XCTAssertFalse(error.message.isEmpty)
        }
    }

    func testOnlyAccessDeniedIsPermissionError() {
        XCTAssertTrue(CameraError.accessDenied.isPermissionError)
        XCTAssertFalse(CameraError.noDevicesFound.isPermissionError)
        XCTAssertFalse(CameraError.deviceUnavailable.isPermissionError)
    }
}
