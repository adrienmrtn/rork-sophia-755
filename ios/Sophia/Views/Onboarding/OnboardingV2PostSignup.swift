import SwiftUI
import UIKit

/// Les deux pages qui suivent la création du compte : « Bienvenue à bord, {prénom} ! » avec
/// des confettis, puis « {prénom}, apprendre n'a pas à être compliqué » avec les atouts de
/// Sophia, la note App Store et « Sans engagement, annulable à tout moment ».

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
                    .scaleEffect(badgeIn ? 1 : 0.2)
                    .opacity(badgeIn ? 1 : 0)
            }
            .scaleEffect(logoIn ? 1 : 0.7)
            .opacity(logoIn ? 1 : 0)

            Spacer().frame(height: 36)

            Text(vm.personalizedText("onboardingV2.aboard.title", language: languageManager.current))
                .font(DS.title(.largeTitle, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 28)
                .ov2Reveal(delay: 0.35)

            Spacer()

            Text(languageManager.text("onboardingV2.aboard.subtitle"))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(OV2.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
                .padding(.bottom, 18)
                .ov2Reveal(delay: 0.6)

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .overlay {
            if confetti {
                PathConfettiBurst(
                    colors: [OV2.accent, OV2.accentSoft, OV2.pink, OV2.warm, OV2.success],
                    pieceCount: 80,
                    duration: 2.6,
                    origin: CGPoint(x: 0.5, y: 0.32)
                )
                .ignoresSafeArea()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { logoIn = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.45)) { badgeIn = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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

// MARK: - Apprendre n'a pas à être compliqué

/// Quatre atouts de Sophia sur une frise verticale (les chiffres viennent du catalogue de la
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

    private static let rowHeight: CGFloat = 58

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

                Spacer().frame(height: 30)

                featureList
                    .padding(.horizontal, 28)

                Spacer().frame(height: 30)

                laurels
                    .ov2Reveal(delay: 0.9)

                Spacer().frame(height: 14)

                reviews
                    .ov2Reveal(delay: 1.05)

                Spacer().frame(height: 22)

                Text(languageManager.text("onboardingV2.features.noCommitment"))
                    .font(DS.title(.title3, .bold))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .ov2Reveal(delay: 1.2)

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
            for i in 0..<4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + Double(i) * 0.16) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { revealed = i + 1 }
                    OnboardingHaptics.selection()
                }
            }
        }
    }

    /// Les quatre atouts ; les nombres de cours et de questions de quiz sont ceux du
    /// catalogue de la langue, arrondis vers le bas (« 300+ », « 2 600+ »).
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
            Feature(id: 3, icon: "atom", color: Color(red: 0.95, green: 0.64, blue: 0.23), text: languageManager.text("onboardingV2.features.row4")),
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
                    .frame(width: 50, height: trackHeight)
                VStack(spacing: 0) {
                    ForEach(features) { feature in
                        iconBadge(feature)
                            .frame(height: Self.rowHeight)
                            .scaleEffect(feature.id < revealed ? 1 : 0.4)
                            .opacity(feature.id < revealed ? 1 : 0)
                    }
                }
            }
            .frame(width: 50, height: trackHeight)

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
            Circle().fill(feature.color).frame(width: 38, height: 38)
            Image(systemName: feature.icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Lauriers, étoiles, avis

    private var laurels: some View {
        HStack(spacing: 8) {
            Image(systemName: "laurel.leading")
                .font(.system(size: 50, weight: .regular))
                .foregroundStyle(OV2.inkSecondary)
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
            Image(systemName: "laurel.trailing")
                .font(.system(size: 50, weight: .regular))
                .foregroundStyle(OV2.inkSecondary)
        }
        .accessibilityElement(children: .combine)
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
