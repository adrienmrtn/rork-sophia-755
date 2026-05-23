import SwiftUI

struct OnboardingWelcomeScreen: View {
    let onNext: () -> Void
    @State private var titleAppeared: Bool = false
    @State private var visibleQuestions: Int = 0
    @State private var subtitleAppeared: Bool = false
    @State private var ctaAppeared: Bool = false

    private let questions: [String] = [
        "Sais-tu pourquoi la Joconde est vraiment connue ?",
        "Saurais-tu expliquer pourquoi l'Empire Romain a chuté ?",
        "Savais-tu que le micro-ondes a été découvert car une barre chocolatée avait fondu devant un radar militaire ?",
    ]

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 28) {
                    Text("Saurais-tu répondre\nà ces questions ?")
                        .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(titleAppeared ? 1 : 0)
                        .offset(y: titleAppeared ? 0 : 20)

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(0..<questions.count, id: \.self) { index in
                            QuestionRow(text: questions[index])
                                .opacity(index < visibleQuestions ? 1 : 0)
                                .offset(y: index < visibleQuestions ? 0 : 18)
                                .scaleEffect(index < visibleQuestions ? 1 : 0.96, anchor: .leading)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 24)

                VStack(spacing: 18) {
                    Text("Sophia t'aide à répondre à ces questions tous les jours, et de manière passionnante.")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(BrutalPalette.ink.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(subtitleAppeared ? 1 : 0)
                        .offset(y: subtitleAppeared ? 0 : 16)

                    OnboardingPrimaryButton(title: "Continuer →", action: handleNext)
                        .opacity(ctaAppeared ? 1 : 0)
                        .offset(y: ctaAppeared ? 0 : 24)
                }
            }
        }
        .onAppear(perform: runEntranceAnimation)
    }

    private func runEntranceAnimation() {
        // Title
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15)) {
            titleAppeared = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }

        // Questions, one by one
        for index in 0..<questions.count {
            let delay = 0.55 + Double(index) * 0.55
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                    visibleQuestions = index + 1
                }
                let generator = UIImpactFeedbackGenerator(style: index == questions.count - 1 ? .medium : .light)
                generator.impactOccurred(intensity: index == questions.count - 1 ? 1.0 : 0.85)
            }
        }

        // Subtitle
        let subtitleDelay = 0.55 + Double(questions.count) * 0.55 + 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + subtitleDelay) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                subtitleAppeared = true
            }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7)
        }

        // CTA
        DispatchQueue.main.asyncAfter(deadline: .now() + subtitleDelay + 0.25) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                ctaAppeared = true
            }
            let notif = UINotificationFeedbackGenerator()
            notif.notificationOccurred(.success)
        }
    }

    private func handleNext() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onNext()
    }
}

private struct QuestionRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(BrutalPalette.ink)
                .frame(width: 8, height: 8)
                .padding(.top, 8)

            Text(text)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(BrutalPalette.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(BrutalPalette.ink, lineWidth: 2)
        )
        .shadow(color: BrutalPalette.ink.opacity(0.12), radius: 0, x: 3, y: 3)
    }
}
