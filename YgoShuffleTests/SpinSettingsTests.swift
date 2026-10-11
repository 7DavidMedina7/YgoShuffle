import Foundation
import Testing
@testable import YgoShuffle

struct SpinSettingsTests {
    @Test func preferenceDefaultsAndPersistence() throws {
        let suite = "SpinSettingsTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var preferences = SpinPreferences(defaults: defaults)
        #expect(preferences.hapticsEnabled)
        #expect(!preferences.soundEnabled)
        #expect(!preferences.quickSpinEnabled)
        #expect(preferences.avoidConsecutiveDuplicates)
        preferences.hapticsEnabled = false
        preferences.soundEnabled = true
        preferences.quickSpinEnabled = true
        preferences.avoidConsecutiveDuplicates = false
        preferences.save(defaults: defaults)
        #expect(SpinPreferences(defaults: defaults) == preferences)
    }

    @Test func repeatsAreExcludedWhenAnAlternativeExists() throws {
        for _ in 0..<100 {
            let outcome = try #require(RuleGenerator.pick(from: ["Draw", "Draw", "Discard"], avoiding: "Draw"))
            #expect(outcome.rule == "Discard")
            #expect(!outcome.didReroll)
        }
    }

    @Test func rerollDoesNotRestoreExcludedPreviousRule() throws {
        for _ in 0..<100 {
            let outcome = try #require(RuleGenerator.pick(
                from: ["Draw", RuleGenerator.rerollRule, "Discard"], avoiding: "Draw"
            ))
            #expect(outcome.rule == "Discard")
        }
    }

    @Test func oneDistinctPlayableRuleStillWorks() throws {
        for rules in [["Draw"], ["Draw", "Draw"], ["Draw", RuleGenerator.rerollRule]] {
            let outcome = try #require(RuleGenerator.pick(from: rules, avoiding: "Draw"))
            #expect(outcome.rule == "Draw")
        }
        #expect(RuleGenerator.pick(from: [], avoiding: "Draw") == nil)
        #expect(RuleGenerator.pick(from: [RuleGenerator.rerollRule], avoiding: "Draw") == nil)
    }

    @Test func unrelatedPreviousRuleDoesNotChangeAvailableResults() throws {
        for _ in 0..<100 {
            let outcome = try #require(RuleGenerator.pick(from: ["Draw", "Discard"], avoiding: "Other"))
            #expect(["Draw", "Discard"].contains(outcome.rule))
        }
    }

    @Test func disabledDuplicateAvoidanceAllowsPreviousRule() throws {
        var generator = FirstIndexGenerator()
        let outcome = try #require(RuleGenerator.pick(
            from: ["Draw", "Discard"], avoiding: nil, using: &generator
        ))
        #expect(outcome.rule == "Draw")
    }

    @Test func previousResultIsScopedToItsSourceList() throws {
        let suite = "SpinSettingsTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var history = RuleHistory(defaults: defaults)
        let first = RuleList(name: "A", rules: ["Draw"])
        let second = RuleList(name: "B", rules: ["Discard"])
        history.record(rule: "Draw", list: first)
        history.record(rule: "Discard", list: second)
        #expect(history.entries.first(where: { $0.listID == first.id })?.rule == "Draw")
        #expect(history.entries.first(where: { $0.listID == second.id })?.rule == "Discard")
        history.clear()
        #expect(history.entries.first(where: { $0.listID == first.id }) == nil)
    }
}

private struct FirstIndexGenerator: RandomNumberGenerator {
    mutating func next() -> UInt64 { 0 }
}
