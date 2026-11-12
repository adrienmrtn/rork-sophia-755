import SwiftUI

/// Écran « Voici ton profil » — moment de **récompense** inséré juste avant la création de
/// compte / le paywall. On attribue un surnom à l'utilisateur selon ses réponses, on lui
/// rappelle l'objectif qu'il a saisi (carte bleutée « Ton objectif ») et on lui montre les
/// cours qui l'attendent, numérotés le long d'un fil, pour qu'il se sente identifié et
/// impatient de commencer.
struct OnboardingV2Profile: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var badgeIn = false
    @State private var nameRevealed = false
    @State private var reveal = 0

    private var courses: [Course] {
        vm.awaitingCourses(language: languageManager.current)
    }

    private var objectives: [String] {
        vm.objectiveKeys.isEmpty ? [vm.profileArchetypeKey] : vm.objectiveKeys
    }

    /// « Les cours qui **t'attendent** » : la version à passage surligné quand la langue en
    /// a une, le titre existant sinon.
    private var coursesTitle: String {
        OV2End.marked(
            "onboardingV2.profile.coursesTitleMarked",
            fallback: languageManager.text("onboardingV2.profile.coursesTitle"),
            language: languageManager.current
        )
    }

    var body: some View {
        // Contenu scrollable + CTA épinglé : la pile (surnom, objectifs, cours) dépasse la
        // hauteur d'un petit iPhone avec plusieurs objectifs sélectionnés, une grande taille
        // de texte ou une traduction longue. Sans ce conteneur le CTA sortait de l'écran :
        // l'utilisateur ne pouvait plus avancer dans l'onboarding.
        OV2ScrollableContent {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.top, 18)

                objectiveCard
                    .padding(.top, 16)
                    .opacity(reveal >= 1 ? 1 : 0)
                    .offset(y: reveal >= 1 || reduceMotion ? 0 : 14)

                DSHighlightTitle(text: coursesTitle, style: .title2, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, 22)
                    .opacity(reveal >= 2 ? 1 : 0)
                    .offset(y: reveal >= 2 || reduceMotion ? 0 : 14)

                coursesTimeline
                    .padding(.top, 18)
            }
            .padding(.horizontal, OV2End.side)
            .padding(.bottom, 20)
        } footer: {
            // Reveal autonome (état interne au modifieur) : le CTA apparaît toujours,
            // même si la séquence d'animation du contenu est interrompue.
            OnboardingV2Button(
                title: languageManager.text("onboardingV2.profile.cta"),
                enabled: true,
                action: onNext
            )
            .ov2Reveal(delay: 0.9, yOffset: 0)
        }
        .ov2Background()
        .onAppear(perform: runAnimation)
    }

    // MARK: - En-tête (pastille + surnom)

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(DS.accentTint)
                Text(vm.profileEmoji)
                    .font(.system(size: 28))
            }
            .frame(width: 56, height: 56)
            .scaleEffect(badgeIn || reduceMotion ? 1 : 0.4)
            .opacity(badgeIn ? 1 : 0)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(vm.personalizedText("onboardingV2.profile.eyebrow", language: languageManager.current))
                    .font(DS.sans(.footnote, .regular))
                    .foregroundStyle(DS.inkSecondary)

                Text(vm.profileNickname(language: languageManager.current))
                    .font(DS.title(.title3, .bold))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)
            }
            .opacity(nameRevealed ? 1 : 0)
            .offset(x: nameRevealed || reduceMotion ? 0 : -10)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Rappel de l'objectif

    /// Carte bleutée « Ton objectif » : la phrase du profil, puis les objectifs choisis.
    private var objectiveCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            DSEyebrow(text: languageManager.text("onboardingV2.profile.objectiveTitle"))

            Text(vm.profileTagline(language: languageManager.current))
                .font(DS.sans(.callout, .semibold))
                .foregroundStyle(DS.ink)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(objectives, id: \.self) { key in
                    objectiveChip(key)
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ov2EndCard(fill: DS.accentTint, border: Self.objectiveBorder)
    }

    /// Bordure de la carte objectif : le bleu d'accent très éclairci.
    private static let objectiveBorder = Color(red: 0.773, green: 0.835, blue: 0.945)

    private func objectiveChip(_ key: String) -> some View {
        HStack(spacing: 8) {
            Text(OnboardingV2ViewModel.objectiveEmoji(key))
                .font(.system(size: 14))
            Text(OnboardingV2ViewModel.objectiveLabel(key, language: languageManager.current))
                .font(DS.sans(.footnote, .semibold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous).fill(DS.surface))
    }

    // MARK: - Cours qui t'attendent

    /// Les cours numérotés le long d'un fil vertical, le premier mis en avant.
    private var coursesTimeline: some View {
        let shown: [Course] = Array(courses.prefix(6))
        return VStack(spacing: 12) {
            ForEach(Array(shown.enumerated()), id: \.element.id) { i, course in
                timelineRow(course, index: i)
                    .opacity(reveal >= 2 ? 1 : 0)
                    .offset(y: reveal >= 2 || reduceMotion ? 0 : 16)
                    .animation(DS.Motion.reveal.delay(0.06 + Double(i) * 0.08), value: reveal)
            }
        }
        .background(alignment: .leading) {
            Rectangle()
                .fill(Self.objectiveBorder)
                .frame(width: 2)
                .padding(.vertical, 20)
                .padding(.leading, 13)
                .scaleEffect(x: 1, y: reveal >= 2 || reduceMotion ? 1 : 0, anchor: .top)
                .opacity(reveal >= 2 ? 1 : 0)
                .animation(DS.Motion.reveal.delay(0.1), value: reveal)
        }
    }

    private func timelineRow(_ course: Course, index: Int) -> some View {
        let isFirst: Bool = index == 0
        return HStack(spacing: 12) {
            Text(verbatim: "\(index + 1)")
                .font(DS.sans(.footnote, .bold))
                .foregroundStyle(isFirst ? Color.white : DS.accent)
                .frame(width: 28, height: 28)
                .background(Circle().fill(isFirst ? DS.accent : DS.accentTint))
                .accessibilityHidden(true)

            courseCard(course)
        }
    }

    private func courseCard(_ course: Course) -> some View {
        HStack(spacing: 12) {
            courseThumbnail(course)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                DSEyebrow(text: course.subject.localizedShortName(language: languageManager.current))
                Text(course.title)
                    .font(DS.sans(.footnote, .semibold))
                    .foregroundStyle(DS.ink)
                    .lineSpacing(1)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .ov2EndCard()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func courseThumbnail(_ course: Course) -> some View {
        if let img = CourseImageMap.loadImage(for: course.id) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [course.subject.color, course.subject.color.opacity(0.6)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Animation (étagée)

    private func runAnimation() {
        withAnimation(DS.Motion.pop.delay(0.1)) { badgeIn = true }
        withAnimation(DS.Motion.reveal.delay(0.22)) { nameRevealed = true }
        OnboardingHaptics.selection()

        for step in 1...2 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + Double(step) * 0.3) {
                withAnimation(DS.Motion.reveal) {
                    reveal = step
                }
                if step == 1 { OnboardingHaptics.selection() }
            }
        }
    }
}
