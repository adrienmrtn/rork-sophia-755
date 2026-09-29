import SwiftUI

/// Neo-brutalist palette shared by Library / SubjectCourses screens.
enum BrutalPalette {
    static let cream = Color(red: 0.984, green: 0.961, blue: 0.918)
    static let ink = Color.black
    static let pink = Color(red: 1.0, green: 0.553, blue: 0.706)
    static let yellow = Color(red: 1.0, green: 0.84, blue: 0.35)

    /// Pastel tint matching the Home FlashCard for each subject.
    static func pastel(for subject: Subject) -> Color {
        switch subject {
        case .histoire: return Color(red: 1.0, green: 0.86, blue: 0.62)
        case .sciences: return Color(red: 0.70, green: 0.95, blue: 0.80)
        case .litterature: return Color(red: 1.0, green: 0.78, blue: 0.78)
        case .art: return Color(red: 0.66, green: 0.92, blue: 0.96)
        case .mythologie: return Color(red: 0.82, green: 0.78, blue: 1.0)
        case .comprendreLeMonde: return Color(red: 0.74, green: 0.90, blue: 1.0)
        }
    }
}

struct LibraryView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.scenePhase) private var scenePhase
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    /// Premium en essai gratuit : on ne lui propose pas le widget.
    var isInFreeTrial: Bool = false
    @State private var searchText: String = ""
    @State private var featuredIndex: Int = 0
    /// Jour affiché par « À la une ». Relu au retour au premier plan : passé minuit, les
    /// cartes changent et le carrousel repart sur la question du jour.
    @State private var featuredDay: String = DailyQuestion.day(for: Date()).key
    @State private var widgetPromoVisible: Bool = false

    /// Hauteur du bloc texte de la carte « À la une ».
    ///
    /// Constante plutôt que mesurée : la carte a une hauteur déterministe (couverture fixe,
    /// et les deux textes réservent exactement deux lignes chacun), donc il n'y a rien à
    /// mesurer. La mesure hors écran qui était là ne pouvait que **monter** — une seule
    /// passe de mise en page trop haute restait acquise — et laissait la carte flotter au
    /// milieu d'un cadre bien trop grand, avec un vide au-dessus et au-dessous.
    ///
    /// `@ScaledMetric` couvre la raison d'être de cette mesure : la carte suit la taille de
    /// texte du système, donc plus rien n'est rogné en bas aux grandes tailles.
    @ScaledMetric(relativeTo: .body) private var featuredPanelHeight: CGFloat = 190

    @FocusState private var searchFocused: Bool

    private var featuredCardHeight: CGFloat {
        LibraryFeaturedCard.coverHeight + featuredPanelHeight
    }

    private let previewCount = 4
    private let cream = DS.canvas

    private var filteredCourses: [Course] {
        if searchText.isEmpty { return ContentCatalog.activeCourses }
        return ContentCatalog.activeCourses.filter {
            $0.title.localizedStandardContains(searchText) ||
            $0.subcategory.localizedStandardContains(searchText) ||
            $0.subject.localizedShortName(language: languageManager.current).localizedStandardContains(searchText)
        }
    }

    private var isSearching: Bool { !searchText.isEmpty }

    /// « À la une » : la question du jour, puis cinq autres questions du jour. Tout change à
    /// minuit et reste stable dans la journée.
    private var featuredCourses: [Course] {
        _ = featuredDay
        let lang = languageManager.current
        let isCompleted: (String) -> Bool = { progressManager.courseStatus(for: $0) == .completed }
        let today = DailyQuestion.todayCourseId(language: lang, isCompleted: isCompleted)
            .flatMap { ContentCatalog.course(withId: $0, language: lang) }
        let companions = DailyQuestion.featuredCompanions(
            count: today == nil ? 6 : 5,
            excluding: Set([today?.id].compactMap { $0 }),
            interests: OnboardingViewModel.userInterestKeys(),
            language: lang,
            isCompleted: isCompleted
        )
        return [today].compactMap { $0 } + companions
    }

    /// Courses the user already started — surfaced as a "continue" row.
    private var inProgressCourses: [Course] {
        ContentCatalog.activeCourses.filter { progressManager.courseStatus(for: $0.id) == .inProgress }
    }

    /// Personalized picks based on the interests chosen during onboarding.
    private var recommendedCourses: [Course] {
        let recos = OnboardingCourseRecommender.recommendedCourses(
            interests: OnboardingViewModel.userInterestKeys(),
            language: languageManager.current,
            limit: 10
        )
        let featuredIds = Set(featuredCourses.map(\.id))
        return recos.filter { !featuredIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                cream.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        HStack {
                            Text(languageManager.text("library.title"))
                                .font(DS.title(.largeTitle, .semibold))
                                .foregroundStyle(DS.ink)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        searchBar
                            .padding(.horizontal, 20)

                        if isSearching {
                            ForEach(Subject.allCases, id: \.self) { subject in
                                let courses = filteredCourses.filter { $0.subject == subject }
                                if !courses.isEmpty {
                                    searchSection(subject: subject, courses: courses)
                                }
                            }
                            if filteredCourses.isEmpty {
                                emptyResults
                                    .padding(.top, 60)
                            }
                        } else {
                            let featured = featuredCourses
                            if !featured.isEmpty {
                                featuredCarousel(featured)
                            }

                            if widgetPromoVisible {
                                DailyQuestionWidgetPromoCard(onDismiss: dismissWidgetPromo)
                                    .padding(.horizontal, 20)
                                    .transition(.opacity)
                            }

                            if !inProgressCourses.isEmpty {
                                courseRow(
                                    title: languageManager.text("library.section.continue"),
                                    courses: inProgressCourses
                                )
                            }

                            if !recommendedCourses.isEmpty {
                                courseRow(
                                    title: languageManager.text("library.section.recommended"),
                                    courses: recommendedCourses
                                )
                            }

                            ForEach(Subject.allCases, id: \.self) { subject in
                                let courses = filteredCourses.filter { $0.subject == subject }
                                if !courses.isEmpty {
                                    previewSection(subject: subject, courses: courses)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Subject.self) { subject in
                let courses = ContentCatalog.activeCourses.filter { $0.subject == subject }
                SubjectCoursesView(
                    subject: subject,
                    courses: courses,
                    progressManager: progressManager,
                    selectedCourse: $selectedCourse
                )
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            let today = DailyQuestion.day(for: Date()).key
            if today != featuredDay {
                featuredDay = today
                featuredIndex = 0
            }
            Task { await refreshWidgetPromo() }
        }
        .onChange(of: progressManager.completedCount) { _, _ in
            Task { await refreshWidgetPromo() }
        }
        .onChange(of: isInFreeTrial) { _, _ in
            Task { await refreshWidgetPromo() }
        }
        .task { await refreshWidgetPromo() }
    }

    // MARK: - Widget promo

    private func refreshWidgetPromo() async {
        let visible = await DailyQuestionWidgetPromo.shouldShow(
            isInFreeTrial: isInFreeTrial,
            isCompleted: { progressManager.courseStatus(for: $0) == .completed }
        )
        guard visible != widgetPromoVisible else { return }
        withAnimation(.easeInOut(duration: 0.25)) { widgetPromoVisible = visible }
    }

    private func dismissWidgetPromo() {
        DailyQuestionWidgetPromo.dismiss()
        withAnimation(.easeInOut(duration: 0.25)) { widgetPromoVisible = false }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.jakarta(size: 16, weight: .regular))
                .foregroundStyle(DS.inkTertiary)

            ZStack(alignment: .leading) {
                if searchText.isEmpty {
                    Text(languageManager.text("library.search.placeholder"))
                        .font(DS.sans(.subheadline))
                        .foregroundStyle(DS.inkTertiary)
                        .allowsHitTesting(false)
                }
                TextField("", text: $searchText)
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.ink)
                    .tint(DS.accentSoft)
                    .focused($searchFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    let g = UIImpactFeedbackGenerator(style: .light)
                    g.impactOccurred()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.jakarta(size: 16, weight: .regular))
                        .foregroundStyle(DS.inkTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.control))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
    }

    private var emptyResults: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.jakarta(size: 38, weight: .light))
                .foregroundStyle(DS.inkTertiary)
            Text(languageManager.text("library.empty.title"))
                .font(DS.title(.title3, .semibold))
                .foregroundStyle(DS.ink)
            Text(languageManager.text("library.empty.subtitle"))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Featured swipeable carousel

    private func featuredCarousel(_ featuredCourses: [Course]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(languageManager.text("library.section.featured"))
                    .font(DS.title(.title3, .semibold))
                    .foregroundStyle(DS.ink)
                Spacer()
            }
            .padding(.horizontal, 20)

            TabView(selection: $featuredIndex) {
                ForEach(Array(featuredCourses.enumerated()), id: \.element.id) { index, course in
                    // Calée en haut : un `TabView` paginé centre ses pages, donc le moindre
                    // point de marge en trop se voyait en décalant la carte vers le bas.
                    // Ici l'éventuel reste passe sous la carte, où il ne se remarque pas.
                    VStack(spacing: 0) {
                        LibraryFeaturedCard(
                            course: course,
                            status: progressManager.courseStatus(for: course.id),
                            badge: index == 0 && DailyQuestion.isQuestion(course.id)
                                ? languageManager.text("dailyQuestion.badge")
                                : nil,
                            onTap: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedCourse = course
                            }
                        )
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            // Un `TabView` paginé ne peut pas se dimensionner sur son contenu : la hauteur
            // vient de la carte, taille de texte système comprise.
            .frame(height: featuredCardHeight + 16)
            .onAppear {
                CourseImageMap.preloadImages(for: featuredCourses.map(\.id))
            }

            HStack(spacing: 6) {
                ForEach(featuredCourses.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == featuredIndex ? DS.accentSoft : DS.hairline)
                        .frame(width: i == featuredIndex ? 22 : 7, height: 7)
                        .animation(.spring(response: 0.3), value: featuredIndex)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Generic horizontal course row (continue / recommended)

    private func courseRow(title: String, courses: [Course]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(DS.title(.title3, .semibold))
                    .foregroundStyle(DS.ink)
                Spacer()
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(courses) { course in
                        LibraryCardView(
                            course: course,
                            status: progressManager.courseStatus(for: course.id),
                            onTap: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedCourse = course
                            },
                            progressManager: progressManager
                        )
                        .frame(width: 180)
                    }
                }
            }
            .contentMargins(.horizontal, 20)
        }
    }

    private func previewSection(subject: Subject, courses: [Course]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(subject: subject)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(Array(courses.prefix(previewCount))) { course in
                        LibraryCardView(
                            course: course,
                            status: progressManager.courseStatus(for: course.id),
                            onTap: {
                                let g = UIImpactFeedbackGenerator(style: .light)
                                g.impactOccurred()
                                selectedCourse = course
                            },
                            progressManager: progressManager
                        )
                        .frame(width: 180)
                    }
                }
            }
            .contentMargins(.horizontal, 20)
        }
    }

    private func sectionHeader(subject: Subject) -> some View {
        NavigationLink(value: subject) {
            sectionHeaderContent(subject: subject)
        }
        .buttonStyle(.plain)
    }

    private func sectionHeaderContent(subject: Subject) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: subject.icon)
                    .font(.jakarta(size: 14, weight: .medium))
                    .foregroundStyle(DS.accentSoft)
                Text(subject.localizedShortName(language: languageManager.current))
                    .font(DS.title(.headline, .semibold))
                    .foregroundStyle(DS.ink)
            }

            Spacer()

            HStack(spacing: 4) {
                Text(languageManager.text("library.seeMore"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.accentSoft)
                Image(systemName: "chevron.forward")
                    .font(.jakarta(size: 12, weight: .semibold))
                    .foregroundStyle(DS.accentSoft)
            }
        }
    }

    private func searchSection(subject: Subject, courses: [Course]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: subject.icon)
                        .font(.jakarta(size: 14, weight: .medium))
                        .foregroundStyle(DS.accentSoft)
                    Text(subject.localizedShortName(language: languageManager.current))
                        .font(DS.title(.headline, .semibold))
                        .foregroundStyle(DS.ink)
                }

                Spacer()

                Text("\(courses.count)")
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.inkTertiary)
            }
            .padding(.horizontal, 20)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 18) {
                ForEach(courses) { course in
                    LibraryCardView(
                        course: course,
                        status: progressManager.courseStatus(for: course.id),
                        onTap: {
                            let g = UIImpactFeedbackGenerator(style: .light)
                            g.impactOccurred()
                            selectedCourse = course
                        },
                        progressManager: progressManager
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

/// Button style that gives the press-down 3D feel without intercepting scroll gestures.
struct BrutalCardButtonStyle: ButtonStyle {
    var depth: CGFloat = 2

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? depth : 0)
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Large editorial "featured" card used in the swipeable Library carousel.
struct LibraryFeaturedCard: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    let status: CourseStatus
    /// Pastille posée sur la couverture (« Question du jour » sur la première carte).
    var badge: String? = nil
    let onTap: () -> Void

    @State private var image: UIImage?

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                cover
                infoPanel
            }
            .background(DS.surface)
            .clipShape(.rect(cornerRadius: DS.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .strokeBorder(DS.hairline, lineWidth: 1)
            }
            .dsSoftShadow()
        }
        .buttonStyle(BrutalCardButtonStyle(depth: 2))
        .courseAudioContextMenu(courseId: course.id, source: "library_featured")
        .onAppear {
            if image == nil { image = CourseImageMap.loadImage(for: course.id) }
        }
    }

    /// Hauteur de la couverture. Exposée pour que le carrousel calcule la hauteur de la
    /// carte sans que les deux valeurs puissent diverger.
    static let coverHeight: CGFloat = 160

    private var cover: some View {
        DS.surfaceMuted
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .allowsHitTesting(false)
                } else {
                    Image(systemName: course.subject.icon)
                        .font(.jakarta(size: 40, weight: .light))
                        .foregroundStyle(DS.accentSoft.opacity(0.5))
                }
            }
            .frame(height: Self.coverHeight)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .bottomTrailing) {
                CourseAudioCardButton(courseId: course.id, source: "library_featured", size: 34)
                    .padding(10)
            }
            .overlay(alignment: .topLeading) {
                if let badge {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.jakarta(size: 10, weight: .semibold))
                        Text(badge.uppercased())
                            .font(DS.sans(.caption2, .semibold))
                            .tracking(0.8)
                            .lineLimit(1)
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DS.accent, in: Capsule())
                    .padding(10)
                }
            }
    }

    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.subject.localizedShortName(language: languageManager.current).uppercased())
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(DS.accentSoft)
                .tracking(1.2)

            Text(course.title)
                .font(DS.title(.title3, .semibold))
                .foregroundStyle(DS.ink)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)

            Text(course.plainDescription)
                .font(DS.sans(.caption))
                .foregroundStyle(DS.inkSecondary)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)

            HStack(spacing: 8) {
                metaChip(icon: "rectangle.stack", text: String(format: languageManager.text("onboarding.showcase.courses.lessons"), course.lessons.count))
                metaChip(icon: "book.pages", text: String(format: languageManager.text("course.reads"), course.readsCountShort))

                Spacer(minLength: 0)

                Image(systemName: status == .completed ? "checkmark" : "arrow.forward")
                    .font(.jakarta(size: 14, weight: .semibold))
                    .foregroundStyle(status == .completed ? DS.accentSoft : Color.white)
                    .frame(width: 34, height: 34)
                    .background(status == .completed ? DS.accentTint : DS.accent, in: Circle())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metaChip(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.jakarta(size: 10, weight: .medium))
            Text(text).font(DS.sans(.caption2, .medium))
        }
        .foregroundStyle(DS.inkSecondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(DS.accentTint, in: Capsule())
    }
}

