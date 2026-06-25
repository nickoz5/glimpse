import AVFoundation
import Foundation

/// Supplies the set of available cameras.
///
/// Abstracting discovery behind a protocol allows tests to inject deterministic
/// device lists without touching real hardware.
protocol CameraDiscovering: Sendable {
    func availableCameras() -> [CameraDevice]
}

/// Discovers cameras using `AVCaptureDevice.DiscoverySession`.
struct AVCameraDiscovery: CameraDiscovering {
    func availableCameras() -> [CameraDevice] {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .external,
                .continuityCamera
            ],
            mediaType: .video,
            position: .unspecified
        )
        return session.devices.map(CameraDevice.init(device:))
    }
}

/// Chooses which camera to start, given the available devices and the user's
/// previously selected camera.
///
/// Pure function so the selection rules can be unit tested in isolation.
enum CameraSelection {
    static func resolve(
        available: [CameraDevice],
        preferredID: String?
    ) -> CameraDevice? {
        if let preferredID,
           let match = available.first(where: { $0.id == preferredID }) {
            return match
        }
        return available.first
    }
}
