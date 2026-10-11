import SwiftUI

struct SpinSettingsView: View {
    @Binding var preferences: SpinPreferences
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Haptic Feedback", isOn: $preferences.hapticsEnabled)
                    Toggle("Sound Effects", isOn: $preferences.soundEnabled)
                } header: {
                    Text("Feedback")
                } footer: {
                    Text("Sound effects respect your device’s silent mode. Haptics require a supported device.")
                }
                Section {
                    Toggle("Quick Spin", isOn: $preferences.quickSpinEnabled)
                } header: {
                    Text("Animation")
                } footer: {
                    Text("Shorten the spin from 2 seconds to 0.65 seconds, with a shorter re-roll pause.")
                }
                Section {
                    Toggle("Avoid Consecutive Duplicates", isOn: $preferences.avoidConsecutiveDuplicates)
                } header: {
                    Text("Rule Selection")
                } footer: {
                    Text("Skip the last completed rule for this list when another enabled result is available. Uses saved history; clearing history resets this comparison.")
                }
            }
            .navigationTitle("Spin Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
