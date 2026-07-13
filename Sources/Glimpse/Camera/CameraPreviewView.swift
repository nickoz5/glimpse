import AVFoundation
import SwiftUI

/// SwiftUI wrapper around an `AVCaptureVideoPreviewLayer`.
///
/// AppKit is required here because SwiftUI has no native way to render a live
/// capture session.
struct CameraPreviewView: NSViewRepresentable {
    let session: AVCaptureSession
    let isMirrored: Bool

    func makeNSView(context: Context) -> PreviewLayerView {
        let view = PreviewLayerView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        updateMirroring(for: view.previewLayer)
        return view
    }

    func updateNSView(_ nsView: PreviewLayerView, context: Context) {
        if nsView.previewLayer.session !== session {
            nsView.previewLayer.session = session
        }
        updateMirroring(for: nsView.previewLayer)
    }

    private func updateMirroring(for previewLayer: AVCaptureVideoPreviewLayer) {
        guard
            let connection = previewLayer.connection,
            connection.isVideoMirroringSupported
        else { return }
        connection.automaticallyAdjustsVideoMirroring = false
        connection.isVideoMirrored = isMirrored
    }
}

/// Layer-backed view whose backing layer is an `AVCaptureVideoPreviewLayer`.
final class PreviewLayerView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = AVCaptureVideoPreviewLayer()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        // Safe: the backing layer is assigned an AVCaptureVideoPreviewLayer above.
        layer as! AVCaptureVideoPreviewLayer
    }
}
