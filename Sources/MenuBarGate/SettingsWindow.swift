import AppKit
import CoreGraphics

@MainActor
final class SettingsWindowController: NSWindowController {
    var onChange: (() -> Void)?
    private let bindingButton = NSButton(title: "", target: nil, action: nil)
    private let clearanceSlider = NSSlider(value: 4, minValue: 1, maxValue: 12,
                                            target: nil, action: nil)
    private let clearanceLabel = NSTextField(labelWithString: "")
    private let fullscreenOnly = NSButton(checkboxWithTitle: "Protect only while the menu bar is hidden",
                                          target: nil, action: nil)
    private var recordingMonitor: Any?

    init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 430, height: 245),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Menu Bar Gate Settings"
        window.center()
        super.init(window: window)
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show() {
        refresh()
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildUI() {
        guard let content = window?.contentView else { return }
        let title = NSTextField(labelWithString: "Keep the menu bar out of accidental reach")
        title.font = .systemFont(ofSize: 17, weight: .semibold)
        let explanation = NSTextField(wrappingLabelWithString:
            "The pointer stops just below the top edge. Hold your gate key while moving upward to reveal the menu bar.")
        explanation.textColor = .secondaryLabelColor

        bindingButton.target = self
        bindingButton.action = #selector(recordBinding)
        bindingButton.bezelStyle = .rounded
        clearanceSlider.target = self
        clearanceSlider.action = #selector(clearanceChanged)
        fullscreenOnly.target = self
        fullscreenOnly.action = #selector(fullscreenOnlyChanged)

        let bindingRow = row(label: "Gate key", control: bindingButton)
        let sliderStack = NSStackView(views: [clearanceSlider, clearanceLabel])
        sliderStack.orientation = .horizontal
        sliderStack.spacing = 10
        let clearanceRow = row(label: "Edge clearance", control: sliderStack)
        let permission = NSButton(title: "Open Accessibility Settings…", target: self,
                                  action: #selector(openAccessibilitySettings))
        permission.bezelStyle = .rounded

        let stack = NSStackView(views: [title, explanation, bindingRow, clearanceRow, fullscreenOnly, permission])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 15
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 22),
            bindingRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            clearanceRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            explanation.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
        refresh()
    }

    private func row(label: String, control: NSView) -> NSStackView {
        let labelField = NSTextField(labelWithString: label)
        labelField.widthAnchor.constraint(equalToConstant: 115).isActive = true
        let row = NSStackView(views: [labelField, control])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        return row
    }

    private func refresh() {
        bindingButton.title = Preferences.shared.binding.displayName + " — Change…"
        clearanceSlider.doubleValue = Preferences.shared.clearance
        clearanceLabel.stringValue = "\(Int(Preferences.shared.clearance)) pt"
        fullscreenOnly.state = Preferences.shared.onlyWhenMenuBarHidden ? .on : .off
    }

    @objc private func recordBinding() {
        bindingButton.title = "Press a key… (Esc cancels)"
        window?.makeFirstResponder(bindingButton)
        if let recordingMonitor { NSEvent.removeMonitor(recordingMonitor) }
        recordingMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self else { return event }
            if event.type == .keyDown && event.keyCode == 53 { self.finishRecording(nil); return nil }
            if event.type == .flagsChanged, let binding = GateBinding.modifier(from: CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue))) {
                self.finishRecording(binding); return nil
            }
            if event.type == .keyDown {
                self.finishRecording(.key(code: event.keyCode, characters: event.charactersIgnoringModifiers)); return nil
            }
            return event
        }
    }

    private func finishRecording(_ binding: GateBinding?) {
        if let recordingMonitor { NSEvent.removeMonitor(recordingMonitor) }
        recordingMonitor = nil
        if let binding { Preferences.shared.binding = binding; onChange?() }
        refresh()
    }

    @objc private func clearanceChanged() {
        Preferences.shared.clearance = clearanceSlider.doubleValue.rounded()
        refresh()
        onChange?()
    }

    @objc private func fullscreenOnlyChanged() {
        Preferences.shared.onlyWhenMenuBarHidden = fullscreenOnly.state == .on
        onChange?()
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
