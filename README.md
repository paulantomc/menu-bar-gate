# Menu Bar Gate

Menu Bar Gate is a small, system-wide native macOS utility that prevents the menu bar from accidentally appearing when your mouse or trackpad reaches the top of the screen in a full-screen app. Normally, macOS reveals the hidden menu bar there, covering browser tabs, editor tabs, and other controls near the top of the window.

**Website:** [paulantomc.github.io/menu-bar-gate](https://paulantomc.github.io/menu-bar-gate/)

Menu Bar Gate stops the pointer just below the top edge. Choose how to pass through when you actually want the menu bar: hold a configurable gate key—Control by default—or keep the pointer at the edge for a configurable delay. Protection runs only in full screen by default, or it can work across non-full-screen apps whenever the menu bar is hidden.

**No Hammerspoon setup or Lua scripts required.** It is a standalone menu-bar app with no third-party dependencies.

## Install

Requires **Apple silicon (M1 or newer) and macOS 13 Ventura or later**, including Sonoma, Sequoia, and Tahoe. Intel Macs and macOS 11/12 are not supported by this download.

1. Download `MenuBarGate.dmg` from the [latest release](https://github.com/paulantomc/menu-bar-gate/releases/latest).
2. Open it and drag `MenuBarGate.app` onto the **Applications** shortcut.
3. Open MenuBarGate from Applications. If Gatekeeper blocks the first launch, Control-click the app and choose **Open**.
4. Allow **Menu Bar Gate** in **System Settings → Privacy & Security → Accessibility**.

Click the gate icon in the menu bar to pause protection, choose **Hold a key** or **Wait at edge**, change the key or wait time, adjust the edge clearance, retry permission, enable Launch at Login, or quit. Existing installs continue to use Control by default. Wait-at-edge mode defaults to 0.75 seconds, and the clearance defaults to 4 points.

**Compatibility fix in 1.1.1:** earlier builds could incorrectly require the macOS version they were compiled on, despite advertising macOS 13+. The build now explicitly targets macOS 13 and verifies the executable's real minimum version, not just the app's `Info.plist`. Quit the old copy before replacing it with the corrected app.

Edge clearance is adjustable from **1 to 100 points**. If the menu bar still appears on your MacBook, increase the clearance until the pointer stops below its activation area. Use the smallest value that works for your display; larger values keep more of the top of the screen behind the gate.

## Why Accessibility permission is required

macOS protects system-wide input event taps and frontmost-window accessibility attributes behind this permission. Menu Bar Gate needs those APIs to:

- observe pointer movement and dragging across apps, plus the selected gate-key state when key mode is active;
- move only the pointer's vertical coordinate back by a few points when it enters the protected strip, then move it to the top edge after the chosen delay when wait mode is active; and
- check whether the frontmost window is full screen.

Without Accessibility permission, protection cannot start. Keyboard events are passed through unchanged; the app keeps only the currently held key codes and modifier flags in memory. It does not capture the screen, inspect window contents, read files, or send data anywhere.

Gatekeeper approval and Accessibility permission are separate. The current downloadable build is ad-hoc signed (`codesign --sign -`), not Developer ID signed or notarized, so macOS may require Control-click → **Open** once. Developer ID signing and notarization are planned when the required Apple credentials are available.

## How it works

The complete runtime is intentionally small and readable:

1. [`EventGate.swift`](Sources/MenuBarGate/EventGate.swift) creates one session event tap for mouse movement, dragging, key up/down, and modifier changes. In wait mode, first contact starts one cancellable timer; moving away cancels it, and completion releases the pointer at the top edge.
2. [`FullscreenDetector.swift`](Sources/MenuBarGate/FullscreenDetector.swift) reads the frontmost window's `AXFullScreen` value. For apps that do not expose it, it compares the front window's bounds with the active displays; it never reads screen pixels.
3. [`GateBinding.swift`](Sources/MenuBarGate/GateBinding.swift) leaves the event untouched when the gate key is held. Otherwise, entering the top strip changes only `y` to `display.minY + clearance`; `x` is preserved. [`ReleaseMode.swift`](Sources/MenuBarGate/ReleaseMode.swift) contains the small wait-mode state machine.
4. [`Preferences.swift`](Sources/MenuBarGate/Preferences.swift) stores the enabled state, release method, gate key, wait time, clearance, and full-screen-only setting locally in macOS user defaults.

Pausing or quitting removes the event tap. Leaving full screen bypasses the clamp by default. Launch at Login uses Apple's `SMAppService`. There is no networking, analytics, updater, account, or third-party package.

## Build from source

Requires Apple's developer tools with Swift 6 or later. The app and self-tests explicitly target `arm64-apple-macosx13.0`, even when built on a newer macOS SDK. [`scripts/build-settings.sh`](scripts/build-settings.sh) keeps the architecture and minimum macOS version in one place; the package also declares macOS 13 as its minimum.

```sh
scripts/build-app.sh
open "outputs/MenuBarGate.app"
```

To build the drag-to-Applications installer, run `scripts/build-dmg.sh`.

## Tests

```sh
scripts/test.sh
```

The self-tests cover edge clamping, gate-key release, delayed release and cancellation, multiple display coordinates, shortcut matching, and full-screen detection geometry. Run `swift test` for the full unit-test suite.

Every app build also runs [`scripts/verify-app.sh`](scripts/verify-app.sh), checking its actual Mach-O architecture and minimum macOS version against `Info.plist` and the shared build settings, then verifying its code signature. You can run it independently on an extracted app:

```sh
scripts/verify-app.sh outputs/MenuBarGate.app
```

These checks prevent accidental Tahoe-only builds; they do not replace hands-on testing on each supported macOS release.

## Feedback and requests

Found a bug, compatibility problem, or have an idea? [Open an issue](https://github.com/paulantomc/menu-bar-gate/issues/new). The current download is Apple-silicon-only; if you need an Intel or universal build, please add a request there. One can be added if there is demand.

## Uninstall

Quit Menu Bar Gate and move `MenuBarGate.app` to the Trash. Its small preferences entry is stored under `com.local.MenuBarGate` in your user defaults.

## License

[Menu Bar Gate Source-Available License](LICENSE)
