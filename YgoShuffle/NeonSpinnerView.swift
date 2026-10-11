import SwiftUI

struct NeonSpinnerView: View {
    let rules: [String]
    let offset: CGFloat
    let selectedRule: String?
    let isSpinning: Bool
    let canSpin: Bool
    let quickSpin: Bool
    let revealID: UUID
    let onSpin: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let cyan = Color(red: 0.25, green: 0.9, blue: 1)
    private let violet = Color(red: 0.65, green: 0.35, blue: 1)
    private var rerolling: Bool { isSpinning && selectedRule == "🎲 RE-ROLLING! 🎲" }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Label("DUEL RANDOMIZER", systemImage: "sparkles")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(cyan)
                Spacer()
                Text(quickSpin ? "QUICK" : "CLASSIC")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(cyan.opacity(0.1), in: Capsule())
                    .foregroundStyle(cyan.opacity(0.9))
            }
            reelWindow
            Button(action: onSpin) {
                HStack(spacing: 12) {
                    Image(systemName: isSpinning ? "hourglass" : "dice.fill")
                        .font(.title3)
                    Text(isSpinning ? (rerolling ? "RE-ROLLING" : "DRAWING YOUR FATE") :
                            (canSpin ? "SPIN FOR RULE" : "NO ENABLED RULES"))
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                    Image(systemName: isSpinning ? "lock.fill" : "arrow.right")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(minHeight: 58)
                .background(
                    LinearGradient(colors: canSpin && !isSpinning ? [violet, .indigo, cyan.opacity(0.75)] :
                        [.gray.opacity(0.4), .gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 18)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                }
                .shadow(color: canSpin && !isSpinning ? violet.opacity(0.35) : .clear, radius: 16, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(isSpinning || !canSpin)
            .accessibilityLabel(isSpinning ? "Spinning" : "Spin for rule")

            HStack(spacing: 6) {
                Circle().fill(isSpinning ? cyan : .green).frame(width: 5, height: 5)
                Text(isSpinning ? "THE NEXT MOVE IS IN MOTION" : "ONE SPIN. A WHOLE NEW DUEL.")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .accessibilityHidden(true)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(colors: [
                    Color(red: 0.08, green: 0.06, blue: 0.17),
                    Color(red: 0.03, green: 0.04, blue: 0.09)
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(LinearGradient(colors: [violet.opacity(0.8), cyan.opacity(0.25), violet.opacity(0.15)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                }
                .shadow(color: violet.opacity(0.16), radius: 24, y: 10)
        }
        .padding(.horizontal)
    }

    private var reelWindow: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(.black.opacity(0.65))
            starfield
            if isSpinning && !rerolling && !reduceMotion {
                spinningReel
            } else if let rule = selectedRule {
                resultCard(rule)
                    .id(revealID)
                    .transition(.scale(scale: reduceMotion ? 1 : 0.94).combined(with: .opacity))
            } else {
                standby
            }
        }
        .frame(height: CGFloat(SpinReelPlan.windowHeight))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(LinearGradient(colors: [cyan.opacity(isSpinning ? 0.8 : 0.35), violet.opacity(0.65)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
        }
        .shadow(color: (isSpinning ? cyan : violet).opacity(0.18), radius: 16)
    }

    private var spinningReel: some View {
        ZStack {
            NeonOrbitView(isSpinning: true)
                .frame(width: 220, height: 220)
                .opacity(0.2)
                .accessibilityHidden(true)
            SlotMachineView(rules: rules, offset: offset)
                .padding(.horizontal, 24)
                .accessibilityHidden(true)
            VStack {
                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                Spacer().frame(height: 65)
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
            }
            RoundedRectangle(cornerRadius: 12)
                .fill(cyan.opacity(0.08))
                .frame(height: 55)
                .overlay {
                    RoundedRectangle(cornerRadius: 12).stroke(cyan.opacity(0.5), lineWidth: 1)
                }
                .padding(.horizontal, 16)
            HStack {
                Image(systemName: "arrowtriangle.right.fill")
                Spacer()
                Image(systemName: "arrowtriangle.left.fill")
            }
            .font(.caption2)
            .foregroundStyle(cyan)
            .padding(.horizontal, 5)
            VStack {
                Text("SHUFFLING THE POSSIBILITIES")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(cyan)
                    .padding(.top, 16)
                Spacer()
                ProgressView().tint(cyan).padding(.bottom, 14)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Spinning for a rule")
    }

    private var standby: some View {
        VStack(spacing: 14) {
            NeonOrbitView(isSpinning: isSpinning && !reduceMotion)
                .frame(width: 132, height: 132)
                .overlay {
                    Image(systemName: "suit.diamond.fill")
                        .font(.system(size: 38, weight: .light))
                        .foregroundStyle(LinearGradient(colors: [cyan, violet], startPoint: .top, endPoint: .bottom))
                        .shadow(color: cyan.opacity(0.7), radius: 16)
                }
                .accessibilityHidden(true)
            Text(isSpinning ? "Drawing your fate…" : "Let fate choose.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text("A new rule. A new possibility.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private func resultCard(_ rule: String) -> some View {
        VStack(spacing: 12) {
            Label(rerolling ? "FATE HAS OTHER PLANS" : "YOUR NEXT RULE",
                  systemImage: rerolling ? "arrow.triangle.2.circlepath" : "sparkle")
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .tracking(1)
                .foregroundStyle(rerolling ? cyan : .yellow)
            Rectangle()
                .fill(LinearGradient(colors: [.clear, cyan.opacity(0.8), .clear],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
            ScrollView {
                Text(rule)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .scrollIndicators(.visible)
            .frame(maxHeight: 200)
        }
        .padding(22)
        .accessibilityElement(children: .combine)
    }

    private var starfield: some View {
        Canvas { context, size in
            for index in 0..<32 {
                let x = CGFloat((index * 47 + 13) % 101) / 101 * size.width
                let y = CGFloat((index * 31 + 7) % 97) / 97 * size.height
                let diameter: CGFloat = index % 5 == 0 ? 2 : 1
                let path = Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter))
                context.fill(path, with: .color(cyan.opacity(index % 3 == 0 ? 0.4 : 0.15)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct NeonOrbitView: View {
    let isSpinning: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !isSpinning)) { timeline in
            let angle = isSpinning ? timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 4) * 90 : 25
            ZStack {
                Circle().stroke(.white.opacity(0.07), lineWidth: 1)
                Circle().trim(from: 0.05, to: 0.8)
                    .stroke(AngularGradient(colors: [.cyan, .purple, .clear], center: .center),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(angle))
                Circle().trim(from: 0.15, to: 0.65)
                    .stroke(.purple.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [3, 6]))
                    .padding(12)
                    .rotationEffect(.degrees(-angle))
                Circle().fill(.cyan).frame(width: 5, height: 5).offset(y: -65)
                    .rotationEffect(.degrees(angle))
                    .shadow(color: .cyan, radius: 6)
            }
        }
    }
}

#Preview("Ready") {
    NeonSpinnerView(rules: [], offset: 0, selectedRule: nil, isSpinning: false,
                    canSpin: true, quickSpin: false, revealID: UUID(), onSpin: {})
        .padding(.vertical)
        .background(Color.black)
        .preferredColorScheme(.dark)
}

#Preview("Rule Revealed") {
    NeonSpinnerView(rules: [], offset: 0,
                    selectedRule: "Shuffle your hand into your deck and then draw that many cards.",
                    isSpinning: false, canSpin: true, quickSpin: true,
                    revealID: UUID(), onSpin: {})
        .padding(.vertical)
        .background(Color.black)
        .preferredColorScheme(.dark)
}
