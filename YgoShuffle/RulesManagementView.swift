import SwiftUI

struct RulesManagementView: View {
    @Binding var ruleList: RuleList
    let onSave: () -> Void
    @State private var newRule = ""
    @State private var newCategory: RuleCategory = .miscellaneous
    @State private var editingRule: Rule?
    @State private var showingRenameAlert = false
    @State private var newListName = ""

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("Add New Rule").font(.headline)
                HStack {
                    TextField("Enter new rule...", text: $newRule, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3, reservesSpace: true)
                    Button("Add") {
                        let text = newRule.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        ruleList.rules.append(Rule(text: text, category: newCategory))
                        onSave()
                        newRule = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(.black)
                    .disabled(newRule.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                Picker("Category", selection: $newCategory) {
                    ForEach(RuleCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
            }
            .padding()
            .background(AppTheme.surface)
            .cornerRadius(12)
            .padding()

            List {
                ForEach(ruleList.rules) { rule in
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(rule.text)
                            Text(rule.category.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            editingRule = rule
                        } label: {
                            Image(systemName: "pencil").foregroundColor(AppTheme.accent)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit rule")
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(AppTheme.surface)
                }
                .onDelete { offsets in
                    ruleList.rules.remove(atOffsets: offsets)
                    onSave()
                }
                .onMove { source, destination in
                    ruleList.rules.move(fromOffsets: source, toOffset: destination)
                    onSave()
                }
            }
        }
        .appPageStyle()
        .navigationTitle(ruleList.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button("Rename") {
                        newListName = ruleList.name
                        showingRenameAlert = true
                    }
                    EditButton()
                }
            }
        }
        .sheet(item: $editingRule) { rule in
            RuleEditorView(rule: rule) { updated in
                guard let index = ruleList.rules.firstIndex(where: { $0.id == updated.id }) else { return }
                ruleList.rules[index] = updated
                onSave()
            }
        }
        .alert("Rename List", isPresented: $showingRenameAlert) {
            TextField("List Name", text: $newListName)
            Button("Cancel", role: .cancel) { newListName = "" }
            Button("Save") {
                let name = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                ruleList.name = name
                onSave()
                newListName = ""
            }
            .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Enter a new name for this rule list")
        }
    }
}

private struct RuleEditorView: View {
    @State var rule: Rule
    let onSave: (Rule) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Rule Text") {
                    TextField("Rule text", text: $rule.text, axis: .vertical)
                        .lineLimit(5...10)
                }
                .listRowBackground(AppTheme.surface)
                Section {
                    Picker("Category", selection: $rule.category) {
                        ForEach(RuleCategory.allCases) { category in
                            Text(category.title).tag(category)
                        }
                    }
                }
                .listRowBackground(AppTheme.surface)
            }
            .appPageStyle()
            .navigationTitle("Edit Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        rule.text = rule.text.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(rule)
                        dismiss()
                    }
                    .disabled(rule.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
