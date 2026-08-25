import AppKit
import ApplicationServices
import CoreGraphics

@MainActor
final class EventGate {
    var onStatusChange: ((String) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var heldKeyCodes = Set<UInt16>()
    private var currentFlags: CGEventFlags = []
    private var displays: [CGRect] = []
    private var enabled = false

    func start(promptForPermission: Bool = true) {
        stop()
        enabled = Preferences.shared.isEnabled
        guard enabled else { onStatusChange?("Paused"); return }

        refreshDisplays()
        let trusted: Bool
        if promptForPermission {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            trusted = AXIsProcessTrustedWithOptions(options)
        } else {
            trusted = AXIsProcessTrusted()
        }
        guard trusted else {
            onStatusChange?("Permission needed")
            return
        }

        let types: [CGEventType] = [.mouseMoved, .leftMouseDragged, .rightMouseDragged,
                                    .otherMouseDragged, .keyDown, .keyUp, .flagsChanged]
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: mask, callback: EventGate.callback, userInfo: pointer
        )
        guard let eventTap else {
            onStatusChange?("Could not start")
            return
        }
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        onStatusChange?("Protected")
    }

    func stop() {
        if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: false) }
        if let runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes) }
        eventTap = nil
        runLoopSource = nil
        heldKeyCodes.removeAll()
        currentFlags = []
    }

    func restart() { start(promptForPermission: false) }

    func refreshDisplays() {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success else { return }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &ids, &count) == .success else { return }
        displays = ids.prefix(Int(count)).map(CGDisplayBounds)
    }

    private static let callback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else { return Unmanaged.passUnretained(event) }
        let gate = Unmanaged<EventGate>.fromOpaque(userInfo).takeUnretainedValue()
        return gate.handle(type: type, event: event)
    }

    nonisolated private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        MainActor.assumeIsolated {
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
                return Unmanaged.passUnretained(event)
            }

            currentFlags = event.flags
            if type == .keyDown { heldKeyCodes.insert(UInt16(event.getIntegerValueField(.keyboardEventKeycode))) }
            if type == .keyUp { heldKeyCodes.remove(UInt16(event.getIntegerValueField(.keyboardEventKeycode))) }

            if type == .mouseMoved || type == .leftMouseDragged || type == .rightMouseDragged || type == .otherMouseDragged {
                if Preferences.shared.onlyWhenMenuBarHidden && !FullscreenDetector.frontmostAppIsFullscreen(displays: displays) {
                    return Unmanaged.passUnretained(event)
                }
                let binding = Preferences.shared.binding
                let held = binding.isHeld(flags: currentFlags, heldKeyCodes: heldKeyCodes)
                let clamped = EdgeClamp.clampedLocation(event.location, displays: displays,
                                                        clearance: Preferences.shared.clearance, gateHeld: held)
                if clamped != event.location { event.location = clamped }
            }
            return Unmanaged.passUnretained(event)
        }
    }
}
