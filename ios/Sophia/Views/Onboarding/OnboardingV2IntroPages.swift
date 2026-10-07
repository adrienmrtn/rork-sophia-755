import SwiftUI
import UIKit

// MARK: - Gabarit de page

/// Gabarit commun des quatre pages de présentation : le visuel en haut, le titre (mots en
/// rose) au milieu, le sous-titre calé en bas, juste au-dessus des points et du bouton.
struct OnboardingV2IntroPageFrame<Visual: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder let visual: (CGSize) -> Visual

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 600
            let box = CGSize(width: geo.size.width, height: Self.visualHeight(for: geo.size))

            VStack(spacing: 0) {
                Spacer().frame(height: compact ? 8 : 20)

                visual(box)
                    .frame(width: box.width, height: box.height)

                Spacer().frame(height: compact ? 16 : 26)

                OV2Markup.highlighted(title)
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(5)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 28)

                Spacer(minLength: 12)

                if let subtitle {
                    Text(subtitle)
                        .font(DS.sans(.subheadline, .medium))
                        .foregroundStyle(OV2.inkSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 4)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    /// Un peu moins de la moitié de la page pour le visuel, borné sur les grands écrans.
    static func visualHeight(for size: CGSize) -> CGFloat {
        min(300, max(190, size.height * 0.44))
    }
}

// MARK: - 1. Leçons

/// « Get smarter with exciting 10-minute lessons » : quatre cartes de cours qui se posent
/// l'une après l'autre.
struct OnboardingV2IntroLessonsPage: View {
    @Environment(LanguageManager.self) private var languageManager
    let isActive: Bool

    @State private var courses: [Course] = []
    @State private var revealed = 0

    /// Les cours les plus lus de l'app (lecteurs par cours dans `scripts/data/course_quality.csv`,
    /// comptes synchronisés), retenus aussi pour leur titre accrocheur et des matières variées.
    /// Un cours retiré d'une langue est remplacé par le recommandeur.
    static let featuredCourseIds = [
        "course_42_pourquoi_reve_t_on",
        "course_67_qu_est_ce_qu_un_trou_noir",
        "course_201_la_naissance_du_conflit_israelo_palestin",
        "course_150_la_nuit_etoilee_van_gogh",
    ]

    var body: some View {
        OnboardingV2IntroPageFrame(title: languageManager.text("onboardingV2.intro.lessons.title")) { box in
            cards(in: box)
        }
        .onAppear {
            if courses.isEmpty {
                courses = Self.featuredCourses(language: languageManager.current)
            }
        }
        .onIntroPageActivated(isActive) { reveal() }
    }

    static func featuredCourses(language: AppLanguage) -> [Course] {
        var picked = featuredCourseIds.compactMap { ContentCatalog.course(withId: $0, language: language) }
        let missing = featuredCourseIds.count - picked.count
        if missing > 0 {
            let fill = OnboardingCourseRecommender.recommendedCourses(
                interests: [],
                language: language,
                limit: featuredCourseIds.count,
                excluding: Set(picked.map(\.id))
            )
            picked.append(contentsOf: fill.prefix(missing))
        }
        return picked
    }

    private func cards(in box: CGSize) -> some View {
        let spacing: CGFloat = 10
        let count = CGFloat(max(courses.count, 1))
        let cardHeight = min(74, max(54, (box.height - spacing * (count - 1)) / count))
        return VStack(spacing: spacing) {
            ForEach(Array(courses.enumerated()), id: \.element.id) { i, course in
                OnboardingV2IntroCourseCard(course: course, height: cardHeight)
                    .opacity(i < revealed ? 1 : 0)
                    .offset(y: i < revealed ? 0 : 30)
                    .scaleEffect(i < revealed ? 1 : 0.94)
            }
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func reveal() {
        for i in 0..<max(courses.count, Self.featuredCourseIds.count) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.22) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                    revealed = i + 1
                }
                OnboardingHaptics.selection()
            }
        }
    }
}

