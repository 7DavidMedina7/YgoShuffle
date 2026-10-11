import Foundation

enum RuleGenerator {
    static let rerollRule = "Re-roll the generator."

    struct Outcome: Equatable {
        let rule: String
        let didReroll: Bool
    }

    static func pick(from rules: [String], avoiding previousRule: String? = nil) -> Outcome? {
        var generator = SystemRandomNumberGenerator()
        return pick(from: rules, avoiding: previousRule, using: &generator)
    }

    static func pick<R: RandomNumberGenerator>(from rules: [String], avoiding previousRule: String? = nil, using generator: inout R) -> Outcome? {
        let playableRules = rules.filter { $0 != rerollRule }
        guard !playableRules.isEmpty else { return nil }
        let alternatives = playableRules.filter { $0 != previousRule }
        let shouldAvoidPrevious = previousRule != nil && !alternatives.isEmpty
        let pool = shouldAvoidPrevious ? rules.filter { $0 != previousRule } : rules
        let eligibleRules = shouldAvoidPrevious ? alternatives : playableRules
        guard let first = pool.randomElement(using: &generator) else { return nil }
        if first == rerollRule {
            guard let rule = eligibleRules.randomElement(using: &generator) else { return nil }
            return Outcome(rule: rule, didReroll: true)
        }
        return Outcome(rule: first, didReroll: false)
    }
}
