import SwiftUI
import UIKit

/// « Voici ce que nos utilisateurs en pensent » : le titre, cinq étoiles avec la note et le
/// nombre d'utilisateurs, puis les avis en cartes empilées (la citation, puis le portrait et
/// le prénom). Les cartes se posent en cascade ; celles qui ne tiennent pas à l'écran se
/// découvrent en faisant défiler, le bouton restant épinglé.
struct OnboardingV2Review: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    private var testimonials: [(quote: String, author: String, index: Int)] {
        (1...6).map { i in
            (languageManager.text("onboardingV2.review.t\(i).quote"),
             languageManager.text("onboardingV2.review.t\(i).author"),
             i)
        }
    }

    /// « 4,8 » au séparateur décimal de la langue.
    private var ratingText: String {
        (4.8).formatted(.number.precision(.fractionLength(1)).locale(languageManager.locale))
    }

    var body: some View {
        // Six avis ne tiennent pas sur un écran : la liste défile, le CTA reste épinglé et
        // un fondu au-dessus de lui signale qu'il y a une suite.
        OV2ScrollableContent {
            pageBody
        } footer: {
            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
                .background(alignment: .top) { OV2EndBottomFade() }
        }
        .ov2Background()
    }

    private var pageBody: some View {
        VStack(spacing: 0) {
            OV2EndTitle(text: languageManager.text("onboardingV2.review.title"))
                .padding(.top, OV2End.top)
                .dsStagger(0)

            ratingRow
                .padding(.top, 12)
                .dsStagger(1)

            VStack(spacing: 9) {
                ForEach(testimonials.indices, id: \.self) { i in
                    reviewCard(
                        quote: testimonials[i].quote,
                        author: testimonials[i].author,
                        index: testimonials[i].index
                    )
                    .dsStagger(i, step: 0.08, base: 0.22)
                }
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, OV2End.side)
        .padding(.bottom, 28)
    }

    // MARK: - Note

    /// Cinq étoiles, la note et le nombre d'utilisateurs, sur une ligne.
    private var ratingRow: some View {
        HStack(spacing: 8) {
            OV2EndStars(size: 17, baseDelay: 0.2)
            Text(verbatim: ratingText + " · " + languageManager.text("onboardingV2.loading.social.count"))
                .font(DS.sans(.footnote, .bold))
                .foregroundStyle(DS.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Carte d'avis

    private func reviewCard(quote: String, author: String, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(quote)
                .font(DS.sans(.footnote, .regular))
                .foregroundStyle(DS.ink)
                .lineSpacing(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                ReviewAvatar(index: index, name: author)
                Text(author)
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(DS.ink)
                Spacer(minLength: 8)
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(DS.warm)
                    }
                }
                .accessibilityHidden(true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ov2EndCard()
        .accessibilityElement(children: .combine)
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
                        .font(.jakarta(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(DS.hairline, lineWidth: 1))
        .accessibilityHidden(true)
    }
}
