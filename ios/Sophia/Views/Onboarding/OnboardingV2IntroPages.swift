import SwiftUI
import UIKit

// MARK: - Cours montrés en exemple

/// Les cours du catalogue repris par les écrans de présentation (leçons, lecteur audio,
/// question de quiz). Un cours retiré d'une langue est remplacé par le recommandeur.
enum OnboardingV2IntroCatalog {
    /// Les cours les plus lus de l'app (lecteurs par cours dans `scripts/data/course_quality.csv`,
    /// comptes synchronisés), retenus aussi pour leur titre accrocheur et des matières variées.
    static let featuredCourseIds = [
        "course_42_pourquoi_reve_t_on",
        "course_67_qu_est_ce_qu_un_trou_noir",
        "course_201_la_naissance_du_conflit_israelo_palestin",
        "course_150_la_nuit_etoilee_van_gogh",
    ]

    /// Le cours des illustrations « quiz » et « audio ».
    static let blackHoleCourseId = "course_67_qu_est_ce_qu_un_trou_noir"
    /// Le cours de la carte « une leçon Sophia ».
    static let dreamCourseId = "course_42_pourquoi_reve_t_on"

    static func featuredCourses(language: AppLanguage) -> [Course] {
        var picked: [Course] = featuredCourseIds.compactMap { ContentCatalog.course(withId: $0, language: language) }
        let missing: Int = featuredCourseIds.count - picked.count
        if missing > 0 {
            let fill: [Course] = OnboardingCourseRecommender.recommendedCourses(
                interests: [],
                language: language,
                limit: featuredCourseIds.count,
                excluding: Set(picked.map(\.id))
            )
            picked.append(contentsOf: fill.prefix(missing))
        }
        return picked
    }

    /// Le cours demandé, ou à défaut le premier cours mis en avant disponible dans la langue.
    static func course(preferring id: String, language: AppLanguage) -> Course? {
        if let course = ContentCatalog.course(withId: id, language: language) {
            return course
        }
        return featuredCourses(language: language).first
    }

    /// La couverture d'un cours, ramenée à une vignette (les illustrations la montrent petite).
    static func coverThumbnail(for courseId: String) -> UIImage? {
        guard let image = CourseImageMap.loadImage(for: courseId) else { return nil }
        return OnboardingV2CoverWall.thumbnail(of: image)
    }
}

// MARK: - Gabarit de page

