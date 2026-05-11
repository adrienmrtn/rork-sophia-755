import SwiftUI

struct OnboardingBaselineProgressScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var showCTA: Bool = false
    @State private var progresses: [Subject: CGFloat] = [:]

    private let subjects: [Subject] = [
        .mythologie,
        .histoire,
        .sciences,
        .litterature,
        .art,
        .comprendreLeMonde,
    ]

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 18) {
                    VStack(spacing: 10) {
                        Text("Voici ton niveau de départ")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 14)

                        Text("Avec Sophia, progresse dans chaque thème chaque jour.")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 26)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 14)
                    }

                    VStack(spacing: 12) {
                        ForEach(Array(subjects.enumerated()), id: \.offset) { i, subject in
                            progressRow(subject: subject)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 14)
                                .animation(.spring(response: 0.55).delay(Double(i) * 0.05), value: appeared)
                        }
                    }
                    .padding(.horizontal, 24)

                    if showCTA {
                        Text("13 903 utilisateurs ont progressé dans leurs thèmes aujourd'hui.")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 26)
                            .transition(.opacity.combined(with: .offset(y: 10)))
                    }
                }

                Spacer()

                OnboardingButton(title: "Commencer mon parcours", action: onNext)
                    .opacity(showCTA ? 1 : 0)
            }
        }
        .onAppear {
            progresses = subjects.reduce(into: [Subject: CGFloat]()) { acc, subject in
                acc[subject] = 0
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15)) {
                appeared = true
            }
            animateBars()
        }
    }

    private func progressRow(subject: Subject) -> some View {
        let fraction = progresses[subject] ?? 0
        let level = viewModel.themeLevel(for: subject)
        let label = levelLabel(level)
        let labelColor = levelColor(level)

        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(subject.color.opacity(0.22))
                        .frame(width: 26, height: 26)
                    Image(systemName: subject.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(subject.color)
                }

                Text(subject.shortName)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Text(label)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(labelColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(labelColor.opacity(0.15), in: Capsule())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.12))
                        .frame(height: 8)
                    Capsule()
                        .fill(subject.color)
                        .frame(width: geo.size.width * fraction, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(14)
        .background(.white.opacity(0.04), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func animateBars() {
        for (index, subject) in subjects.enumerated() {
            let target = targetFraction(for: viewModel.themeLevel(for: subject))
            let delay = 0.55 + Double(index) * 0.18
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.85)) {
                    progresses[subject] = target
                }
            }
        }

        let ctaDelay = 0.55 + Double(subjects.count) * 0.18 + 0.25
        DispatchQueue.main.asyncAfter(deadline: .now() + ctaDelay) {
            let heavy = UIImpactFeedbackGenerator(style: .medium)
            heavy.impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showCTA = true
            }
        }
    }

    private func targetFraction(for level: Int) -> CGFloat {
        switch level {
        case 0: 0.2
        case 1: 0.5
        default: 0.8
        }
    }

    private func levelLabel(_ level: Int) -> String {
        switch level {
        case 0: "Débutant"
        case 1: "Moyen"
        default: "À l'aise"
        }
    }

    private func levelColor(_ level: Int) -> Color {
        switch level {
        case 0: SophiaTheme.accent
        case 1: SophiaTheme.emerald
        default: Color(red: 0.25, green: 0.72, blue: 0.85)
        }
    }
}
