import SwiftUI

// Slot Machine Animation View
struct SlotMachineView: View {
    let rules: [String]
    let offset: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rules.enumerated()), id: \.offset) { index, rule in
                Text(rule)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.green.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .frame(height: 45)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.3),
                                        Color.yellow.opacity(0.1),
                                        Color.black.opacity(0.3)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(Double(index % 3) * 0.3 + 0.1)
                    )
            }
        }
        .offset(y: offset)
    }
}