/// Gabarit commun des quatre pages du carrousel : l'illustration dans l'espace qui reste
/// (réduite d'un bloc si elle ne tient pas), puis un bloc titre et un bloc sous-titre de
/// hauteur fixe, pour que rien ne saute d'une page à l'autre.
struct OnboardingV2IntroPageFrame<Visual: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let visual: () -> Visual

    /// Trois lignes de titre (quatre en se resserrant) et deux de sous-titre.
    private static var titleHeight: CGFloat { 96 }
    private static var subtitleHeight: CGFloat { 44 }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingV2FitHeight {
                visual()
            }
            .padding(.top, 10)
            .accessibilityHidden(true)

            OV2Markup.elevate(title, highlightFont: DS.title(.title2, .bold))
                .font(DS.title(.title2, .medium))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .lineLimit(4)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(height: Self.titleHeight, alignment: .top)
                .padding(.top, 16)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(DS.sans(.subheadline, .regular))
                .foregroundStyle(OV2.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .lineLimit(3)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .frame(height: Self.subtitleHeight, alignment: .top)
                .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - 5. Quiz

/// « Sophia te teste avec des quiz ludiques » : une vraie question du catalogue, la bonne
/// réponse qui se valide, le bandeau « Excellent ! ».
struct OnboardingV2IntroQuizPage: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isActive: Bool

    @State private var sample: QuizSample?
    @State private var answered = false

    /// Ce que la carte montre : une question à choix, sa bonne réponse et deux autres.
    struct QuizSample {
        let eyebrow: String
        let question: String
        /// Les réponses dans l'ordre d'affichage.
        let options: [String]
        let correctIndex: Int
        /// Rang de la question dans son quiz (1 pour la première) et taille du quiz.
        let position: Int
        let total: Int
    }

    private static let comboGold = Color(red: 0.694, green: 0.498, blue: 0.063)
    private static let comboTint = Color(red: 0.984, green: 0.937, blue: 0.788)
    private static let comboInk = Color(red: 0.420, green: 0.306, blue: 0.0)

    var body: some View {
        OnboardingV2IntroPageFrame(
            title: languageManager.text("onboardingV2.intro.quizzes.title"),
            subtitle: languageManager.text("onboardingV2.intro.quizzes.subtitle")
        ) {
            card
        }
        .onAppear {
            if sample == nil { sample = Self.makeSample(languageManager: languageManager) }
        }
        .onIntroPageActivated(isActive) { play() }
    }

    // MARK: Carte

    @ViewBuilder
    private var card: some View {
        if let sample {
            VStack(spacing: 0) {
                progressRow(sample)

                DSEyebrow(text: sample.eyebrow)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)

                Text(sample.question)
                    .font(DS.title(.title3, .regular))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)

                VStack(spacing: 8) {
                    ForEach(Array(sample.options.enumerated()), id: \.offset) { index, option in
                        optionRow(option, isCorrect: index == sample.correctIndex)
                    }
                }
                .padding(.top, 14)

                feedbackBar(sample)
                    .padding(.top, 14)
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .ov2Card()
            .padding(.bottom, 2)
        }
    }

    private func progressRow(_ sample: QuizSample) -> some View {
        HStack(spacing: 10) {
            DSSegmentedProgress(
                total: min(max(sample.total, sample.position), 10),
                filled: min(sample.position, 10),
                height: 5,
                spacing: 3
            )

            if sample.position >= 2 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Self.comboGold)
                    Text(verbatim: "x2")
                        .font(DS.sans(.caption2, .heavy))
                        .foregroundStyle(Self.comboInk)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule(style: .continuous).fill(Self.comboTint))
                .scaleEffect(answered ? 1 : 0.6)
                .opacity(answered ? 1 : 0)
            }
        }
    }

    private func optionRow(_ text: String, isCorrect: Bool) -> some View {
        let state: DSOptionState = answered ? (isCorrect ? .correct : .dimmed) : .idle
        return HStack(spacing: 10) {
            Text(text)
                .font(DS.sans(.footnote, answered && isCorrect ? .bold : .medium))
                .foregroundStyle(optionColor(answered: answered, isCorrect: isCorrect))
                .multilineTextAlignment(.leading)
                .lineSpacing(1)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if answered && isCorrect {
                DSCheckBadge(size: 22)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minHeight: 42)
        .dsOptionCard(state, cornerRadius: 14)
    }

    private func optionColor(answered: Bool, isCorrect: Bool) -> Color {
        guard answered else { return OV2.ink }
        return isCorrect ? DS.success : OV2.inkTertiary
    }

    /// Le bandeau de verdict, collé au bas de la carte : « Excellent ! » et le combo.
    private func feedbackBar(_ sample: QuizSample) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(DS.successTint)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(DS.success)
            }
            .frame(width: 26, height: 26)

            Text(languageManager.text("quiz.feedback.excellent"))
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(DS.success)

            Spacer(minLength: 8)

            if sample.position >= 2 {
                Text(String(format: languageManager.text("quiz.combo"), 2))
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(OV2.inkSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            Rectangle().fill(DS.hairline).frame(height: 1.5)
        }
        .padding(.horizontal, -16)
        .opacity(answered ? 1 : 0)
        .offset(y: answered || reduceMotion ? 0 : 12)
    }

    // MARK: Animation

    /// Les réponses sont posées ; un instant plus tard la bonne se valide, comme si le
    /// lecteur venait de la toucher.
    private func play() {
        guard !answered else { return }
        if reduceMotion {
            answered = true
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(DS.Motion.snappy) {
                answered = true
            }
            Haptics.success()
        }
    }

    // MARK: Données

    /// Une question à choix du cours sur les trous noirs (la deuxième du quiz de préférence :
    /// le combo x2 y a un sens), sinon l'exemple de la table de textes.
    static func makeSample(languageManager: LanguageManager) -> QuizSample {
        let language: AppLanguage = languageManager.current
        if let course = ContentCatalog.course(withId: OnboardingV2IntroCatalog.blackHoleCourseId, language: language),
           let found = catalogSample(from: course, languageManager: languageManager) {
            return found
        }
        return QuizSample(
            eyebrow: Subject.sciences.localizedShortName(language: language).uppercasedInApp(),
            question: languageManager.text("onboardingV2.elevate.quiz.sample.question"),
            options: [
                languageManager.text("onboardingV2.elevate.quiz.sample.correct"),
                languageManager.text("onboardingV2.elevate.quiz.sample.wrong1"),
                languageManager.text("onboardingV2.elevate.quiz.sample.wrong2"),
            ],
            correctIndex: 0,
            position: 1,
            total: 1
        )
    }

    private static func catalogSample(from course: Course, languageManager: LanguageManager) -> QuizSample? {
        let quiz: [QuizQuestion] = course.quiz
        // La deuxième question et les suivantes d'abord, la première en dernier recours.
        let order: [Int] = Array(quiz.indices.dropFirst()) + Array(quiz.indices.prefix(1))
        for index in order {
            let question: QuizQuestion = quiz[index]
            guard question.type == .mcq,
                  let options = question.options,
                  let correct = question.correctIndex,
                  options.count >= 3,
                  options.indices.contains(correct)
            else { continue }

            // La bonne réponse et les deux premières autres, dans leur ordre d'origine.
            var kept: [Int] = [correct]
            for other in options.indices where other != correct && kept.count < 3 {
                kept.append(other)
            }
            kept.sort()
            let texts: [String] = kept.map { options[$0].withoutInlineMarkup }
            let prompt: String = question.question.withoutInlineMarkup
            // Une question ou une réponse trop longue ne tient pas dans la carte.
            guard prompt.count <= 110, texts.allSatisfy({ $0.count <= 100 }) else { continue }

            let language: AppLanguage = languageManager.current
            let counter: String = String(format: languageManager.text("duel.game.counter"), index + 1, quiz.count)
            return QuizSample(
                eyebrow: "\(course.subject.localizedShortName(language: language)) · \(counter)".uppercasedInApp(),
                question: prompt,
                options: texts,
                correctIndex: kept.firstIndex(of: correct) ?? 0,
                position: index + 1,
                total: quiz.count
            )
        }
        return nil
    }
}

