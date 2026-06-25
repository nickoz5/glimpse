import SwiftUI

/// Root content of the floating preview window.
///
/// Renders the live camera, a loading state, or a native error view depending
/// on the manager's state. The camera lifecycle (start/stop) is driven by the
/// window controller in step with the window's visibility, not by this view.
struct PreviewContentView: View {
    @ObservedObject var camera: CameraManager

    var body: some View {
        Group {
            switch camera.state {
            case .idle:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black)
            case .running:
                CameraPreviewView(session: camera.session)
            case .failed(let error):
                CameraErrorView(error: error)
            }
        }
    }
}
