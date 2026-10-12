import SwiftUI

struct RuleCategoryFilterView: View {
    @Binding var ruleList: RuleList
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(RuleCategory.allCases) { category in
                        Toggle(isOn: Binding(
                            get: { ruleList.enabledCategories.contains(category) },
                            set: { enabled in
                                var updated = ruleList
                                if enabled { updated.enabledCategories.insert(category) }
                                else { updated.enabledCategories.remove(category) }
                                ruleList = updated
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.title)
                                Text("\(ruleList.rules.filter { $0.category == category }.count) rules")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text(ruleList.name)
                } footer: {
                    Text("Only enabled categories are used when you spin. These filters are saved separately for each list.")
                }
                .listRowBackground(AppTheme.surface)
                Section {
                    Button("Enable All Categories") {
                        var updated = ruleList
                        updated.enabledCategories = Set(RuleCategory.allCases)
                        ruleList = updated
                    }
                    Text("\(ruleList.eligibleRules.count) of \(ruleList.rules.count) rules enabled")
                        .foregroundStyle(.secondary)
                    if ruleList.eligibleRules.isEmpty {
                        Text("Enable a category with rules to spin again.")
                            .foregroundStyle(.orange)
                    }
                }
                .listRowBackground(AppTheme.surface)
            }
            .appPageStyle()
            .navigationTitle("Rule Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
