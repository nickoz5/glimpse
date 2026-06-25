
# AGENTS.md

This file guides LLM agents working in this repository. Keep it current as the application evolves.

## Project Overview

- **Project:** Glimpse
- **Platform:** macOS 26.0+
- **Purpose:** A lightweight native menu bar utility that lets users quickly verify their camera, framing and lighting before joining a video call.

## Core Principles

- Native-first.
- Instant launch.
- Minimal UI.
- Small memory footprint.
- Follow Apple Human Interface Guidelines.
- Prefer Apple frameworks over third-party dependencies.

## Functional Requirements

- macOS 26.0 or newer only.
- Lives exclusively in the macOS menu bar.
- Left-click toggles a floating camera preview.
- Preview defaults beneath the menu bar icon.
- Preview can be dragged from anywhere.
- Preview is resizable.
- Right-click opens a native configuration menu.
- Configuration supports:
  - Camera selection.
  - Launch at login.
  - Reset window size and position.
  - Quit.
- Camera failures display a native error view with a clear explanation.

## Non-functional Requirements

- Native macOS application.
- No web technologies.
- Fast startup.
- Low CPU usage while idle.
- Small application bundle.
- Minimal dependencies.

## Technology Stack

### Language

- Swift 6+

### UI

- SwiftUI

### Native Frameworks

- AppKit
- AVFoundation
- Foundation

### Persistence

- UserDefaults
- AppStorage

### Packaging

- Xcode
- Apple code signing
- Apple notarisation

## Architecture

```
GlimpseApp
├── App
├── MenuBar
├── Camera
├── Windows
├── Settings
└── Shared
```

### Modules

#### App

Owns application lifecycle.

#### MenuBar

- MenuBarExtra
- Status item
- Context menu

#### Camera

- CameraManager
- Device discovery
- Permissions
- AVCaptureSession lifecycle

#### Windows

- Floating preview window
- Window positioning
- Resize and drag behaviour

#### Settings

- UserDefaults
- AppStorage bindings

## Coding Guidelines

- Use Swift exclusively.
- Prefer SwiftUI.
- Use AppKit only where SwiftUI cannot provide required behaviour.
- Keep business logic out of Views.
- Keep camera logic isolated inside CameraManager.
- Prefer value types (structs).
- Use actors or async/await for concurrent work.
- Avoid unnecessary third-party packages.

## UI Guidelines

- Feel like a native macOS utility.
- No splash screen.
- No dock icon unless explicitly required.
- Native context menus.
- Native animations only.
- Keep interactions under 100ms where practical.

## Testing

- XCTest for unit tests.
- Mock camera devices where practical.
- Manually verify:
  - Camera permissions.
  - Camera switching.
  - Menu bar behaviour.
  - Launch at login.
  - Window positioning.
  - Resize and drag.
  - Multiple monitor support.

## Repository Layout

```
Glimpse/
├── GlimpseApp.swift
├── App/
├── MenuBar/
├── Camera/
├── Windows/
├── Settings/
├── Shared/
├── Resources/
└── Tests/
```

## Agent Workflow

Before making changes:

1. Read this file.
2. Read the relevant source.
3. Preserve native macOS behaviour.
4. Keep changes focused.
5. Build successfully.
6. Run tests where possible.
7. Update README.md when functionality changes.

## Definition of Done

- Builds without warnings where practical.
- No unnecessary dependencies.
- Native look and feel maintained.
- Error handling implemented.
- Code is simple, readable and idiomatic Swift.
- New behaviour is tested where practical.
