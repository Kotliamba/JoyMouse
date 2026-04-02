# Repository Guidelines

## Project Structure & Module Organization
- `JoyMouse/` contains the main macOS menu bar app: app delegate, Core Data model, UI controllers, localized resources, and assets.
- `JoyMouseLauncher/` contains the login-item helper app that starts the main app on login.
- `JoyMouse.xcodeproj/` holds project, scheme, and workspace metadata.
- `scripts/` contains release tooling such as DMG packaging and notarization helpers.
- `resources/` stores screenshots and marketing assets. There is currently no dedicated test target in the repository.

## Build, Test, and Development Commands
- `open JoyMouse.xcodeproj` opens the project in Xcode.
- `xcodebuild -project JoyMouse.xcodeproj -scheme JoyMouse -configuration Debug build` builds the main app from the command line.
- `xcodebuild -project JoyMouse.xcodeproj -scheme JoyMouseLauncher -configuration Debug build` builds the helper target.
- `./scripts/build_dmg.sh /path/to/JoyMouse.app` signs, packages, and notarizes a DMG for release.

## Coding Style & Naming Conventions
- Use Swift with 4-space indentation and keep files ASCII unless the file already uses localized or non-ASCII content.
- Follow the existing AppKit-style structure: `AppDelegate.swift`, feature folders under `Views/`, and small utility files under `Misc/`.
- Prefer clear type names in PascalCase and properties/functions in camelCase.
- Keep storyboard identifiers and module names aligned with the current app name, `JoyMouse`.

## Testing Guidelines
- No automated tests are present yet. When adding tests, prefer `XCTest` with a new unit test target under `JoyMouseTests/`.
- Name test files `*Tests.swift` and test methods `test...`.
- For now, verify changes by building both `JoyMouse` and `JoyMouseLauncher`, then smoke-test launch, menu-bar behavior, and login-item registration.

## Commit & Pull Request Guidelines
- Recent history uses short, imperative commit messages such as `Update README`. Keep commits focused and similarly concise.
- Pull requests should include a summary, affected areas, manual verification steps, and screenshots for UI or storyboard changes.
- Call out bundle ID, signing, entitlements, or packaging changes explicitly because they affect release behavior.

## Configuration & Release Notes
- The app and helper bundle identifiers are `ru.kotliamba.JoyMouse` and `ru.kotliamba.JoyMouseLauncher`.
- Review entitlements, signing settings, and `scripts/build_dmg.sh` before cutting a release.
