import SwiftUI

/// Un passage du lecteur pas à pas : ce qui apparaît à un tap sur « Continuer ».
///
/// Les passages d'un cours sont calculés à l'ouverture (`ReaderStep.build`) à partir des
/// sections structurées, dans l'ordre de lecture ; `CourseView` ne garde que le nombre de
/// passages révélés. Le découpage suit docs/lecture-pas-a-pas.md : l'unité est le bloc (une
/// image est un passage à part entière), un titre de section ouvre un chapitre.
struct ReaderStep: Identifiable {
    typealias Resolved = (content: CourseContentV2, section: CourseSectionV2, isFirst: Bool, isLast: Bool)

    enum Kind {
        /// L'en-tête de la section : hero, titre et accroche pour l'intro, le titre sinon.
        case header
        /// Un bloc du cours tel quel : paragraphe, image, frise, encart, citation. Un `heading`
        /// s'affiche avec le bloc qui le suit plutôt que d'occuper un tap à lui seul.
        case block(ContentBlockV2, heading: String?)
        /// La carte auteur et les sources, après « À retenir » de la dernière section.
        case footer
        /// Une section réservée (gratuit hors cours du jour) : la page floutée et le cadenas, en
        /// un seul passage, comme la page verrouillée du mode par pages.
        case locked
        /// Une leçon sans édition structurée : le rendu legacy de la page entière.
        case legacy
    }

    let id: String
    let kind: Kind
    /// Index de la section (0 = intro), aligné sur `course.lessons`.
    let sectionIndex: Int
    let lesson: LessonPage
    /// Contenu et section résolus ; nil pour `.legacy`.
    let resolved: Resolved?

    /// Le texte de prose du passage, pour le coachmark du glossaire ; vide s'il n'en a pas.
    var proseText: String {
        guard case .block(let block, _) = kind else { return "" }
        switch block {
        case .heading(let text), .paragraph(let text), .funFact(let text), .takeaway(let text):
            return text
        case .quote(let text, _):
            return text
        case .image, .timeline:
            return ""
        }
    }

    /// Vrai quand le passage montre une image : son entrée gagne une légère montée d'échelle.
    var showsPicture: Bool {
        switch kind {
        case .header:
            return resolved?.isFirst == true && resolved?.content.hero != nil
        case .block(let block, _):
            if case .image = block { return true }
            return false
        case .footer, .locked, .legacy:
            return false
        }
    }

    // MARK: - Construction

    /// Les passages d'un cours, dans l'ordre de lecture. Les sections verrouillées pour ce
    /// lecteur tiennent en un passage ; une leçon sans édition structurée aussi.
    static func build(course: Course, isPremium: Bool, isDailyFreeCourse: Bool) -> [ReaderStep] {
        var steps: [ReaderStep] = []
        for (index, lesson) in course.lessons.enumerated() {
            guard let resolved = CourseContentStore.section(courseId: course.id, sectionId: lesson.id) else {
                steps.append(ReaderStep(id: "\(lesson.id)#legacy", kind: .legacy, sectionIndex: index, lesson: lesson, resolved: nil))
                continue
            }
            if FreemiumGate.isLessonContentLocked(lessonIndex: index, isPremium: isPremium, isDailyFreeCourse: isDailyFreeCourse) {
                steps.append(ReaderStep(id: "\(lesson.id)#locked", kind: .locked, sectionIndex: index, lesson: lesson, resolved: resolved))
                continue
            }
            steps.append(ReaderStep(id: "\(lesson.id)#header", kind: .header, sectionIndex: index, lesson: lesson, resolved: resolved))
            steps.append(contentsOf: blockSteps(for: resolved, lesson: lesson, sectionIndex: index))
            let content = resolved.content
            if resolved.isLast, content.author != nil || !(content.sources ?? []).isEmpty {
                steps.append(ReaderStep(id: "\(lesson.id)#footer", kind: .footer, sectionIndex: index, lesson: lesson, resolved: resolved))
            }
        }
        return steps
    }

