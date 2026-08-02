import SwiftUI

/// Écran « Voici ton profil » — moment de **récompense** inséré juste avant la création de
/// compte / le paywall. On attribue un surnom à l'utilisateur selon ses réponses, on lui
/// rappelle l'objectif qu'il a saisi et on lui montre les cours qui l'attendent, pour qu'il
/// se sente identifié et impatient de commencer.
///
/// Direction artistique : identique aux autres écrans de l'OB (calme, premium), animations
/// lentes et étagées.
struct OnboardingV2Profile: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var haloIn = false
    @State private var badgeIn = false
    @State private var nameRevealed = false
    @State private var reveal = 0

    private var courses: [Course] {
        vm.awaitingCourses(language: languageManager.current)
    }

    private var objectives: [String] {
        vm.objectiveKeys.isEmpty ? [vm.profileArchetypeKey] : vm.objectiveKeys
    }

    /// Tailles resserrées sur les petits écrans (iPhone SE / mini) pour que la « récompense »
    /// tienne sans scroll. Le conteneur scrollable reste le garde-fou quand ça ne suffit pas
    /// (plusieurs objectifs, grande taille de texte, traduction longue).
    struct Metrics {
        let topSpacing: CGFloat
        let sectionSpacing: CGFloat
        let badge: CGFloat
        let emoji: CGFloat
        let cardWidth: CGFloat
        let cardHeight: CGFloat

        static let regular = Metrics(
            topSpacing: 44, sectionSpacing: 22,
            badge: 116, emoji: 52,
            cardWidth: 168, cardHeight: 214
        )

        static let compact = Metrics(
            topSpacing: 16, sectionSpacing: 16,
            badge: 92, emoji: 42,
            cardWidth: 148, cardHeight: 188
        )

        /// `height` = hauteur disponible pour l'écran (hors safe areas). Le seuil couvre les
        /// iPhone SE / 8 / mini (≈ 647–728 pt utiles), où la version « regular » ne tient pas.
        static func fitting(height: CGFloat) -> Metrics {
            height < 740 ? .compact : .regular
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = Metrics.fitting(height: proxy.size.height)

            // Contenu scrollable + CTA épinglé : la pile (badge, chips d'objectifs, cartes de
            // cours) a une hauteur minimale supérieure à l'écran sur les petits iPhone, avec
            // plusieurs objectifs sélectionnés, une grande taille de texte ou une traduction
            // longue. Sans ce conteneur le CTA sortait de l'écran (et le badge était rogné en
            // haut) : l'utilisateur ne pouvait plus avancer dans l'onboarding.
            OV2ScrollableContent {
                VStack(spacing: 0) {
                    Spacer().frame(height: metrics.topSpacing)

                    header(metrics)

                    Spacer().frame(height: metrics.sectionSpacing)

                    objectiveReminder
                        .opacity(reveal >= 1 ? 1 : 0)
                        .offset(y: reveal >= 1 ? 0 : 16)

                    Spacer().frame(height: metrics.sectionSpacing)

                    coursesSection(metrics)
                        .opacity(reveal >= 2 ? 1 : 0)
                        .offset(y: reveal >= 2 ? 0 : 20)

                    Spacer().frame(height: 16)
                }
            } footer: {
                // Reveal autonome (état interne au modifieur) : le CTA apparaît toujours,
                // même si la séquence d'animation du contenu est interrompue.
                OnboardingV2Button(
                    title: languageManager.text("onboardingV2.profile.cta"),
                    enabled: true,
                    action: onNext
                )
                .ov2Reveal(delay: 1.5, yOffset: 0)
            }
            // Halo doux qui « respire » derrière le badge.
            .background(alignment: .top) {
                Circle()
                    .fill(OV2.accentSoft.opacity(0.10))
                    .frame(width: 340, height: 340)
                    .scaleEffect(haloIn ? 1.05 : 0.75)
                    .blur(radius: 34)
                    .opacity(haloIn ? 1 : 0)
                    .offset(y: -60)
            }
        }
        .ov2Background()
        .onAppear(perform: runAnimation)
    }

    // MARK: - Header (badge + surnom)

    private func header(_ metrics: Metrics) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(OV2.accent.opacity(0.10))
                    .frame(width: metrics.badge, height: metrics.badge)
                Circle()
                    .strokeBorder(OV2.accent.opacity(0.18), lineWidth: 1)
                    .frame(width: metrics.badge, height: metrics.badge)
                Text(vm.profileEmoji)
                    .font(.system(size: metrics.emoji))
                    .scaleEffect(badgeIn ? 1 : 0.4)
                    .opacity(badgeIn ? 1 : 0)
            }

            VStack(spacing: 8) {
                Text(languageManager.text("onboardingV2.profile.eyebrow").uppercased())
                    .font(DS.sans(.caption, .bold))
                    .tracking(1.6)
                    .foregroundStyle(OV2.accentSoft)
                    .opacity(nameRevealed ? 1 : 0)

                Text(vm.profileNickname(language: languageManager.current))
                    .font(DS.title(.largeTitle, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)
                    .scaleEffect(nameRevealed ? 1 : 0.86)
                    .opacity(nameRevealed ? 1 : 0)

                Text(vm.profileTagline(language: languageManager.current))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(OV2.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .opacity(nameRevealed ? 1 : 0)
            }
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Rappel de l'objectif

    private var objectiveReminder: some View {
        VStack(spacing: 10) {
            Text(languageManager.text("onboardingV2.profile.objectiveTitle").uppercased())
                .font(DS.sans(.caption2, .bold))
                .tracking(1.2)
                .foregroundStyle(OV2.inkTertiary)

            FlexibleChips(items: objectives) { key in
                HStack(spacing: 8) {
                    Text(OnboardingV2ViewModel.objectiveEmoji(key))
                        .font(.system(size: 15))
                    Text(OnboardingV2ViewModel.objectiveLabel(key, language: languageManager.current))
                        .font(DS.sans(.subheadline, .semibold))
                        .foregroundStyle(OV2.ink)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(OV2.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(OV2.accent.opacity(0.25), lineWidth: 1))
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Cours qui t'attendent

    private func coursesSection(_ metrics: Metrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.text("onboardingV2.profile.coursesTitle"))
                .font(DS.title(.title3, .heavy))
                .foregroundStyle(OV2.ink)
                .padding(.horizontal, 28)

            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(Array(courses.prefix(6).enumerated()), id: \.element.id) { i, course in
                        courseCard(course, metrics)
                            .opacity(reveal >= 2 ? 1 : 0)
                            .offset(y: reveal >= 2 ? 0 : 18)
                            .animation(.spring(response: 0.6, dampingFraction: 0.85).delay(Double(i) * 0.08), value: reveal)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func courseCard(_ course: Course, _ metrics: Metrics) -> some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let img = CourseImageMap.loadImage(for: course.id) {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    LinearGradient(
                        colors: [course.subject.color, course.subject.color.opacity(0.6)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                }
            }
            .frame(width: metrics.cardWidth, height: metrics.cardHeight)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.15), .black.opacity(0.78)],
                startPoint: .center, endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(course.subject.localizedShortName(language: languageManager.current).uppercased())
                    .font(DS.sans(.caption2, .bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.white.opacity(0.22), in: Capsule())
                Text(course.title)
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
        }
        .frame(width: metrics.cardWidth, height: metrics.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(OV2.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 14, y: 8)
    }

    // MARK: - Animation (lente et étagée)

    private func runAnimation() {
        withAnimation(.easeInOut(duration: 1.4)) { haloIn = true }
        withAnimation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.2)) { badgeIn = true }
        withAnimation(.spring(response: 0.9, dampingFraction: 0.82).delay(0.55)) { nameRevealed = true }
        OnboardingHaptics.selection()

        for step in 1...2 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9 + Double(step) * 0.45) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                    reveal = step
                }
                if step == 1 { OnboardingHaptics.selection() }
            }
        }
    }
}

/// Petit wrap horizontal (chips) qui passe à la ligne — utilisé pour rappeler les objectifs.
private struct FlexibleChips<Content: View>: View {
    let items: [String]
    @ViewBuilder let content: (String) -> Content

    var body: some View {
        OV2FlowLayout(spacing: 8, lineSpacing: 8) {
            ForEach(items, id: \.self) { item in
                content(item)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
