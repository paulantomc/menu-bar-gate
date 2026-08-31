import AppKit
@preconcurrency import ApplicationServices
@preconcurrency import CoreGraphics

@MainActor
final class EventGate {
    var onStatusChange: ((String) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var heldKeyCodes = Set<UInt16>()
    private var currentFlags: CGEventFlags = []
    private var displays: [CGRect] = []
    private var enabled = false
    private var delayedRelease = DelayedReleaseState()
    private var delayedReleaseTask: Task<Void, Never>?
    private var delayedDisplay: CGRect?

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
        resetDelayedRelease()
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
                guard shouldProtectPointer() else {
                    resetDelayedRelease()
                    return Unmanaged.passUnretained(event)
                }

                switch Preferences.shared.releaseMode {
                case .key:
                    resetDelayedRelease()
                    let binding = Preferences.shared.binding
                    let held = binding.isHeld(flags: currentFlags, heldKeyCodes: heldKeyCodes)
                    let clamped = EdgeClamp.clampedLocation(event.location, displays: displays,
                                                            clearance: Preferences.shared.clearance,
                                                            gateHeld: held)
                    if clamped != event.location { event.location = clamped }
                case .delay:
                    handleDelayedRelease(event: event)
                }
            }
            return Unmanaged.passUnretained(event)
        }
    }

    private func shouldProtectPointer() -> Bool {
        !Preferences.shared.onlyWhenMenuBarHidden ||
            FullscreenDetector.frontmostAppIsFullscreen(displays: displays)
    }

    private func handleDelayedRelease(event: CGEvent) {
        let location = event.location
        let clearance = Preferences.shared.clearance
        guard let display = EdgeClamp.display(containing: location, displays: displays) else {
            resetDelayedRelease()
            return
        }
        let boundary = EdgeClamp.boundary(for: display, clearance: clearance)

        if delayedRelease.permitsPassThrough {
            if delayedDisplay != display || location.y > boundary + 2 {
                resetDelayedRelease()
            }
            return
        }

        let clamped = EdgeClamp.clampedLocation(location, displays: displays,
                                                clearance: clearance, gateHeld: false)
        if clamped != location {
            event.location = clamped
            delayedDisplay = display
            if delayedRelease.touchedGate() {
                scheduleDelayedRelease(after: Preferences.shared.releaseDelay)
            }
        } else if location.y > boundary + 0.5 {
            resetDelayedRelease()
        }
    }

    private func scheduleDelayedRelease(after delay: TimeInterval) {
        delayedReleaseTask?.cancel()
        let nanoseconds = UInt64(delay * 1_000_000_000)
        delayedReleaseTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: nanoseconds)
            } catch {
                return
            }
            self?.completeDelayedRelease()
        }
    }

    private func completeDelayedRelease() {
        delayedReleaseTask = nil
        guard Preferences.shared.releaseMode == .delay,
              shouldProtectPointer(),
              let display = delayedDisplay,
              let pointerEvent = CGEvent(source: nil) else {
            resetDelayedRelease()
            return
        }

        let location = pointerEvent.location
        let boundary = EdgeClamp.boundary(for: display, clearance: Preferences.shared.clearance)
        guard EdgeClamp.display(containing: location, displays: displays) == display,
              abs(location.y - boundary) <= 1,
              delayedRelease.delayCompleted() else {
            resetDelayedRelease()
            return
        }

        CGWarpMouseCursorPosition(CGPoint(x: location.x, y: display.minY))
    }

    private func resetDelayedRelease() {
        delayedReleaseTask?.cancel()
        delayedReleaseTask = nil
        delayedDisplay = nil
        delayedRelease.reset()
    }
}
