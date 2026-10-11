import Foundation

enum RuleListTransfer {
    static let maximumFileBytes = 1_000_000
    static let maximumRules = 1_000

    private struct Envelope: Codable {
        let format: String
        let version: Int
        let list: RuleList
    }

    enum TransferError: LocalizedError {
        case invalidFile, unsupportedVersion, tooLarge, invalidContent

        var errorDescription: String? {
            switch self {
            case .invalidFile: return "Choose a YGO Shuffle rule-list JSON file."
            case .unsupportedVersion: return "This file uses an unsupported format version. Update YGO Shuffle to import it."
            case .tooLarge: return "Rule-list files must be under 1 MB and contain at most 1,000 rules."
            case .invalidContent: return "The list needs a name and nonempty rule text."
            }
        }
    }

    static func encode(_ list: RuleList) throws -> Data {
        try validate(list)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(Envelope(format: "YGOShuffle", version: 1, list: list))
        guard data.count <= maximumFileBytes else { throw TransferError.tooLarge }
        return data
    }

    static func decode(_ data: Data, existingNames: [String]) throws -> RuleList {
        guard data.count <= maximumFileBytes else { throw TransferError.tooLarge }
        let decoder = JSONDecoder()
        // An envelope marker must be honored rather than falling back to legacy decoding.
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TransferError.invalidFile
        }
        let imported: RuleList
        if object["format"] != nil || object["version"] != nil || object["list"] != nil {
            guard object["format"] as? String == "YGOShuffle" else { throw TransferError.invalidFile }
            guard let version = object["version"] as? Int, version == 1 else {
                throw TransferError.unsupportedVersion
            }
            guard let envelope = try? decoder.decode(Envelope.self, from: data) else {
                throw TransferError.invalidFile
            }
            imported = envelope.list
        } else {
            // Accept standalone current lists and older string-array lists.
            guard let list = try? decoder.decode(RuleList.self, from: data) else {
                throw TransferError.invalidFile
            }
            imported = list
        }
        try validate(imported)
        let name = uniqueName(imported.name.trimmingCharacters(in: .whitespacesAndNewlines), existingNames: existingNames)
        // Never reuse identities from another device or overwrite an existing list.
        return imported.duplicate(named: name)
    }

    static func filename(for name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitized = name.unicodeScalars.map { allowed.contains($0) ? String($0) : "_" }.joined()
        let stem = String(sanitized.prefix(80))
        return (stem.isEmpty ? "YGOShuffle-Rules" : stem) + ".json"
    }

    private static func validate(_ list: RuleList) throws {
        guard list.rules.count <= maximumRules else { throw TransferError.tooLarge }
        guard !list.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              list.rules.allSatisfy({ !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw TransferError.invalidContent
        }
    }

    private static func uniqueName(_ name: String, existingNames: [String]) -> String {
        let names = Set(existingNames.map { $0.lowercased() })
        guard names.contains(name.lowercased()) else { return name }
        var candidate = name + " Imported"
        var number = 2
        while names.contains(candidate.lowercased()) {
            candidate = name + " Imported \(number)"
            number += 1
        }
        return candidate
    }
}
