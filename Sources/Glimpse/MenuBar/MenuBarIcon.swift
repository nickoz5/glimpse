import AppKit

/// Draws the menu bar icon: an eye with lashes.
///
/// SF Symbols only ships a lash-less `eye`, so the glyph is drawn manually as a
/// template image. Returned as a template so the menu bar tints it correctly in
/// light and dark appearances.
enum MenuBarIcon {
    /// Point size of the square icon. 18pt matches the menu bar's standard
    /// template-image footprint.
    static let size: CGFloat = 18

    static func make() -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
            draw()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Glimpse"
        return image
    }

    /// Renders the eye almond, iris, and lashes into the current context.
    private static func draw() {
        let lineWidth: CGFloat = 1.3
        let inset = lineWidth
        let w = size - inset * 2
        let h = size - inset * 2
        let midY = inset + h / 2

        NSColor.black.setStroke()
        NSColor.black.setFill()

        // Eye almond: two symmetric quadratic arcs meeting at the corners.
        let left = NSPoint(x: inset, y: midY)
        let right = NSPoint(x: inset + w, y: midY)
        let curve: CGFloat = h * 0.46

        let almond = NSBezierPath()
        almond.lineWidth = lineWidth
        almond.lineCapStyle = .round
        almond.lineJoinStyle = .round
        almond.move(to: left)
        almond.curve(
            to: right,
            controlPoint1: NSPoint(x: inset + w * 0.3, y: midY + curve),
            controlPoint2: NSPoint(x: inset + w * 0.7, y: midY + curve)
        )
        almond.curve(
            to: left,
            controlPoint1: NSPoint(x: inset + w * 0.7, y: midY - curve),
            controlPoint2: NSPoint(x: inset + w * 0.3, y: midY - curve)
        )
        almond.stroke()

        // Iris: a filled dot centred in the eye.
        let irisRadius = h * 0.16
        let iris = NSBezierPath(ovalIn: NSRect(
            x: inset + w / 2 - irisRadius,
            y: midY - irisRadius,
            width: irisRadius * 2,
            height: irisRadius * 2
        ))
        iris.fill()

        // Lashes: short strokes radiating from the top of the almond.
        let lashLength = h * 0.22
        let lashAngles: [CGFloat] = [108, 90, 72] // degrees from the +x axis
        let lashBaseX: [CGFloat] = [0.32, 0.5, 0.68]
        for (fraction, angle) in zip(lashBaseX, lashAngles) {
            let baseX = inset + w * fraction
            let baseY = midY + curve * 0.62
            let radians = angle * .pi / 180
            let tip = NSPoint(
                x: baseX + cos(radians) * lashLength,
                y: baseY + sin(radians) * lashLength
            )
            let lash = NSBezierPath()
            lash.lineWidth = lineWidth
            lash.lineCapStyle = .round
            lash.move(to: NSPoint(x: baseX, y: baseY))
            lash.line(to: tip)
            lash.stroke()
        }
    }
}
