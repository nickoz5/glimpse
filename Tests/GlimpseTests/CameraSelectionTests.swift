import XCTest
@testable import Glimpse

final class CameraSelectionTests: XCTestCase {
    private let devices = [
        CameraDevice(id: "a", name: "FaceTime HD"),
        CameraDevice(id: "b", name: "External Webcam")
    ]

    func testPrefersSavedCameraWhenAvailable() {
        let chosen = CameraSelection.resolve(available: devices, preferredID: "b")
        XCTAssertEqual(chosen?.id, "b")
    }

    func testFallsBackToFirstWhenPreferredMissing() {
        let chosen = CameraSelection.resolve(available: devices, preferredID: "gone")
        XCTAssertEqual(chosen?.id, "a")
    }

    func testFallsBackToFirstWhenNoPreference() {
        let chosen = CameraSelection.resolve(available: devices, preferredID: nil)
        XCTAssertEqual(chosen?.id, "a")
    }

    func testReturnsNilWhenNoDevices() {
        XCTAssertNil(CameraSelection.resolve(available: [], preferredID: "a"))
    }
}

/// Verifies a mock discovery source can stand in for real hardware, satisfying
/// the AGENTS.md guidance to mock camera devices where practical.
final class CameraDiscoveryMockTests: XCTestCase {
    struct MockDiscovery: CameraDiscovering {
        let devices: [CameraDevice]
        func availableCameras() -> [CameraDevice] { devices }
    }

    func testMockDiscoveryFeedsSelection() {
        let mock = MockDiscovery(devices: [CameraDevice(id: "x", name: "Mock Cam")])
        let chosen = CameraSelection.resolve(
            available: mock.availableCameras(),
            preferredID: nil
        )
        XCTAssertEqual(chosen?.name, "Mock Cam")
    }
}
