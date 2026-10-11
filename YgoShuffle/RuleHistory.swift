import Foundation

struct RuleHistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let rule: String
    let listID: UUID
    let listName: String
    let generatedAt: Date

    init(rule: String, list: RuleList, generatedAt: Date = Date()) {
        id = UUID()
        self.rule = rule
        listID = list.id
        listName = list.name
        self.generatedAt = generatedAt
    }
}

/// Keeps snapshots so editing or deleting a list never changes past results.
struct RuleHistory {
    static let storageKey = "ruleHistory"
    static let maximumEntries = 100
    private(set) var entries: [RuleHistoryEntry]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([RuleHistoryEntry].self, from: data) {
            entries = Array(decoded.prefix(Self.maximumEntries))
        } else {
            entries = []
        }
    }

    mutating func record(rule: String, list: RuleList, generatedAt: Date = Date()) {
        entries.insert(RuleHistoryEntry(rule: rule, list: list, generatedAt: generatedAt), at: 0)
        entries = Array(entries.prefix(Self.maximumEntries))
        persist()
    }

    mutating func clear() {
        entries.removeAll()
        defaults.removeObject(forKey: Self.storageKey)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
