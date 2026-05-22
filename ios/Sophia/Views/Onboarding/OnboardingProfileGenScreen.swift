import SwiftUI

struct OnboardingProfileGenScreen: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false

    private let floatingCards: [FloatingCardInfo] = [
        FloatingCardInfo(title: "1984, George Orwell", courseId: "course_101_1984_george_orwell", rotation: -6, xRatio: 0.22, yRatio: 0.13, scale: 1.15),
        FloatingCardInfo(title: "Le Big Bang", courseId: "course_61_le_big_bang", rotation: 7, xRatio: 0.74, yRatio: 0.22, scale: 0.9),
        FloatingCardInfo(title: "La Joconde", courseId: "course_149_la_joconde", rotation: -3, xRatio: 0.78, yRatio: 0.62, scale: 1.05),
        FloatingCardInfo(title: "La Joconde", courseId: "course_149_la_joconde", rotation: 5, xRatio: 0.20, yRatio: 0.58, scale: 0.95),
    ]

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            FloatingCardsBackground(dismissing: false, cards: floatingCards)
                .opacity(appeared ? 0.85 : 0)

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 22) {
                    BrutalPill(
                        text: "Profil",
                        icon: "person.fill.checkmark",
                        background: BrutalPalette.pink,
                        foreground: BrutalPalette.ink
                    )
                    .opacity(appeared ? 1 : 0)

                    VStack(spacing: 12) {
                        Text("On génère\nton profil")
                            .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                            .multilineTextAlignment(.center)

                        Text("9 utilisateurs sur 10 se sentent\nplus cultivés après une semaine.")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                }
                .padding(.horizontal, 24)

                Spacer()

                OnboardingPrimaryButton(title: "Continuer", action: onNext)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
            }
        }
        .onAppear {
            let ids = floatingCards.map(\.courseId)
            CourseImageMap.preloadImages(for: ids)
            withAnimation(.spring(response: 0.6).delay(0.2)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        }
    }
}
