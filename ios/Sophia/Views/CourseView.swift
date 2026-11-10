import StoreKit
import SwiftUI
import RevenueCatUI

struct CourseView: View {
    @Environment(LanguageManager.self) private var languageManager

    let course: Course
    let progressManager: ProgressManager
    @Bindable var store: StoreViewModel
    let onDismissToHome: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    /// Le paquet du cours (texte, quiz, glossaire) : déjà sur le téléphone, en cours de
    /// téléchargement, ou introuvable hors ligne.
    @State private var contentState: ContentLoadState = .ready

    private enum ContentLoadState { case ready, loading, unavailable }
    @State private var showQuiz: Bool = false
    @State private var appeared: Bool = false
    @State private var showDebloquerPaywall: Bool = false
    @State private var showQuizPaywall: Bool = false
    /// Second-chance comparison paywall (both offers, like the end of onboarding), shown after
    /// the user closes the quiz / course-unlock paywall without subscribing.
    /// Comparison paywall stacked *on top* of the quiz paywall (second-chance, quiz flow only).
    @State private var showComparisonOverQuiz: Bool = false
    /// Comparison paywall stacked *on top* of the course-unlock paywall (second-chance).
    @State private var showComparisonOverDebloquer: Bool = false
    @State private var endPhase: CourseEndPhase = .none
    @State private var previousSubjectCount: Int = 0
    @State private var previousSubjectXP: Int = 0
    @State private var globalCourseAwardResult: GlobalXPAwardResult?
    @State private var pendingCollectionEvents: [CollectionProgressEvent] = []
    @State private var rewardSteps: [PostCompletionRewardStep] = []
    @State private var showRewardFlow: Bool = false
    /// Vrai entre l'ouverture du cours et sa fermeture. Un `fullScreenCover` (quiz,
    /// paywall) fait disparaître puis réapparaître le lecteur : ce n'est pas une nouvelle
    /// visite, les tâches d'ouverture ne doivent pas repartir.
    @State private var isVisitActive = false
    /// Quand la section affichée a commencé, pour le temps passé de `section_view`.
    @State private var sectionEnteredAt = Date()
    @State private var coachmarkTerm: String? = nil
    /// Double-tap on a lesson: the big heart of the feed, same rule (never un-likes).
    @State private var bigHeart = 0
    /// Glossary term tapped in the lesson body. Shown as an in-app overlay (not a system
    /// sheet) so the course text stays perfectly still when a term is tapped.
    @State private var selectedGlossaryEntry: GlossaryEntry? = nil
    /// Professor whose page is open (byline or "written by" card tapped).
    @State private var presentedAuthor: CourseAuthor? = nil
    /// « Voir l'original » : la langue d'écriture du cours, quand son texte original est ouvert.
    @State private var originalLanguage: AppLanguage? = nil
    /// Full audio player, opened by the headphones in the header.
    @State private var showAudioPlayer: Bool = false
    @State private var showAudioPaywall: Bool = false
    /// Another course's narration is loaded: listen now, next, or at the end of the queue.
    @State private var showAudioChoice: Bool = false
    /// While the reader is up, the player's paywall requests land here, not in ContentView.
    @State private var audioPaywallHandlerId: UUID?

    /// Fixed XP awarded for finishing a course (reaching the completion screen). Always granted.
    /// Listening to the narration to the end grants the same (see `ContentView`).
    static let courseCompletionXP: Int = 10

    private var isPremium: Bool { store.isPremium }

    /// True while a `fullScreenCover` is presented over the reader. Each of these removes the
    /// reader from the visible hierarchy without the user having left the course.
    private var isCoveredByOverlay: Bool {
        showQuiz || showDebloquerPaywall || showQuizPaywall
            || showComparisonOverQuiz || showComparisonOverDebloquer || showAudioPaywall
    }

    /// The one course a free user can fully read today (claimed on open in `ContentView`).
    private var isDailyFreeCourse: Bool {
        progressManager.isDailyFreeCourse(course.id)
    }

    /// Full read + completion access: premium, or this is the free course of the day.
    private var hasFullAccess: Bool {
        isPremium || isDailyFreeCourse
    }

    /// A free user's 2nd+ course of the day: only the intro is readable, the rest is locked.
    private var isCourseLocked: Bool {
        !hasFullAccess
    }

