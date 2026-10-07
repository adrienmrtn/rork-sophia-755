import SwiftUI
import UIKit

/// Les deux pages qui suivent la création du compte : « Bienvenue à bord, {prénom} ! » avec
/// des confettis et des images de cours qui flottent derrière, puis « {prénom}, apprendre n'a
/// pas à être compliqué » avec les atouts de Sophia, la note App Store et « Sans engagement,
/// annulable à tout moment ».

// MARK: - Bienvenue à bord

struct OnboardingV2WelcomeAboard: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var logoIn = false
    @State private var badgeIn = false
    @State private var confetti = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle().fill(OV2.accentSoft.opacity(0.10)).frame(width: 200, height: 200)
                    Circle().fill(OV2.accentSoft.opacity(0.12)).frame(width: 136, height: 136)
                    logo
                }
                checkBadge
                    .offset(x: -30, y: -30)
                    .scaleEffect(badgeIn ? 1 : 0.4)
                    .opacity(badgeIn ? 1 : 0)
            }
            // Les images de cours flottent autour du logo, dans sa bande : jamais derrière
            // le titre, le sous-titre ou le bouton.
            .background { OnboardingV2FloatingCourseImages() }
            .scaleEffect(logoIn ? 1 : 0.82)
            .opacity(logoIn ? 1 : 0)

            Spacer().frame(height: 36)

            Text(vm.personalizedText("onboardingV2.aboard.title", language: languageManager.current))
                .font(DS.title(.largeTitle, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 28)
                .ov2Reveal(delay: 0.45, yOffset: 12)

            Spacer()

            Text(languageManager.text("onboardingV2.aboard.subtitle"))
                .font(DS.sans(.body, .medium))
                .foregroundStyle(OV2.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
                .padding(.bottom, 18)
                .ov2Reveal(delay: 0.75, yOffset: 10)

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .overlay {
            if confetti {
                PathConfettiBurst(
                    colors: [OV2.accent, OV2.accentSoft, OV2.pink, OV2.warm, OV2.success],
                    pieceCount: 70,
                    duration: 3.0,
                    origin: CGPoint(x: 0.5, y: 0.32)
                )
                .ignoresSafeArea()
            }
        }
        .onAppear {
            // Un seul ressort doux pour le logo, la coche qui suit : rien ne claque.
            withAnimation(.spring(response: 1.0, dampingFraction: 0.85)) { logoIn = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.5)) { badgeIn = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                confetti = true
                OnboardingHaptics.counterComplete()
            }
        }
    }

    @ViewBuilder
    private var logo: some View {
        if UIImage(named: "SplashLogo") != nil {
            Image("SplashLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
        } else {
            ZStack {
                Circle().fill(OV2.accent).frame(width: 96, height: 96)
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    /// Le compte est créé : une coche verte sur le logo.
    private var checkBadge: some View {
        ZStack {
            Circle().fill(.white)
            Circle().fill(OV2.success).padding(3)
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.white)
        }
        .frame(width: 38, height: 38)
        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
    }
}

// MARK: - Images de cours qui flottent

/// Six petites images de cours autour du logo, qui dérivent doucement et en boucle. Elles
/// sont posées par rapport au centre du logo et restent dans sa bande (jamais sous le
/// titre, le sous-titre ou le bouton : un texte ne passe jamais devant une image).
private struct OnboardingV2FloatingCourseImages: View {
    /// Décalage par rapport au centre du logo, taille, inclinaison.
    private static let slots: [(x: CGFloat, y: CGFloat, size: CGFloat, rotation: Double)] = [
        (-148, -60, 44, -8), (150, -50, 40, 7), (-128, 46, 38, 5),
        (134, 56, 44, -6), (-62, -126, 42, 6), (76, -130, 46, -5),
    ]
    private static let courseIds = [
        "course_42_pourquoi_reve_t_on",
        "course_149_la_joconde",
        "course_290_comment_les_etats_unis_ont_ils_gagne_la",
        "course_67_qu_est_ce_qu_un_trou_noir",
        "course_264_qui_a_vraiment_construit_les_pyramides",
        "course_150_la_nuit_etoilee_van_gogh",
    ]

    @State private var images: [UIImage?] = []
    @State private var shown = false

    var body: some View {
        ZStack {
            ForEach(Array(Self.slots.enumerated()), id: \.offset) { i, slot in
                OnboardingV2FloatingImage(
                    image: i < images.count ? images[i] : nil,
                    size: slot.size,
                    rotation: slot.rotation,
                    phase: Double(i)
                )
                .offset(x: slot.x, y: slot.y)
            }
        }
        .opacity(shown ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            if images.isEmpty {
                images = Self.courseIds.map { CourseImageMap.loadImage(for: $0) }
            }
            withAnimation(.easeOut(duration: 1.4).delay(0.25)) { shown = true }
        }
    }
}

private struct OnboardingV2FloatingImage: View {
    let image: UIImage?
    let size: CGFloat
    let rotation: Double
    let phase: Double

    @State private var drift = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                OV2.accentSoft.opacity(0.25)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous).strokeBorder(.white.opacity(0.8), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        .opacity(0.72)
        .rotationEffect(.degrees(rotation + (drift ? 3 : -3)))
        .offset(y: drift ? -9 : 9)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3.2 + phase * 0.35)
                .repeatForever(autoreverses: true)
                .delay(phase * 0.3)
            ) {
                drift = true
            }
        }
    }
}

// MARK: - Apprendre n'a pas à être compliqué

