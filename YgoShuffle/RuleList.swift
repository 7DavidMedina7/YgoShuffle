import Foundation

struct RuleList: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var rules: [String]

    init(id: UUID = UUID(), name: String, rules: [String]) {
        self.id = id
        self.name = name
        self.rules = rules
    }

    private enum CodingKeys: String, CodingKey { case id, name, rules }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        // Older data without IDs is migrated once, then saved on launch.
        id = try values.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try values.decode(String.self, forKey: .name)
        rules = try values.decode([String].self, forKey: .rules)
    }
}

enum RuleListPersistence {
    static func selectedID(in lists: [RuleList], defaults: UserDefaults = .standard) -> UUID? {
        if let value = defaults.string(forKey: "selectedRuleListID"),
           let id = UUID(uuidString: value),
           lists.contains(where: { $0.id == id }) {
            return id
        }
        // Only use the old position when there is no new ID selection.
        if defaults.string(forKey: "selectedRuleListID") == nil {
            let index = defaults.integer(forKey: "selectedRuleListIndex")
            if lists.indices.contains(index) { return lists[index].id }
        }
        return lists.first?.id
    }
}
