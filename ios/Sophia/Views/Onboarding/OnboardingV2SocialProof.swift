import SwiftUI
import UIKit

/// Cinquième page de présentation, après le carrousel : « Rejoins les 500 000 utilisateurs
/// heureux qui apprennent avec Sophia » en haut, des photos d'étudiants, la note App Store
/// entre deux lauriers, la disponibilité dans plus de 140 pays au-dessus du bouton, et le CTA
/// « C'est parti ».
///
/// Les photos sont les `student_<n>.jpg` du bundle (voir `Resources/StudentPhotos/README.md`),
/// suivies des portraits des avis (`review_avatar_<n>`), dans une grille symétrique.
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
                Spacer().frame(height: 64)

                OV2Markup.highlighted(languageManager.text("onboardingV2.intro.social.title"))
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 28)
                    .ov2Reveal(delay: 0.05)

                Spacer(minLength: 20)

                if !photos.isEmpty {
                    OnboardingV2StudentCluster(photos: photos, revealed: revealedPhotos)
                        .padding(.horizontal, 16)

                    Spacer().frame(height: 26)
                }

                OnboardingV2LaurelBadge {
                    OnboardingV2RatingStack(caption: languageManager.text("onboardingV2.review.appStore"))
                }
                .scaleEffect(ratingIn ? 1 : 0.7)
                .opacity(ratingIn ? 1 : 0)

                Spacer(minLength: 24)

                countriesLine
                    .opacity(textIn ? 1 : 0)
                    .offset(y: textIn ? 0 : 14)

                Spacer().frame(height: 10)
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

    /// « Disponible dans plus de 140 pays », centré, juste au-dessus du bouton.
    private var countriesLine: some View {
        VStack(spacing: 8) {
            Image(systemName: "globe.europe.africa.fill")
                .font(.system(size: 18))
                .foregroundStyle(OV2.accentSoft)
            Text(languageManager.text("onboardingV2.intro.social.countries"))
                .font(DS.sans(.body, .medium))
                .foregroundStyle(OV2.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }

    // MARK: - Animation

    private func reveal() {
        guard revealedPhotos == 0 else { return }
        let count = min(photos.count, OnboardingV2StudentCluster.maxPhotos)
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.08) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.62)) {
                    revealedPhotos = i + 1
                }
                OnboardingHaptics.selection()
            }
        }
        let afterPhotos = 0.4 + Double(count) * 0.08
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

/// Photos d'étudiants dans des ronds de même taille, en rangées centrées (cinq par rangée au
/// plus, les rangées équilibrées entre elles) : une grille symétrique, le même style pour
/// toutes. Seules les vraies photos sont montrées.
struct OnboardingV2StudentCluster: View {
    let photos: [UIImage]
    let revealed: Int

    static let maxPhotos = 10
    private static let perRow = 5
    private static let diameter: CGFloat = 58
    private static let spacing: CGFloat = 10
    private static let rowSpacing: CGFloat = 12

    /// Les rangées, aussi pleines les unes que les autres : 10 → 5 + 5, 7 → 4 + 3, 5 → 5.
    private var rows: [[Int]] {
        let count = min(photos.count, Self.maxPhotos)
        guard count > 0 else { return [] }
        let rowCount = Int((Double(count) / Double(Self.perRow)).rounded(.up))
        let base = count / rowCount
        let extra = count % rowCount
        var rows: [[Int]] = []
        var next = 0
        for row in 0..<rowCount {
            let size = base + (row < extra ? 1 : 0)
            rows.append(Array(next..<(next + size)))
            next += size
        }
        return rows
    }

    var body: some View {
        VStack(spacing: Self.rowSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: Self.spacing) {
                    ForEach(row, id: \.self) { i in
                        portrait(photos[i])
                            .scaleEffect(i < revealed ? 1 : 0.2)
                            .opacity(i < revealed ? 1 : 0)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private func portrait(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: Self.diameter, height: Self.diameter)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(.white, lineWidth: 3))
            .shadow(color: .black.opacity(0.14), radius: 8, y: 4)
    }
}

/// Une rangée de portraits qui se chevauchent, pour les pages qui citent les utilisateurs
/// sans leur laisser toute la place (chargement, avis).
struct OnboardingV2PhotoRow: View {
    let photos: [UIImage]
    var size: CGFloat = 36

    var body: some View {
        HStack(spacing: -(size * 0.28)) {
            ForEach(Array(photos.enumerated()), id: \.offset) { i, image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                    .shadow(color: .black.opacity(0.10), radius: 5, y: 2)
                    .zIndex(Double(photos.count - i))
            }
        }
        .accessibilityHidden(true)
    }
}

/// Les photos de la page : `student_<n>.jpg|png` du bundle (`Resources/StudentPhotos`), dans
/// l'ordre de n, puis les portraits des avis (`review_avatar_<n>`), tous dans le même style.
enum OnboardingStudentPhotos {
    static func load() -> [UIImage] {
        bundled(prefix: "student_") + bundled(prefix: "review_avatar_")
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
