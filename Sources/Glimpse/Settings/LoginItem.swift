import Foundation
import ServiceManagement

/// Controls whether Glimpse launches automatically at login.
///
/// Wraps `SMAppService.mainApp`, which registers the running application as a
/// login item without requiring a separate helper bundle.
enum LoginItem {
    /// Whether the app is currently registered to launch at login.
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Registers or unregisters the app as a login item.
    ///
    /// Failures are logged rather than thrown: launch-at-login is a
    /// convenience and must never block the rest of the UI.
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("Glimpse: failed to update login item: \(error.localizedDescription)")
        }
    }
}