    private static func blockSteps(for resolved: Resolved, lesson: LessonPage, sectionIndex: Int) -> [ReaderStep] {
        var steps: [ReaderStep] = []
        var pendingHeading: String?

        func make(_ kind: Kind, suffix: String) -> ReaderStep {
            ReaderStep(id: "\(lesson.id)#\(suffix)", kind: kind, sectionIndex: sectionIndex, lesson: lesson, resolved: resolved)
        }

        for (blockIndex, block) in resolved.section.blocks.enumerated() {
            if case .heading(let text) = block {
                if let waiting = pendingHeading {
                    steps.append(make(.block(.heading(waiting), heading: nil), suffix: "\(blockIndex)-heading"))
                }
                pendingHeading = text
                continue
            }
            steps.append(make(.block(block, heading: pendingHeading), suffix: "\(blockIndex)"))
            pendingHeading = nil
        }
        if let heading = pendingHeading {
            steps.append(make(.block(.heading(heading), heading: nil), suffix: "end-heading"))
        }
        return steps
    }
}

/// Le fil du lecteur pas à pas : les passages révélés dans un seul défilement vertical, avec
/// l'animation d'entrée et le défilement automatique vers le dernier passage révélé.
///
/// La vue ne décide rien : `CourseView` tient le nombre de passages révélés, les gestes
/// (glossaire, auteur, cadenas, double-tap « j'aime ») lui remontent comme en mode par pages.
struct CourseStepReaderView: View {
    /// Demande de défilement : le passage à amener en vue, et un jeton qui change à chaque demande
    /// (le même passage peut être demandé deux fois, par exemple après un changement de mode).
    struct ScrollRequest: Equatable {
        let stepID: String
        let token: Int
    }

