import Foundation

@MainActor
final class Preferences {
    static let shared = Preferences()
    private let defaults = UserDefaults.standard

    private init() {
        // The original 2-point default is not enough on every display. Migrate
        // untouched installs once while preserving any other chosen value.
        if !defaults.bool(forKey: "didMigrateClearanceTo4") {
            if defaults.object(forKey: "clearance") == nil || defaults.double(forKey: "clearance") == 2 {
                defaults.set(4.0, forKey: "clearance")
            }
            defaults.set(true, forKey: "didMigrateClearanceTo4")
        }
    }

    var isEnabled: Bool {
        get { defaults.object(forKey: "isEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "isEnabled") }
    }

    var clearance: Double {
        get { defaults.object(forKey: "clearance") as? Double ?? 4 }
        set { defaults.set(min(12, max(1, newValue)), forKey: "clearance") }
    }

    var onlyWhenMenuBarHidden: Bool {
        get { defaults.object(forKey: "onlyWhenMenuBarHidden") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "onlyWhenMenuBarHidden") }
    }

    var releaseMode: GateReleaseMode {
        get {
            guard let rawValue = defaults.string(forKey: "releaseMode"),
                  let mode = GateReleaseMode(rawValue: rawValue) else { return .key }
            return mode
        }
        set { defaults.set(newValue.rawValue, forKey: "releaseMode") }
    }

    var releaseDelay: Double {
        get { defaults.object(forKey: "releaseDelay") as? Double ?? 0.75 }
        set { defaults.set(min(3, max(0.25, newValue)), forKey: "releaseDelay") }
    }

    var binding: GateBinding {
        get {
            guard let data = defaults.data(forKey: "binding"),
                  let value = try? JSONDecoder().decode(GateBinding.self, from: data) else { return .control }
            return value
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) { defaults.set(data, forKey: "binding") }
        }
    }
}
