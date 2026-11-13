import SwiftUI
import UIKit

// Blocs de contenu des paywalls « Elevate arrondi » : en-tête avant / après, titre, liste
// d'avantages, « Écrits par des experts », « Ils lisent avec Sophia », lignes à pictogramme,
// et les illustrations propres à chaque paywall (éventail de cours, question d'exemple,
// lecteur d'exemple, étapes de l'anti-scroll).

// MARK: - En-tête avant / après

/// Deux illustrations côte à côte : « avant » à gauche, en gris assombri, au coin bas arrondi ;
/// « après » à droite, en couleurs. Une étiquette sur chacune.
struct ElevateBeforeAfterHero: View {
    @Environment(LanguageManager.self) private var languageManager
    let beforeImage: String
    let afterImage: String
    let beforeLabel: String
    /// Étiquette de droite. Avec `afterLabelHasLogo`, le `%@` du texte marque la place du logo
    /// Sophia (« Avec %@ », « %@ ile »…).
    let afterLabel: String
    var afterLabelHasLogo: Bool = false

    private static let height: CGFloat = 268
    /// Proportions du logo complet `sophia_mark` (1192 × 334).
    private static let logoRatio: CGFloat = 1192.0 / 334.0

    var body: some View {
        GeometryReader { proxy in
            let width: CGFloat = proxy.size.width
            let leftWidth: CGFloat = width * (208.0 / 390.0)
            let rightWidth: CGFloat = width - leftWidth + 28
            let leftShape = UnevenRoundedRectangle(bottomTrailingRadius: 90, style: .continuous)

            ZStack(alignment: .bottom) {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Image(afterImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: rightWidth, height: Self.height, alignment: .top)
                        .clipped()
                }

                HStack(spacing: 0) {
                    Image(beforeImage)
                        .resizable()
                        .scaledToFill()
                        .grayscale(1)
                        .colorMultiply(Color(white: 0.72))
                        .contrast(1.05)
                        .frame(width: leftWidth, height: Self.height, alignment: .top)
                        .clipShape(leftShape)
                        // Le liseré blanc qui détache l'image de gauche de celle de droite.
                        .background(
                            leftShape
                                .fill(DS.canvas)
                                .frame(width: leftWidth + 6, height: Self.height)
                                .offset(x: 3)
                        )
                    Spacer(minLength: 0)
                }

                HStack(alignment: .bottom, spacing: 8) {
                    beforeTag
                    Spacer(minLength: 8)
                    afterTag
                }
                .padding(14)
            }
            .frame(width: width, height: Self.height)
            .clipped()
        }
        .frame(height: Self.height)
        // Une image : « avant » reste à gauche dans toutes les langues.
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityElement(children: .combine)
    }

    private var beforeTag: some View {
        Text(beforeLabel)
            .font(DS.sans(.caption, .bold))
            .foregroundStyle(Color(white: 0.87))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(red: 0.133, green: 0.149, blue: 0.180).opacity(0.72), in: Capsule())
    }

    private var afterTag: some View {
        HStack(spacing: 5) {
            if afterLabelHasLogo {
                let pieces: [String] = afterLabel.components(separatedBy: "%@")
                let before: String = (pieces.first ?? "").trimmingCharacters(in: .whitespaces)
                let after: String = (pieces.count > 1 ? pieces[1] : "").trimmingCharacters(in: .whitespaces)
                if !before.isEmpty { Text(before) }
                Image("sophia_mark")
                    .resizable()
                    .frame(width: 14 * Self.logoRatio, height: 14)
                    .accessibilityLabel(Text(verbatim: "Sophia"))
                if !after.isEmpty { Text(after) }
            } else {
                Text(afterLabel)
            }
        }
        .font(DS.sans(.caption, .bold))
        .foregroundStyle(Color(red: 0.180, green: 0.384, blue: 0.769))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white, in: Capsule())
        // Le mot et le logo, eux, suivent le sens de lecture de la langue.
        .environment(\.layoutDirection, languageManager.layoutDirection)
    }
}

// MARK: - Titre et sous-titre

/// Titre centré d'un paywall : graisse moyenne, passage entre `**` en gras bleu.
struct ElevatePaywallTitle: View {
    let text: String

