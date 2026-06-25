import CoreGraphics
import Foundation

/// Keys used to persist user preferences in `UserDefaults`.
enum PreferenceKey {
    static let selectedCameraID = "selectedCameraID"
    static let previewFrame = "previewFrame"
}

/// Persists lightweight user preferences.
///
/// Backed by `UserDefaults` but initialised with an injectable store so it can
/// be exercised in tests against an isolated suite.
final class Preferences {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Unique identifier of the camera the user last selected, if any.
    var selectedCameraID: String? {
        get { defaults.string(forKey: PreferenceKey.selectedCameraID) }
        set { defaults.set(newValue, forKey: PreferenceKey.selectedCameraID) }
    }

    /// Last known frame of the floating preview window, in screen coordinates.
    ///
    /// Returns `nil` when no frame has been saved, allowing callers to fall
    /// back to the default position beneath the menu bar icon.
    var previewFrame: CGRect? {
        get {
            guard let raw = defaults.string(forKey: PreferenceKey.previewFrame) else {
                return nil
            }
            return Self.decodeFrame(raw)
        }
        set {
            if let frame = newValue {
                defaults.set(Self.encodeFrame(frame), forKey: PreferenceKey.previewFrame)
            } else {
                defaults.removeObject(forKey: PreferenceKey.previewFrame)
            }
        }
    }

    // MARK: - Frame encoding

    /// Encodes a frame as a `"x y width height"` string.
    ///
    /// A plain string keeps the stored representation portable and easy to
    /// validate, avoiding the platform-specific `NSStringFromRect` formatting.
    static func encodeFrame(_ frame: CGRect) -> String {
        "\(frame.origin.x) \(frame.origin.y) \(frame.size.width) \(frame.size.height)"
    }

    /// Decodes a frame previously produced by ``encodeFrame(_:)``.
    ///
    /// Returns `nil` when the string is malformed or describes a non-positive
    /// size, so corrupt stored values cannot produce an unusable window.
    static func decodeFrame(_ raw: String) -> CGRect? {
        let parts = raw.split(separator: " ").compactMap { Double($0) }
        guard parts.count == 4 else { return nil }
        let size = CGSize(width: parts[2], height: parts[3])
        guard size.width > 0, size.height > 0 else { return nil }
        return CGRect(origin: CGPoint(x: parts[0], y: parts[1]), size: size)
    }
}
