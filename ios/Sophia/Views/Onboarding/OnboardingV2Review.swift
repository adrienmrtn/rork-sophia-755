import SwiftUI

/// Page 8 — preuve sociale, épurée : un titre qui s'affiche doucement, puis des avis
/// d'utilisateurs qui défilent en **roulette floutée** (même effet que « Avec Sophia, tu
/// sauras répondre à ces questions ») : l'avis centré est net, ses voisins sont atténués et
/// floutés, et l'ensemble glisse lentement vers le haut.
struct OnboardingV2Review: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    /// Position continue de la roulette : +1 à chaque tick, le contenu bouclant via un modulo.
    @State private var position: Double = 0
    @State private var titleIn = false
    @State private var listIn = false

    /// Espacement vertical entre deux avis (cartes plus hautes que les questions).
    private let slotSpacing: CGFloat = 172
    private let scrollDuration: Double = 0.95
    private let tickInterval: UInt64 = 3_000_000_000

    private var testimonials: [(quote: String, author: String)] {
        (1...6).map { i in
            (languageManager.text("onboardingV2.review.t\(i).quote"),
             languageManager.text("onboardingV2.review.t\(i).author"))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 84)

            Text(languageManager.text("onboardingV2.review.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .opacity(titleIn ? 1 : 0)
                .offset(y: titleIn ? 0 : 12)

            Spacer()

            roulette
                .frame(height: 380)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .opacity(listIn ? 1 : 0)
                // Dégradé haut/bas pour l'effet roulette (les voisins s'estompent).
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black, location: 0.26),
                            .init(color: .black, location: 0.74),
                            .init(color: .clear, location: 1.0),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )

            Spacer()

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            // Le titre apparaît doucement, puis les avis, puis la roulette se met en route.
            withAnimation(.easeOut(duration: 0.9)) { titleIn = true }
            withAnimation(.easeOut(duration: 0.9).delay(0.7)) { listIn = true }
        }
        .task {
            // Glissement lent et continu tant que l'écran est visible.
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: tickInterval)
                if Task.isCancelled { break }
                guard listIn else { continue }
                withAnimation(.easeInOut(duration: scrollDuration)) {
                    position += 1
                }
                OnboardingHaptics.selection()
            }
        }
    }

    // MARK: - Roulette

    private var roulette: some View {
        let count = max(testimonials.count, 1)
        let base = Int(position.rounded(.down))
        let slots = Array((base - 1)...(base + 2))
        return ZStack {
            ForEach(slots, id: \.self) { k in
                let distance = Double(k) - position
                let ti = ((k % count) + count) % count
                reviewCard(quote: testimonials[ti].quote, author: testimonials[ti].author, focused: abs(distance) < 0.5)
                    .scaleEffect(scale(for: distance))
                    .opacity(opacity(for: distance))
                    .blur(radius: blur(for: distance))
                    .offset(y: CGFloat(distance) * slotSpacing)
                    .zIndex(abs(distance) < 0.5 ? 1 : 0)
                    .transition(.opacity)
            }
        }
    }

    private func scale(for distance: Double) -> CGFloat {
        let d = min(abs(distance), 1)
        return 1 - 0.16 * CGFloat(d)
    }

    private func opacity(for distance: Double) -> Double {
        let d = abs(distance)
        if d < 0.5 { return 1 }
        return max(0, 0.42 - (d - 0.5) * 0.42)
    }

    private func blur(for distance: Double) -> CGFloat {
        let d = abs(distance)
        if d < 0.5 { return 0 }
        return min(7, CGFloat((d - 0.5) * 9))
    }

    private func reviewCard(quote: String, author: String, focused: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(OV2.warm)
                }
            }
            Text(quote)
                .font(DS.sans(.body, .medium))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text(author)
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(OV2.inkSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 148)
        .background(OV2.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(OV2.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(focused ? 0.08 : 0.03), radius: focused ? 16 : 8, y: focused ? 8 : 4)
    }
}
