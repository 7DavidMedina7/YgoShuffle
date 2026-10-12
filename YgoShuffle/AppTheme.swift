import SwiftUI

/// Shared palette for the generator and every in-app page.
enum AppTheme {
    static let accent = Color.cyan
    static let electricBlue = Color(red: 0.10, green: 0.45, blue: 1)
    static let background = Color.black
    static let surface = Color(red: 0.09, green: 0.12, blue: 0.16)
    static let raisedSurface = Color(red: 0.13, green: 0.18, blue: 0.28)
}

private struct AppPageStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .tint(AppTheme.accent)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .toolbarBackground(AppTheme.background, for: .navigationBar, .bottomBar)
            .toolbarBackground(.visible, for: .navigationBar, .bottomBar)
            .toolbarColorScheme(.dark, for: .navigationBar, .bottomBar)
            .preferredColorScheme(.dark)
    }
}

extension View {
    func appPageStyle() -> some View {
        modifier(AppPageStyle())
    }
}
