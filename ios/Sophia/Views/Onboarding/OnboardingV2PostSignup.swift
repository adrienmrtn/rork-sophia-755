import SwiftUI
import UIKit

/// Les deux pages qui suivent la création du compte : « Bienvenue à bord, {prénom} ! » avec
/// un trophée et des confettis, puis « {prénom}, apprendre n'a pas à être compliqué » avec
/// les atouts de Sophia, la note App Store et « Sans engagement, annulable à tout moment ».

// MARK: - Bienvenue à bord

struct OnboardingV2WelcomeAboard: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var logoIn = false
    @State private var badgeIn = false
    @State private var confetti = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            OnboardingV2AboardMedallion(shown: logoIn, badgeShown: badgeIn)
                .layoutPriority(1)

            Spacer(minLength: 24)

            OV2EndTitle(text: vm.personalizedText("onboardingV2.aboard.title", language: languageManager.current))
                .padding(.horizontal, OV2End.side)
                .ov2Reveal(delay: 0.4, yOffset: 12)

            OV2EndSubtitle(text: languageManager.text("onboardingV2.aboard.subtitle"))
                .padding(.top, 10)
                .padding(.horizontal, OV2End.side)
                .padding(.bottom, 28)
                .ov2Reveal(delay: 0.6, yOffset: 10)

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .overlay {
            if confetti {
                PathConfettiBurst(
                    colors: [DS.accent, DS.accentTint, OV2.pink, DS.warm, DS.success],
                    pieceCount: 70,
                    duration: 3.0,
                    origin: CGPoint(x: 0.5, y: 0.32)
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            // Le trophée se pose avec un rebond, la coche du compte créé suit.
            withAnimation(DS.Motion.pop.delay(0.05)) { logoIn = true }
            withAnimation(DS.Motion.pop.delay(0.45)) { badgeIn = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                confetti = !reduceMotion
                OnboardingHaptics.counterComplete()
            }
        }
    }
}

// MARK: - Médaillon du trophée

/// Le trophée dans un grand rond, avec la coche verte du compte créé posée sur son bord et
/// une onde qui s'élargit derrière lui à l'arrivée. Il rétrécit de lui-même sur un écran court.
private struct OnboardingV2AboardMedallion: View {
    let shown: Bool
    let badgeShown: Bool
    var maxSize: CGFloat = 240

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ripple = false
    @State private var floating = false

    var body: some View {
        trophy
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: maxSize, maxHeight: maxSize)
            .clipShape(Circle())
            .background {
                Circle()
                    .strokeBorder(DS.accentTint, lineWidth: 6)
                    .scaleEffect(ripple ? 1.28 : 1)
                    .opacity(ripple ? 0 : 1)
            }
            .overlay(alignment: .bottomTrailing) {
                checkBadge
                    .scaleEffect(badgeShown || reduceMotion ? 1 : 0.3)
                    .opacity(badgeShown ? 1 : 0)
                    .padding(14)
            }
            .scaleEffect(shown || reduceMotion ? 1 : 0.6)
            .opacity(shown ? 1 : 0)
            .offset(y: floating ? -5 : (reduceMotion ? 0 : 5))
            .accessibilityHidden(true)
            .onAppear(perform: start)
    }

    @ViewBuilder
    private var trophy: some View {
        if UIImage(named: "duel_trophy") != nil {
            Image("duel_trophy")
                .resizable()
        } else {
            ZStack {
                DS.accentTint
                Image(systemName: "trophy.fill")
                    .font(.system(size: 84, weight: .semibold))
                    .foregroundStyle(DS.warm)
            }
        }
    }

    /// Le compte est créé : une coche verte, cerclée de blanc, sur le bord du trophée.
    private var checkBadge: some View {
        ZStack {
            Circle().fill(DS.surface)
            Circle().fill(DS.success).padding(3)
            Image(systemName: "checkmark")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(.white)
        }
        .frame(width: 44, height: 44)
    }

    private func start() {
        guard !reduceMotion else { return }
        if !ripple {
            withAnimation(.easeOut(duration: 1.1).delay(0.3)) { ripple = true }
        }
        if !floating {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true).delay(0.9)) {
                floating = true
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
                    .font(DS.title(.title, .medium))
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
                    .font(DS.title(.title3, .semibold))
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
                        .font(DS.sans(.body, .regular))
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
                .font(DS.title(.title3, .bold))
                .foregroundStyle(OV2.ink)
            Text(languageManager.text("onboardingV2.review.appStore").uppercasedInApp())
                .font(DS.sans(.caption2, .semibold))
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
                .font(DS.sans(.subheadline, .bold))
                .tracking(1.0)
                .foregroundStyle(OV2.ink)
        }
        .accessibilityElement(children: .combine)
    }
}
