import SwiftUI
import UIKit

/// Page 8 — preuve sociale, épurée : un titre qui s'affiche doucement, les lauriers « 4,8 ·
/// 500 000 utilisateurs », puis des avis
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

    /// Hauteur minimale d'une carte d'avis. La hauteur réelle suit le texte : une citation
    /// longue (allemand, finnois) ou une grande taille de texte débordait d'un cadre fixe à
    /// 148pt et se retrouvait coupée en plein milieu.
    private static let minCardHeight: CGFloat = 148

    /// Hauteur de la plus haute carte, mesurée. L'espacement des créneaux en découle : avec
    /// un pas fixe, une carte qui grandit chevaucherait sa voisine.
    @State private var cardHeight: CGFloat = OnboardingV2Review.minCardHeight

    /// Espacement vertical entre deux avis (cartes plus hautes que les questions).
    private var slotSpacing: CGFloat { cardHeight + 24 }
    private let scrollDuration: Double = 0.95
    private let tickInterval: UInt64 = 3_000_000_000

    private var testimonials: [(quote: String, author: String, index: Int)] {
        (1...6).map { i in
            (languageManager.text("onboardingV2.review.t\(i).quote"),
             languageManager.text("onboardingV2.review.t\(i).author"),
             i)
        }
    }

    var body: some View {
        // The testimonial roulette is 380pt tall; on a short phone at a large text size the CTA
        // below it went off screen. Scrolls instead, with the button pinned.
        OV2ScrollableContent {
            pageBody
        } footer: {
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

    /// Page content, unchanged; the container above is what keeps the CTA on screen.
    private var pageBody: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 84)

            Text(languageManager.text("onboardingV2.review.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .opacity(titleIn ? 1 : 0)
                .offset(y: titleIn ? 0 : 12)

            Spacer().frame(height: 18)

            OnboardingV2LaurelBadge(size: 46) {
                OnboardingV2RatingStack(caption: languageManager.text("onboardingV2.loading.social.count"), compact: true)
            }
            .opacity(titleIn ? 1 : 0)
            .offset(y: titleIn ? 0 : 12)

            Spacer()

            roulette
                .frame(height: max(380, slotSpacing * 2 + 36))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                // Mesure hors écran de la plus haute citation, pour que le pas de la
                // roulette suive le texte au lieu de le rogner.
                .background {
                    VStack(spacing: 0) {
                        ForEach(testimonials.indices, id: \.self) { i in
                            reviewCard(
                                quote: testimonials[i].quote,
                                author: testimonials[i].author,
                                index: testimonials[i].index,
                                focused: false,
                                height: nil
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .onGeometryChange(for: CGFloat.self) { proxy in
                                proxy.size.height
                            } action: { height in
                                if height > cardHeight { cardHeight = height }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .hidden()
                    .accessibilityHidden(true)
                }
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
                reviewCard(
                    quote: testimonials[ti].quote,
                    author: testimonials[ti].author,
                    index: testimonials[ti].index,
                    focused: abs(distance) < 0.5,
                    height: cardHeight
                )
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

    /// [height] `nil` pour la mesure hors écran (hauteur idéale), la hauteur mesurée pour
    /// les cartes visibles.
    ///
    /// Elle doit être **imposée** sur les cartes visibles : la roulette est un `ZStack` haut
    /// de plusieurs centaines de points, et il propose sa propre hauteur à chacun de ses
    /// enfants. Avec un simple `minHeight`, le `Spacer(minLength: 0)` de la carte s'étirait
    /// pour remplir toute la fenêtre — une carte de 400 pt avec trois lignes de texte en
    /// haut et du vide en dessous.
    private func reviewCard(quote: String, author: String, index: Int, focused: Bool, height: CGFloat?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ReviewAvatar(index: index, name: author)
                VStack(alignment: .leading, spacing: 3) {
                    Text(author)
                        .font(DS.sans(.caption, .semibold))
                        .foregroundStyle(OV2.ink)
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill").font(.system(size: 11)).foregroundStyle(OV2.warm)
                        }
                    }
                }
            }
            Text(quote)
                .font(DS.sans(.body, .medium))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height, alignment: .topLeading)
        .frame(minHeight: Self.minCardHeight, alignment: .topLeading)
        .background(OV2.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(OV2.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(focused ? 0.08 : 0.03), radius: focused ? 16 : 8, y: focused ? 8 : 4)
    }
}

// MARK: - Avatar

/// Profile picture of a testimonial. A bundled `review_avatar_<n>.jpg` (or `.png`) is used
/// when there is one; otherwise a generated portrait: initials on a gradient that is
/// always the same for the same person.
private struct ReviewAvatar: View {
    let index: Int
    let name: String

    /// `UIImage(named:)` only finds a bundled file without its extension when it is a PNG,
    /// so the JPG portraits never showed. Looked up by URL, with the extension.
    private static func bundledImage(index: Int) -> UIImage? {
        for ext in ["jpg", "jpeg", "png"] {
            if let url = Bundle.main.url(forResource: "review_avatar_\(index)", withExtension: ext),
               let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }
        return UIImage(named: "review_avatar_\(index)")
    }

    private static let palettes: [(Color, Color)] = [
        (Color(red: 0.98, green: 0.62, blue: 0.45), Color(red: 0.93, green: 0.35, blue: 0.45)),
        (Color(red: 0.45, green: 0.72, blue: 0.98), Color(red: 0.25, green: 0.45, blue: 0.85)),
        (Color(red: 0.55, green: 0.85, blue: 0.65), Color(red: 0.22, green: 0.60, blue: 0.45)),
        (Color(red: 0.85, green: 0.65, blue: 0.98), Color(red: 0.56, green: 0.40, blue: 0.92)),
        (Color(red: 0.99, green: 0.80, blue: 0.40), Color(red: 0.92, green: 0.55, blue: 0.15)),
        (Color(red: 0.55, green: 0.85, blue: 0.92), Color(red: 0.25, green: 0.60, blue: 0.75)),
    ]

    private var initial: String {
        String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }

    var body: some View {
        Group {
            if let image = Self.bundledImage(index: index) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                let palette = Self.palettes[(index - 1 + Self.palettes.count) % Self.palettes.count]
                ZStack {
                    LinearGradient(colors: [palette.0, palette.1], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Text(initial)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 1))
    }
}
