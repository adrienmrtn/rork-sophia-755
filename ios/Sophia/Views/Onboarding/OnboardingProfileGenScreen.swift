import SwiftUI

struct OnboardingProfileGenScreen: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false

    private let floatingCards: [FloatingCardInfo] = [
        FloatingCardInfo(title: "1984, George Orwell", courseId: "course_101_1984_george_orwell", rotation: -6, xRatio: 0.25, yRatio: 0.15, scale: 1.2),
        FloatingCardInfo(title: "Le Big Bang", courseId: "course_61_le_big_bang", rotation: 7, xRatio: 0.72, yRatio: 0.28, scale: 0.9),
        FloatingCardInfo(title: "La Joconde", courseId: "course_149_la_joconde", rotation: -3, xRatio: 0.45, yRatio: 0.62, scale: 1.1),
    ]

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            FloatingCardsBackground(dismissing: false, cards: floatingCards)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 36) {
                Spacer()

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(SophiaTheme.emerald.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .scaleEffect(appeared ? 1.2 : 0.8)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: appeared)

                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(SophiaTheme.emerald)
                    }
                    .opacity(appeared ? 1 : 0)

                    VStack(spacing: 12) {
                        Text("Il est temps de générer\nvotre profil personnalisé")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("9 utilisateurs sur 10 se sentent\nplus cultivés après une semaine")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                }

                Spacer()

                OnboardingButton(title: "Continuer", action: onNext)
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