/// Carte rectangulaire d'un cours : vignette à gauche, matière et titre, la durée à droite.
struct OnboardingV2IntroCourseCard: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    let height: CGFloat

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
                .frame(width: height - 14, height: height - 14)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(course.subject.localizedShortName(language: languageManager.current).uppercasedInApp())
                    .font(DS.sans(.caption2, .bold))
                    .tracking(0.8)
                    .foregroundStyle(course.subject.color.mix(with: .black, by: 0.3))
                    .lineLimit(1)
                Text(course.title)
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(OV2.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            durationChip
        }
        .padding(7)
        .padding(.trailing, 5)
        .frame(height: height)
        .background(OV2.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(OV2.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.07), radius: 12, y: 6)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let image = CourseImageMap.loadImage(for: course.id) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            LinearGradient(
                colors: [course.subject.color, course.subject.color.opacity(0.6)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    /// « 10 min », avec la chaîne « %d min » de la page temps d'écran.
    private var durationChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 10, weight: .bold))
            Text(String(format: languageManager.text("onboardingV2.screenTime.minutes"), 10))
                .font(DS.sans(.caption2, .bold))
                .lineLimit(1)
        }
        .foregroundStyle(OV2.accentSoft)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(DS.accentTint, in: Capsule())
        .fixedSize()
    }
}

// MARK: - 2. Vrais chercheurs

/// « Written by real researchers » : les têtes des profs dans des ronds, puis les logos des
/// universités qui défilent.
struct OnboardingV2IntroResearchersPage: View {
    @Environment(LanguageManager.self) private var languageManager
    let isActive: Bool

    @State private var portraits: [UIImage] = []
    @State private var logos: [UIImage] = []
    @State private var revealedPortraits = 0
    @State private var marqueeIn = false

    var body: some View {
        OnboardingV2IntroPageFrame(
            title: languageManager.text("onboardingV2.intro.researchers.title"),
            subtitle: languageManager.text("onboardingV2.intro.researchers.subtitle")
        ) { box in
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                portraitRow(width: box.width)
                Spacer().frame(height: box.height < 220 ? 20 : 30)
                OnboardingV2LogoMarquee(logos: logos, logoHeight: min(72, box.height * 0.3), paused: !isActive)
                    .opacity(marqueeIn ? 1 : 0)
                    .offset(y: marqueeIn ? 0 : 14)
                Spacer(minLength: 0)
            }
        }
        .onAppear {
            if portraits.isEmpty { portraits = Self.loadPortraits() }
            if logos.isEmpty { logos = OnboardingV2LogoMarquee.loadLogos() }
        }
        .onIntroPageActivated(isActive) { reveal() }
    }

    /// Les portraits se chevauchent légèrement ; la rangée se resserre pour tenir en largeur.
    private func portraitRow(width: CGFloat) -> some View {
        let count = max(portraits.count, 1)
        let overlap: CGFloat = 12
        let size = min(60, (width - 56 + overlap * CGFloat(count - 1)) / CGFloat(count))
        return HStack(spacing: -overlap) {
            ForEach(Array(portraits.enumerated()), id: \.offset) { i, image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2.5))
                    .shadow(color: .black.opacity(0.14), radius: 8, y: 4)
                    .scaleEffect(i < revealedPortraits ? 1 : 0.3)
                    .opacity(i < revealedPortraits ? 1 : 0)
                    .zIndex(Double(portraits.count - i))
            }
        }
    }

    /// Les profs qui ont un portrait dans `Resources/AuthorPhotos`, dans l'ordre d'`authors.json`.
    private static func loadPortraits() -> [UIImage] {
        AuthorStore.all.compactMap { AuthorStore.photo(for: $0) }
    }

    private func reveal() {
        let count = max(portraits.count, 8)
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + Double(i) * 0.11) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                    revealedPortraits = i + 1
                }
                if i < portraits.count { OnboardingHaptics.selection() }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 + Double(count) * 0.11) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                marqueeIn = true
            }
        }
    }
}

