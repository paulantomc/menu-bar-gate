# Menu Bar Gate

A tiny macOS menu-bar utility that prevents the pointer from touching the top edge unless a chosen gate key is held. This stops accidental menu-bar reveals in full-screen apps.

## Build and run

```sh
chmod +x scripts/build-app.sh
scripts/build-app.sh
open "outputs/MenuBarGate.app"
```

On first launch, allow **Menu Bar Gate** in **System Settings → Privacy & Security → Accessibility**. Quit and reopen it if macOS asks you to do so.

Click the gate icon in the menu bar to pause protection, change the gate key, adjust the edge clearance, retry permission, or quit. The default gate is Control and the default clearance is 4 points.

Choose **Launch at Login** from the gate menu if you want the utility to return automatically after restarting or signing back in.

By default the edge is protected only when macOS reports that the menu bar is hidden. You can turn this off in Settings if you want protection everywhere.

Run `scripts/test.sh` to exercise the edge and keybinding logic.

## Uninstall

Quit the app and move `MenuBarGate.app` to the Trash. Its small preferences entry is stored under `com.local.MenuBarGate` in your user defaults.