    var body: some View {
        DSHighlightTitle(text: text, style: .title, weight: .medium)
            .tracking(0.2)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
            .padding(.top, 20)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Texte secondaire centré sous le titre.
struct ElevatePaywallSubtitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DS.sans(.subheadline, .regular))
            .foregroundStyle(DS.inkSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 10)
    }
}

/// Titre de section centré (« Ta mémoire, ça s'entraîne »).
struct ElevateSectionTitle: View {
    let text: String
    var style: Font.TextStyle = .title3

    var body: some View {
        Text(text)
            .font(DS.title(style, .semibold))
            .foregroundStyle(DS.ink)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Liste d'avantages

/// Les avantages de l'abonnement, un emoji devant chacun, le passage entre `**` en gras.
/// « Toutes les matières débloquées » n'y est pas : la version gratuite les a déjà toutes.
struct ElevateFeatureList: View {
    @Environment(LanguageManager.self) private var languageManager

    private static let rows: [(emoji: String, key: String)] = [
        ("📚", "paywall.elevate.common.feature.courses"),
        ("🧠", "paywall.elevate.common.feature.quiz"),
        ("🎧", "paywall.elevate.common.feature.audio"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(Self.rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 12) {
                    Text(verbatim: row.emoji)
                        .font(.system(size: 22))
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    ElevateMarkup.text(
                        languageManager.text(row.key),
                        base: DS.sans(.subheadline, .regular),
                        strong: DS.sans(.subheadline, .bold)
                    )
                    .foregroundStyle(DS.ink)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 22)
    }
}

// MARK: - « Écrits par des experts »

/// L'illustration des profs, le titre, puis les portraits et les institutions des vrais
/// auteurs de l'app (`AuthorStore`). Sans auteur avec portrait, la rangée disparaît et il
/// reste l'illustration et le titre.
struct ElevateExpertsCard: View {
    @Environment(LanguageManager.self) private var languageManager

    @State private var faces: [UIImage] = []
    @State private var institutions: String = ""
    @State private var didLoad = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("pw_experts_group")
                .resizable()
                .aspectRatio(348.0 / 261.0, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 14) {
                Text(languageManager.text("paywall.elevate.common.experts.title"))
                    .font(DS.title(.title2, .semibold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                if !faces.isEmpty || !institutions.isEmpty {
                    HStack(spacing: 10) {
                        if !faces.isEmpty { faceRow }
                        if !institutions.isEmpty {
                            Text(institutions)
                                .font(DS.sans(.caption, .semibold))
                                .foregroundStyle(DS.inkSecondary)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 20)
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .dsOptionCard(.idle)
        .padding(.horizontal, 20)
        .onAppear { load() }
    }

    private var faceRow: some View {
        HStack(spacing: -10) {
            ForEach(Array(faces.enumerated()), id: \.offset) { index, face in
                Image(uiImage: face)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(DS.surface, lineWidth: 2))
                    .zIndex(Double(faces.count - index))
            }
        }
        .accessibilityHidden(true)
    }

    /// Un portrait par institution, dans l'ordre du fichier des auteurs : cinq visages au
    /// plus, quatre institutions citées, « … » quand il y en a d'autres.
    private func load() {
        guard !didLoad else { return }
        didLoad = true
        var names: [String] = []
        var photos: [UIImage] = []
        for author in AuthorStore.all {
            guard let raw: String = author.institution else { continue }
            let institution: String = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if institution.isEmpty || names.contains(institution) { continue }
            guard let photo: UIImage = AuthorStore.photo(for: author) else { continue }
            names.append(institution)
            photos.append(photo)
            if names.count >= 6 { break }
        }
        faces = Array(photos.prefix(5))
        let shown: [String] = Array(names.prefix(4))
        if shown.isEmpty {
            institutions = ""
        } else {
            institutions = shown.joined(separator: ", ") + (names.count > shown.count ? "…" : "")
        }
    }
}

// MARK: - « Ils lisent avec Sophia »

/// Le titre, la note du store, puis les avis déjà dans l'app (`onboardingV2.review.*` et leurs
/// portraits) en carrousel : on fait glisser, ou on passe par les points et les flèches.
struct ElevateReviewsBlock: View {
    @Environment(LanguageManager.self) private var languageManager
    @State private var current: Int? = 0

    private static let count = 5
    private static let cardWidth: CGFloat = 290

    private var ratingText: String {
        (4.8).formatted(.number.precision(.fractionLength(1)).locale(languageManager.locale))
    }

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                Text(languageManager.text("paywall.elevate.common.reviews.title"))
                    .font(DS.title(.headline, .semibold))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(DS.warm)
                        }
                    }
                    .accessibilityHidden(true)
                    Text(ratingText + " " + languageManager.text("paywall.quiz.rating"))
                        .font(DS.sans(.footnote, .bold))
                        .foregroundStyle(DS.inkSecondary)
                }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(0..<Self.count, id: \.self) { index in
                        card(index)
                            .frame(width: Self.cardWidth)
                            .id(index)
                    }
                }
                .scrollTargetLayout()
                .padding(.top, 4)
                .padding(.bottom, 6)
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $current)
            .scrollIndicators(.hidden)

            controls
                .padding(.horizontal, 20)
        }
        .padding(.top, 32)
    }

    private func card(_ index: Int) -> some View {
        let number: Int = index + 1
        let author: String = languageManager.text("onboardingV2.review.t\(number).author")
        return VStack(alignment: .leading, spacing: 12) {
            Text(quoted(languageManager.text("onboardingV2.review.t\(number).quote")))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.ink)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                ElevateReviewAvatar(index: number, name: author)
                Text(author)
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(DS.inkSecondary)
                    .lineLimit(1)
            }
        }
        .padding(18)
        .frame(minHeight: 140, maxHeight: .infinity, alignment: .top)
        .dsOptionCard(.idle)
        .accessibilityElement(children: .combine)
    }

    /// L'avis entre les guillemets de la langue lue (« … », “…”, „…“).
    private func quoted(_ text: String) -> String {
        let locale: Locale = languageManager.locale
        guard let open: String = locale.quotationBeginDelimiter,
              let close: String = locale.quotationEndDelimiter else { return text }
        // Le français met une espace insécable à l'intérieur de ses guillemets.
        let gap: String = open == "«" ? "\u{00A0}" : ""
        return open + gap + text + gap + close
    }

    private var controls: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<Self.count, id: \.self) { index in
                    Capsule()
                        .fill(index == (current ?? 0) ? DS.accent : DS.inkTertiary.opacity(0.45))
                        .frame(width: index == (current ?? 0) ? 20 : 8, height: 8)
                        .animation(DS.Motion.snappy, value: current)
                }
            }
            Spacer(minLength: 8)
            arrow("chevron.backward") { move(by: -1) }
            arrow("chevron.forward") { move(by: 1) }
        }
        // Le carrousel se parcourt déjà avis par avis avec VoiceOver.
        .accessibilityHidden(true)
    }

    private func arrow(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DS.accent)
                .frame(width: 44, height: 44)
                .background(DS.surface, in: Circle())
                .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1.5) }
        }
        .buttonStyle(PressableStyle(scale: 0.9))
    }

    private func move(by step: Int) {
        let now: Int = current ?? 0
        let next: Int = (now + step + Self.count) % Self.count
        withAnimation(DS.Motion.snappy) { current = next }
    }
}

