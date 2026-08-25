import CoreGraphics
import Testing
@testable import MenuBarGate

struct MenuBarGateTests {
    @Test func clampsAtTopEdge() {
        let display = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        #expect(EdgeClamp.clampedLocation(CGPoint(x: 900, y: 0), displays: [display], clearance: 2, gateHeld: false) == CGPoint(x: 900, y: 2))
    }

    @Test func leavesPointerAloneWhenGateHeld() {
        let point = CGPoint(x: 900, y: 0)
        #expect(EdgeClamp.clampedLocation(point, displays: [CGRect(x: 0, y: 0, width: 1920, height: 1080)], clearance: 2, gateHeld: true) == point)
    }

    @Test func handlesDisplayWithNegativeOrigin() {
        let display = CGRect(x: -1440, y: -900, width: 1440, height: 900)
        #expect(EdgeClamp.clampedLocation(CGPoint(x: -200, y: -900), displays: [display], clearance: 1, gateHeld: false).y == -899)
    }

    @Test func doesNotAffectInteriorOrOutsideDisplays() {
        let display = CGRect(x: 0, y: 0, width: 100, height: 100)
        #expect(EdgeClamp.clampedLocation(CGPoint(x: 50, y: 5), displays: [display], clearance: 2, gateHeld: false).y == 5)
        #expect(EdgeClamp.clampedLocation(CGPoint(x: 200, y: 0), displays: [display], clearance: 2, gateHeld: false).x == 200)
    }

    @Test func controlBindingRecognizesControlOnly() {
        #expect(GateBinding.control.isHeld(flags: [.maskControl], heldKeyCodes: []))
        #expect(!GateBinding.control.isHeld(flags: [.maskShift], heldKeyCodes: []))
    }

    @Test func ordinaryKeyBindingTracksKeyCode() {
        let binding = GateBinding.key(code: 49, characters: " ")
        #expect(binding.isHeld(flags: [], heldKeyCodes: [49]))
        #expect(!binding.isHeld(flags: [], heldKeyCodes: [48]))
    }

    @Test func recognizesFullscreenGeometryWithinTolerance() {
        let display = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        #expect(FullscreenDetector.isFullscreenFrame(display, display: display))
        #expect(FullscreenDetector.isFullscreenFrame(CGRect(x: 1, y: 1, width: 1919, height: 1079), display: display))
        #expect(!FullscreenDetector.isFullscreenFrame(CGRect(x: 0, y: 25, width: 1920, height: 1055), display: display))
    }
}
