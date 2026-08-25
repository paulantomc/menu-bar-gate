# Menu Bar Gate

Menu Bar Gate is a small, system-wide native macOS utility that prevents the menu bar from accidentally appearing when your mouse or trackpad reaches the top of the screen in a full-screen app. Normally, macOS reveals the hidden menu bar there, covering browser tabs, editor tabs, and other controls near the top of the window.

**Website:** [paulantomc.github.io/menu-bar-gate](https://paulantomc.github.io/menu-bar-gate/)

Menu Bar Gate stops the pointer just below the top edge. Hold a configurable gate key—Control by default—when you actually want to pass through and reveal the menu bar. Protection runs only in full screen by default, or it can work across non-full-screen apps whenever the menu bar is hidden.

**No Hammerspoon setup or Lua scripts required.** It is a standalone menu-bar app with no third-party dependencies.

## Install

The current prebuilt release requires macOS 13 or later on Apple silicon (M1 or newer).

1. Download `MenuBarGate.dmg` from the [latest release](https://github.com/paulantomc/menu-bar-gate/releases/latest).
2. Open it and drag `MenuBarGate.app` onto the **Applications** shortcut.
3. Open MenuBarGate from Applications. If Gatekeeper blocks the first launch, Control-click the app and choose **Open**.
4. Allow **Menu Bar Gate** in **System Settings → Privacy & Security → Accessibility**.

Click the gate icon in the menu bar to pause protection, change the gate key, adjust the edge clearance, retry permission, enable Launch at Login, or quit. The defaults are Control and a 4-point clearance.

## Why Accessibility permission is required

macOS protects system-wide input event taps and frontmost-window accessibility attributes behind this permission. Menu Bar Gate needs those APIs to:

- observe pointer movement, dragging, and the selected gate-key state across apps;
- move only the pointer's vertical coordinate back by a few points when it enters the protected strip; and
- check whether the frontmost window is full screen.

Without Accessibility permission, protection cannot start. Keyboard events are passed through unchanged; the app keeps only the currently held key codes and modifier flags in memory. It does not capture the screen, inspect window contents, read files, or send data anywhere.

Gatekeeper approval and Accessibility permission are separate. The current downloadable build is ad-hoc signed (`codesign --sign -`), not Developer ID signed or notarized, so macOS may require Control-click → **Open** once. Developer ID signing and notarization are planned when the required Apple credentials are available.

## How it works

The complete runtime is intentionally small and readable:

1. [`EventGate.swift`](Sources/MenuBarGate/EventGate.swift) creates one session event tap for mouse movement, dragging, key up/down, and modifier changes.
2. [`FullscreenDetector.swift`](Sources/MenuBarGate/FullscreenDetector.swift) reads the frontmost window's `AXFullScreen` value. For apps that do not expose it, it compares the front window's bounds with the active displays; it never reads screen pixels.
3. [`GateBinding.swift`](Sources/MenuBarGate/GateBinding.swift) leaves the event untouched when the gate key is held. Otherwise, entering the top strip changes only `y` to `display.minY + clearance`; `x` is preserved.
4. [`Preferences.swift`](Sources/MenuBarGate/Preferences.swift) stores the enabled state, gate key, clearance, and full-screen-only setting locally in macOS user defaults.

Pausing or quitting removes the event tap. Leaving full screen bypasses the clamp by default. Launch at Login uses Apple's `SMAppService`. There is no networking, analytics, updater, account, or third-party package.

## Build from source

Requires macOS 13 or later and Apple's command-line developer tools. The build targets the Mac it runs on.

```sh
scripts/build-app.sh
open "outputs/MenuBarGate.app"
```

To build the drag-to-Applications installer, run `scripts/build-dmg.sh`.

## Tests

```sh
scripts/test.sh
```

The self-tests cover edge clamping, gate-key release, multiple display coordinates, shortcut matching, and full-screen detection geometry.

## Feedback and requests

Found a bug, compatibility problem, or have an idea? [Open an issue](https://github.com/paulantomc/menu-bar-gate/issues/new). The current download is Apple-silicon-only; if you need an Intel or universal build, please add a request there. One can be added if there is demand.

## Uninstall

Quit Menu Bar Gate and move `MenuBarGate.app` to the Trash. Its small preferences entry is stored under `com.local.MenuBarGate` in your user defaults.

## License

[Menu Bar Gate Source-Available License](LICENSE)
