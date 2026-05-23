import SwiftUI

struct OnboardingWastedTimeScreen: View {
    let viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var counterValue: Int = 0
    @State private var showMessage: Bool = false
    @State private var showProofPill: Bool = false

    private let blushBackground = Color(red: 1.0, green: 0.937, blue: 0.925)

    private var targetValue: Int {
        guard let sel = viewModel.phoneTimeSelection else { return 0 }
        switch sel {
        case 0: return 182
        case 1: return 547
        case 2: return 1095
        case 3: return 2190
        default: return 0
        }
    }

    var body: some View {
        ZStack {
            blushBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    BrutalPill(text: "Temps perdu", icon: "hourglass", background: Color(red: 1.0, green: 0.78, blue: 0.78), foreground: BrutalPalette.ink)
                        .opacity(appeared ? 1 : 0)

                    VStack(spacing: 8) {
                        Text("C'est")
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.55))

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(counterValue)")
                                .font(.system(size: 76, weight: .heavy, design: .rounded))
                                .foregroundStyle(BrutalPalette.ink)
                                .contentTransition(.numericText(countsDown: false))
                            Text("h")
                                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                                .foregroundStyle(BrutalPalette.ink)
                        }

                        Text("perdues par an.")
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.55))
                    }
                    .opacity(appeared ? 1 : 0)

                    VStack(spacing: 12) {
                        if showMessage {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Soit \(viewModel.wastedTimeDays) complets.")
                                    .font(.system(.headline, design: .rounded, weight: .heavy))
                                    .foregroundStyle(BrutalPalette.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Avec Sophia, fais un bon usage\nde ton temps.")
                                    .font(.system(.body, design: .rounded, weight: .semibold))
                                    .foregroundStyle(BrutalPalette.ink.opacity(0.7))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .brutalOnboardingCard(depth: 2, corner: 18)
                            .padding(.horizontal, 28)
                            .transition(.opacity.combined(with: .offset(y: 10)))
                        }

                        if showProofPill {
                            ScientificProofPill()
                                .padding(.horizontal, 28)
                                .transition(.opacity.combined(with: .scale(scale: 0.96)).combined(with: .offset(y: 8)))
                        }
                    }
                }

                Spacer()

                OnboardingPrimaryButton(title: "Continuer", action: onNext)
                    .opacity(showMessage ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.2)) {
                appeared = true
            }
            animateCounter()
        }
    }

    private func animateCounter() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        let duration: Double = 1.8
        let steps = 40
        let interval = duration / Double(steps)

        for step in 0...steps {
            let delay = 0.6 + interval * Double(step)
            let progress = Double(step) / Double(steps)
            let eased = 1 - pow(1 - progress, 3)
            let value = Int(eased * Double(targetValue))

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.snappy(duration: 0.1)) {
                    counterValue = value
                }
                if step % 5 == 0 {
                    generator.impactOccurred(intensity: 0.4 + 0.6 * progress)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showMessage = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.95) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                showProofPill = true
            }
        }
    }
}

private struct ScientificProofPill: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
                .frame(width: 24, height: 24)
                .background(Color.white.opacity(0.75), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("PREUVE SCIENTIFIQUE")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(0.9)
                    .foregroundStyle(BrutalPalette.ink.opacity(0.55))

                Text("Le scrolling excessif fragmente l'attention et affaiblit la mémoire")
                    .font(.system(.footnote, design: .rounded, weight: .bold))
                    .foregroundStyle(BrutalPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(BrutalPalette.ink.opacity(0.18), lineWidth: 1.5)
        }
    }
}