/// Portrait d'un avis : le `review_avatar_<n>` du bundle, sinon l'initiale sur fond teinté.
struct ElevateReviewAvatar: View {
    let index: Int
    let name: String
    var size: CGFloat = 36

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Circle().fill(DS.accentTint)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased())
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(DS.accent)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
        .onAppear {
            if image == nil { image = Self.bundledImage(index: index) }
        }
    }

    /// `UIImage(named:)` ne trouve pas un JPG du bundle sans son extension : recherche par URL.
    private static func bundledImage(index: Int) -> UIImage? {
        for ext in ["jpg", "jpeg", "png"] {
            if let url = Bundle.main.url(forResource: "review_avatar_\(index)", withExtension: ext),
               let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }
        return UIImage(named: "review_avatar_\(index)")
    }
}

// MARK: - Ligne à pictogramme

/// Un pictogramme dans une tuile bleu pâle, un titre en gras et une phrase dessous.
struct ElevateInfoRow: View {
    let systemImage: String
    let title: String
    let detail: String
    var alignment: VerticalAlignment = .top

    var body: some View {
        HStack(alignment: alignment, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(DS.accent)
                .frame(width: 40, height: 40)
                .background(DS.accentTint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(DS.sans(.footnote, .regular))
                    .foregroundStyle(DS.inkSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Cours : « Toute la bibliothèque »

/// Le titre de la variante avis : « Toute la bibliothèque », le logo Sophia dessous.
struct ElevateLibraryTitle: View {
    @Environment(LanguageManager.self) private var languageManager

    var body: some View {
        VStack(spacing: 8) {
            Text(languageManager.text("paywall.elevate.reviews.title"))
                .font(DS.title(.title, .medium))
                .tracking(0.2)
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Image("sophia_mark")
                .resizable()
                .frame(width: 38 * (1192.0 / 334.0), height: 38)
                .accessibilityLabel(Text(verbatim: "Sophia"))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 28)
        .padding(.top, 6)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Trois vrais cours du catalogue en éventail : celui qu'on voulait lire au centre quand il y
/// en a un, deux autres matières sur les côtés.
struct ElevateCourseFan: View {
    @Environment(LanguageManager.self) private var languageManager
    var course: Course? = nil

    private struct Entry: Identifiable {
        let id: String
        let title: String
        let category: String
        let cover: UIImage
    }

    @State private var entries: [Entry] = []
    @State private var didLoad = false

    var body: some View {
        ZStack(alignment: .top) {
            Ellipse()
                .fill(DS.hairline)
                .frame(width: 200, height: 18)
                .offset(y: 232)

            if entries.count > 1 {
                card(entries[1], width: 112, coverHeight: 112, large: false)
                    .rotationEffect(.degrees(-9))
                    .offset(x: -77, y: 34)
            }
            if entries.count > 2 {
                card(entries[2], width: 112, coverHeight: 112, large: false)
                    .rotationEffect(.degrees(9))
                    .offset(x: 77, y: 34)
            }
            if let first: Entry = entries.first {
                card(first, width: 144, coverHeight: 160, large: true)
                    .offset(y: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 262, alignment: .top)
        .padding(.top, 22)
        // Toujours de gauche à droite : c'est une image, pas une rangée de lecture.
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
        .onAppear { load() }
    }

    private func card(_ entry: Entry, width: CGFloat, coverHeight: CGFloat, large: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: large ? 4 : 3) {
                Image("sophia_mark")
                    .resizable()
                    .frame(width: (large ? 12 : 10) * (1192.0 / 334.0), height: large ? 12 : 10)
                Text(entry.title)
                    .font(.jakarta(size: large ? 13 : 10, weight: .bold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if large {
                    Text(entry.category)
                        .font(.jakarta(size: 10, weight: .semibold))
                        .foregroundStyle(DS.inkSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, large ? 10 : 8)
            .padding(.top, large ? 10 : 8)
            .padding(.bottom, large ? 8 : 6)
            .frame(width: width, alignment: .leading)

            Image(uiImage: entry.cover)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: coverHeight)
                .clipped()
        }
        .frame(width: width)
        .background(DS.surface)
        .clipShape(RoundedRectangle(cornerRadius: large ? 10 : 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: large ? 10 : 8, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        )
    }

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        let language: AppLanguage = languageManager.current
        let all: [Course] = ContentCatalog.courses(for: language)
        var picked: [Course] = []
        var covers: [UIImage] = []

        func tryAdd(_ candidate: Course) {
            if picked.contains(where: { $0.id == candidate.id || $0.subject == candidate.subject }) { return }
            guard let cover: UIImage = CourseImageMap.loadImage(for: candidate.id) else { return }
            picked.append(candidate)
            covers.append(cover)
        }

        if let course { tryAdd(course) }
        // Le cours de la maquette en premier choix, puis le catalogue dans son ordre.
        if let star: Course = all.first(where: { $0.id == "course_281_comment_meurt_une_etoile" }) {
            tryAdd(star)
        }
        for candidate in all {
            if picked.count >= 3 { break }
            tryAdd(candidate)
        }

        var built: [Entry] = []
        for (index, item) in picked.prefix(3).enumerated() {
            let subject: String = item.subject.localizedName(language: language)
            let category: String = item.subcategory.isEmpty ? subject : subject + " · " + item.subcategory
            built.append(Entry(id: item.id, title: item.title, category: category, cover: covers[index]))
        }
        entries = built
    }
}

// MARK: - Quiz : question d'exemple

/// Une question de quiz déjà répondue (la bonne réponse en vert, l'explication dessous), pour
/// montrer ce que l'abonnement débloque. Illustration : rien n'y est cliquable.
struct ElevateSampleQuizCard: View {
    @Environment(LanguageManager.self) private var languageManager

    /// Texte fixe sur la pastille ambrée du nom du cours.
    private static let pillInk = Color(red: 0.478, green: 0.325, blue: 0.063)
    private static let pillFill = Color(red: 0.984, green: 0.945, blue: 0.839)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(String(format: languageManager.text("paywall.sample.quiz.progress"), 4, 5).uppercasedInApp())
                    .font(DS.sans(.caption, .bold))
                    .tracking(0.5)
                    .foregroundStyle(DS.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 8)
                Text(languageManager.text("paywall.sample.quiz.course"))
                    .font(DS.sans(.caption, .bold))
                    .foregroundStyle(Self.pillInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Self.pillFill, in: Capsule())
            }

            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    Capsule()
                        .fill(index < 3 ? DS.success : (index == 3 ? DS.accent : DS.hairline))
                        .frame(height: 5)
                }
            }
            .accessibilityHidden(true)

            Text(languageManager.text("paywall.sample.quiz.question"))
                .font(DS.sans(.callout, .bold))
                .foregroundStyle(DS.ink)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)

            option(languageManager.text("paywall.sample.quiz.option1"), correct: true)
            option(languageManager.text("paywall.sample.quiz.option2"), correct: false)
            option(languageManager.text("paywall.sample.quiz.option3"), correct: false)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.warm)
                    .accessibilityHidden(true)
                Text(languageManager.text("paywall.sample.quiz.explanation"))
                    .font(DS.sans(.footnote, .regular))
                    .foregroundStyle(DS.inkSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .padding(16)
        .dsOptionCard(.idle)
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .accessibilityElement(children: .combine)
    }

    private func option(_ text: String, correct: Bool) -> some View {
        HStack(spacing: 10) {
            ZStack {
                if correct {
                    Circle().fill(DS.success)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Circle().strokeBorder(DS.inkTertiary.opacity(0.5), lineWidth: 2)
                }
            }
            .frame(width: 22, height: 22)
            Text(text)
                .font(DS.sans(.footnote, correct ? .bold : .semibold))
                .foregroundStyle(correct ? DS.success : DS.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(correct ? DS.successTint : DS.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(correct ? DS.success : DS.hairline, lineWidth: correct ? 2 : 1.5)
        )
    }
}

// MARK: - Audio : lecteur d'exemple

/// Un lecteur figé en pleine écoute : couverture, titre, barre de progression, commandes.
/// Avec un cours (celui qu'on voulait écouter), c'est sa couverture et son titre ; sinon le
/// cours d'exemple. Illustration : rien n'y est cliquable.
struct ElevateSamplePlayerCard: View {
    @Environment(LanguageManager.self) private var languageManager
    var course: Course? = nil

    @State private var cover: UIImage?
    private static let sampleCourseId = "course_281_comment_meurt_une_etoile"
    private static let progress: CGFloat = 0.36

    private var title: String {
        course?.title ?? languageManager.text("paywall.sample.audio.title")
    }

    /// La langue de narration qui correspond à la langue lue, l'anglais sinon.
    private var languageCode: String {
        (AudioLanguage(rawValue: languageManager.current.rawValue) ?? .english).shortCode
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                coverView
                VStack(alignment: .leading, spacing: 3) {
                    Text(languageManager.text("audio.nowPlaying").uppercasedInApp())
                        .font(DS.sans(.caption, .bold))
                        .tracking(0.5)
                        .foregroundStyle(DS.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(title)
                        .font(DS.sans(.callout, .bold))
                        .foregroundStyle(DS.ink)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 6) {
                progressBar
                HStack {
                    Text(verbatim: AudioFormat.time(124))
                    Spacer(minLength: 8)
                    Text(verbatim: "−" + AudioFormat.time(221))
                }
                .font(DS.sans(.caption, .semibold))
                .monospacedDigit()
                .foregroundStyle(DS.inkSecondary)
            }

            HStack(spacing: 0) {
                chip(AudioFormat.speed(1.5, locale: languageManager.locale))
                Spacer(minLength: 4)
                HStack(spacing: 18) {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(DS.ink)
                        .frame(width: 44, height: 44)
                    Image(systemName: "pause.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(DS.accent, in: Circle())
                    Image(systemName: "goforward.15")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(DS.ink)
                        .frame(width: 44, height: 44)
                }
                Spacer(minLength: 4)
                chip(languageCode)
            }
            // Le lecteur se lit de gauche à droite dans toutes les langues.
            .environment(\.layoutDirection, .leftToRight)
        }
        .padding(18)
        .dsOptionCard(.idle)
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(languageManager.text("audio.nowPlaying") + ", " + title))
        .onAppear {
            if cover == nil {
                cover = CourseImageMap.loadImage(for: course?.id ?? Self.sampleCourseId)
                    ?? CourseImageMap.loadImage(for: Self.sampleCourseId)
            }
        }
    }

    @ViewBuilder
    private var coverView: some View {
        if let cover {
            Image(uiImage: cover)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            Image(systemName: "headphones")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(DS.accent)
                .frame(width: 64, height: 64)
                .background(DS.accentTint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            let filled: CGFloat = proxy.size.width * Self.progress
            ZStack(alignment: .leading) {
                Capsule().fill(DS.hairline).frame(height: 6)
                Capsule().fill(DS.accent).frame(width: filled, height: 6)
                Circle().fill(DS.accent).frame(width: 14, height: 14).offset(x: filled - 7)
            }
            .frame(height: 14)
        }
        .frame(height: 14)
    }

    private func chip(_ text: String) -> some View {
        Text(verbatim: text)
            .font(DS.sans(.footnote, .bold))
            .foregroundStyle(DS.accent)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(DS.accentTint, in: Capsule())
    }
}

// MARK: - Anti-scroll : « Comment ça marche »

/// L'illustration du téléphone verrouillé, puis les trois étapes numérotées, reliées par un
/// pointillé ; la première montre les apps verrouillées (le composant de l'app, sans logo de
/// marque).
struct ElevateBlockerStepsCard: View {
    @Environment(LanguageManager.self) private var languageManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("pw_blocker_lock")
                .resizable()
                .scaledToFill()
                .frame(width: 220, height: 220)
                .clipped()
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                Text(languageManager.text("ambassador.how.title"))
                    .font(DS.title(.headline, .semibold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 16)
                    .accessibilityAddTraits(.isHeader)

                step(1, isLast: false) {
                    stepText(titleKey: "paywall.elevate.blocker.step1.title", bodyKey: "paywall.elevate.blocker.step1.body")
                    AntiScrollLockedApps(tileSize: 38, spacing: 9)
                        .padding(.top, 10)
                    Text(languageManager.text("paywall.elevate.blocker.step1.more"))
                        .font(DS.sans(.caption, .bold))
                        .foregroundStyle(DS.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                }
                step(2, isLast: false) {
                    stepText(titleKey: "paywall.elevate.blocker.step2.title", bodyKey: "paywall.elevate.blocker.step2.body")
                }
                step(3, isLast: true) {
                    stepText(titleKey: "paywall.elevate.blocker.step3.title", bodyKey: "paywall.elevate.blocker.step3.body")
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 6)
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .dsOptionCard(.idle)
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    private func step<Detail: View>(_ number: Int, isLast: Bool, @ViewBuilder detail: () -> Detail) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number.formatted(.number.locale(languageManager.locale)))
                .font(DS.sans(.footnote, .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(DS.accent, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                detail()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 5)
            .padding(.bottom, 18)
        }
        // Le pointillé descend de la pastille jusqu'à l'étape suivante, sur toute la hauteur
        // de la rangée.
        .background(alignment: .topLeading) {
            if !isLast {
                ElevateDashedLine()
                    .stroke(DS.inkTertiary.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    .frame(width: 2)
                    .padding(.top, 36)
                    .padding(.leading, 15)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func stepText(titleKey: String, bodyKey: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(languageManager.text(titleKey))
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(languageManager.text(bodyKey))
                .font(DS.sans(.footnote, .regular))
                .foregroundStyle(DS.inkSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Trait vertical au milieu de son cadre, pour le pointillé entre deux étapes.
nonisolated struct ElevateDashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}
