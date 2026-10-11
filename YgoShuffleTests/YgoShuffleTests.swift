import Foundation
import Testing
@testable import YgoShuffle

struct YgoShuffleTests {
    @Test func identityAndEditsSurviveRoundTrip() throws {
        var list = RuleList(name: "Custom", rules: ["Draw", "Draw"])
        let id = list.id
        list.name = "Renamed"
        list.rules.append("Discard")
        let decoded = try JSONDecoder().decode(RuleList.self, from: JSONEncoder().encode(list))
        #expect(decoded == list)
        #expect(decoded.id == id)
        #expect(RuleList(name: list.name, rules: list.rules).id != id)
    }

    @Test func legacyListWithoutIDMigratesAndKeepsItsRules() throws {
        let data = Data(#"{"name":"Legacy","rules":["Draw","Draw"]}"#.utf8)
        let migrated = try JSONDecoder().decode(RuleList.self, from: data)
        let reloaded = try JSONDecoder().decode(RuleList.self, from: JSONEncoder().encode(migrated))
        #expect(reloaded.id == migrated.id)
        #expect(reloaded.rules == ["Draw", "Draw"])
    }

    @Test func selectionMigrationReorderingAndDeletion() throws {
        let suite = "YgoShuffleTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let a = RuleList(name: "A", rules: [])
        let b = RuleList(name: "B", rules: [])
        defaults.set(1, forKey: "selectedRuleListIndex")
        #expect(RuleListPersistence.selectedID(in: [a, b], defaults: defaults) == b.id)
        defaults.set(b.id.uuidString, forKey: "selectedRuleListID")
        #expect(RuleListPersistence.selectedID(in: [b, a], defaults: defaults) == b.id)
        #expect(RuleListPersistence.selectedID(in: [a], defaults: defaults) == a.id)
        #expect(RuleListPersistence.selectedID(in: [], defaults: defaults) == nil)
    }

    @Test(arguments: [-1, 99])
    func invalidLegacyIndexFallsBack(index: Int) throws {
        let suite = "YgoShuffleTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let list = RuleList(name: "A", rules: [])
        defaults.set(index, forKey: "selectedRuleListIndex")
        #expect(RuleListPersistence.selectedID(in: [list], defaults: defaults) == list.id)
    }

    @Test func emptyAndRerollOnlyListsHaveNoOutcome() {
        #expect(RuleGenerator.pick(from: []) == nil)
        #expect(RuleGenerator.pick(from: [RuleGenerator.rerollRule]) == nil)
        #expect(RuleGenerator.pick(from: Array(repeating: RuleGenerator.rerollRule, count: 10)) == nil)
        #expect(RuleGenerator.pick(from: ["Draw"]) == .init(rule: "Draw", didReroll: false))
    }

    @Test func mixedListRerollsWithoutReturningTheSentinel() throws {
        var generator = SeededGenerator()
        var sawReroll = false
        var sawDirectDraw = false
        for _ in 0..<100 {
            let outcome = try #require(RuleGenerator.pick(
                from: [RuleGenerator.rerollRule, "Draw", "Draw"], using: &generator
            ))
            #expect(outcome.rule == "Draw")
            sawReroll = sawReroll || outcome.didReroll
            sawDirectDraw = sawDirectDraw || !outcome.didReroll
        }
        #expect(sawReroll)
        #expect(sawDirectDraw)
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64 = 42
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
