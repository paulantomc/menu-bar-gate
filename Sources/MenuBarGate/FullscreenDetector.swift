import AppKit
import ApplicationServices
import CoreGraphics

@MainActor
enum FullscreenDetector {
    static func frontmostAppIsFullscreen(displays: [CGRect]) -> Bool {
        guard let app = NSWorkspace.shared.frontmostApplication else { return false }
        let applicationElement = AXUIElementCreateApplication(app.processIdentifier)
        var focusedValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(applicationElement,
                                        kAXFocusedWindowAttribute as CFString,
                                        &focusedValue) == .success,
           let focusedValue,
           CFGetTypeID(focusedValue) == AXUIElementGetTypeID() {
            let windowElement = unsafeBitCast(focusedValue, to: AXUIElement.self)
            var fullscreenValue: CFTypeRef?
            if AXUIElementCopyAttributeValue(windowElement,
                                             "AXFullScreen" as CFString,
                                             &fullscreenValue) == .success,
               let isFullscreen = fullscreenValue as? Bool {
                return isFullscreen
            }
        }

        // Some apps do not expose AXFullScreen. Fall back to checking whether
        // their frontmost layer-zero window fills one complete display.
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return false }
        for window in info where window[kCGWindowOwnerPID as String] as? pid_t == app.processIdentifier {
            guard (window[kCGWindowLayer as String] as? Int) == 0,
                  let boundsDictionary = window[kCGWindowBounds as String] as? NSDictionary,
                  let frame = CGRect(dictionaryRepresentation: boundsDictionary as CFDictionary) else { continue }
            if displays.contains(where: { isFullscreenFrame(frame, display: $0) }) { return true }
        }
        return false
    }

    nonisolated static func isFullscreenFrame(_ frame: CGRect, display: CGRect, tolerance: CGFloat = 2) -> Bool {
        abs(frame.minX - display.minX) <= tolerance &&
        abs(frame.minY - display.minY) <= tolerance &&
        abs(frame.width - display.width) <= tolerance &&
        abs(frame.height - display.height) <= tolerance
    }
}