/// Six atouts de Sophia sur une frise verticale (les chiffres viennent du catalogue de la
/// langue), la note App Store entre deux lauriers, les étoiles et le nombre d'avis, puis
/// « Sans engagement, annulable à tout moment ».
struct OnboardingV2Features: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var features: [Feature] = []
    @State private var revealed = 0

    struct Feature: Identifiable {
        let id: Int
        let icon: String
        let color: Color
        let text: String
    }

    private static let rowHeight: CGFloat = 52
    private static let featureCount = 6

    var body: some View {
        OV2ScrollableContent {
            VStack(spacing: 0) {
                Spacer().frame(height: 64)

                Text(vm.personalizedText("onboardingV2.features.title", language: languageManager.current))
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .ov2Reveal(delay: 0.05)

                Spacer().frame(height: 28)

                featureList
                    .padding(.horizontal, 28)

                Spacer().frame(height: 28)

                OnboardingV2LaurelBadge(size: 50, tint: OV2.inkSecondary) {
                    appStoreStack
                }
                .ov2Reveal(delay: 1.1)

                Spacer().frame(height: 14)

                reviews
                    .ov2Reveal(delay: 1.25)

                Spacer().frame(height: 22)

                Text(languageManager.text("onboardingV2.features.noCommitment"))
                    .font(DS.title(.title3, .bold))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .ov2Reveal(delay: 1.4)

                Spacer(minLength: 24)
            }
        } footer: {
            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            if features.isEmpty {
                features = Self.makeFeatures(languageManager: languageManager)
            }
            for i in 0..<Self.featureCount {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + Double(i) * 0.14) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { revealed = i + 1 }
                    OnboardingHaptics.selection()
                }
            }
        }
    }

    /// Les six atouts ; les nombres de cours et de questions de quiz sont ceux du catalogue
    /// de la langue, arrondis vers le bas (« 300+ », « 2 600+ »).
    private static func makeFeatures(languageManager: LanguageManager) -> [Feature] {
        let language = languageManager.current
        let courses = ContentCatalog.courses(for: language)
        let courseCount = (courses.count / 10) * 10
        let questionCount = (courses.reduce(0) { $0 + $1.quiz.count } / 100) * 100
        let locale = languageManager.locale
        let courseText = String(format: languageManager.text("onboardingV2.features.row2"), courseCount.formatted(.number.locale(locale)))
        let questionText = String(format: languageManager.text("onboardingV2.features.row3"), questionCount.formatted(.number.locale(locale)))
        return [
            Feature(id: 0, icon: "puzzlepiece.extension.fill", color: Color(red: 0.94, green: 0.47, blue: 0.24), text: languageManager.text("onboardingV2.features.row1")),
            Feature(id: 1, icon: "text.book.closed.fill", color: Color(red: 0.48, green: 0.36, blue: 0.84), text: courseText),
            Feature(id: 2, icon: "trophy.fill", color: Color(red: 0.24, green: 0.73, blue: 0.66), text: questionText),
            Feature(id: 3, icon: "headphones", color: Color(red: 0.29, green: 0.48, blue: 0.97), text: languageManager.text("onboardingV2.features.row5")),
            Feature(id: 4, icon: "hand.raised.fill", color: Color(red: 0.95, green: 0.64, blue: 0.23), text: languageManager.text("onboardingV2.features.row6")),
            Feature(id: 5, icon: "atom", color: Color(red: 0.30, green: 0.69, blue: 0.48), text: languageManager.text("onboardingV2.features.row4")),
        ]
    }

    // MARK: - Frise des atouts

    /// Les pastilles colorées sur un rail clair à gauche, les textes alignés à droite ; une
    /// hauteur de ligne fixe tient les deux colonnes en face l'une de l'autre.
    private var featureList: some View {
        let trackHeight = Self.rowHeight * CGFloat(max(features.count, 1))
        return HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(DS.accentTint)
                    .frame(width: 48, height: trackHeight)
                VStack(spacing: 0) {
                    ForEach(features) { feature in
                        iconBadge(feature)
                            .frame(height: Self.rowHeight)
                            .scaleEffect(feature.id < revealed ? 1 : 0.4)
                            .opacity(feature.id < revealed ? 1 : 0)
                    }
                }
            }
            .frame(width: 48, height: trackHeight)

            VStack(spacing: 0) {
                ForEach(features) { feature in
                    Text(feature.text)
                        .font(DS.sans(.body, .medium))
                        .foregroundStyle(OV2.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: Self.rowHeight)
                        .opacity(feature.id < revealed ? 1 : 0)
                        .offset(x: feature.id < revealed ? 0 : -10)
                }
            }
        }
    }

    private func iconBadge(_ feature: Feature) -> some View {
        ZStack {
            Circle().fill(feature.color).frame(width: 36, height: 36)
            Image(systemName: feature.icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Lauriers, étoiles, avis

    /// Dans les lauriers : la pomme, « 4,8 / 5 », « sur l'App Store ».
    private var appStoreStack: some View {
        VStack(spacing: 3) {
            Image(systemName: "apple.logo")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(OV2.ink)
            Text((4.8).formatted(.number.precision(.fractionLength(1)).locale(languageManager.locale)) + " / 5")
                .font(DS.title(.title3, .heavy))
                .foregroundStyle(OV2.ink)
            Text(languageManager.text("onboardingV2.review.appStore").uppercasedInApp())
                .font(DS.sans(.caption2, .bold))
                .tracking(1.2)
                .foregroundStyle(OV2.inkSecondary)
                .lineLimit(1)
        }
    }

    private var reviews: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(OV2.warm)
                }
            }
            Text(languageManager.text("onboardingV2.loading.reviews").uppercasedInApp())
                .font(DS.sans(.subheadline, .heavy))
                .tracking(1.0)
                .foregroundStyle(OV2.ink)
        }
        .accessibilityElement(children: .combine)
    }
}
