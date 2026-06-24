# AGENTS.md

This file guides LLM agents working in this project. Keep it current as project requirements, architecture decisions, and workflows evolve.

## Project Overview

- Project name: Glimpse
- Primary users: Work from home users
- Core problem solved: Allows an end-user to test their camera is working and well positioned, lighting is sufficient and their appearance before starting a video call.

## Goals

Build a simple, easy to use application.

## Requirements

Add requirements here as they become known. Use clear, testable language where possible.

### Functional Requirements

Glimpse must support macOS 26.0 and newer only.
Glimpse should provide a simple icon in the menu bar on MacOS or Windows system tray.
When the icon is clicked, a small "Glimpse" window should appear showing the video from the default camera.
The position of the "Glimpse" window should be movable by the user by clicking anywhere in the window and dragging.
The initial position of the "Glimpse" window should be directly under the menu bar icon, centered horizontally.
The window size should be changed by dragging an edge or corner.
Right-click on the app icon should show app configuration.
App configuration should include:
    - Change the camera
    - Enable/disable startup on system boot
    - Reset window position/size to default
    - Exit the app
If the camera is unable to start, show a black window with a clear and well styled message with technical details below (if available or essential)

### Non-Functional Requirements

Application must be a native macOS 26.0+ application.
Use standard and well supported open-source libraries for implementation.


## Architecture Notes

Glimpse should be designed as a small native desktop utility, not a full windowed application. The default user interaction is through a macOS menu bar icon.

Recommended stack:

- Application framework: Tauri v2.
- Native/application layer: Rust.
- Native macOS UI layer: AppKit.
- Camera preview: native macOS `AVCaptureSession` / `AVCaptureVideoPreviewLayer`.
- Preferences: Tauri store plugin or a small Rust-managed user config file.
- Startup on boot: Tauri autostart plugin.
- Packaging: Tauri bundler, with macOS signing/notarization and Windows code signing added before distribution.
- Testing: Rust unit tests where practical, plus manual macOS validation for tray behavior, camera permission prompts, camera effects integration, and window placement.

- Main modules/components:
  - Application shell for native lifecycle management.
  - Menu bar/system tray controller.
  - Camera preview window.
  - Camera device discovery and selection.
  - User preferences storage.
  - Startup-on-boot integration.
- Data model:
  - Selected camera device identifier.
  - Startup-on-boot preference.
  - Window placement/size only if needed for a better user experience.
- External integrations:
  - Native camera APIs and permissions.
  - Native menu bar/system tray APIs.
  - Native startup/login item APIs.
- Background jobs or async work:
  - Camera device enumeration.
  - Camera stream startup and shutdown.
  - Permission checks and permission request flow.
- Configuration and environment variables:
  - Prefer native user preferences or application settings over environment variables.
  - Do not require manual configuration for normal end users.
  - Use development-only environment variables only when they simplify local debugging.

## Development Guidelines

- Follow existing patterns before introducing new ones.
- Keep changes scoped to the requested behavior.
- Use descriptive names for files, functions, components, and tests.
- Prefer structured APIs and parsers over ad hoc string manipulation.
- Add comments only when they clarify non-obvious decisions.
- Do not commit secrets, credentials, tokens, generated caches, or local machine state.

## Testing Guidelines

- Add or update tests for behavior changes where the chosen application stack supports automated testing.
- Keep tests focused on observable behavior: device selection, preference persistence, startup setting changes, window visibility, and error states.
- Mock camera devices and operating system integrations in unit tests where practical.
- Manually verify native behavior that is difficult to automate, including camera permissions, menu bar/system tray behavior, startup-on-boot behavior, and camera stream cleanup.
- Run the relevant test suite before handing work back.
- If tests cannot be run, explain why and describe the remaining risk.

## UI/UX Guidelines

- Keep the product quiet, fast, and task-focused. Users open Glimpse immediately before a call and should understand the camera state at a glance.
- The primary click action should show or hide the camera preview with minimal delay.
- The preview window should be small, unobtrusive, and easy to dismiss.
- Right-click configuration should use native menu conventions where possible.
- Use clear labels for camera selection, startup-on-boot, and exit actions.
- Handle camera permission errors, missing cameras, and busy cameras with plain user-facing messages.
- Match native platform conventions on macOS first, while avoiding design choices that block future Windows support.
- Keep camera capture native on each platform so operating-system camera indicators and video effects work correctly.

## Code Quality Bar

Before considering work complete, verify:

- The implementation matches the stated requirement.
- The change is small enough to review.
- Error states and edge cases are handled deliberately.
- New behavior is covered by tests where practical.
- Formatting, linting, and type checks pass where configured.

## Common Commands

```sh
# Install dependencies
npm install

# Run development server
npm run tauri dev

# Run tests
cargo check --manifest-path src-tauri/Cargo.toml

# Run lint/type checks
cargo check --manifest-path src-tauri/Cargo.toml

# Regenerate packaging icons after changing src-tauri/icons/icon-large.png
npm run icons
```

## Repository Conventions

Update this section as the repository structure emerges.

- Source code: place application source under the stack's standard source directory.
- Tests: keep tests near the behavior they cover or in the stack's standard test directory.
- Documentation: keep project guidance and decisions in Markdown files at the repository root or in a docs directory.
- Scripts/tooling: prefer checked-in scripts for repeatable build, test, packaging, and release tasks.
- Generated files: do not commit build artifacts, local caches, logs, packaged applications, or machine-specific settings unless explicitly required.

## Agent Workflow

When working in this repository:

1. Read this file and the relevant source before editing.
2. Clarify ambiguous requirements when a safe assumption is not possible.
3. Make focused changes that preserve existing behavior unless asked otherwise.
4. Run relevant validation commands.
5. Report what changed, what was verified, and any remaining risks.
6. Ensure the README.md is maintained.

## Open Questions

Use this section to capture unresolved project decisions.

- None.
