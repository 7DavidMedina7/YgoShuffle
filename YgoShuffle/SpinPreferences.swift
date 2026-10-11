import Foundation

struct SpinPreferences: Equatable {
    var hapticsEnabled: Bool
    var soundEnabled: Bool
    var quickSpinEnabled: Bool
    var avoidConsecutiveDuplicates: Bool

    init(defaults: UserDefaults = .standard) {
        hapticsEnabled = defaults.object(forKey: "spin.haptics") as? Bool ?? true
        soundEnabled = defaults.object(forKey: "spin.sound") as? Bool ?? false
        quickSpinEnabled = defaults.object(forKey: "spin.quick") as? Bool ?? false
        avoidConsecutiveDuplicates = defaults.object(forKey: "spin.avoidDuplicates") as? Bool ?? true
    }

    var spinDuration: Double { quickSpinEnabled ? 0.65 : 2.0 }
    var rerollDuration: Double { quickSpinEnabled ? 0.3 : 1.0 }

    func save(defaults: UserDefaults = .standard) {
        defaults.set(hapticsEnabled, forKey: "spin.haptics")
        defaults.set(soundEnabled, forKey: "spin.sound")
        defaults.set(quickSpinEnabled, forKey: "spin.quick")
        defaults.set(avoidConsecutiveDuplicates, forKey: "spin.avoidDuplicates")
    }
}
