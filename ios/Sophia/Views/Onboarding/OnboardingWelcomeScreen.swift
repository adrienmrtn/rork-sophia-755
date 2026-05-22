import SwiftUI

struct OnboardingWelcomeScreen: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var dismissing: Bool = false

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            FloatingCardsBackground(dismissing: dismissing)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 18) {
                    BrutalPill(text: "Bienvenue", icon: "sparkles", background: BrutalPalette.pink, foreground: BrutalPalette.ink)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    Text("Bienvenue\nsur Sophia")
                        .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    Text("Ton compagnon quotidien.\nChaque jour, il te raconte\nquelque chose de nouveau.")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(BrutalPalette.ink.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                }
                .padding(.horizontal, 24)

                Spacer()

                OnboardingPrimaryButton(title: "Suivant", action: handleNext)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
            }
        }
        .onAppear {
            let ids = ["course_43_pourquoi_la_glace_flotte_t_elle", "course_40_la_guerre_de_secession_americaine_1861_1", "course_157_la_persistance_de_la_memoire_dali"]
            CourseImageMap.preloadImages(for: ids)
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }
        }
    }

    private func handleNext() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dismissing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            onNext()
        }
    }
}
