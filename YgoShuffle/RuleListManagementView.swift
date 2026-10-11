import SwiftUI
import UniformTypeIdentifiers

// Manage, reorder, and duplicate rule lists.
struct RuleListManagementView: View {
    @Binding var ruleLists: [RuleList]
    @Binding var selectedListID: UUID?
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingNewListAlert = false
    @State private var newListName = ""
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var exportDocument: RuleListDocument?
    @State private var exportFilename = "YGOShuffle-Rules.json"
    @State private var sharedFile: SharedRuleListFile?
    @State private var shareDirectory: URL?
    @State private var transferMessage: TransferMessage?

    private struct TransferMessage: Identifiable {
        let id = UUID()
        let title: String
        let text: String
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Rule Lists")) {
                    ForEach(ruleLists) { ruleList in
                        NavigationLink(destination: RulesManagementView(
                            ruleList: Binding(
                                get: { ruleLists.first(where: { $0.id == ruleList.id }) ?? ruleList },
                                set: {
                                    guard let currentIndex = ruleLists.firstIndex(where: { $0.id == ruleList.id }) else { return }
                                    ruleLists[currentIndex] = $0
                                    onSave()
                                }
                            ),
                            onSave: onSave
                        )) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ruleList.name)
                                        .font(.headline)
                                    Text("\(ruleList.rules.count) rules")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if ruleList.id == selectedListID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                deleteRuleList(id: ruleList.id)
                            }
                            .disabled(ruleLists.count == 1) // Don't allow deleting the last list
                        }
                        .swipeActions(edge: .leading) {
                            Button("Duplicate") {
                                duplicateRuleList(id: ruleList.id)
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button {
                                shareRuleList(ruleList)
                            } label: {
                                Label("Share JSON", systemImage: "square.and.arrow.up")
                            }
                            Button {
                                exportRuleList(ruleList)
                            } label: {
                                Label("Save JSON File", systemImage: "doc")
                            }
                            Button("Select as Active") {
                                selectedListID = ruleList.id
                                onSave()
                            }
                            
                            Button("Duplicate") {
                                duplicateRuleList(id: ruleList.id)
                            }
                            
                            if ruleLists.count > 1 {
                                Button("Delete", role: .destructive) {
                                    deleteRuleList(id: ruleList.id)
                                }
                            }
                        }
                    }
                    .onMove(perform: moveRuleList)
                }
                
                Section {
                    Button {
                        showingImporter = true
                    } label: {
                        Label("Import Rule List", systemImage: "square.and.arrow.down")
                    }
                } footer: {
                    Text("Import a JSON file to add a new list. Press and hold a list to share it or save its JSON file.")
                }
            }
            .navigationTitle("Rule Lists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        EditButton()
                        Button("Add List") {
                            showingNewListAlert = true
                        }
                    }
                }
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
                importRuleList(result)
            }
            .fileExporter(isPresented: $showingExporter, document: exportDocument,
                          contentType: .json, defaultFilename: exportFilename) { result in
                if case .failure(let error) = result { showTransferError(error) }
            }
            .sheet(item: $sharedFile, onDismiss: removeShareFile) { file in
                RuleListShareSheet(url: file.url)
            }
            .alert(item: $transferMessage) { message in
                Alert(title: Text(message.title), message: Text(message.text), dismissButton: .default(Text("OK")))
            }
            .alert("New Rule List", isPresented: $showingNewListAlert) {
                TextField("List Name", text: $newListName)
                Button("Cancel", role: .cancel) {
                    newListName = ""
                }
                Button("Create") {
                    createNewRuleList()
                }
                .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } message: {
                Text("Enter a name for your new rule list")
            }
        }
    }
    
    private func exportRuleList(_ list: RuleList) {
        do {
            exportDocument = RuleListDocument(data: try RuleListTransfer.encode(list))
            exportFilename = RuleListTransfer.filename(for: list.name)
            showingExporter = true
        } catch { showTransferError(error) }
    }

    private func shareRuleList(_ list: RuleList) {
        do {
            let data = try RuleListTransfer.encode(list)
            removeShareFile()
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            shareDirectory = directory
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent(RuleListTransfer.filename(for: list.name))
            try data.write(to: url, options: .atomic)
            sharedFile = SharedRuleListFile(url: url)
        } catch {
            removeShareFile()
            showTransferError(error)
        }
    }

    private func removeShareFile() {
        if let directory = shareDirectory {
            try? FileManager.default.removeItem(at: directory)
        }
        shareDirectory = nil
    }

    private func importRuleList(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize
            if let size, size > RuleListTransfer.maximumFileBytes {
                throw RuleListTransfer.TransferError.tooLarge
            }
            let data = try Data(contentsOf: url)
            let imported = try RuleListTransfer.decode(data, existingNames: ruleLists.map { $0.name })
            ruleLists.append(imported)
            onSave()
            transferMessage = TransferMessage(title: "List Imported",
                                              text: "Added \(imported.name) with \(imported.rules.count) rules.")
        } catch { showTransferError(error) }
    }

    private func showTransferError(_ error: Error) {
        let cocoaError = error as NSError
        if cocoaError.domain == NSCocoaErrorDomain && cocoaError.code == NSUserCancelledError { return }
        transferMessage = TransferMessage(title: "Couldn’t Transfer List", text: error.localizedDescription)
    }

    func createNewRuleList() {
        let trimmedName = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newList = RuleList(name: trimmedName, rules: [])
        ruleLists.append(newList)
        onSave()
        newListName = ""
    }
    
    func duplicateRuleList(id: UUID) {
        guard let index = ruleLists.firstIndex(where: { $0.id == id }) else { return }
        
        let originalList = ruleLists[index]
        let duplicatedName = generateDuplicateName(from: originalList.name)
        let duplicatedList = originalList.duplicate(named: duplicatedName)
        
        // Insert the duplicated list right after the original
        ruleLists.insert(duplicatedList, at: index + 1)
        
        onSave()
    }
    
    private func generateDuplicateName(from originalName: String) -> String {
        let baseName: String
        let copyNumber: Int
        
        // Check if the name already has a "Copy" suffix with a number
        let copyPattern = #"^(.*?)(?: Copy(?: (\d+))?)?$"#
        if let regex = try? NSRegularExpression(pattern: copyPattern),
           let match = regex.firstMatch(in: originalName, range: NSRange(originalName.startIndex..., in: originalName)) {
            
            if let baseRange = Range(match.range(at: 1), in: originalName) {
                baseName = String(originalName[baseRange]).trimmingCharacters(in: .whitespaces)
                
                if let numberRange = Range(match.range(at: 2), in: originalName),
                   let number = Int(originalName[numberRange]) {
                    copyNumber = number + 1
                } else if originalName.contains("Copy") {
                    copyNumber = 2
                } else {
                    copyNumber = 1
                }
            } else {
                baseName = originalName
                copyNumber = 1
            }
        } else {
            baseName = originalName
            copyNumber = 1
        }
        
        // Generate the new name
        let newName = copyNumber == 1 ? "\(baseName) Copy" : "\(baseName) Copy \(copyNumber)"
        
        // Check if this name already exists and increment if needed
        var finalName = newName
        var counter = copyNumber
        while ruleLists.contains(where: { $0.name == finalName }) {
            counter += 1
            finalName = "\(baseName) Copy \(counter)"
        }
        
        return finalName
    }
    
    func deleteRuleList(id: UUID) {
        guard ruleLists.count > 1 else { return } // Don't delete the last list
        
        guard let index = ruleLists.firstIndex(where: { $0.id == id }) else { return }
        let deletedID = ruleLists[index].id
        ruleLists.remove(at: index)
        if selectedListID == deletedID {
            selectedListID = ruleLists.first?.id
        }
        onSave()
    }

    func moveRuleList(from source: IndexSet, to destination: Int) {
        ruleLists.move(fromOffsets: source, toOffset: destination)
        onSave()
    }
}