// MARK: - 6. Parcours personnalisé

/// « Sophia te construit un parcours personnalisé » : le premier niveau du Parcours, deux
/// cours faits, le suivant à lire, un quatrième encore fermé.
struct OnboardingV2IntroRoutePage: View {
    @Environment(LanguageManager.self) private var languageManager
    let isActive: Bool

    var body: some View {
        OnboardingV2IntroPageFrame(
            title: languageManager.text("onboardingV2.intro.route.title"),
            subtitle: languageManager.text("onboardingV2.intro.route.subtitle")
        ) {
            OnboardingV2PathPreview(isActive: isActive)
        }
    }
}

// MARK: - 7. Duels

/// « Affronte tes amis en duel » : un classement d'exemple où « Toi » gagne des trophées et
/// remonte de deux places.
struct OnboardingV2IntroDuelsPage: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isActive: Bool

    /// Place de « Toi » dans le classement (0 pour la première).
    @State private var youRank: Int = OnboardingV2IntroDuelsPage.startRank
    @State private var youTrophies: Int = OnboardingV2IntroDuelsPage.startTrophies
    @State private var rowsShown = false

    struct Row: Identifiable {
        let id: String
        let name: String
        let avatar: String
        let trophies: Int
        let isYou: Bool
    }

    // Classement d'exemple : pseudos tirés de la table de textes, avatars du jeu d'avatars
    // de l'app, trophées purement illustratifs.
    private static let rivalAvatars: [String] = ["avatar_09", "avatar_03", "avatar_36", "avatar_48"]
    private static let rivalTrophies: [Int] = [412, 341, 298, 275]
    private static let youAvatar = "avatar_22"
    private static let startRank = 3
    private static let endRank = 1
    private static let startTrophies = 286
    private static let endTrophies = 386

    private static let trophyGold = Color(red: 0.694, green: 0.498, blue: 0.063)
    private static let trophyTint = Color(red: 0.984, green: 0.937, blue: 0.788)
    private static let medalColors: [Color] = [
        Color(red: 0.902, green: 0.698, blue: 0.200),
        Color(red: 0.788, green: 0.816, blue: 0.859),
        Color(red: 0.890, green: 0.710, blue: 0.557),
    ]

    var body: some View {
        OnboardingV2IntroPageFrame(
            title: languageManager.text("onboardingV2.elevate.duels.title"),
            subtitle: languageManager.text("onboardingV2.elevate.duels.subtitle")
        ) {
            card
        }
        .onIntroPageActivated(isActive) { play() }
    }

    private var rows: [Row] {
        var list: [Row] = []
        for index in Self.rivalAvatars.indices {
            let handle: String = languageManager.text("onboardingV2.elevate.duels.sample.handle\(index + 1)")
            list.append(Row(
                id: "rival\(index)",
                name: "@\(handle)",
                avatar: Self.rivalAvatars[index],
                trophies: Self.rivalTrophies[index],
                isYou: false
            ))
        }
        let you = Row(
            id: "you",
            name: languageManager.text("duel.you"),
            avatar: Self.youAvatar,
            trophies: youTrophies,
            isYou: true
        )
        list.insert(you, at: min(max(youRank, 0), list.count))
        return list
    }

    // MARK: Carte

    private var card: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 2) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    rowView(row, rank: index + 1)
                        .zIndex(row.isYou ? 1 : 0)
                }
            }
            .padding(.top, 12)
            .opacity(rowsShown ? 1 : 0)
            .offset(y: rowsShown || reduceMotion ? 0 : 10)

            footer
                .padding(.top, 10)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .ov2Card()
        .padding(.bottom, 2)
    }

    private var header: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(Self.trophyTint)
                Image(systemName: "trophy")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Self.trophyGold)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                DSEyebrow(text: languageManager.text("duel.trophies.title").uppercasedInApp())
                Text(languageManager.text("duel.friends.title"))
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(OV2.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
    }

    private func rowView(_ row: Row, rank: Int) -> some View {
        HStack(spacing: 10) {
            rankBadge(rank)

            Image(row.avatar)
                .resizable()
                .scaledToFill()
                .frame(width: 34, height: 34)
                .clipShape(Circle())

            Text(row.name)
                .font(DS.sans(.footnote, row.isYou ? .heavy : .semibold))
                .foregroundStyle(OV2.ink)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 3) {
                Image(systemName: "trophy")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Self.trophyGold)
                Text(verbatim: "\(row.trophies)")
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(OV2.ink)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(row.trophies)))
            }
        }
        .padding(.vertical, row.isYou ? 8 : 7)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(row.isYou ? DS.accentTint : Color.clear)
        )
        .padding(.horizontal, -8)
    }

    private func rankBadge(_ rank: Int) -> some View {
        let onPodium: Bool = rank <= Self.medalColors.count
        return ZStack {
            Circle().fill(onPodium ? Self.medalColors[rank - 1] : Color.clear)
            Text(verbatim: "\(rank)")
                .font(DS.sans(.caption, .heavy))
                .foregroundStyle(onPodium ? Color.white : OV2.inkTertiary)
        }
        .frame(width: 24, height: 24)
    }

    /// Le geste qui lance un duel entre amis, montré comme sur la fiche d'un ami.
    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 11, weight: .bold))
            Text(languageManager.text("duel.friend.challenge"))
                .font(DS.sans(.caption, .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(DS.accent))
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .background(alignment: .top) {
            OnboardingV2DashedRule()
        }
    }

    // MARK: Animation

    /// Le classement se pose, puis « Toi » gagne cent trophées et passe deuxième.
    private func play() {
        guard !rowsShown else { return }
        if reduceMotion {
            rowsShown = true
            youRank = Self.endRank
            youTrophies = Self.endTrophies
            return
        }
        withAnimation(DS.Motion.reveal.delay(0.15)) {
            rowsShown = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(DS.Motion.reveal) {
                youTrophies = Self.endTrophies
            }
            Haptics.tick()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.45) {
            withAnimation(DS.Motion.pop) {
                youRank = Self.endRank
            }
            Haptics.success()
        }
    }
}

