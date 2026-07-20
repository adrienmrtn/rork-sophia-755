import SwiftUI

/// Page 8 — preuve sociale : note App Store + témoignage (marketing).
struct OnboardingV2Review: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var starsIn = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 72)

            Text(languageManager.text("onboardingV2.review.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .ov2Reveal(delay: 0.1)

            Spacer()

            VStack(spacing: 10) {
                Text("4.8")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(OV2.ink)
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(OV2.warm)
                            .scaleEffect(i < starsIn ? 1 : 0.3)
                            .opacity(i < starsIn ? 1 : 0)
                    }
                }
                Text(languageManager.text("onboardingV2.review.appStore"))
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(OV2.inkSecondary)
            }

            Spacer().frame(height: 32)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(OV2.warm)
                    }
                }
                Text(languageManager.text("onboardingV2.review.quote"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(OV2.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(languageManager.text("onboardingV2.review.author"))
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(OV2.inkSecondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(OV2.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(OV2.hairline, lineWidth: 1))
            .padding(.horizontal, 24)
            .ov2Reveal(delay: 0.5)

            Spacer()

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            for i in 1...5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.1) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { starsIn = i }
                    OnboardingHaptics.selection()
                }
            }
        }
    }
}
