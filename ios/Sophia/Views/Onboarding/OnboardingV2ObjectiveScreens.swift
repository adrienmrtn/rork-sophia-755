import SwiftUI

// MARK: - Questions (« Me cultiver au quotidien »)

/// « Avec Sophia, tu sauras répondre à ces questions » — les questions défilent en douceur.
/// Montré à tout le monde (page « me cultiver au quotidien »), quel que soit l'objectif choisi.
struct OnboardingV2QuestionsScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var index = 0
    @State private var appeared = false

    private var questions: [String] {
        (1...10).map { languageManager.text("onboardingV2.questions.q\($0)") }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 84)

            Text(languageManager.text("onboardingV2.questions.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .ov2Reveal(delay: 0.1)

            Spacer()

            ZStack {
                ForEach(Array(questions.enumerated()), id: \.offset) { i, q in
                    if i == index {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "sparkle.magnifyingglass")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(OV2.accentSoft)
                            Text(q)
                                .font(DS.title(.title2, .bold))
                                .foregroundStyle(OV2.ink)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(22)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(OV2.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(OV2.hairline, lineWidth: 1))
                        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                    }
                }
            }
            .frame(height: 200)
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)

            Spacer()

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
        .task {
            // Rotation douce des questions tant que l'écran est visible.
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if Task.isCancelled { break }
                withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                    index = (index + 1) % questions.count
                }
                OnboardingHaptics.selection()
            }
        }
    }
}
