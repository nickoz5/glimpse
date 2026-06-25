import AppKit
import SwiftUI

/// Manages the floating preview window: its content, visibility, position,
/// persisted frame, and the camera lifecycle tied to its visibility.
@MainActor
final class PreviewWindowController: NSObject, NSWindowDelegate {
    private let preferences: Preferences
    private var panel: PreviewPanel?

    /// Supplies the horizontal centre of the status item so the window can be
    /// positioned beneath it on first show.
    var statusItemMidXProvider: (() -> CGFloat?)?

    /// Called when the window becomes visible; start the camera here.
    var onShow: (() -> Void)?
    /// Called when the window is hidden (toggle, close, or minimise); stop the
    /// camera here so the capture LED turns off.
    var onHide: (() -> Void)?

    init(preferences: Preferences) {
        self.preferences = preferences
        super.init()
    }

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    /// Shows the window if hidden, hides it if visible.
    func toggle<Content: View>(@ViewBuilder content: () -> Content) {
        if isVisible {
            hide()
        } else {
            show(content: content())
        }
    }

    /// Shows the window, creating it on first use and restoring its saved frame.
    func show<Content: View>(content: Content) {
        let panel = panel ?? makePanel(content: content)
        self.panel = panel
        panel.setFrame(resolvedFrame(for: panel), display: true)
        panel.makeKeyAndOrderFront(nil)
        onShow?()
    }

    /// Hides the window and stops the camera.
    func hide() {
        guard isVisible else { return }
        panel?.orderOut(nil)
        onHide?()
    }

    /// Resets the window to its default size and position beneath the menu bar.
    func resetFrame() {
        preferences.previewFrame = nil
        guard let panel else { return }
        panel.setFrame(defaultFrame(), display: true, animate: true)
        persistFrame()
    }

    // MARK: - NSWindowDelegate

    /// Intercept the red close button: hide (and stop the camera) instead of
    /// destroying the window, so it can be re-shown from the menu bar.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hide()
        return false
    }

    func windowDidMove(_ notification: Notification) {
        persistFrame()
    }

    func windowDidResize(_ notification: Notification) {
        persistFrame()
    }

    // MARK: - Private

    private func makePanel<Content: View>(content: Content) -> PreviewPanel {
        let initial = preferences.previewFrame ?? defaultFrame()
        let panel = PreviewPanel(contentRect: initial)
        panel.delegate = self

        let hosting = NSHostingView(rootView: content)
        hosting.frame = panel.contentLayoutRect
        hosting.autoresizingMask = [.width, .height]
        panel.contentView?.addSubview(hosting)

        // The yellow miniaturise button has no useful target on a Dock-less
        // app, so repurpose it to hide the window (and stop the camera) too.
        if let minimise = panel.standardWindowButton(.miniaturizeButton) {
            minimise.target = self
            minimise.action = #selector(miniaturiseButtonClicked)
        }
        return panel
    }

    @objc private func miniaturiseButtonClicked() {
        hide()
    }

    /// Returns the saved frame if present, otherwise the default, clamped to
    /// the screen the window would appear on.
    private func resolvedFrame(for panel: PreviewPanel) -> CGRect {
        if let saved = preferences.previewFrame {
            let screen = screenContaining(saved) ?? NSScreen.main?.visibleFrame ?? saved
            return PreviewPositioner.clamp(saved, to: screen)
        }
        return defaultFrame()
    }

    private func defaultFrame() -> CGRect {
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let midX = statusItemMidXProvider?() ?? screen.midX
        return PreviewPositioner.defaultFrame(
            statusItemMidX: midX,
            menuBarBottomY: screen.maxY,
            screen: screen
        )
    }

    private func screenContaining(_ frame: CGRect) -> CGRect? {
        NSScreen.screens.first { $0.frame.intersects(frame) }?.visibleFrame
    }

    private func persistFrame() {
        guard let panel else { return }
        preferences.previewFrame = panel.frame
    }
}
