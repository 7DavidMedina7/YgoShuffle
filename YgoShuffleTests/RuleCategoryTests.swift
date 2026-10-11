import Foundation
import Testing
@testable import YgoShuffle

struct RuleCategoryTests {
    @Test func migratesLegacyStringsAndPreservesListIdentity() throws {
        let id = UUID()
        let legacy: [String: Any] = [
            "id": id.uuidString, "name": "Saved",
            "rules": ["Draw two cards.", "Custom rule", "Custom rule"]
        ]
        let data = try JSONSerialization.data(withJSONObject: legacy)
        let list = try JSONDecoder().decode(RuleList.self, from: data)
        #expect(list.id == id)
        #expect(list.rules.map { $0.text } == ["Draw two cards.", "Custom rule", "Custom rule"])
        #expect(list.rules.map { $0.category } == [.drawAndHand, .miscellaneous, .miscellaneous])
        #expect(Set(list.rules.map { $0.id }).count == 3)
        #expect(list.enabledCategories == Set(RuleCategory.allCases))
        let reloaded = try JSONDecoder().decode(RuleList.self, from: JSONEncoder().encode(list))
        #expect(reloaded == list)
    }

    @Test func filteringPreservesOrderAndRepeatedRules() {
        var list = RuleList(name: "Custom", entries: [
            Rule(text: "Draw", category: .drawAndHand),
            Rule(text: "LP", category: .lifePoints),
            Rule(text: "Draw", category: .drawAndHand)
        ])
        list.enabledCategories = [.drawAndHand]
        #expect(list.eligibleRules == ["Draw", "Draw"])
        #expect(list.rules.count == 3)
        list.enabledCategories = []
        #expect(list.eligibleRules.isEmpty)
        #expect(RuleGenerator.pick(from: list.eligibleRules) == nil)
        list.enabledCategories = Set(RuleCategory.allCases)
        #expect(list.eligibleRules == ["Draw", "LP", "Draw"])
    }

    @Test func filtersAndEditedRuleIdentitySurviveReload() throws {
        var list = RuleList(name: "Custom", entries: [Rule(text: "Old", category: .miscellaneous)])
        let ruleID = list.rules[0].id
        list.rules[0].text = "New"
        list.rules[0].category = .lifePoints
        list.enabledCategories = [.lifePoints]
        let restored = try JSONDecoder().decode(RuleList.self, from: JSONEncoder().encode(list))
        #expect(restored == list)
        #expect(restored.rules[0].id == ruleID)
        #expect(restored.eligibleRules == ["New"])
    }

    @Test func emptyCategorySelectionRemainsEmptyAfterReload() throws {
        var list = RuleList(name: "Custom", rules: ["Draw two cards."])
        list.enabledCategories = []
        let restored = try JSONDecoder().decode(RuleList.self, from: JSONEncoder().encode(list))
        #expect(restored.enabledCategories.isEmpty)
        #expect(restored.eligibleRules.isEmpty)
    }

    @Test func duplicateCopiesCategoriesAndFiltersWithFreshIDs() {
        let original = RuleList(name: "Custom", entries: [
            Rule(text: "Draw", category: .drawAndHand)
        ], enabledCategories: [.drawAndHand])
        let copy = original.duplicate(named: "Custom Copy")
        #expect(copy.id != original.id)
        #expect(copy.rules[0].id != original.rules[0].id)
        #expect(copy.rules[0].text == original.rules[0].text)
        #expect(copy.rules[0].category == .drawAndHand)
        #expect(copy.enabledCategories == original.enabledCategories)
    }

    @Test func defaultRulesHaveCategoryCoverageAndRerollsStillTerminate() throws {
        let list = RuleList(name: "Default", rules: DefaultRules.rules)
        #expect(list.eligibleRules == DefaultRules.rules)
        for category in RuleCategory.allCases {
            #expect(list.rules.contains { $0.category == category })
        }
        var custom = RuleList(name: "Custom", entries: [
            Rule(text: RuleGenerator.rerollRule, category: .miscellaneous),
            Rule(text: "Draw", category: .drawAndHand)
        ], enabledCategories: [.miscellaneous])
        #expect(RuleGenerator.pick(from: custom.eligibleRules) == nil)
        custom.enabledCategories.insert(.drawAndHand)
        let result = try #require(RuleGenerator.pick(from: custom.eligibleRules))
        #expect(result.rule == "Draw")
    }
}
