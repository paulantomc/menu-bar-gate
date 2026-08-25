import CoreGraphics
import Foundation

private var failures = 0

private func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    if condition() { print("PASS: \(name)") }
    else { failures += 1; print("FAIL: \(name)") }
}

let display = CGRect(x: 0, y: 0, width: 1920, height: 1080)
check(EdgeClamp.clampedLocation(CGPoint(x: 900, y: 0), displays: [display], clearance: 2, gateHeld: false) == CGPoint(x: 900, y: 2), "top edge clamps")
check(EdgeClamp.clampedLocation(CGPoint(x: 900, y: 0), displays: [display], clearance: 2, gateHeld: true) == CGPoint(x: 900, y: 0), "held gate releases")
check(EdgeClamp.clampedLocation(CGPoint(x: 900, y: 5), displays: [display], clearance: 2, gateHeld: false).y == 5, "interior is unchanged")
let upperDisplay = CGRect(x: -1440, y: -900, width: 1440, height: 900)
check(EdgeClamp.clampedLocation(CGPoint(x: -200, y: -900), displays: [upperDisplay], clearance: 1, gateHeld: false).y == -899, "negative-origin display clamps")
check(EdgeClamp.clampedLocation(CGPoint(x: 2000, y: 0), displays: [display], clearance: 2, gateHeld: false).x == 2000, "outside displays is unchanged")
check(GateBinding.control.isHeld(flags: [.maskControl], heldKeyCodes: []), "Control binding recognizes Control")
check(!GateBinding.control.isHeld(flags: [.maskShift], heldKeyCodes: []), "Control binding rejects Shift")
let space = GateBinding.key(code: 49, characters: " ")
check(space.isHeld(flags: [], heldKeyCodes: [49]), "ordinary key binding recognizes key")
check(!space.isHeld(flags: [], heldKeyCodes: [48]), "ordinary key binding rejects other key")
check(FullscreenDetector.isFullscreenFrame(display, display: display), "exact fullscreen geometry is recognized")
check(FullscreenDetector.isFullscreenFrame(CGRect(x: 1, y: 1, width: 1919, height: 1079), display: display), "fullscreen geometry allows rounding")
check(!FullscreenDetector.isFullscreenFrame(CGRect(x: 0, y: 25, width: 1920, height: 1055), display: display), "ordinary window is not fullscreen")
if failures > 0 { exit(1) }
print("All self-tests passed.")
