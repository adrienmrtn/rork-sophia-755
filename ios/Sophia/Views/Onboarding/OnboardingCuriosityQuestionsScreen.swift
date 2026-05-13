import SwiftUI

struct OnboardingCuriosityQuestionsScreen: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false

    private let questions = [
        "Sais-tu pourquoi la Joconde est vraiment connue ?",
        "Saurais-tu expliquer pourquoi l'Empire Romain a chuté ?",
        "Savais-tu que le micro-ondes a été découvert car une barre chocolatée avait fondu devant un radar militaire ?",
    ]

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            LinearGradient(
                colors: [
                    SophiaTheme.emerald.opacity(0.12),
                    .clear,
                    SophiaTheme.accent.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 22) {
                    Text("Saurais-tu répondre à ces questions ?")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 18)

                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        SophiaTheme.emerald.opacity(0.20),
                                        SophiaTheme.accent.opacity(0.12),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blur(radius: 12)
                            .offset(y: 10)

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(questions.enumerated()), id: \.offset) { _, q in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(.white.opacity(0.65))
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 7)
                                    Text(q)
                                        .font(.system(.callout, design: .rounded, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.88))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(18)
                        .background(.white.opacity(0.06), in: .rect(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)

                    Text("Sophia t'aide à répondre à ces questions tous les jours, et de manière passionnante.")
                        .font(.system(.footnote, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 18)
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
}
