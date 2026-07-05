import SwiftUI

struct OnboardingWidgetScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void
    let onSkip: () -> Void

    @State private var appeared = false

    private let ink = BrutalPalette.ink

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onSkip) {
                    Text(languageManager.text("widget.onboarding.skip"))
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(ink.opacity(0.55))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 44)

            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 8) {
                        Text(languageManager.text("widget.onboarding.title"))
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .lineSpacing(-2)
                            .foregroundStyle(ink)
                            .multilineTextAlignment(.center)

                        Text(languageManager.text("widget.onboarding.subtitle"))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(ink.opacity(0.58))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                    WidgetTutorialView(showsCloseButton: false, embedInParentScrollView: true)
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                }
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)

            OnboardingPrimaryButton(
                title: languageManager.text("widget.onboarding.cta"),
                action: onNext
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .opacity(appeared ? 1 : 0)
        }
        .onboardingFullBleedBackground(BrutalPalette.cream)
        .onAppear {
            AnalyticsService.trackWidgetTutorialOpened(source: "onboarding")
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                appeared = true
            }
        }
    }
}