/// Logos des universités qui défilent en continu (`university_*.png` du bundle, voir
/// `Resources/UniversityLogos/README.md`) ; sans aucun logo la bande montre des pictogrammes,
/// pour que la page ne soit jamais vide.
struct OnboardingV2LogoMarquee: View {
    let logos: [UIImage]
    var logoHeight: CGFloat = 64
    /// Figée quand la page n'est pas visible, pour ne pas animer dans le vide.
    var paused: Bool = false

    private var gap: CGFloat { 28 }
    /// Largeur fixe par logo : la largeur de la bande se connaît sans rien mesurer.
    private var slotWidth: CGFloat { logoHeight * 1.6 }

    private var slotCount: Int { logos.isEmpty ? Self.placeholderSymbols.count : logos.count }
    /// Largeur d'une bande plus l'écart avec la copie suivante : la distance après laquelle
    /// la seconde copie est exactement là où était la première.
    private var period: CGFloat { CGFloat(slotCount) * (slotWidth + gap) }

    var body: some View {
        // Un cadre fixe, les bandes dessinées en overlay : un overlay ne participe pas à la
        // mise en page de son parent, les bandes ne peuvent donc pas élargir la page.
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: logoHeight + 12)
            .overlay(alignment: .leading) {
                TimelineView(.animation(paused: paused)) { context in
                    HStack(spacing: gap) {
                        strip
                        strip
                    }
                    .fixedSize()
                    .offset(x: -marqueeOffset(at: context.date))
                }
            }
            .clipped()
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.12),
                        .init(color: .black, location: 0.88),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
            )
    }

    /// 38 points par seconde, bouclés sur la période d'une bande.
    private func marqueeOffset(at date: Date) -> CGFloat {
        let travelled: Double = date.timeIntervalSinceReferenceDate * 38.0
        let wrapped: Double = travelled.truncatingRemainder(dividingBy: Double(period))
        return CGFloat(wrapped)
    }

    private var strip: some View {
        HStack(spacing: gap) {
            ForEach(0..<slotCount, id: \.self) { i in
                slot(i)
                    .frame(width: slotWidth, height: logoHeight)
            }
        }
    }

    @ViewBuilder
    private func slot(_ i: Int) -> some View {
        if logos.isEmpty {
            Image(systemName: Self.placeholderSymbols[i % Self.placeholderSymbols.count])
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(OV2.inkTertiary)
        } else {
            Image(uiImage: logos[i])
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
        }
    }

    private static let placeholderSymbols = [
        "building.columns.fill", "books.vertical.fill", "graduationcap.fill",
        "text.book.closed.fill", "building.2.fill", "scroll.fill",
    ]

    static func loadLogos() -> [UIImage] {
        let urls = Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: nil) ?? []
        return urls
            .filter { $0.lastPathComponent.hasPrefix("university_") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { UIImage(contentsOfFile: $0.path) }
    }
}

// MARK: - 3. Quiz

/// « Sophia tests you with fun quizzes » : des images de cours dans des carrés, qui
/// apparaissent une à une, puis des coches « bonne réponse » sur certaines.
struct OnboardingV2IntroQuizzesPage: View {
    @Environment(LanguageManager.self) private var languageManager
    let isActive: Bool

    @State private var images: [UIImage?] = []
    @State private var revealed = 0
    @State private var badges = 0

