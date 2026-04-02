# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

JoyMouse is a macOS menu bar app that maps Nintendo Joy-Con / Pro Controller buttons to keyboard and mouse events. It runs natively on Apple Silicon and Intel macOS Big Sur+. Based on [magicien/JoyKeyMapper](https://github.com/magicien/JoyKeyMapper).

## Building and Running

Open directly in Xcode — no CocoaPods or other setup needed. SPM resolves `JoyConSwift` automatically from the local sibling directory `../JoyConSwift`.

```bash
open JoyMouse.xcodeproj
```

Build scheme: **JoyMouse** (the main app target). The second target `JoyMouseLauncher` is a login-item helper.

**Git tag required for build:** The build script `scripts/set_build_number.sh` runs during every build and calls `git describe --tags`. A tag in `v*.*.*` format must exist or the build will fail with `error: Version tag not found`. Create one with:
```bash
git tag v1.0.0
```

## Architecture

### Threading Model
All controller connect/disconnect handling must run on the **main thread**. `JoyConManager.connectHandler` and `disconnectHandler` fire on a background thread — they are wrapped in `DispatchQueue.main.async` in `AppDelegate`. Core Data (`viewContext`) and all UI updates must be on main.

Battery/charging/icon callbacks from `JoyConSwift` still fire on background threads and explicitly dispatch to main where needed.

### Data Flow

```
JoyConSwift (Bluetooth HID)
    └── JoyConManager callbacks (background thread)
        └── AppDelegate.connectController / disconnectController (→ dispatched to main)
            ├── AppDelegate.controllers: [GameController]   (source of truth)
            ├── Core Data (DataManager / NSPersistentContainer "JoyMouse")
            └── NotificationCenter posts → ViewController reloads collection view
```

### Key Classes

- **`AppDelegate`** — owns `JoyConManager`, the `controllers` array, and `DataManager`. Bridges JoyConSwift callbacks to the rest of the app.
- **`GameController`** — wraps a `JoyConSwift.Controller?` (nil when disconnected) and its persisted `ControllerData`. Handles all input event translation to CGEvents. The `controller` property has a `didSet` that calls `setControllerHandler()` to attach all JoyConSwift callbacks.
- **`DataManager`** — thin wrapper around `NSPersistentContainer`. The Core Data model is named `JoyMouse`. Controllers are identified across launches by `ControllerData.serialID`.
- **`AppSettings`** — static properties backed by `UserDefaults` plus `SMAppService` (macOS 13+) / `SMLoginItemSetEnabled` (macOS 12 and below) for launch-on-login.

### Mouse Event Coordinate System

`NSEvent.mouseLocation` returns AppKit coordinates (origin at bottom-left of primary screen). `CGEvent` uses Quartz coordinates (origin at top-left of primary screen). Conversion: `cgY = NSScreen.screens[0].frame.maxY - appKitY`. Mouse bounds for multi-display clamping use `NSScreen.screens.reduce(CGRect.null) { $0.union($1.frame) }`.

### Persistence

Core Data saves happen in:
1. `AppDelegate.addController` — immediately after a new controller is first seen (persists `serialID`)
2. `AppDelegate.applicationWillTerminate` — on SIGTERM (covers Xcode Stop)
3. `AppDelegate.applicationShouldTerminate` — on graceful quit
4. `AppDelegate.windowWillClose` — when the settings window closes

Key mappings configured via the settings UI are only saved at points 3 and 4. If Xcode kills the process before the window is closed, key mapping changes are lost.

### Notification Names (`Misc/Notifications.swift`)

| Name | Posted when |
|---|---|
| `.controllerAdded` | New controller seen for first time |
| `.controllerConnected` | Known controller reconnects |
| `.controllerDisconnected` | Controller disconnects |
| `.controllerRemoved` | Controller record deleted |
| `.controllerIconChanged` | Icon needs refresh (battery, enable state, color) |

### Collection View (Settings Window)

`ViewController` owns the settings window. `connectedControllers` (computed, filters `AppDelegate.controllers` where `controller != nil`) drives the `NSCollectionView`. The window is lazily instantiated from storyboard in `applicationDidFinishLaunching` but not shown until the user opens it from the menu bar.
