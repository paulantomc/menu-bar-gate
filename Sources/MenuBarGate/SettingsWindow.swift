import AppKit
import CoreGraphics

@MainActor
final class SettingsWindowController: NSWindowController {
    var onChange: (() -> Void)?
    private let explanation = NSTextField(wrappingLabelWithString: "")
    private let releaseModePopUp = NSPopUpButton(frame: .zero, pullsDown: false)
    private let bindingButton = NSButton(title: "", target: nil, action: nil)
    private let delaySlider = NSSlider(value: 0.75, minValue: 0.25, maxValue: 3,
                                       target: nil, action: nil)
    private let delayLabel = NSTextField(labelWithString: "")
    private let clearanceSlider = NSSlider(value: 4,
                                            minValue: Preferences.clearanceRange.lowerBound,
                                            maxValue: Preferences.clearanceRange.upperBound,
                                            target: nil, action: nil)
    private let clearanceLabel = NSTextField(labelWithString: "")
    private let fullscreenOnly = NSButton(checkboxWithTitle: "Protect only in full screen",
                                          target: nil, action: nil)
    private var recordingMonitor: Any?
    private weak var bindingRow: NSStackView?
    private weak var delayRow: NSStackView?

    init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 455, height: 300),
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
        explanation.textColor = .secondaryLabelColor

        releaseModePopUp.addItems(withTitles: GateReleaseMode.allCases.map(\.displayName))
        releaseModePopUp.target = self
        releaseModePopUp.action = #selector(releaseModeChanged)
        bindingButton.target = self
        bindingButton.action = #selector(recordBinding)
        bindingButton.bezelStyle = .rounded
        delaySlider.numberOfTickMarks = 12
        delaySlider.allowsTickMarkValuesOnly = true
        delaySlider.target = self
        delaySlider.action = #selector(delayChanged)
        clearanceSlider.target = self
        clearanceSlider.action = #selector(clearanceChanged)
        clearanceSlider.toolTip = "Increase clearance if the menu bar still appears, especially on a MacBook display. Range: 1–100 points."
        fullscreenOnly.target = self
        fullscreenOnly.action = #selector(fullscreenOnlyChanged)

        let releaseModeRow = row(label: "Release method", control: releaseModePopUp)
        let bindingRow = row(label: "Gate key", control: bindingButton)
        self.bindingRow = bindingRow
        let delayStack = NSStackView(views: [delaySlider, delayLabel])
        delayStack.orientation = .horizontal
        delayStack.spacing = 10
        let delayRow = row(label: "Wait time", control: delayStack)
        self.delayRow = delayRow
        let sliderStack = NSStackView(views: [clearanceSlider, clearanceLabel])
        sliderStack.orientation = .horizontal
        sliderStack.spacing = 10
        let clearanceRow = row(label: "Edge clearance", control: sliderStack)
        let permission = NSButton(title: "Open Accessibility Settings…", target: self,
                                  action: #selector(openAccessibilitySettings))
        permission.bezelStyle = .rounded

        let stack = NSStackView(views: [title, explanation, releaseModeRow, bindingRow, delayRow,
                                        clearanceRow, fullscreenOnly, permission])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 15
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 22),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -22),
            releaseModeRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            bindingRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            delayRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
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
        let mode = Preferences.shared.releaseMode
        releaseModePopUp.selectItem(at: GateReleaseMode.allCases.firstIndex(of: mode) ?? 0)
        bindingButton.title = Preferences.shared.binding.displayName + " — Change…"
        bindingButton.isEnabled = mode == .key
        bindingRow?.isHidden = mode != .key
        delaySlider.doubleValue = Preferences.shared.releaseDelay
        delaySlider.isEnabled = mode == .delay
        delayLabel.stringValue = formattedDelay(Preferences.shared.releaseDelay)
        delayLabel.textColor = mode == .delay ? .labelColor : .disabledControlTextColor
        delayRow?.isHidden = mode != .delay
        clearanceSlider.doubleValue = Preferences.shared.clearance
        clearanceLabel.stringValue = "\(Int(Preferences.shared.clearance)) pt"
        fullscreenOnly.state = Preferences.shared.onlyWhenMenuBarHidden ? .on : .off
        explanation.stringValue = switch mode {
        case .key:
            "The pointer stops just below the top edge. Hold your gate key while moving upward to reveal the menu bar."
        case .delay:
            "The pointer stops just below the top edge. Keep it there and the menu bar appears after your chosen wait time."
        }
    }

    private func formattedDelay(_ value: Double) -> String {
        value == value.rounded() ? String(format: "%.0f s", value) : String(format: "%.2g s", value)
    }

    @objc private func releaseModeChanged() {
        let modes = GateReleaseMode.allCases
        let selectedIndex = releaseModePopUp.indexOfSelectedItem
        guard modes.indices.contains(selectedIndex) else { return }
        finishRecording(nil)
        Preferences.shared.releaseMode = modes[selectedIndex]
        refresh()
        onChange?()
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

    @objc private func delayChanged() {
        Preferences.shared.releaseDelay = (delaySlider.doubleValue * 4).rounded() / 4
        refresh()
        onChange?()
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
