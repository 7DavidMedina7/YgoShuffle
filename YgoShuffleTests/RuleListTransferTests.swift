import Foundation
import Testing
@testable import YgoShuffle

struct RuleListTransferTests {
    @Test func roundTripPreservesContentAndFiltersWithFreshIdentities() throws {
        let original = RuleList(name: "Party 🎴", entries: [
            Rule(text: "Draw two cards.", category: .drawAndHand),
            Rule(text: "Draw two cards.", category: .lifePoints)
        ], enabledCategories: [.drawAndHand])
        let imported = try RuleListTransfer.decode(RuleListTransfer.encode(original), existingNames: [])
        #expect(imported.name == original.name)
        #expect(imported.id != original.id)
        #expect(imported.rules.map { $0.text } == original.rules.map { $0.text })
        #expect(imported.rules.map { $0.category } == original.rules.map { $0.category })
        #expect(imported.enabledCategories == original.enabledCategories)
        #expect(Set(imported.rules.map { $0.id }).count == 2)
        #expect(Set(imported.rules.map { $0.id }).isDisjoint(with: original.rules.map { $0.id }))
    }

    @Test func repeatedImportsChooseUniqueNamesAndIDs() throws {
        let data = try RuleListTransfer.encode(RuleList(name: "Custom", rules: ["Draw"]))
        let first = try RuleListTransfer.decode(data, existingNames: ["custom", "Custom Imported"])
        #expect(first.name == "Custom Imported 2")
        let second = try RuleListTransfer.decode(data, existingNames: ["Custom", "Custom Imported", first.name])
        #expect(second.name == "Custom Imported 3")
        #expect(second.id != first.id)
        #expect(second.rules[0].id != first.rules[0].id)
    }

    @Test func importsLegacyStandaloneLists() throws {
        let data = Data(#"{"name":"Legacy","rules":["Draw two cards.","Custom"]}"#.utf8)
        let list = try RuleListTransfer.decode(data, existingNames: [])
        #expect(list.rules.map { $0.text } == ["Draw two cards.", "Custom"])
        #expect(list.rules.map { $0.category } == [.drawAndHand, .miscellaneous])
        #expect(list.enabledCategories == Set(RuleCategory.allCases))
    }

    @Test func importsCurrentStandaloneListsAndEmptyFilters() throws {
        let original = RuleList(name: "Empty", entries: [], enabledCategories: [])
        let data = try JSONEncoder().encode(original)
        let imported = try RuleListTransfer.decode(data, existingNames: [])
        #expect(imported.rules.isEmpty)
        #expect(imported.enabledCategories.isEmpty)
    }

    @Test func rejectsMalformedUnsupportedAndUnrelatedFiles() throws {
        let malformed = Data("not JSON".utf8)
        #expect(throws: (any Error).self) {
            try RuleListTransfer.decode(malformed, existingNames: [])
        }
        let valid = try RuleListTransfer.encode(RuleList(name: "Custom", rules: []))
        var envelope = try #require(JSONSerialization.jsonObject(with: valid) as? [String: Any])
        envelope["version"] = 99
        let future = try JSONSerialization.data(withJSONObject: envelope)
        #expect(throws: (any Error).self) {
            try RuleListTransfer.decode(future, existingNames: [])
        }
        envelope["version"] = 1
        envelope["format"] = "OtherApp"
        let unrelated = try JSONSerialization.data(withJSONObject: envelope)
        #expect(throws: (any Error).self) {
            try RuleListTransfer.decode(unrelated, existingNames: [])
        }
    }

    @Test func rejectsBlankContentAndOversizedFiles() {
        #expect(throws: (any Error).self) {
            try RuleListTransfer.encode(RuleList(name: "  ", rules: []))
        }
        #expect(throws: (any Error).self) {
            try RuleListTransfer.decode(Data(#"{"name":"Bad","rules":[" "]}"#.utf8), existingNames: [])
        }
        #expect(throws: (any Error).self) {
            try RuleListTransfer.decode(Data(repeating: 0, count: RuleListTransfer.maximumFileBytes + 1), existingNames: [])
        }
        #expect(throws: (any Error).self) {
            try RuleListTransfer.encode(RuleList(name: "Huge", rules: Array(repeating: "Draw", count: RuleListTransfer.maximumRules + 1)))
        }
    }

    @Test func filenameIsSafeAndBounded() {
        let filename = RuleListTransfer.filename(for: "../Party/Rules\n")
        #expect(filename.hasSuffix(".json"))
        #expect(!filename.contains("/"))
        #expect(!filename.contains(".."))
        #expect(!filename.contains("\n"))
        #expect(RuleListTransfer.filename(for: "").hasPrefix("YGOShuffle-Rules"))
        #expect(RuleListTransfer.filename(for: String(repeating: "x", count: 200)).count == 85)
    }
}
