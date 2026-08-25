# Menu Bar Gate

Menu Bar Gate prevents the macOS menu bar from accidentally appearing when your mouse or trackpad cursor reaches the top of the screen in a full-screen app.
Normally, macOS reveals the hidden menu bar whenever the pointer touches the top edge. This can cover browser tabs, editor tabs and other controls near the top of a full-screen window.
Menu Bar Gate blocks the pointer just below the top edge. Hold a configurable key (Control by default) when you actually want to access the macOS menu bar.
## Build and run

```sh
chmod +x scripts/build-app.sh
scripts/build-app.sh
open "outputs/MenuBarGate.app"
```

## Install the downloadable app

1. Download and open `MenuBarGate.dmg` from the latest GitHub Release.
2. Drag `MenuBarGate.app` onto the **Applications** shortcut.
3. Open MenuBarGate from the Applications folder. If macOS blocks the first launch, Control-click the app and choose **Open**.
4. Allow MenuBarGate in **System Settings → Privacy & Security → Accessibility**.

To build the drag-and-drop installer locally, run `scripts/build-dmg.sh`.

On first launch, allow **Menu Bar Gate** in **System Settings → Privacy & Security → Accessibility**. Quit and reopen it if macOS asks you to do so.

Click the gate icon in the menu bar to pause protection, change the gate key, adjust the edge clearance, retry permission, or quit. The default gate is Control and the default clearance is 4 points.

Choose **Launch at Login** from the gate menu if you want the utility to return automatically after restarting or signing back in.

By default the edge is protected only while the frontmost app is in full screen. You can turn this off in Settings if you want protection everywhere.

Run `scripts/test.sh` to exercise the edge and keybinding logic.

## Uninstall

Quit the app and move `MenuBarGate.app` to the Trash. Its small preferences entry is stored under `com.local.MenuBarGate` in your user defaults.

## Why?

In full-screen apps, macOS reveals the menu bar whenever your mouse or trackpad cursor touches the top edge of the screen.

This can get annoying when you're trying to click browser tabs, editor tabs, or other controls near the top of a full-screen window. Overshoot by a few pixels and the menu bar drops down over what you were trying to click.

Menu Bar Gate prevents this by stopping the cursor just before it reaches the menu-bar activation area. When you actually want to access the menu bar, simply hold your chosen gate key (Control by default) and move the cursor through. It can also work in Non fullscreen applications where the bar is still hidden. 

The result is normal macOS full-screen behaviour without accidentally triggering the menu bar every time your cursor reaches the top of the screen.
