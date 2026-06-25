import XCTest
@testable import Glimpse

final class PreferencesTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "com.glimpse.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testSelectedCameraIDRoundTrips() {
        let prefs = Preferences(defaults: defaults)
        XCTAssertNil(prefs.selectedCameraID)
        prefs.selectedCameraID = "cam-1"
        XCTAssertEqual(prefs.selectedCameraID, "cam-1")
    }

    func testPreviewFrameRoundTrips() {
        let prefs = Preferences(defaults: defaults)
        XCTAssertNil(prefs.previewFrame)
        let frame = CGRect(x: 12, y: 34, width: 320, height: 240)
        prefs.previewFrame = frame
        XCTAssertEqual(prefs.previewFrame, frame)
    }

    func testPreviewFrameClears() {
        let prefs = Preferences(defaults: defaults)
        prefs.previewFrame = CGRect(x: 1, y: 2, width: 3, height: 4)
        prefs.previewFrame = nil
        XCTAssertNil(prefs.previewFrame)
    }

    func testDecodeFrameRejectsMalformed() {
        XCTAssertNil(Preferences.decodeFrame("not a frame"))
        XCTAssertNil(Preferences.decodeFrame("1 2 3"))
        XCTAssertNil(Preferences.decodeFrame("1 2 0 100"), "zero width is invalid")
        XCTAssertNil(Preferences.decodeFrame("1 2 100 -5"), "negative height is invalid")
    }

    func testEncodeDecodeFrameAreInverse() {
        let frame = CGRect(x: -10.5, y: 20.25, width: 400, height: 300)
        let decoded = Preferences.decodeFrame(Preferences.encodeFrame(frame))
        XCTAssertEqual(decoded, frame)
    }
}
