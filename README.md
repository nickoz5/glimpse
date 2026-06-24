# Glimpse

Glimpse is a small desktop camera preview utility for people working from home. It lives in the macOS menu bar.

## Stack

- Tauri v2
- Rust
- AppKit
- AVFoundation

## Installation

### Prerequisites

- macOS 26.0 or newer
- Xcode Command Line Tools
- Rust toolchain
- Node.js and npm

Install Xcode Command Line Tools:

```sh
xcode-select --install
```

Install Rust:

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Install project dependencies:

```sh
npm install
```

### Run Locally

```sh
npm run tauri dev
```

Glimpse appears in the macOS menu bar. Click the menu bar icon to open the camera preview. Click outside the preview to close it.

### Build The App

```sh
npm run tauri build
```

The packaged app is written under `src/target/release/bundle/`.

For local testing, open the generated `.app`. For distribution, add proper macOS code signing and notarization before sharing the app.

## Useful Commands

```sh
npm run tauri dev
npm run tauri build
npm run icons
cargo check --manifest-path src/Cargo.toml
```

## Icons

Use `src/icons/icon-large.png` as the source artwork. The ideal source is a square `1024x1024` PNG with transparency if needed. The current Tauri config points at this source file so the project remains buildable before derived icons are generated.

When the source PNG changes, regenerate the derived Tauri packaging icons:

```sh
npm run icons
```

To use a different source file:

```sh
bash scripts/regenerate-icons.sh path/to/source.png
```

## Current Scope

- Native tray/menu bar app shell.
- Click tray icon to show or hide the camera preview.
- Right-click tray menu for camera selection, startup toggle, reset, and exit.
- Native macOS camera preview from the default or selected camera.
- JSON-backed local preferences.
