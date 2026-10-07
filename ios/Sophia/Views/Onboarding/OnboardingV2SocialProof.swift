import SwiftUI
import UIKit

/// Cinquième page de présentation, après le carrousel : « Rejoins les 500 000 utilisateurs
/// heureux qui apprennent avec Sophia ». Des photos d'étudiants, la note App Store entre deux
/// lauriers, la disponibilité dans plus de 140 pays, et le CTA « C'est parti ».
///
/// Les photos sont les `student_<n>.jpg` du bundle (voir `Resources/StudentPhotos/README.md`) ;
/// tant qu'il n'y en a pas, les portraits des avis (`review_avatar_<n>`) servent de placeholders.
struct OnboardingV2SocialProof: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var photos: [UIImage] = []
    @State private var revealedPhotos = 0
    @State private var ratingIn = false
    @State private var textIn = false

    var body: some View {
        // Photos, lauriers, titre et pays dépassent un petit iPhone en grande taille de texte :
        // le contenu défile, le CTA reste épinglé.
        OV2ScrollableContent {
            VStack(spacing: 0) {
                Spacer().frame(height: 28)

                OnboardingV2StudentCluster(photos: photos, revealed: revealedPhotos)
                    .frame(height: 176)

                Spacer().frame(height: 22)

                ratingBadge
                    .scaleEffect(ratingIn ? 1 : 0.7)
                    .opacity(ratingIn ? 1 : 0)

                Spacer().frame(height: 26)

                OV2Markup.highlighted(languageManager.text("onboardingV2.intro.social.title"))
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 28)
                    .opacity(textIn ? 1 : 0)
                    .offset(y: textIn ? 0 : 14)

                Spacer().frame(height: 18)

                countriesLine
                    .opacity(textIn ? 1 : 0)
                    .offset(y: textIn ? 0 : 14)

                Spacer(minLength: 20)
            }
        } footer: {
            OnboardingV2Button(title: languageManager.text("onboardingV2.intro.social.cta"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            if photos.isEmpty { photos = OnboardingStudentPhotos.load() }
            reveal()
        }
    }

    // MARK: - Note App Store

    /// La note entre deux lauriers, avec ses cinq étoiles ; le nombre suit le séparateur
    /// décimal de la langue (« 4,8 » en français).
    private var ratingBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "laurel.leading")
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(OV2.warm)
            VStack(spacing: 3) {
                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(OV2.warm)
                    }
                }
                Text((4.8).formatted(.number.precision(.fractionLength(1)).locale(languageManager.locale)))
                    .font(DS.title(.largeTitle, .heavy))
                    .foregroundStyle(OV2.ink)
                Text(languageManager.text("onboardingV2.review.appStore"))
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(OV2.inkSecondary)
                    .lineLimit(1)
            }
            Image(systemName: "laurel.trailing")
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(OV2.warm)
        }
        .accessibilityElement(children: .combine)
    }

    private var countriesLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "globe.europe.africa.fill")
                .font(.system(size: 15))
                .foregroundStyle(OV2.accentSoft)
            Text(languageManager.text("onboardingV2.intro.social.countries"))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(OV2.inkSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Animation

    private func reveal() {
        guard revealedPhotos == 0 else { return }
        let count = OnboardingV2StudentCluster.slotCount
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + Double(i) * 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.62)) {
                    revealedPhotos = i + 1
                }
                OnboardingHaptics.selection()
            }
        }
        let afterPhotos = 0.3 + Double(count) * 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + afterPhotos) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) {
                ratingIn = true
            }
            OnboardingHaptics.counterComplete()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + afterPhotos + 0.25) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) {
                textIn = true
            }
        }
    }
}

// MARK: - Photos d'étudiants

/// Photos d'étudiants dans des ronds, posées en deux rangées décalées, comme une pile de
/// polaroïds. Un emplacement sans photo montre une silhouette sur un dégradé.
struct OnboardingV2StudentCluster: View {
    let photos: [UIImage]
    let revealed: Int

    /// Position (par rapport au centre) et diamètre de chaque rond.
    private static let slots: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (-118, -34, 58), (-40, -50, 66), (42, -42, 60), (118, -28, 56),
        (-80, 36, 64), (2, 48, 72), (84, 38, 62),
    ]

    static var slotCount: Int { slots.count }

    private static let palettes: [(Color, Color)] = [
        (Color(red: 0.98, green: 0.62, blue: 0.45), Color(red: 0.93, green: 0.35, blue: 0.45)),
        (Color(red: 0.45, green: 0.72, blue: 0.98), Color(red: 0.25, green: 0.45, blue: 0.85)),
        (Color(red: 0.55, green: 0.85, blue: 0.65), Color(red: 0.22, green: 0.60, blue: 0.45)),
        (Color(red: 0.85, green: 0.65, blue: 0.98), Color(red: 0.56, green: 0.40, blue: 0.92)),
        (Color(red: 0.99, green: 0.80, blue: 0.40), Color(red: 0.92, green: 0.55, blue: 0.15)),
        (Color(red: 0.55, green: 0.85, blue: 0.92), Color(red: 0.25, green: 0.60, blue: 0.75)),
    ]

    var body: some View {
        ZStack {
            ForEach(Array(Self.slots.enumerated()), id: \.offset) { i, slot in
                portrait(i, size: slot.size)
                    .offset(x: slot.x, y: slot.y)
                    .scaleEffect(i < revealed ? 1 : 0.2)
                    .opacity(i < revealed ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private func portrait(_ index: Int, size: CGFloat) -> some View {
        Group {
            if index < photos.count {
                Image(uiImage: photos[index])
                    .resizable()
                    .scaledToFill()
            } else {
                let palette = Self.palettes[index % Self.palettes.count]
                ZStack {
                    LinearGradient(colors: [palette.0, palette.1], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.42, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.14), radius: 10, y: 5)
    }
}

/// Les photos de la page : `student_<n>.jpg|png` du bundle (`Resources/StudentPhotos`), dans
/// l'ordre de n ; sinon les portraits des avis, en attendant les vraies photos.
enum OnboardingStudentPhotos {
    static func load() -> [UIImage] {
        let students = bundled(prefix: "student_")
        return students.isEmpty ? bundled(prefix: "review_avatar_") : students
    }

    /// `UIImage(named:)` ne trouve pas un JPG du bundle sans son extension ; recherche par URL.
    private static func bundled(prefix: String) -> [UIImage] {
        var urls: [URL] = []
        for ext in ["jpg", "jpeg", "png"] {
            urls += Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
        }
        return urls
            .filter { $0.lastPathComponent.hasPrefix(prefix) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            .compactMap { UIImage(contentsOfFile: $0.path) }
    }
}