/// Calm library card — white surface, hairline border, soft diffuse shadow.
struct LibraryCardView: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    let status: CourseStatus
    let onTap: () -> Void
    var progressManager: ProgressManager? = nil
    /// Off where the card sits in a cover over `ContentView` (favourites): the audio
    /// paywall is presented from the root and could not show there.
    var showsAudio: Bool = true
    @State private var favTrigger: Int = 0

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                illustration
                bottomPanel
            }
            .background(DS.surface)
            .clipShape(.rect(cornerRadius: DS.Radius.control))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .strokeBorder(DS.hairline, lineWidth: 1)
            }
            .dsSoftShadow()
            .opacity(status == .completed ? 0.82 : 1.0)
        }
        .buttonStyle(BrutalCardButtonStyle(depth: 2))
        .courseAudioContextMenu(courseId: course.id, source: "library_card", enabled: showsAudio)
    }

    private var illustration: some View {
        DS.surfaceMuted
            .frame(height: 110)
            .overlay {
                if let uiImage = CourseImageMap.loadImage(for: course.id) {
                    Color.clear
                        .overlay {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipped()
                        .allowsHitTesting(false)
                } else {
                    Image(systemName: course.subject.icon)
                        .font(.jakarta(size: 30, weight: .light))
                        .foregroundStyle(DS.accentSoft.opacity(0.5))
                }
            }
            .overlay(alignment: .topLeading) {
                statusBadge
                    .padding(8)
            }
            .overlay(alignment: .topTrailing) {
                if let pm = progressManager {
                    Button {
                        let g = UIImpactFeedbackGenerator(style: .light)
                        g.impactOccurred()
                        favTrigger += 1
                        pm.toggleFavorite(course.id)
                    } label: {
                        Image(systemName: pm.isFavorite(course.id) ? "bookmark.fill" : "bookmark")
                            .font(.jakarta(size: 13, weight: .medium))
                            .foregroundStyle(pm.isFavorite(course.id) ? DS.accent : DS.inkSecondary)
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.impact(weight: .light), trigger: favTrigger)
                    .padding(8)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if showsAudio {
                    CourseAudioCardButton(courseId: course.id, source: "library_card", size: 30)
                        .padding(8)
                }
            }
    }

    private var bottomPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(course.subject.localizedShortName(language: languageManager.current).uppercased())
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(DS.accentSoft)
                .tracking(1.0)

            Text(course.title)
                .font(DS.title(.subheadline, .semibold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.leading)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(DS.surface)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch status {
        case .completed:
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.jakarta(size: 9, weight: .semibold))
                Text(languageManager.text("library.status.done"))
                    .font(DS.sans(.caption2, .semibold))
                    .tracking(0.3)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(DS.accent, in: Capsule())
        case .inProgress:
            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.jakarta(size: 8, weight: .semibold))
                Text(languageManager.text("library.status.inProgress"))
                    .font(DS.sans(.caption2, .semibold))
                    .tracking(0.3)
            }
            .foregroundStyle(DS.accentSoft)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay { Capsule().strokeBorder(DS.hairline, lineWidth: 1) }
        case .notStarted:
            EmptyView()
        }
    }
}
