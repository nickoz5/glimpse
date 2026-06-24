# Glimpse

### A small menu bar app for checking your camera before a video call.

![Platform: macOS 26+](https://img.shields.io/badge/platform-macOS%2026%2B-black) ![Status: early project](https://img.shields.io/badge/status-early%20project-6b7280) ![Stack: Tauri v2 + Rust](https://img.shields.io/badge/stack-Tauri%20v2%20%2B%20Rust-0f766e)

[Why Glimpse?](#why-glimpse) · [Quick Start](#quick-start) · [Current Capabilities](#current-capabilities) · [Development](#development)

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

## Quick Start

### 1. Prerequisites

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

### 2. Install Dependencies

```sh
npm install
```

### 3. Run Glimpse Locally

```sh
npm run tauri dev
```

Glimpse appears in the macOS menu bar. Click the menu bar icon to show the camera preview. Click outside the preview to close it.

### 4. Build The App

```sh
npm run tauri build
```

The packaged app is written under `src-tauri/target/release/bundle/`.

For local testing, open the generated `.app`. For distribution, add proper macOS code signing and notarization before sharing the app.

## Current Capabilities

- Native macOS tray or menu bar app shell
- Click tray icon to show or hide the camera preview
- Native camera preview from the default or selected camera
- Right-click menu for camera selection, startup on boot, reset, and exit
- Local JSON-backed preferences

## Stack

- Tauri v2
- Rust
- AppKit
- AVFoundation

## Development

Useful commands:

```sh
npm run tauri dev
npm run tauri build
npm run icons
cargo check --manifest-path src-tauri/Cargo.toml
```

## Testing

Run the Rust unit tests:

```sh
cargo test --manifest-path src-tauri/Cargo.toml --lib
```

These cover the platform-independent logic: preference defaults, JSON
preference persistence (including missing and corrupt files), initial preview
window placement under the tray icon, and window-frame preservation across
preference writes.

The native macOS camera, menu bar, permission, and startup-on-boot behavior is
not automatically tested. Verify those manually on macOS 26.0+ by running
`npm run tauri dev`.

## Icons

Use `src-tauri/icons/icon-large.png` as the source artwork. The ideal source is a square `1024x1024` PNG with transparency if needed. The current Tauri config points at this source file so the project remains buildable before derived icons are generated.

When the source PNG changes, regenerate the derived Tauri packaging icons:

```sh
npm run icons
```

To use a different source file:

```sh
bash scripts/regenerate-icons.sh path/to/source.png
```