/// Filet pointillé horizontal (séparateur du pied de carte).
struct OnboardingV2DashedRule: View {
    var body: some View {
        OnboardingV2HorizontalLine()
            .stroke(DS.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            .frame(height: 1.5)
            .frame(maxWidth: .infinity)
    }
}

private struct OnboardingV2HorizontalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

// MARK: - 8. Audio

/// « Écoute tes cours quand tu ne peux pas les lire » : l'illustration du métro et, posé
/// dessus, le lecteur audio d'un vrai cours dont le temps s'écoule.
struct OnboardingV2IntroAudioPage: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isActive: Bool

    @State private var course: Course?
    @State private var cover: UIImage?
    @State private var authorName: String?
    @State private var playerIn = false
    @State private var startedAt: Date?

    /// Durée annoncée d'un cours, en minutes (le « 10 min » des leçons).
    private static let lessonMinutes = 10
    /// Où en est la lecture quand la page s'ouvre, en secondes.
    private static let startSeconds = 192
    private static let imageHeight: CGFloat = 300
    private static let totalHeight: CGFloat = 372

    /// Ancre fixe de l'horloge du lecteur : un battement par seconde pleine.
    private static let clockAnchor = Date(timeIntervalSinceReferenceDate: 0)

    private var totalSeconds: Int { Self.lessonMinutes * 60 }

    var body: some View {
        OnboardingV2IntroPageFrame(
            title: languageManager.text("onboardingV2.elevate.audio.title"),
            subtitle: languageManager.text("onboardingV2.elevate.audio.subtitle")
        ) {
            illustration
        }
        .onAppear { loadCourse() }
        .onIntroPageActivated(isActive) { play() }
    }

