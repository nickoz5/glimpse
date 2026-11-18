import SwiftUI

/// The preview window's only window control: a round glass close button that
/// sits in the top-left corner, where macOS users expect to find "close".
///
/// It is deliberately a little larger than a standard traffic light (14pt) so
/// it is easy to hit on top of live video, and it stays legible over any
/// camera image thanks to the system glass material.
struct PreviewCloseButton: View {
    /// Diameter of the button, in points.
    static let diameter: CGFloat = 22

    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.primary.opacity(isHovered ? 1 : 0.8))
                .frame(width: Self.diameter, height: Self.diameter)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .scaleEffect(isHovered ? 1.1 : 1)
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .onHover { isHovered = $0 }
        .help("Close")
        .accessibilityLabel("Close preview")
    }
}
