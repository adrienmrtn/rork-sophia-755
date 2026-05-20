import SwiftUI

struct OnboardingCuriosityQuestionsScreen: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var selectedIndex: Int = 0
    
    private let questions = [
        "Sais-tu pourquoi la Joconde est vraiment connue ?",
        "Saurais-tu expliquer pourquoi l'Empire Romain a chuté ?",
        "Savais-tu que le micro-ondes a été découvert car une barre chocolatée avait fondu devant un radar militaire ?",
    ]

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 22) {
                    VStack(spacing: 10) {
                        Image("logo_white")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 22)
                            .opacity(appeared ? 0.9 : 0)
                            .offset(y: appeared ? 0 : 10)

                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(SophiaTheme.emerald)
                            .symbolEffect(.pulse, isActive: appeared)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)

                        Text("Ta curiosité va exploser")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("Chaque jour, Sophia te donne une réponse claire,\navec une histoire qui se retient.")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 26)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(questions.enumerated()), id: \.offset) { _, q in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(SophiaTheme.emerald.opacity(0.85))
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 8)
                                Text(q)
                                    .font(.system(.callout, design: .rounded, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.55))
                            Text("2 minutes par jour pour progresser")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.55))
                            Spacer()
                        }
                    }
                    .padding(18)
                    .background(.white.opacity(0.06), in: .rect(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                    Text("Sophia t'aide à répondre à ces questions tous les jours, et de manière passionnante.")
                        .font(.system(.footnote, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                }

                Spacer()

                OnboardingButton(title: "Continuer", action: onNext)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 26)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15)) {
                appeared = true
            }
        }
    }
}
