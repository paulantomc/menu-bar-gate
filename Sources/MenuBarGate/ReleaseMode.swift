import Foundation

enum GateReleaseMode: String, CaseIterable, Codable, Sendable {
    case key
    case delay

    var displayName: String {
        switch self {
        case .key: "Hold a key"
        case .delay: "Wait at edge"
        }
    }
}

struct DelayedReleaseState: Equatable, Sendable {
    enum Phase: Equatable, Sendable {
        case idle
        case waiting
        case released
    }

    private(set) var phase: Phase = .idle

    var permitsPassThrough: Bool { phase == .released }

    mutating func touchedGate() -> Bool {
        guard phase == .idle else { return false }
        phase = .waiting
        return true
    }

    mutating func delayCompleted() -> Bool {
        guard phase == .waiting else { return false }
        phase = .released
        return true
    }

    mutating func reset() {
        phase = .idle
    }
}
