import AppKit
import SwiftUI

/// Owns the menu bar status item and routes clicks.
///
/// Left-click toggles the floating preview; right-click (or control-click)
/// opens a native configuration menu. `NSStatusItem` is used directly because
/// `MenuBarExtra` cannot distinguish click types or drive a separate floating
/// window.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let camera: CameraManager
    private let preferences: Preferences
    private let windowController: PreviewWindowController

    init(camera: CameraManager, preferences: Preferences) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.camera = camera
        self.preferences = preferences
        self.windowController = PreviewWindowController(preferences: preferences)
        super.init()

        configureButton()
        windowController.statusItemMidXProvider = { [weak self] in
            self?.statusItemMidX()
        }
        // Tie the camera lifecycle to the window's visibility so the capture
        // session — and the camera LED — stops whenever the window is hidden.
        windowController.onShow = { [weak self] in
            guard let self else { return }
            Task { await self.camera.start() }
        }
        windowController.onHide = { [weak self] in
            self?.camera.stop()
        }
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.image = MenuBarIcon.make()
        button.target = self
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    // MARK: - Click handling

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true

        if isRightClick {
            presentMenu()
        } else {
            togglePreview()
        }
    }

    private func togglePreview() {
        windowController.toggle {
            PreviewContentView(camera: camera)
        }
    }

    // MARK: - Menu

    private func presentMenu() {
        // Ensure the device list is current even if the preview was never opened.
        camera.refreshCameras()
        let menu = ConfigurationMenuBuilder.build(
            cameras: camera.cameras,
            activeCameraID: camera.activeCameraID,
            launchAtLogin: LoginItem.isEnabled,
            target: self,
            selectCamera: #selector(selectCamera(_:)),
            toggleLaunchAtLogin: #selector(toggleLaunchAtLogin(_:)),
            resetWindow: #selector(resetWindow(_:)),
            quit: #selector(quit(_:))
        )
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func selectCamera(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        Task { await camera.select(cameraID: id) }
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        LoginItem.setEnabled(!LoginItem.isEnabled)
    }

    @objc private func resetWindow(_ sender: NSMenuItem) {
        windowController.resetFrame()
    }

    @objc private func quit(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }

    // MARK: - Geometry

    /// Horizontal centre of the status item button in screen coordinates.
    private func statusItemMidX() -> CGFloat? {
        guard
            let button = statusItem.button,
            let window = button.window
        else { return nil }
        let rectInWindow = button.convert(button.bounds, to: nil)
        let rectInScreen = window.convertToScreen(rectInWindow)
        return rectInScreen.midX
    }
}
