import AppKit
import SwiftUI

/// Native error presentation shown inside the preview window when the camera
/// cannot be displayed.
struct CameraErrorView: View {
    let error: CameraError

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text(error.title)
                .font(.headline)
            Text(error.message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if error.isPermissionError {
                Button("Open System Settings") {
                    openCameraSettings()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }

    private func openCameraSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
        ) else { return }
        NSWorkspace.shared.open(url)
    }
}
