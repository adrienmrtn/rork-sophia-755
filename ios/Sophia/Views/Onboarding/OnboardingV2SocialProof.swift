import SwiftUI
import UIKit

/// Écran 9 — preuve sociale, après le carrousel : « Rejoins les 500 000 utilisateurs… »
/// dans une carte, deux lauriers (les cinq étoiles et le nombre d'utilisateurs, la note
/// App Store), trois avis d'utilisateurs, la disponibilité dans plus de 140 pays, et le CTA
/// « C'est parti ».
///
/// Tous les chiffres sont ceux que l'app affichait déjà (titre, note, pays) ; les avis sont
/// ceux de la page « Voici ce que nos utilisateurs en pensent ».
struct OnboardingV2SocialProof: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onNext: () -> Void

    @State private var photos: [UIImage] = []
    @State private var laurelsIn = false
    @State private var starsShown = 0

    /// Les avis montrés ici (clés `onboardingV2.review.t<n>`) : la fin de la liste, pour ne
    /// pas ouvrir sur les mêmes que la page des avis, plus loin dans le déroulé.
    private static let reviewIndices: [Int] = [4, 5, 6]
    private static let starCount = 5

    var body: some View {
        // Carte, lauriers et avis dépassent un petit iPhone en grande taille de texte :
        // le contenu défile, le CTA reste épinglé.
        OV2ScrollableContent {
            VStack(spacing: 0) {
                titleCard
                    .padding(.top, 12)
                    .dsStagger(0)

                laurels
                    .padding(.top, 20)

                VStack(spacing: 10) {
                    ForEach(Array(Self.reviewIndices.enumerated()), id: \.element) { position, index in
                        reviewCard(index: index)
                            .dsStagger(position + 3, step: 0.09)
                    }
                }
                .padding(.top, 18)

                countriesLine
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    .dsStagger(Self.reviewIndices.count + 3, step: 0.09)
            }
            .padding(.horizontal, 24)
        } footer: {
            OnboardingV2Button(title: languageManager.text("onboardingV2.intro.social.cta"), action: onNext)
                .padding(.top, 10)
        }
        .ov2Background()
        .onAppear {
            if photos.isEmpty { photos = Array(OnboardingStudentPhotos.load().prefix(4)) }
        }
        .task { await reveal() }
    }

    // MARK: - Titre

    private var titleCard: some View {
        OV2Markup.elevate(languageManager.text("onboardingV2.intro.social.title"), highlightFont: DS.title(.title3, .bold))
            .font(DS.title(.title3, .regular))
            .foregroundStyle(OV2.ink)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .ov2Card()
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Lauriers

    private var laurels: some View {
        HStack(spacing: 8) {
            OnboardingV2PaperLaurels {
                VStack(spacing: 5) {
                    Text(languageManager.text("onboardingV2.loading.social.count").uppercasedInApp())
                        .font(DS.sans(.caption, .heavy))
                        .tracking(0.6)
                        .foregroundStyle(OV2.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                    stars(size: 14, shown: starsShown)
                }
            }
            .frame(maxWidth: .infinity)

            OnboardingV2PaperLaurels {
                VStack(spacing: 5) {
                    Text((4.8).formatted(.number.precision(.fractionLength(1)).locale(languageManager.locale)))
                        .font(DS.title(.title2, .heavy))
                        .foregroundStyle(OV2.ink)
                    Text(languageManager.text("onboardingV2.review.appStore").uppercasedInApp())
                        .font(DS.sans(.caption2, .bold))
                        .tracking(0.6)
                        .foregroundStyle(OV2.inkSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .scaleEffect(laurelsIn || reduceMotion ? 1 : 0.8)
        .opacity(laurelsIn ? 1 : 0)
    }

    /// Cinq étoiles ; `shown` en allume les premières (toutes par défaut).
    private func stars(size: CGFloat, shown: Int = OnboardingV2SocialProof.starCount) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<Self.starCount, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: size))
                    .foregroundStyle(OV2.warm)
                    .scaleEffect(index < shown || reduceMotion ? 1 : 0.2)
                    .opacity(index < shown ? 1 : 0)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Avis

    private func reviewCard(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(languageManager.text("onboardingV2.review.t\(index).quote"))
                .font(DS.sans(.subheadline, .regular))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                stars(size: 13)
                Spacer(minLength: 8)
                Text(languageManager.text("onboardingV2.review.t\(index).author"))
                    .font(DS.sans(.caption, .regular))
                    .foregroundStyle(OV2.inkSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .ov2Card()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Pays

    /// « Disponible dans plus de 140 pays », à côté de quelques visages d'utilisateurs.
    private var countriesLine: some View {
        HStack(spacing: 10) {
            if !photos.isEmpty {
                OnboardingV2PhotoRow(photos: photos, size: 26)
            } else {
                Image(systemName: "globe.europe.africa.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(OV2.accent)
                    .accessibilityHidden(true)
            }
            Text(languageManager.text("onboardingV2.intro.social.countries"))
                .font(DS.sans(.footnote, .medium))
                .foregroundStyle(OV2.inkSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Animation

    /// Les lauriers se posent, puis les étoiles s'allument une à une.
    private func reveal() async {
        guard !laurelsIn else { return }
        if reduceMotion {
            laurelsIn = true
            starsShown = Self.starCount
            return
        }
        await pause(0.25)
        if Task.isCancelled { return }
        withAnimation(OV2CoreMotion.settle) {
            laurelsIn = true
        }
        Haptics.soft()
        await pause(0.15)
        for count in 1...Self.starCount {
            if Task.isCancelled { return }
            withAnimation(OV2CoreMotion.settle) {
                starsShown = count
            }
            Haptics.tick(0.3 + 0.08 * CGFloat(count))
            await pause(0.07)
        }
    }

    private func pause(_ seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
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