    private var isLastLesson: Bool {
        currentIndex == course.lessons.count - 1
    }

    private var progressValue: Double {
        Double(currentIndex + 1) / Double(course.lessons.count)
    }

    private let cream = DS.canvas

    /// Anchor id used to snap each lesson page back to the top on arrival.
    private static let lessonTopID = "lessonTopAnchor"

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            switch endPhase {
            case .none:
                lessonsBody
            case .completed:
                CourseCompletedView(
                    course: course,
                    progressManager: progressManager,
                    previousSubjectXP: previousSubjectXP,
                    earnedXP: Self.courseCompletionXP,
                    globalAwardResult: globalCourseAwardResult,
                    showFreemiumGate: !isPremium,
                    onClose: {
                        continueAfterCourseCompletion()
                    },
                    onQuizTapped: {
                        if isPremium {
                            showQuiz = true
                        } else {
                            showQuizPaywall = true
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .streak:
                StreakCelebrationView(
                    streak: progressManager.streak,
                    subject: course.subject,
                    lastActiveDate: progressManager.progress.lastActiveDate,
                    onReturnHome: { onDismissToHome() }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if showRewardFlow {
                PostCompletionRewardFlowView(
                    steps: rewardSteps,
                    progressManager: progressManager,
                    onFinished: {
                        showRewardFlow = false
                        onDismissToHome()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.985)))
                .zIndex(50)
            }

            if let coachmarkTerm {
                GlossaryCoachmark(
                    term: coachmarkTerm,
                    onDismiss: {
                        TutorialFlags.markSeen(.courseTerms)
                        withAnimation(.easeOut(duration: 0.25)) { self.coachmarkTerm = nil }
                    }
                )
                .transition(.opacity)
                .zIndex(60)
            }

            // Glossary explanation, drawn INSIDE the course (not a system sheet) so tapping a
            // term never shifts or animates the course text — it just shows the explanation.
            if let entry = selectedGlossaryEntry {
                GlossaryTermOverlay(
                    entry: entry,
                    onDismiss: { selectedGlossaryEntry = nil }
                )
                .transition(.opacity)
                .zIndex(70)
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            // A `fullScreenCover` takes its presenter off screen, so opening the quiz or a
            // paywall over the course fires `onDisappear` then `onAppear` again on the way
            // back. An active visit means this is a return from a cover, not a new visit.
            guard !isVisitActive else { return }
            isVisitActive = true
            sectionEnteredAt = Date()
            // Inline images come from the bucket: start fetching them now so paging forward
            // finds them on disk rather than in flight.
            CourseImageLoader.prefetch(courseId: course.id)
            progressManager.registerFirstCourseOpenedIfNeeded(course.id)
            requestAppStoreReviewIfEligible(lessonIndex: currentIndex)
            maybeShowTermCoachmark(lessonIndex: currentIndex)
        }
        .onDisappear {
            // Covered, not closed: the reader is still the screen the user is on.
            guard !isCoveredByOverlay else { return }
            isVisitActive = false
            // Fermé en cours de route : la section en cours compte, non lue jusqu'au bout.
            if endPhase == .none {
                logSectionView(index: currentIndex, reachedEnd: false)
            }
        }
        .onChange(of: currentIndex) { oldIndex, newIndex in
            logSectionView(index: oldIndex, reachedEnd: newIndex > oldIndex)
            requestAppStoreReviewIfEligible(lessonIndex: newIndex)
            maybeShowTermCoachmark(lessonIndex: newIndex)
        }
        .fullScreenCover(item: $presentedAuthor) { author in
            // La page créateur plein écran (prompt 2) ; depuis le lecteur, un autre de ses cours
            // passe par la porte habituelle (`openOtherCourse`).
            CreatorPageView(
                author: author,
                progressManager: progressManager,
                onOpenCourse: { target in
                    presentedAuthor = nil
                    guard target.id != course.id else { return }
                    openOtherCourse(target)
                },
                onOpenCampaign: { _ in },
                showsCampaignCard: false
            )
            .sophiaColorScheme()
        }
        .fullScreenCover(isPresented: $showQuiz) {
            QuizView(
                course: course,
                progressManager: progressManager,
                initialCollectionEvents: pendingCollectionEvents,
                onReturnHome: {
                    showQuiz = false
                    onDismissToHome()
                }
            )
            .sophiaColorScheme()
        }
        .onChange(of: currentIndex) { _, _ in
            let g = UIImpactFeedbackGenerator(style: .light)
            g.impactOccurred()
        }
        .fullScreenCover(isPresented: $showDebloquerPaywall) {
            SophiaPaywallView(
                context: .debloquerCours,
                store: store,
                course: course,
                secondsUntilReset: progressManager.secondsUntilDailyReset(),
                onPurchased: { showComparisonOverDebloquer = false; showDebloquerPaywall = false },
                onRestored: { showComparisonOverDebloquer = false; showDebloquerPaywall = false },
                // Fermer présente le paywall comparatif PAR-DESSUS (empilé), sans fermer le
                // premier — sauf si l'utilisateur est déjà premium.
                onDismissed: {
                    if store.isPremium { showDebloquerPaywall = false }
                    else { showComparisonOverDebloquer = true }
                }
            )
            .fullScreenCover(isPresented: $showComparisonOverDebloquer) {
                OnboardingV2PaywallComparison(
                    store: store,
                    onSubscribed: { showComparisonOverDebloquer = false; showDebloquerPaywall = false },
                    onClose: { showComparisonOverDebloquer = false; showDebloquerPaywall = false }
                )
            }
        }
        .fullScreenCover(isPresented: $showQuizPaywall) {
            SophiaPaywallView(
                context: .quizz,
                store: store,
                course: course,
                onPurchased: { showComparisonOverQuiz = false; showQuizPaywall = false },
                onRestored: { showComparisonOverQuiz = false; showQuizPaywall = false },
                // Fermer le paywall quiz présente le paywall comparatif PAR-DESSUS (empilé),
                // sans que le premier ne se ferme — sauf si l'utilisateur est déjà premium.
                onDismissed: {
                    if store.isPremium { showQuizPaywall = false }
                    else { showComparisonOverQuiz = true }
                }
            )
            .fullScreenCover(isPresented: $showComparisonOverQuiz) {
                OnboardingV2PaywallComparison(
                    store: store,
                    onSubscribed: { showComparisonOverQuiz = false; showQuizPaywall = false },
                    onClose: { showComparisonOverQuiz = false; showQuizPaywall = false }
                )
            }
        }
        .sheet(isPresented: $showAudioPlayer) {
            AudioPlayerView()
                .sophiaSheetChrome()
        }
        .sheet(item: $originalLanguage) { language in
            OriginalCourseView(courseId: course.id, language: language)
                .sophiaSheetChrome()
        }
        .audioPlayChoiceDialog(isPresented: $showAudioChoice, courseId: course.id, source: "course_reader") {
            CourseAudioPlayer.shared.play(courseId: course.id, source: "course_reader")
            showAudioPlayer = true
        }
        .onAppear {
            guard audioPaywallHandlerId == nil else { return }
            audioPaywallHandlerId = CourseAudioPlayer.shared.pushPaywallHandler {
                // From the player sheet (a subscription that lapsed): the sheet goes first.
                guard showAudioPlayer else {
                    showAudioPaywall = true
                    return
                }
                showAudioPlayer = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { showAudioPaywall = true }
            }
        }
        .onDisappear {
            guard !isCoveredByOverlay, let id = audioPaywallHandlerId else { return }
            CourseAudioPlayer.shared.removePaywallHandler(id)
            audioPaywallHandlerId = nil
        }
        .fullScreenCover(isPresented: $showAudioPaywall) {
            SophiaPaywallView(
                context: .audio,
                store: store,
                course: course,
                onPurchased: {
                    showAudioPaywall = false
                    // Bought to listen: start listening.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { openAudio() }
                },
                onRestored: { showAudioPaywall = false },
                onDismissed: { showAudioPaywall = false }
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .sophiaColorScheme()
    }

    private var headerBar: some View {
        HStack(spacing: 14) {
            Button {
                let g = UIImpactFeedbackGenerator(style: .light)
                g.impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.jakarta(size: 15, weight: .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(width: 40, height: 40)
                    .background(DS.surface, in: Circle())
                    .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
            }

            progressBar

            Text("\(currentIndex + 1) / \(course.lessons.count)")
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.inkSecondary)
                .monospacedDigit()

            if CourseAudioCatalog.shared.hasAudio(course.id) {
                audioButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    // MARK: Audio

    /// Headphones: listen to this course. Animated while its narration plays.
    private var audioButton: some View {
        let player = CourseAudioPlayer.shared
        let playing = player.isPlayingCourse(course.id)
        return Button(action: openAudio) {
            Image(systemName: playing ? "waveform" : (isPremium ? "headphones" : "lock.fill"))
                .font(.jakarta(size: 15, weight: .semibold))
                .foregroundStyle(player.isCurrent(course.id) ? DS.accent : DS.inkSecondary)
                .symbolEffect(.variableColor.iterative, isActive: playing)
                .frame(width: 40, height: 40)
                .background(DS.surface, in: Circle())
                .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
        }
        .accessibilityLabel(Text(languageManager.text("audio.listen")))
    }

    private func openAudio() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        guard isPremium else {
            showAudioPaywall = true
            return
        }
        let player = CourseAudioPlayer.shared
        player.isPremium = true
        if player.hasItem, !player.isCurrent(course.id) {
            showAudioChoice = true
            return
        }
        if !player.isCurrent(course.id) {
            player.play(courseId: course.id, source: "course_reader")
        } else if !player.isPlaying {
            player.resume()
        }
        showAudioPlayer = true
    }

    /// Un segment par section, remplis jusqu'à la section courante (maquette) ; au-delà de
    /// douze sections, une barre continue, sinon les segments deviennent des pointillés.
    private var progressBar: some View {
        Group {
            if course.lessons.count <= 12 {
                HStack(spacing: 4) {
                    ForEach(0..<max(1, course.lessons.count), id: \.self) { index in
                        Capsule()
                            .fill(index <= currentIndex ? DS.accentSoft : DS.hairline)
                            .animation(.easeInOut(duration: 0.25), value: currentIndex)
                    }
                }
            } else {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(DS.hairline)
                        Capsule()
                            .fill(DS.accent)
                            .frame(width: max(8, geo.size.width * progressValue))
                            .animation(.spring(response: 0.4), value: progressValue)
                    }
                }
            }
        }
        .frame(height: 6)
    }

    @ViewBuilder
    private func lessonContent(lesson: LessonPage, lessonIndex: Int) -> some View {
        if FreemiumGate.isLessonContentLocked(lessonIndex: lessonIndex, isPremium: isPremium, isDailyFreeCourse: isDailyFreeCourse) {
            lockedLessonView(lesson: lesson, lessonIndex: lessonIndex)
        } else {
            unlockedLessonView(lesson: lesson, lessonIndex: lessonIndex)
        }
    }

    /// Renders a lesson with the structured v2 block engine when content exists for it,
    /// otherwise falls back to the legacy `RichContentView` string renderer.
    @ViewBuilder
    private func lessonBody(lesson: LessonPage) -> some View {
        if let resolved = CourseContentStore.section(courseId: course.id, sectionId: lesson.id) {
            BlockContentView(
                content: resolved.content,
                section: resolved.section,
                isFirst: resolved.isFirst,
                accent: DS.accentSoft,
                courseId: course.id,
                courseTitle: course.title,
                onGlossaryTap: showGlossary,
                isLast: resolved.isLast,
                onAuthorTap: { author in presentedAuthor = author },
                isFollowingAuthor: { progressManager.isFollowing($0.slug) },
                onFollowAuthor: { author in
                    let wasFollowing = progressManager.isFollowing(author.slug)
                    progressManager.toggleFollow(author.slug)
                    AnalyticsService.shared.log(wasFollowing ? .unfollow : .follow, courseId: course.id, screen: "reader", props: ["creator": .string(author.slug)])
                },
                // Le texte original entier n'est proposé qu'à qui peut lire le cours entier.
                onShowOriginal: hasFullAccess ? { language in originalLanguage = language } : nil
            )
        } else {
            VStack(alignment: .leading, spacing: 24) {
                Text(lesson.title)
                    .font(DS.title(.largeTitle, .semibold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)

                RichContentView(
                    content: lesson.content,
                    accent: DS.accentSoft,
                    courseId: course.id,
                    courseTitle: course.title,
                    onGlossaryTap: showGlossary
                )
            }
        }
    }

    /// Surface a tapped glossary term as an in-app overlay. No course-text movement.
    private func showGlossary(_ entry: GlossaryEntry) {
        selectedGlossaryEntry = entry
        AnalyticsService.shared.log(
            .glossaryOpen,
            courseId: course.id,
            props: ["term": .string(entry.displayTerm), "section_index": .int(currentIndex)]
        )
    }

    /// La section que l'on quitte, avec le temps qu'on y a passé (docs/events.md).
    private func logSectionView(index: Int, reachedEnd: Bool) {
        let seconds = Int(Date().timeIntervalSince(sectionEnteredAt).rounded())
        progressManager.addReadingSeconds(seconds)
        AnalyticsService.shared.log(
            .sectionView,
            courseId: course.id,
            props: [
                "section_index": .int(index),
                "section_count": .int(course.lessons.count),
                "seconds": .int(max(0, seconds)),
                "reached_end": .bool(reachedEnd),
            ]
        )
        sectionEnteredAt = Date()
    }

    /// Le cœur du double-tap : il s'affiche toujours, il n'éteint jamais un « j'aime » (comme
    /// sur les réseaux vidéo). Enregistré avec l'écran `reader` (docs/events.md).
    private func likeFromDoubleTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        bigHeart += 1
        guard !progressManager.isLiked(course.id) else { return }
        progressManager.toggleLike(course.id)
        AnalyticsService.shared.log(.like, courseId: course.id, screen: "reader")
    }

    /// Another course picked on the author's page: close this reader, then ask the home
    /// screen to open the new one through the deep-link door, so the daily free course and
    /// the open-source attribution follow the same rules as any other entry point. The
    /// delay lets the full-screen cover finish dismissing before the next one is presented.
    private func openOtherCourse(_ target: Course) {
        onDismissToHome()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            AnalyticsService.shared.pendingCourseOpenSource = .author
            DeepLinkRouter.shared.requestCourse(target.id)
        }
    }

    private func unlockedLessonView(lesson: LessonPage, lessonIndex: Int) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                Color.clear.frame(height: 0).id(Self.lessonTopID)
                lessonBody(lesson: lesson)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            // Deux taps n'importe où sur la leçon : « j'aime », comme sur la carte du fil.
            // Simultané, pour ne pas retarder le tap simple des termes du glossaire.
            .simultaneousGesture(TapGesture(count: 2).onEnded { likeFromDoubleTap() })
            .overlay { BigHeartOverlay(trigger: bigHeart) }
            .onChange(of: currentIndex) { oldIndex, newIndex in
                // Only reset to the top when moving forward (Continue / swipe next).
                // Going back keeps the previous reading position.
                guard newIndex == lessonIndex, newIndex > oldIndex else { return }
                proxy.scrollTo(Self.lessonTopID, anchor: .top)
            }
        }
    }

    /// Locked pages stay vertically scrollable: title stays crisp, the body
    /// quickly blurs, and the unlock card remains centered on the visible screen.
    private func lockedLessonView(lesson: LessonPage, lessonIndex: Int) -> some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ZStack {
                    ScrollView {
                        Color.clear.frame(height: 0).id(Self.lessonTopID)
                        lessonBody(lesson: lesson)
                            .compositingGroup()
                            .blur(radius: 5)
                            .allowsHitTesting(false)
                            // Blurring hides the text from the eye but not from VoiceOver,
                            // which read the whole locked lesson aloud — the paid content,
                            // for free, to the users least able to tell it was meant to be
                            // hidden. The lock below is what this page has to offer.
                            .accessibilityHidden(true)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, max(geo.size.height * 0.34, 180))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: currentIndex) { oldIndex, newIndex in
                        guard newIndex == lessonIndex, newIndex > oldIndex else { return }
                        proxy.scrollTo(Self.lessonTopID, anchor: .top)
                    }

                    CourseLessonLockOverlay {
                        presentDebloquerPaywall()
                    }
                }
            }
        }
    }

    private var lessonsBody: some View {
        VStack(spacing: 0) {
            headerBar

            if TikTokBlockerManager.shared.showsLockBanner {
                TikTokLockBanner()
            }

            if contentState != .ready {
                contentPlaceholder
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(course.lessons.enumerated()), id: \.element.id) { index, lesson in
                        lessonContent(lesson: lesson, lessonIndex: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                // Restaure le slide entre les pages : sur un TabView `.page`, seul ce modifieur
                // anime un changement *programmatique* de sélection (bouton « Continuer »).
                // `withAnimation` seul n'anime pas le slide sur iOS 17/18.
                .animation(.spring(response: 0.4), value: currentIndex)

                bottomButton
            }
        }
        .task(id: course.id) { await loadContentIfNeeded() }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    /// Le texte vient du catalogue en ligne : s'il n'est pas encore sur le téléphone, on le
    /// télécharge avant d'afficher la première page.
    private func loadContentIfNeeded() async {
        let language = AppLanguage.currentPersisted()
        if CourseContentStore.hasContent(courseId: course.id, language: language) {
            contentState = .ready
            return
        }
        contentState = .loading
        let content = await CourseContentStore.ensureContent(courseId: course.id, language: language)
        contentState = content == nil ? .unavailable : .ready
    }

    private var contentPlaceholder: some View {
        let language = AppLanguage.currentPersisted()
        return VStack(spacing: 14) {
            Spacer(minLength: 0)
            if contentState == .loading {
                ProgressView()
                    .tint(DS.accent)
                Text(AppLocalizable.string("course.loading", language: language))
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
            } else {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(DS.inkTertiary)
                Text(AppLocalizable.string("course.offline.title", language: language))
                    .font(DS.title(.headline, .heavy))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)
                Text(AppLocalizable.string("course.offline.body", language: language))
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    Task { await loadContentIfNeeded() }
                } label: {
                    Text(AppLocalizable.string("course.offline.retry", language: language))
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DS.accent))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }

    private var bottomButton: some View {
        Button {
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.impactOccurred()
            // Cours verrouillé (2e+ du jour) : le bouton bas slide comme d'habitude.
            // Le paywall ne s'ouvre que via le cadenas sur les pages floutées.
            if isCourseLocked {
                guard !isLastLesson else { return }
                currentIndex += 1
                progressManager.updateLessonProgress(
                    courseId: course.id,
                    lessonIndex: currentIndex,
                    lessonCount: course.lessons.count
                )
                return
            }
            if isLastLesson {
                guard FreemiumGate.canCompleteCourse(isPremium: isPremium, isDailyFreeCourse: isDailyFreeCourse) else { return }
                progressManager.updateLessonProgress(
                    courseId: course.id,
                    lessonIndex: currentIndex,
                    lessonCount: course.lessons.count
                )
                let wasCompletedBefore = progressManager.courseStatus(for: course.id) == .completed
                previousSubjectCount = progressManager.completedCount(for: course.subject)
                previousSubjectXP = progressManager.xp(for: course.subject)
                progressManager.completeCourse(courseId: course.id, quizScore: 0)
                logSectionView(index: currentIndex, reachedEnd: true)
                AnalyticsService.shared.log(
                    .courseComplete,
                    courseId: course.id,
                    props: ["first_time": .bool(!wasCompletedBefore)]
                )
                // The daily course is done: if TikTok was waiting on it, it opens now.
                TikTokBlockerManager.shared.registerDailyCourseCompleted(courseId: course.id)
                progressManager.addXP(subject: course.subject, amount: Self.courseCompletionXP)
                globalCourseAwardResult = progressManager.awardGlobalXP(
                    reason: .courseCompleted(courseId: course.id),
                    amount: ProgressManager.globalCourseCompletionXP
                )
                pendingCollectionEvents = wasCompletedBefore ? [] : progressManager.collectionProgressEvents(forNewlyCompletedCourseId: course.id)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    endPhase = .completed
                }
            } else {
                // Le slide est animé par `.animation(_:value: currentIndex)` sur le TabView.
                currentIndex += 1
                progressManager.updateLessonProgress(
                    courseId: course.id,
                    lessonIndex: currentIndex,
                    lessonCount: course.lessons.count
                )
            }
        } label: {
            HStack(spacing: 8) {
                Text(isLastLesson && !isCourseLocked
                      ? languageManager.text("course.finish")
                      : languageManager.text("common.continue"))
                Image(systemName: isLastLesson && !isCourseLocked ? "checkmark" : "arrow.forward")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .buttonStyle(DSPrimaryButtonStyle())
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private func presentDebloquerPaywall() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showDebloquerPaywall = true
    }

    /// Third lesson (index 2) of the first course ever opened — once per install.
    private func requestAppStoreReviewIfEligible(lessonIndex: Int) {
        guard lessonIndex == 2 else { return }
        guard progressManager.firstCourseOpenedId == course.id else { return }
        guard !progressManager.hasRequestedAppStoreReview else { return }
        progressManager.markAppStoreReviewRequested()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    /// Coachmark « appuie sur ce mot » affiché quand l'utilisateur voit son premier mot
    /// surligné : déclenché sur la première page (visible) qui contient un terme du glossaire,
    /// et met en avant CE mot précis. Une seule fois par installation.
    private func maybeShowTermCoachmark(lessonIndex: Int) {
        guard !TutorialFlags.seen(.courseTerms) else { return }
        guard coachmarkTerm == nil else { return }
        guard course.lessons.indices.contains(lessonIndex) else { return }
        // Le contenu (et donc les mots surlignés) doit être visible.
        guard !FreemiumGate.isLessonContentLocked(
            lessonIndex: lessonIndex,
            isPremium: isPremium,
            isDailyFreeCourse: isDailyFreeCourse
        ) else { return }
        guard let term = firstGlossaryTerm(lessonIndex: lessonIndex) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            guard !TutorialFlags.seen(.courseTerms), coachmarkTerm == nil else { return }
            guard endPhase == .none, !showQuiz, !showRewardFlow else { return }
            guard currentIndex == lessonIndex else { return }
            withAnimation(.easeIn(duration: 0.3)) {
                coachmarkTerm = term
            }
        }
    }

    /// Premier terme du glossaire réellement résoluble dans la leçon (v2 `[[…]]`, sinon legacy `<…>`).
    private func firstGlossaryTerm(lessonIndex: Int) -> String? {
        let lesson = course.lessons[lessonIndex]
        if let resolved = CourseContentStore.section(courseId: course.id, sectionId: lesson.id) {
            for block in resolved.section.blocks {
                if let term = firstResolvableTerm(in: Self.blockText(block), open: "[[", close: "]]") {
                    return term
                }
            }
            return nil
        }
        return firstResolvableTerm(in: lesson.content, open: "<", close: ">")
    }

    private static func blockText(_ block: ContentBlockV2) -> String {
        switch block {
        case .heading(let t), .paragraph(let t), .funFact(let t), .takeaway(let t):
            return t
        case .quote(let t, _):
            return t
        case .image, .timeline:
            return ""
        }
    }

    private func firstResolvableTerm(in text: String, open: String, close: String) -> String? {
        var searchStart = text.startIndex
        while let openRange = text.range(of: open, range: searchStart..<text.endIndex) {
            guard let closeRange = text.range(of: close, range: openRange.upperBound..<text.endIndex) else { break }
            let term = String(text[openRange.upperBound..<closeRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !term.isEmpty,
               GlossaryStore.entry(courseId: course.id, courseTitle: course.title, displayTerm: term) != nil {
                return term
            }
            searchStart = closeRange.upperBound
        }
        return nil
    }

    private func continueAfterCourseCompletion() {
        rewardSteps = buildRewardSteps()
        if rewardSteps.isEmpty {
            onDismissToHome()
        } else {
            showRewardFlow = true
        }
    }

    private func buildRewardSteps() -> [PostCompletionRewardStep] {
        var steps: [PostCompletionRewardStep] = []

        if progressManager.pendingGlobalRankUp() != nil {
            if let pending = progressManager.pendingGlobalRankUp() {
                steps.append(.globalRankUp(previous: pending.previous, new: pending.new, newLevel: pending.newLevel))
            }
        }

        while !pendingCollectionEvents.isEmpty {
            let event = pendingCollectionEvents.removeFirst()
            steps.append(.collectionProgress(event))
            if event.didCompleteCollection {
                let award = progressManager.awardGlobalXP(
                    reason: .collectionCompleted(id: event.collection.id),
                    amount: progressManager.collectionCompletionXP(for: event.collection)
                )
                steps.append(.collectionCompleted(event, awardedXP: award.awardedXP))
                if award.didRankUp {
                    steps.append(.globalRankUp(previous: award.previousRank, new: award.newRank, newLevel: award.newLevel))
                }
            }
        }

        if progressManager.shouldShowStreakToday {
            progressManager.markStreakShownToday()
            steps.append(.streak(streak: progressManager.streak, subject: course.subject, lastActiveDate: progressManager.progress.lastActiveDate))
        }
        return steps
    }
}
