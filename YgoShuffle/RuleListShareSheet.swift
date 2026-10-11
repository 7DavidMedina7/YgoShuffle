import SwiftUI
import UIKit

struct SharedRuleListFile: Identifiable {
    let id = UUID()
    let url: URL
}

struct RuleListShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