    // MARK: Illustration

    private var illustration: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: Self.imageHeight)
                    .overlay {
                        Image("onb_audio_metro")
                            .resizable()
                            .scaledToFill()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                Spacer(minLength: 0)
            }

            player
                .padding(.horizontal, 14)
                .padding(.bottom, 2)
                .opacity(playerIn ? 1 : 0)
                .offset(y: playerIn || reduceMotion ? 0 : 24)
        }
        .frame(height: Self.totalHeight)
        .frame(maxWidth: .infinity)
    }

    /// Le lecteur : couverture, titre, auteur et durée, la barre de lecture, les commandes.
    private var player: some View {
        TimelineView(.periodic(from: Self.clockAnchor, by: 1)) { context in
            let elapsed: Int = elapsedSeconds(at: context.date)
            VStack(spacing: 10) {
                trackRow
                progressBar(fraction: Double(elapsed) / Double(max(totalSeconds, 1)))
                controls(elapsed: elapsed)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .ov2Card(cornerRadius: 18)
        }
    }

    private var trackRow: some View {
        HStack(spacing: 10) {
            ZStack {
                if let cover {
                    Image(uiImage: cover)
                        .resizable()
                        .scaledToFill()
                } else {
                    DS.accentTint
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(course?.title ?? "")
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(OV2.ink)
                    .lineLimit(1)
                Text(trackCaption)
                    .font(DS.sans(.caption, .regular))
                    .foregroundStyle(OV2.inkSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// « Stacy Jankowski · 10 min » : l'auteur du cours quand le catalogue le connaît.
    private var trackCaption: String {
        let duration: String = String(format: languageManager.text("onboardingV2.screenTime.minutes"), Self.lessonMinutes)
        guard let authorName, !authorName.isEmpty else { return duration }
        return "\(authorName) · \(duration)"
    }

    private func progressBar(fraction: Double) -> some View {
        let clamped: CGFloat = CGFloat(min(max(fraction, 0), 1))
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(DS.hairline)
                    .frame(height: 4)
                Capsule().fill(DS.accent)
                    .frame(width: geo.size.width * clamped, height: 4)
                Circle().fill(DS.accent)
                    .frame(width: 12, height: 12)
                    .offset(x: geo.size.width * clamped - 6)
            }
            .frame(height: 12)
        }
        .frame(height: 12)
        .animation(.linear(duration: 1), value: fraction)
    }

    private func controls(elapsed: Int) -> some View {
        HStack(spacing: 0) {
            Text(verbatim: Self.clock(elapsed))
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(OV2.inkSecondary)
                .monospacedDigit()
                .frame(width: 44, alignment: .leading)

            Spacer(minLength: 0)

            HStack(spacing: 14) {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(OV2.ink)

                ZStack {
                    Circle().fill(DS.accent)
                    Image(systemName: "pause.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 42, height: 42)

                Image(systemName: "goforward.15")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(OV2.ink)
            }

            Spacer(minLength: 0)

            Text(verbatim: Self.clock(totalSeconds))
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(OV2.inkSecondary)
                .monospacedDigit()
                .frame(width: 44, alignment: .trailing)
        }
    }

    // MARK: Temps de lecture

    /// Le temps écoulé depuis l'ouverture de la page, ajouté au point de départ ; figé
    /// quand « Réduire les animations » est actif ou tant que la page n'est pas ouverte.
    private func elapsedSeconds(at date: Date) -> Int {
        guard let startedAt, !reduceMotion else { return Self.startSeconds }
        let played: Int = Int(max(0, date.timeIntervalSince(startedAt)))
        return min(totalSeconds, Self.startSeconds + played)
    }

    private static func clock(_ seconds: Int) -> String {
        let safe: Int = max(0, seconds)
        return String(format: "%d:%02d", safe / 60, safe % 60)
    }

    // MARK: Données et animation

    private func loadCourse() {
        guard course == nil else { return }
        let picked: Course? = OnboardingV2IntroCatalog.course(
            preferring: OnboardingV2IntroCatalog.blackHoleCourseId,
            language: languageManager.current
        )
        course = picked
        if let picked {
            cover = OnboardingV2IntroCatalog.coverThumbnail(for: picked.id)
            authorName = AuthorStore.author(forCourseId: picked.id)?.name
        }
    }

    private func play() {
        guard !playerIn else { return }
        startedAt = Date()
        if reduceMotion {
            playerIn = true
            return
        }
        withAnimation(DS.Motion.reveal.delay(0.2)) {
            playerIn = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            Haptics.soft()
        }
    }
}
