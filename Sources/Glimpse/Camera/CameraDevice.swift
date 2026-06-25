import AVFoundation
import Foundation

/// A value-type description of a capture device.
///
/// Decoupling the rest of the app from `AVCaptureDevice` keeps camera logic
/// isolated and lets device discovery be mocked in tests.
struct CameraDevice: Identifiable, Hashable, Sendable {
    /// Stable unique identifier (`AVCaptureDevice.uniqueID`).
    let id: String
    /// Human-readable name shown in the configuration menu.
    let name: String

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    init(device: AVCaptureDevice) {
        self.id = device.uniqueID
        self.name = device.localizedName
    }
}
