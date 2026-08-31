import AppKit
import CoreGraphics

struct GateBinding: Codable, Equatable, Sendable {
    enum Kind: String, Codable, Sendable { case modifier, key }

    var kind: Kind
    var keyCode: UInt16
    var modifierRawValue: UInt64
    var displayName: String

    static let control = GateBinding(
        kind: .modifier,
        keyCode: 0,
        modifierRawValue: CGEventFlags.maskControl.rawValue,
        displayName: "Control (⌃)"
    )

    var modifierFlag: CGEventFlags { CGEventFlags(rawValue: modifierRawValue) }

    func isHeld(flags: CGEventFlags, heldKeyCodes: Set<UInt16>) -> Bool {
        switch kind {
        case .modifier: return flags.contains(modifierFlag)
        case .key: return heldKeyCodes.contains(keyCode)
        }
    }

    static func modifier(from flags: CGEventFlags) -> GateBinding? {
        let choices: [(CGEventFlags, String)] = [
            (.maskControl, "Control (⌃)"),
            (.maskAlternate, "Option (⌥)"),
            (.maskShift, "Shift (⇧)"),
            (.maskCommand, "Command (⌘)"),
            (.maskSecondaryFn, "Function (fn)"),
            (.maskAlphaShift, "Caps Lock (⇪)")
        ]
        guard let (flag, name) = choices.first(where: { flags.contains($0.0) }) else { return nil }
        return GateBinding(kind: .modifier, keyCode: 0, modifierRawValue: flag.rawValue, displayName: name)
    }

    static func key(code: UInt16, characters: String?) -> GateBinding {
        let special: [UInt16: String] = [
            36: "Return (↩)", 48: "Tab (⇥)", 49: "Space", 51: "Delete (⌫)",
            53: "Escape (⎋)", 115: "Home", 116: "Page Up", 117: "Forward Delete",
            119: "End", 121: "Page Down", 123: "Left Arrow", 124: "Right Arrow",
            125: "Down Arrow", 126: "Up Arrow"
        ]
        let name = special[code] ?? characters?.uppercased() ?? "Key \(code)"
        return GateBinding(kind: .key, keyCode: code, modifierRawValue: 0, displayName: name)
    }
}

enum EdgeClamp {
    static func display(containing point: CGPoint, displays: [CGRect]) -> CGRect? {
        displays.first(where: { $0.contains(point) ||
            (point.x >= $0.minX && point.x <= $0.maxX && abs(point.y - $0.minY) < 0.5)
        })
    }

    static func boundary(for display: CGRect, clearance: CGFloat) -> CGFloat {
        display.minY + max(1, clearance)
    }

    static func clampedLocation(_ point: CGPoint, displays: [CGRect], clearance: CGFloat, gateHeld: Bool) -> CGPoint {
        guard !gateHeld else { return point }
        guard let display = display(containing: point, displays: displays) else { return point }
        let boundary = boundary(for: display, clearance: clearance)
        guard point.y < boundary else { return point }
        return CGPoint(x: point.x, y: boundary)
    }
}
