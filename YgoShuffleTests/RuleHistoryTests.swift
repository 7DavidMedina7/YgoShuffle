import Foundation
import Testing
@testable import YgoShuffle

struct RuleHistoryTests {
    @Test func recordsNewestFirstAndSurvivesReload() throws {
        let suite = "RuleHistoryTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var history = RuleHistory(defaults: defaults)
        let list = RuleList(name: "Custom", rules: ["Draw", "Discard"])
        let firstTime = Date(timeIntervalSince1970: 100)
        let secondTime = Date(timeIntervalSince1970: 200)
        history.record(rule: "Draw", list: list, generatedAt: firstTime)
        history.record(rule: "Discard", list: list, generatedAt: secondTime)

        let reloaded = RuleHistory(defaults: defaults)
        #expect(reloaded.entries == history.entries)
        #expect(reloaded.entries.map { $0.rule } == ["Discard", "Draw"])
        #expect(reloaded.entries.first?.generatedAt == secondTime)
        #expect(reloaded.entries.first?.listID == list.id)
        #expect(reloaded.entries.first?.listName == "Custom")
    }

    @Test func repeatedRulesHaveDistinctIDsAndListSnapshots() throws {
        let suite = "RuleHistoryTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var history = RuleHistory(defaults: defaults)
        var list = RuleList(name: "Original", rules: ["Draw"])
        history.record(rule: "Draw", list: list)
        list.name = "Renamed"
        list.rules = [Rule(text: "Discard")]
        history.record(rule: "Draw", list: list)

        #expect(history.entries.count == 2)
        #expect(history.entries[0].id != history.entries[1].id)
        #expect(history.entries[0].listName == "Renamed")
        #expect(history.entries[1].listName == "Original")
        #expect(history.entries[1].rule == "Draw")
    }

    @Test func capsHistoryAndClearsPersistedResults() throws {
        let suite = "RuleHistoryTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var history = RuleHistory(defaults: defaults)
        let list = RuleList(name: "Custom", rules: [])
        for index in 0..<(RuleHistory.maximumEntries + 5) {
            history.record(rule: "Rule \(index)", list: list)
        }
        #expect(history.entries.count == RuleHistory.maximumEntries)
        #expect(history.entries.first?.rule == "Rule 104")
        #expect(history.entries.last?.rule == "Rule 5")
        #expect(RuleHistory(defaults: defaults).entries == history.entries)
        history.clear()
        #expect(history.entries.isEmpty)
        #expect(RuleHistory(defaults: defaults).entries.isEmpty)
        #expect(defaults.object(forKey: RuleHistory.storageKey) == nil)
    }

    @Test func missingOrCorruptHistoryStartsEmptyWithoutChangingLists() throws {
        let suite = "RuleHistoryTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        #expect(RuleHistory(defaults: defaults).entries.isEmpty)
        let lists = try JSONEncoder().encode([RuleList(name: "Saved", rules: ["Draw"])])
        defaults.set(lists, forKey: "ruleLists")
        defaults.set(Data("invalid JSON".utf8), forKey: RuleHistory.storageKey)
        var history = RuleHistory(defaults: defaults)
        #expect(history.entries.isEmpty)
        history.clear()
        #expect(defaults.data(forKey: "ruleLists") == lists)
    }
}
