import SwiftUI

// Individual Rule List Management View
struct RulesManagementView: View {
    @Binding var ruleList: RuleList
    let onSave: () -> Void
    @State private var newRule: String = ""
    @State private var editingIndex: Int? = nil
    @State private var editingText: String = ""
    @State private var showingEditAlert = false
    @State private var showingRenameAlert = false
    @State private var newListName: String = ""
    @Environment(\.dismiss) private var dismiss
    
    // Computed property to work with rules directly
    private var rulesBinding: Binding<[String]> {
        Binding(
            get: { ruleList.rules },
            set: { newRules in
                ruleList.rules = newRules
                onSave()
            }
        )
    }
    
    var body: some View {
        VStack {
            // Add new rule section
            VStack(alignment: .leading, spacing: 10) {
                Text("Add New Rule")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    TextField("Enter new rule...", text: $newRule, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3, reservesSpace: true)
                    
                    Button("Add") {
                        guard !newRule.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        let trimmedRule = newRule.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        var currentRules = rulesBinding.wrappedValue
                        currentRules.append(trimmedRule)
                        rulesBinding.wrappedValue = currentRules
                        
                        newRule = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newRule.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding()
            
            // Rules list
            List {
                ForEach(Array(rulesBinding.wrappedValue.enumerated()), id: \.offset) { index, rule in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Rule #\(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(rule)
                                    .font(.body)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                editingIndex = index
                                editingText = rule
                                showingEditAlert = true
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteRule)
                .onMove(perform: moveRule)
            }
        }
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
        .alert("Edit Rule", isPresented: $showingEditAlert) {
            TextField("Rule text", text: $editingText, axis: .vertical)
                .lineLimit(5, reservesSpace: true)
            
            Button("Cancel", role: .cancel) {
                editingIndex = nil
                editingText = ""
            }
            
            Button("Save") {
                if let index = editingIndex,
                   !editingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    
                    var currentRules = rulesBinding.wrappedValue
                    currentRules[index] = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
                    rulesBinding.wrappedValue = currentRules
                }
                editingIndex = nil
                editingText = ""
            }
            .disabled(editingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            if let index = editingIndex {
                Text("Edit Rule #\(index + 1)")
            }
        }
        .alert("Rename List", isPresented: $showingRenameAlert) {
            TextField("List Name", text: $newListName)
            Button("Cancel", role: .cancel) {
                newListName = ""
            }
            Button("Save") {
                let trimmedName = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedName.isEmpty {
                    ruleList.name = trimmedName
                    onSave()
                }
                newListName = ""
            }
            .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Enter a new name for this rule list")
        }
    }
    
    func deleteRule(at offsets: IndexSet) {
        var currentRules = rulesBinding.wrappedValue
        currentRules.remove(atOffsets: offsets)
        rulesBinding.wrappedValue = currentRules
    }
    
    func moveRule(from source: IndexSet, to destination: Int) {
        var currentRules = rulesBinding.wrappedValue
        currentRules.move(fromOffsets: source, toOffset: destination)
        rulesBinding.wrappedValue = currentRules
    }
}

