import Foundation

/// Keeps the rendered reel geometry and the chosen result in agreement.
struct SpinReelPlan {
    static let rowHeight: Double = 45
    static let windowHeight: Double = 300

    let rules: [String]
    let landingIndex: Int
    let viewportHeight: Double

    var landingRule: String { rules[landingIndex] }
    var landingOffset: Double {
        viewportHeight / 2 - (Double(landingIndex) + 0.5) * Self.rowHeight
    }

    static func make(from rules: [String], landingRule: String, duration: Double, windowHeight: Double = SpinReelPlan.windowHeight) -> SpinReelPlan? {
        guard !rules.isEmpty, duration.isFinite, duration >= 0, windowHeight.isFinite, windowHeight > 0, windowHeight <= 1_000 else { return nil }
        // Bound the decorative reel even if called with an unexpectedly long duration.
        let distance = min(duration, 10) * 800
        let landingIndex = max(4, Int(ceil(distance / rowHeight)))
        let rowCount = landingIndex + Int(ceil(windowHeight / rowHeight / 2)) + 1
        var reel: [String] = []
        while reel.count < rowCount {
            reel.append(contentsOf: rules.shuffled().prefix(rowCount - reel.count))
        }
        reel[landingIndex] = landingRule
        return SpinReelPlan(rules: reel, landingIndex: landingIndex, viewportHeight: windowHeight)
    }
}
