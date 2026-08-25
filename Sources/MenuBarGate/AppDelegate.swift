import AppKit
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let gate = EventGate()
    private lazy var settings = SettingsWindowController()
    private let enabledItem = NSMenuItem(title: "Protection Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
    private let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    private let statusMenuItem = NSMenuItem(title: "Starting…", action: nil, keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem.button?.image = NSImage(systemSymbolName: "menubar.arrow.up.rectangle", accessibilityDescription: "Menu Bar Gate")
        statusItem.button?.toolTip = "Menu Bar Gate"
        buildMenu()
        settings.onChange = { [weak self] in self?.gate.restart(); self?.refreshMenu() }
        gate.onStatusChange = { [weak self] status in self?.statusMenuItem.title = "Status: \(status)" }
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.gate.refreshDisplays() }
        }
        refreshMenu()
        gate.start()
    }

    func applicationWillTerminate(_ notification: Notification) { gate.stop() }

    private func buildMenu() {
        let menu = NSMenu()
        enabledItem.target = self
        menu.addItem(enabledItem)
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        launchAtLoginItem.target = self
        menu.addItem(launchAtLoginItem)
        let retryItem = NSMenuItem(title: "Retry Permission", action: #selector(retry), keyEquivalent: "")
        retryItem.target = self
        menu.addItem(retryItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Menu Bar Gate", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    private func refreshMenu() {
        enabledItem.state = Preferences.shared.isEnabled ? .on : .off
        enabledItem.title = "Protection Enabled — hold \(Preferences.shared.binding.displayName) to release"
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc private func toggleEnabled() {
        Preferences.shared.isEnabled.toggle()
        refreshMenu()
        gate.start(promptForPermission: Preferences.shared.isEnabled)
    }

    @objc private func openSettings() { settings.show() }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
            refreshMenu()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn’t change Launch at Login"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
            refreshMenu()
        }
    }

    @objc private func retry() { gate.start(promptForPermission: true) }
    @objc private func quit() { NSApp.terminate(nil) }
}
