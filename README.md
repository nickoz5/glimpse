# Glimpse

### A small menu bar app for checking your camera before a video call.

![Platform: macOS 26+](https://img.shields.io/badge/platform-macOS%2026%2B-black) ![Status: early project](https://img.shields.io/badge/status-early%20project-6b7280) ![Stack: Xcode + Swift](https://img.shields.io/badge/stack-XCode%20%2B%20Swift-0f766e)

[Why Glimpse?](#why-glimpse) · [Building](#building) · [Architecture](#architecture) · [Testing](#testing)

![Glimpse hero image showing a pre-call camera setup with lighting, framing, and camera readiness cues](docs/images/glimpse.png)

Glimpse is a native macOS camera preview utility for people who want a fast pre-call check without opening Zoom, Meet, or Teams first. It lives in the menu bar and gives you a quick way to confirm that your camera is working, your face is framed well, and your lighting looks right before you go on screen.

Use Glimpse to:

- make sure the camera is actually available before the call starts
- check framing, angle, and eye line
- catch bad lighting or awkward background composition early
- open a lightweight preview without launching a full meeting app

## Why Glimpse?

Most video call apps only show you what you look like after you are already in their flow. Glimpse is built for the few seconds before that moment.

Open it from the menu bar, sanity-check your setup, then close it and join the call.

## Requirements

- macOS 26.0 or newer
- Xcode 26 / Swift 6 toolchain (to build)

## Building

Glimpse is a Swift Package built via `make`. The executable target is wrapped
in an `.app` bundle so macOS applies the camera-usage description and
menu-bar-only (`LSUIElement`) behaviour.

```sh
make            # build and assemble .build/Glimpse.app (release)
make run        # build the bundle and launch it
make test       # run the unit tests
make clean      # remove build artifacts
make help       # list all targets
```

Use `CONFIG=debug` for a debug build (e.g. `make CONFIG=debug`). For quick
iteration you can also call SwiftPM directly with `swift build` / `swift test`,
and open the package in Xcode with `xed .` (or `open Package.swift`).

> The first time you open the preview, macOS will ask for camera permission.
> Grant it under **System Settings › Privacy & Security › Camera** if you miss
> the prompt.

## Architecture

The code follows the module layout described in `AGENTS.md`:

```
Sources/Glimpse/
├── App/        Application lifecycle (NSApplication bootstrap, AppDelegate)
├── MenuBar/    Status item + native configuration menu
├── Camera/     CameraManager, device discovery, permissions, preview layer
├── Windows/    Floating preview panel, positioning, persistence
├── Settings/   UserDefaults-backed preferences, launch-at-login
└── Views/      SwiftUI preview content and error views
```

Design notes:

- **Business logic stays out of views.** Camera state lives in `CameraManager`;
  views simply render it.
- **Camera logic is isolated** inside `CameraManager`, behind a mockable
  `CameraDiscovering` protocol.
- **AppKit is used only where SwiftUI can't reach** — distinguishing left/right
  clicks on the status item, hosting the live `AVCaptureVideoPreviewLayer`, and
  driving a free-floating, draggable, resizable panel.
- **Geometry and persistence are pure and tested** (`PreviewPositioner`,
  `Preferences`, `CameraSelection`).

## Testing

Unit tests cover the deterministic logic — preferences round-tripping and
validation, window positioning and clamping, camera selection rules (with a
mock discovery source), and error presentation:

```sh
swift test
```

The following are verified manually, as they depend on hardware and system
services:

- Camera permission prompt and denial handling
- Switching between cameras
- Menu bar left/right-click behaviour
- Launch at login
- Window positioning beneath the icon
- Drag and resize, with frame persistence
- Multiple-monitor placement