    /// Six cours choisis pour leur illustration : Apollo 11, Toutânkhamon, la Joconde, les
    /// pyramides, la nébuleuse du Crabe, la tour Eiffel.
    static let imageCourseIds = [
        "course_290_comment_les_etats_unis_ont_ils_gagne_la",
        "course_247_pourquoi_les_momies_font_elles_peur",
        "course_149_la_joconde",
        "course_264_qui_a_vraiment_construit_les_pyramides",
        "course_281_comment_meurt_une_etoile",
        "course_241_pourquoi_voulait_on_demolir_la_tour_eiffel",
    ]
    /// Carrés qui reçoivent une coche, dans l'ordre d'apparition des coches.
    private static let checkedSquares = [1, 3, 4]
    private static let columns = 3

    var body: some View {
        OnboardingV2IntroPageFrame(
            title: languageManager.text("onboardingV2.intro.quizzes.title"),
            subtitle: languageManager.text("onboardingV2.intro.quizzes.subtitle")
        ) { box in
            grid(in: box)
        }
        .onAppear {
            if images.isEmpty {
                images = Self.imageCourseIds.map { CourseImageMap.loadImage(for: $0) }
            }
        }
        .onIntroPageActivated(isActive) { reveal() }
    }

    private func grid(in box: CGSize) -> some View {
        let spacing: CGFloat = 12
        let rows = Self.imageCourseIds.count / Self.columns
        let side = min(
            (box.width - 56 - spacing * CGFloat(Self.columns - 1)) / CGFloat(Self.columns),
            (box.height - spacing * CGFloat(rows - 1)) / CGFloat(rows)
        )
        return VStack(spacing: spacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<Self.columns, id: \.self) { column in
                        square(index: row * Self.columns + column, side: side)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func square(index: Int, side: CGFloat) -> some View {
        let shown = index < revealed
        let badgeRank = Self.checkedSquares.firstIndex(of: index)
        let badgeShown = badgeRank.map { $0 < badges } ?? false
        return ZStack {
            if index < images.count, let image = images[index] {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                LinearGradient(
                    colors: [OV2.accentSoft.opacity(0.55), OV2.accent.opacity(0.85)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.8), lineWidth: 1))
        .shadow(color: .black.opacity(0.10), radius: 10, y: 6)
        .overlay(alignment: .topTrailing) {
            if badgeRank != nil {
                checkBadge
                    .offset(x: 7, y: -7)
                    .scaleEffect(badgeShown ? 1 : 0.2)
                    .opacity(badgeShown ? 1 : 0)
            }
        }
        .scaleEffect(shown ? 1 : 0.6)
        .rotationEffect(.degrees(shown ? 0 : (index.isMultiple(of: 2) ? -8 : 8)))
        .opacity(shown ? 1 : 0)
    }

    private var checkBadge: some View {
        ZStack {
            Circle().fill(.white)
            Circle().fill(OV2.success).padding(2.5)
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(.white)
        }
        .frame(width: 26, height: 26)
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }

    private func reveal() {
        let count = Self.imageCourseIds.count
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + Double(i) * 0.14) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    revealed = i + 1
                }
                OnboardingHaptics.selection()
            }
        }
        let badgesStart = 0.5 + Double(count) * 0.14
        for i in 0..<Self.checkedSquares.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + badgesStart + Double(i) * 0.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                    badges = i + 1
                }
                OnboardingHaptics.swipeCommit()
            }
        }
    }
}

// MARK: - 4. Parcours personnalisé

/// « Sophia builds you a personalized route » : l'aperçu du Parcours, flouté et fondu dans
/// le fond.
struct OnboardingV2IntroRoutePage: View {
    @Environment(LanguageManager.self) private var languageManager
    let isActive: Bool

    @State private var shown = false

    var body: some View {
        OnboardingV2IntroPageFrame(
            title: languageManager.text("onboardingV2.intro.route.title"),
            subtitle: languageManager.text("onboardingV2.intro.route.subtitle")
        ) { box in
            OnboardingV2PathPreview(size: box)
                .scaleEffect(shown ? 1 : 0.94)
                .opacity(shown ? 1 : 0)
        }
        .onIntroPageActivated(isActive) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.15)) {
                shown = true
            }
        }
    }
}
