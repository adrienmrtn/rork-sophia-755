import SwiftUI

/// Second onboarding screen (right after the intro): pick the app language.
/// The device language is preselected by default (`LanguageManager` resolves it from the system).
struct OnboardingLanguageScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var appeared = false
    @State private var revealedCards = 0

    private let ink = BrutalPalette.ink

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 56)

            VStack(spacing: 10) {
                Text(languageManager.text("onboarding.language.title"))
                    .font(.jakarta(size: 30, weight: .heavy, design: .rounded))
                    .lineSpacing(-2)
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.center)

                Text(languageManager.text("onboarding.language.subtitle"))
                    .font(.jakarta(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(ink.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)

            Spacer().frame(height: 26)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element.id) { index, language in
                    LanguageCard(
                        language: language,
                        isSelected: languageManager.current == language
                    ) {
                        OnboardingHaptics.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            languageManager.setLanguage(language)
                        }
                    }
                    .opacity(index < revealedCards ? 1 : 0)
                    .offset(y: index < revealedCards ? 0 : 22)
                    .scaleEffect(index < revealedCards ? 1 : 0.9)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            OnboardingPrimaryButton(title: languageManager.text("common.continue"), action: onNext)
        }
        .onboardingFullBleedBackground(BrutalPalette.cream)
        .onOnboardingSlideSettled {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) { appeared = true }
            for i in 0..<AppLanguage.allCases.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12 + Double(i) * 0.07) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        revealedCards = i + 1
                    }
                }
            }
        }
    }
}

private struct LanguageCard: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void

    private let ink = BrutalPalette.ink

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(language.flag)
                    .font(.jakarta(size: 28))

                Text(language.displayName)
                    .font(.jakarta(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .strokeBorder(ink.opacity(isSelected ? 1 : 0.25), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(ink)
                            .frame(width: 20, height: 20)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.jakarta(size: 10, weight: .heavy))
                                    .foregroundStyle(.white)
                            }
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
        }
        .buttonStyle(BrutalRowButtonStyle(isSelected: isSelected, accentColor: BrutalPalette.pink))
    }
}
