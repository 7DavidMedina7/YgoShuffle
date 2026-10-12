import SwiftUI

struct RuleHistoryView: View {
    let entries: [RuleHistoryEntry]
    let onClear: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Rule History Yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Completed spins will appear here.")
                    )
                } else {
                    List(entries) { entry in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(entry.rule)
                                .font(.body)
                            Text(entry.listName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(entry.generatedAt, format: .dateTime.month().day().hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(AppTheme.surface)
                    }
                }
            }
            .appPageStyle()
            .navigationTitle("Rule History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear", role: .destructive) {
                        showingClearConfirmation = true
                    }
                    .disabled(entries.isEmpty)
                }
                ToolbarItem(placement: .bottomBar) {
                    Text("Your last \(RuleHistory.maximumEntries) completed spins")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .confirmationDialog("Clear all rule history?", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
                Button("Clear History", role: .destructive) { onClear() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
        }
    }
}
