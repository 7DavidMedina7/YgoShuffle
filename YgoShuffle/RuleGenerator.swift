import Foundation

enum RuleGenerator {
    static let rerollRule = "Re-roll the generator."

    struct Outcome: Equatable {
        let rule: String
        let didReroll: Bool
    }

    static func pick(from rules: [String]) -> Outcome? {
        var generator = SystemRandomNumberGenerator()
        return pick(from: rules, using: &generator)
    }

    static func pick<R: RandomNumberGenerator>(from rules: [String], using generator: inout R) -> Outcome? {
        let eligibleRules = rules.filter { $0 != rerollRule }
        guard !eligibleRules.isEmpty, let first = rules.randomElement(using: &generator) else {
            return nil
        }
        if first == rerollRule {
            guard let rule = eligibleRules.randomElement(using: &generator) else { return nil }
            return Outcome(rule: rule, didReroll: true)
        }
        return Outcome(rule: first, didReroll: false)
    }
}
