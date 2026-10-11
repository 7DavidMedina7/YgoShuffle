import SwiftUI

struct SlotMachineView: View {
    let rules: [String]
    let offset: CGFloat

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                ForEach(Array(rules.enumerated()), id: \.offset) { index, rule in
                    HStack(spacing: 10) {
                        Image(systemName: "suit.diamond")
                            .font(.system(size: 9))
                            .foregroundStyle(index.isMultiple(of: 2) ? .cyan : .blue)
                        Text(rule)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 10)
                    .frame(height: CGFloat(SpinReelPlan.rowHeight))
                    .background(index.isMultiple(of: 2) ? Color.cyan.opacity(0.04) : Color.blue.opacity(0.06))
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .offset(y: offset)
        }
        .clipped()
    }
}
