import SwiftUI

/// Page 8 — preuve sociale : accroche chiffrée + note App Store + carrousel de 3 témoignages
/// courts, écrits comme si quelqu'un parlait vraiment.
struct OnboardingV2Review: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var starsIn = 0
    @State private var testimonialIndex = 0
    @State private var autoAdvance = true

    private var testimonials: [(quote: String, author: String)] {
        (1...3).map { i in
            (languageManager.text("onboardingV2.review.t\(i).quote"),
             languageManager.text("onboardingV2.review.t\(i).author"))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 64)

            Text(languageManager.text("onboardingV2.review.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 26)
                .ov2Reveal(delay: 0.1)

            Spacer().frame(height: 20)

            VStack(spacing: 8) {
                Text("4.8")
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(OV2.ink)
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(OV2.warm)
                            .scaleEffect(i < starsIn ? 1 : 0.3)
                            .opacity(i < starsIn ? 1 : 0)
                    }
                }
                Text(languageManager.text("onboardingV2.review.appStore"))
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(OV2.inkSecondary)
            }

            Spacer().frame(height: 26)

            testimonialCarousel
                .ov2Reveal(delay: 0.45)

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
        .task {
            // Rotation automatique lente du carrousel (s'arrête si l'utilisateur swipe).
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_800_000_000)
                if Task.isCancelled { break }
                guard autoAdvance else { continue }
                withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
                    testimonialIndex = (testimonialIndex + 1) % testimonials.count
                }
            }
        }
    }

    private var testimonialCarousel: some View {
        VStack(spacing: 14) {
            TabView(selection: $testimonialIndex) {
                ForEach(Array(testimonials.enumerated()), id: \.offset) { i, item in
                    testimonialCard(quote: item.quote, author: item.author)
                        .padding(.horizontal, 24)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 176)
            // Dès qu'un geste manuel a lieu, on coupe l'auto-avance pour ne pas « lutter »
            // contre l'utilisateur.
            .simultaneousGesture(
                DragGesture().onChanged { _ in autoAdvance = false }
            )

            HStack(spacing: 7) {
                ForEach(0..<testimonials.count, id: \.self) { i in
                    Capsule()
                        .fill(i == testimonialIndex ? OV2.accent : OV2.accent.opacity(0.18))
                        .frame(width: i == testimonialIndex ? 20 : 7, height: 7)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: testimonialIndex)
                }
            }
        }
    }

    private func testimonialCard(quote: String, author: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(OV2.warm)
                }
            }
            Text(quote)
                .font(DS.sans(.body, .medium))
                .foregroundStyle(OV2.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text(author)
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(OV2.inkSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 160)
        .background(OV2.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(OV2.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
    }
}
