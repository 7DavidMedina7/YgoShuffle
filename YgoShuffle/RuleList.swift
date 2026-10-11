import Foundation

struct RuleList: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var rules: [Rule]
    var enabledCategories: Set<RuleCategory>

    init(id: UUID = UUID(), name: String, rules: [String]) {
        self.init(id: id, name: name, entries: rules.map {
            Rule(text: $0, category: DefaultRules.category(for: $0))
        })
    }

    init(id: UUID = UUID(), name: String, entries: [Rule],
         enabledCategories: Set<RuleCategory> = Set(RuleCategory.allCases)) {
        self.id = id
        self.name = name
        rules = entries
        self.enabledCategories = enabledCategories
    }

    var eligibleRules: [String] {
        rules.filter { enabledCategories.contains($0.category) }.map { $0.text }
    }

    func duplicate(named name: String) -> RuleList {
        RuleList(name: name, entries: rules.map { Rule(text: $0.text, category: $0.category) },
                 enabledCategories: enabledCategories)
    }

    private enum CodingKeys: String, CodingKey { case id, name, rules, enabledCategories }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try values.decode(String.self, forKey: .name)
        // Legacy string rules receive stable IDs and categories without changing their text/order.
        if let legacy = try? values.decode([String].self, forKey: .rules) {
            rules = legacy.map { Rule(text: $0, category: DefaultRules.category(for: $0)) }
        } else {
            rules = try values.decode([Rule].self, forKey: .rules)
        }
        enabledCategories = try values.decodeIfPresent(Set<RuleCategory>.self, forKey: .enabledCategories)
            ?? Set(RuleCategory.allCases)
    }
}

enum RuleListPersistence {
    static func selectedID(in lists: [RuleList], defaults: UserDefaults = .standard) -> UUID? {
        if let value = defaults.string(forKey: "selectedRuleListID"),
           let id = UUID(uuidString: value),
           lists.contains(where: { $0.id == id }) {
            return id
        }
        if defaults.string(forKey: "selectedRuleListID") == nil {
            let index = defaults.integer(forKey: "selectedRuleListIndex")
            if lists.indices.contains(index) { return lists[index].id }
        }
        return lists.first?.id
    }
}
