import AppKit

/// Application lifecycle owner.
///
/// Configures the app as a menu bar accessory (no Dock icon) and wires up the
/// status item, camera manager and preferences.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private let preferences = Preferences()
    private lazy var camera = CameraManager(preferences: preferences)

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar utility: no Dock icon, no app menu.
        NSApp.setActivationPolicy(.accessory)
        statusItemController = StatusItemController(camera: camera, preferences: preferences)
    }

    func applicationWillTerminate(_ notification: Notification) {
        camera.stop()
    }
}
