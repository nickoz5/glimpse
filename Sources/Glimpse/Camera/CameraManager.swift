import AVFoundation
import Combine
import Foundation

/// Owns the capture session and all camera logic for the app.
///
/// Kept on the main actor so its observable state can drive SwiftUI directly,
/// while session start/stop work is dispatched to a private queue to avoid
/// blocking the UI.
@MainActor
final class CameraManager: ObservableObject {
    /// High-level state the preview UI renders from.
    enum State: Equatable {
        case idle
        case running
        case failed(CameraError)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var cameras: [CameraDevice] = []
    @Published private(set) var activeCameraID: String?

    /// The capture session, shared with the preview layer.
    let session = AVCaptureSession()

    private let discovery: CameraDiscovering
    private let preferences: Preferences
    private let sessionQueue = DispatchQueue(label: "com.glimpse.camera.session")

    init(discovery: CameraDiscovering = AVCameraDiscovery(), preferences: Preferences) {
        self.discovery = discovery
        self.preferences = preferences
    }

    /// Refreshes the device list and starts capture, requesting permission if
    /// it has not yet been determined.
    func start() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else {
                state = .failed(.accessDenied)
                return
            }
        case .denied, .restricted:
            state = .failed(.accessDenied)
            return
        @unknown default:
            state = .failed(.accessDenied)
            return
        }

        refreshCameras()
        guard let device = CameraSelection.resolve(
            available: cameras,
            preferredID: preferences.selectedCameraID
        ) else {
            state = .failed(.noDevicesFound)
            return
        }
        await activate(device)
    }

    /// Stops capture and releases the session inputs.
    func stop() {
        // Safe across the actor boundary: the session is only ever touched on
        // `sessionQueue`, never concurrently from the main actor.
        nonisolated(unsafe) let session = session
        sessionQueue.async {
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    /// Switches to the given camera and persists the choice.
    func select(cameraID: String) async {
        guard let device = cameras.first(where: { $0.id == cameraID }) else { return }
        preferences.selectedCameraID = cameraID
        await activate(device)
    }

    /// Re-reads the available device list without altering capture state.
    ///
    /// Used to keep the configuration menu current even before the preview has
    /// been opened.
    func refreshCameras() {
        cameras = discovery.availableCameras()
    }

    /// Reconfigures the session to capture from `device` and starts it.
    private func activate(_ device: CameraDevice) async {
        guard let captureDevice = AVCaptureDevice(uniqueID: device.id) else {
            state = .failed(.deviceUnavailable)
            return
        }

        // Safe across the actor boundary: both values are used only inside the
        // serialized `sessionQueue` block below.
        nonisolated(unsafe) let session = session
        nonisolated(unsafe) let sessionDevice = captureDevice
        let configured: Bool = await withCheckedContinuation { continuation in
            sessionQueue.async {
                session.beginConfiguration()
                for existing in session.inputs {
                    session.removeInput(existing)
                }
                guard
                    let input = try? AVCaptureDeviceInput(device: sessionDevice),
                    session.canAddInput(input)
                else {
                    session.commitConfiguration()
                    continuation.resume(returning: false)
                    return
                }
                session.addInput(input)
                session.commitConfiguration()
                if !session.isRunning {
                    session.startRunning()
                }
                continuation.resume(returning: true)
            }
        }

        if configured {
            activeCameraID = device.id
            state = .running
        } else {
            state = .failed(.deviceUnavailable)
        }
    }
}
