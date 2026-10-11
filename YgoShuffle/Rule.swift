import Foundation

enum RuleCategory: String, Codable, CaseIterable, Identifiable {
    case drawAndHand, lifePoints, battle, restrictions, monsters, spellsAndTraps, miscellaneous

    var id: String { rawValue }

    var title: String {
        switch self {
        case .drawAndHand: return "Draw & Hand"
        case .lifePoints: return "Life Points"
        case .battle: return "Battle"
        case .restrictions: return "Restrictions"
        case .monsters: return "Monster Effects & Removal"
        case .spellsAndTraps: return "Spell & Trap Effects"
        case .miscellaneous: return "Miscellaneous"
        }
    }
}

struct Rule: Codable, Identifiable, Equatable {
    let id: UUID
    var text: String
    var category: RuleCategory

    init(id: UUID = UUID(), text: String, category: RuleCategory = .miscellaneous) {
        self.id = id
        self.text = text
        self.category = category
    }
}