    let course: Course
    let steps: [ReaderStep]
    let revealedCount: Int
    let accent: Color
    let scrollRequest: ScrollRequest?
    let bigHeart: Int
    let onGlossaryTap: (GlossaryEntry) -> Void
    let onAuthorTap: (CourseAuthor) -> Void
    let isFollowingAuthor: (CourseAuthor) -> Bool
    let onFollowAuthor: (CourseAuthor) -> Void
    let onUnlock: () -> Void
    let onDoubleTap: () -> Void
    /// « Voir l'original » (nil : non proposé, par exemple quand le cours n'est pas lisible en entier).
    var onShowOriginal: ((AppLanguage) -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Le haut du passage révélé vient se poser à 8 % de la hauteur du lecteur, quelle que soit la
    /// hauteur du passage : la cible du défilement est un repère sans hauteur posé à son sommet.
    private static let revealAnchor = UnitPoint(x: 0.5, y: 0.08)

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(Array(steps.prefix(revealedCount))) { step in
                            VStack(alignment: .leading, spacing: 0) {
                                Color.clear.frame(height: 0).id(step.id)
                                stepView(step)
                            }
                            .transition(transition(for: step))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    // De la place sous le dernier passage, pour qu'il puisse toujours monter jusqu'au
                    // repère de lecture même quand rien ne le suit encore.
                    .padding(.bottom, max(160, geo.size.height * 0.85))
                }
                .scrollIndicators(.hidden)
                // Deux taps n'importe où sur la leçon : « j'aime », comme en mode par pages et sur le fil.
                .simultaneousGesture(TapGesture(count: 2).onEnded { onDoubleTap() })
                .overlay { BigHeartOverlay(trigger: bigHeart) }
                .onAppear {
                    // Retour du mode par pages au milieu du cours : on reprend à la section en cours.
                    guard let request = scrollRequest else { return }
                    DispatchQueue.main.async {
                        proxy.scrollTo(request.stepID, anchor: Self.revealAnchor)
                    }
                }
                .onChange(of: scrollRequest) { _, request in
                    guard let request else { return }
                    // Le passage vient d'être inséré : SwiftUI le pose au prochain tour, on défile ensuite.
                    DispatchQueue.main.async {
                        if reduceMotion {
                            proxy.scrollTo(request.stepID, anchor: Self.revealAnchor)
                        } else {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                                proxy.scrollTo(request.stepID, anchor: Self.revealAnchor)
                            }
                        }
                    }
                }
            }
        }
    }

    /// Fondu et montée de 18 pt (le ressort est donné par `CourseView` au moment de révéler) ;
    /// une image gagne une légère montée d'échelle. Réduire les animations : fondu seul.
    private func transition(for step: ReaderStep) -> AnyTransition {
        if reduceMotion { return .opacity }
        var insertion: AnyTransition = .opacity.combined(with: .offset(y: 18))
        if step.showsPicture {
            insertion = insertion.combined(with: .scale(scale: 0.97))
        }
        return .asymmetric(insertion: insertion, removal: .opacity)
    }

    @ViewBuilder
    private func stepView(_ step: ReaderStep) -> some View {
        switch step.kind {
        case .header:
            if let resolved = step.resolved {
                SectionHeaderV2(
                    content: resolved.content,
                    section: resolved.section,
                    isFirst: resolved.isFirst,
                    accent: accent,
                    onAuthorTap: onAuthorTap,
                    onShowOriginal: onShowOriginal
                )
            }

        case .block(let block, let heading):
            VStack(alignment: .leading, spacing: 24) {
                if let heading {
                    ContentBlockViewV2(
                        block: .heading(heading),
                        accent: accent,
                        courseId: course.id,
                        courseTitle: course.title,
                        onGlossaryTap: onGlossaryTap
                    )
                }
                ContentBlockViewV2(
                    block: block,
                    accent: accent,
                    courseId: course.id,
                    courseTitle: course.title,
                    onGlossaryTap: onGlossaryTap
                )
            }

        case .footer:
            if let resolved = step.resolved {
                SectionFooterV2(
                    content: resolved.content,
                    onAuthorTap: onAuthorTap,
                    isFollowingAuthor: isFollowingAuthor,
                    onFollowAuthor: onFollowAuthor,
                    onShowOriginal: onShowOriginal
                )
            }

        case .locked:
            if let resolved = step.resolved {
                LockedSectionStep(
                    resolved: resolved,
                    accent: accent,
                    courseId: course.id,
                    courseTitle: course.title,
                    onUnlock: onUnlock
                )
            }

        case .legacy:
            VStack(alignment: .leading, spacing: 24) {
                Text(step.lesson.title)
                    .font(DS.title(.largeTitle, .semibold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)

                RichContentView(
                    content: step.lesson.content,
                    accent: accent,
                    courseId: course.id,
                    courseTitle: course.title,
                    onGlossaryTap: onGlossaryTap
                )
            }
        }
    }
}

/// Une section réservée dans le fil : la page floutée, raccourcie et fondue vers le bas, le
/// cadenas par-dessus. Même règle que la page verrouillée du mode par pages : le texte est
/// caché à l'œil comme à VoiceOver, et seul le cadenas ouvre le paywall.
private struct LockedSectionStep: View {
    let resolved: ReaderStep.Resolved
    let accent: Color
    let courseId: String
    let courseTitle: String
    let onUnlock: () -> Void

    var body: some View {
        BlockContentView(
            content: resolved.content,
            section: resolved.section,
            isFirst: resolved.isFirst,
            accent: accent,
            courseId: courseId,
            courseTitle: courseTitle,
            onGlossaryTap: { _ in }
        )
        .compositingGroup()
        .blur(radius: 5)
        .frame(maxWidth: .infinity, maxHeight: 440, alignment: .topLeading)
        .clipped()
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.7),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .overlay { CourseLessonLockOverlay(onUnlock: onUnlock) }
    }
}
