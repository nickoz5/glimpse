import AppKit

/// Floating window that hosts the camera preview.
///
/// A titled panel with a transparent, full-size-content title bar: the video
/// fills the whole window and the native close/minimise/zoom buttons overlay
/// its top-left corner. Using a panel (rather than a plain window) lets it
/// float above other apps without stealing key focus.
final class PreviewPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
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

        // Transparent title bar so the video shows through behind the
        // traffic-light buttons; the window keeps its native rounded corners.
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        title = "Glimpse"

        // Keep the preview usable even when shrunk aggressively.
        minSize = NSSize(width: 160, height: 120)
    }

    // Allow key status so the traffic-light buttons and any hosted SwiftUI
    // controls remain interactive on a non-activating panel.
    override var canBecomeKey: Bool { true }
}
