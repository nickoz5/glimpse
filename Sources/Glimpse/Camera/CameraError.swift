import Foundation

/// User-facing camera failures, each carrying an explanation suitable for the
/// native error view.
enum CameraError: Equatable, Sendable {
    /// Camera access has not been granted.
    case accessDenied
    /// No capture devices were found.
    case noDevicesFound
    /// The selected device could not be opened for capture.
    case deviceUnavailable

    /// Short headline shown in the error view.
    var title: String {
        switch self {
        case .accessDenied: return "Camera Access Needed"
        case .noDevicesFound: return "No Camera Found"
        case .deviceUnavailable: return "Camera Unavailable"
        }
    }

    /// Clear explanation of the failure and how to resolve it.
    var message: String {
        switch self {
        case .accessDenied:
            return "Glimpse needs permission to use the camera. Grant access in System Settings › Privacy & Security › Camera."
        case .noDevicesFound:
            return "Connect a camera and try again."
        case .deviceUnavailable:
            return "The selected camera could not be started. It may be in use by another app."
        }
    }

    /// Whether the failure can be resolved from System Settings.
    var isPermissionError: Bool {
        self == .accessDenied
    }
}
