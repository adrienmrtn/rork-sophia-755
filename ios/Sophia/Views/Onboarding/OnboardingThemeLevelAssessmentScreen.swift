import SwiftUI

struct OnboardingThemeLevelAssessmentScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = false

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

                VStack(spacing: 22) {
                    Text("Comment estimes-tu ton niveau\ndans ces thèmes ?")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)

                    VStack(spacing: 10) {
                        ForEach(Array(subjects.enumerated()), id: \.offset) { i, subject in
                            levelRow(subject: subject)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 16)
                                .animation(.spring(response: 0.55).delay(Double(i) * 0.05), value: appeared)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                OnboardingButton(title: "Continuer", action: onNext)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15)) {
                appeared = true
            }
        }
    }

    private func levelRow(subject: Subject) -> some View {
        let level = viewModel.themeLevel(for: subject)
        let config = levelConfig(level)
        return VStack(alignment: .leading, spacing: 10) {
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

                Text(config.label)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(config.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(config.color.opacity(0.15), in: Capsule())
            }

            Slider(
                value: Binding(
                    get: { Double(viewModel.themeLevel(for: subject)) },
                    set: { newValue in
                        viewModel.setThemeLevel(Int(newValue.rounded()), for: subject)
                    }
                ),
                in: 0...2,
                step: 1
            )
            .tint(config.color)

            HStack {
                Text("Débutant")
                Spacer()
                Text("Moyen")
                Spacer()
                Text("À l'aise")
            }
            .font(.system(.caption2, design: .rounded, weight: .medium))
            .foregroundStyle(.white.opacity(0.35))
        }
        .padding(14)
        .background(.white.opacity(0.04), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
        .animation(.snappy(duration: 0.12), value: level)
    }

    private func levelConfig(_ level: Int) -> (label: String, color: Color) {
        switch level {
        case 0:
            return ("Débutant", SophiaTheme.accent)
        case 1:
            return ("Moyen", SophiaTheme.emerald)
        default:
            return ("À l'aise", Color(red: 0.25, green: 0.72, blue: 0.85))
        }
    }
}
