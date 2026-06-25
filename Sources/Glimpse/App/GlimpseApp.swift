import AppKit

/// Program entry point.
///
/// A plain `NSApplication` bootstrap is used instead of the SwiftUI `App`
/// lifecycle because Glimpse presents no standard windows or scenes — its UI is
/// a status item plus a manually managed floating panel.
@main
@MainActor
enum GlimpseMain {
    /// Held for the process lifetime; `NSApplication.delegate` is weak.
    private static let delegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.run()
    }
}
