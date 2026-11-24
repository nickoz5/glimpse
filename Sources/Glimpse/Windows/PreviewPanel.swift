import AppKit

/// Floating window that hosts the camera preview.
///
/// A titled panel with a transparent, full-size-content title bar: the video
/// fills the whole window and keeps the native rounded corners, shadow and
/// resize behaviour. The standard close/minimise/zoom buttons are hidden; the
/// hosted content supplies a single custom close button instead. Using a panel
/// (rather than a plain window) lets it float above other apps without
/// stealing key focus.
final class PreviewPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [
                .titled,
                .closable,
                .resizable,
                .fullSizeContentView,
                .nonactivatingPanel
            ],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Transparent title bar so the video fills the window, which keeps
        // its native rounded corners.
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        title = "Glimpse"
        backgroundColor = .clear
        isOpaque = false

        // No traffic lights: the content draws its own close button. The
        // (hidden) close button still exists, so ⌘W keeps working.
        for button in [.closeButton, .miniaturizeButton, .zoomButton] as [NSWindow.ButtonType] {
            standardWindowButton(button)?.isHidden = true
        }

        // Keep the preview usable even when shrunk aggressively.
        minSize = NSSize(width: 160, height: 120)
    }

    // Allow key status so the hosted SwiftUI controls (the close button)
    // remain interactive on a non-activating panel.
    override var canBecomeKey: Bool { true }
}
