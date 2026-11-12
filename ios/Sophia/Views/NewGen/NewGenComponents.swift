import SwiftUI

// Briques des écrans « Sophia nouvelle génération » (maquette prompt 2) : identité d'un
// créateur, pastilles, compteurs, lignes de cours compactes, segments. Les prompts 6, 7 et
// 10 n'ont qu'à brancher les vraies données dessus.

// MARK: - Créateur

/// Qui signe un cours sur une carte : un auteur de `AuthorStore`, ou l'équipe Sophia pour les
/// cours maison (la majorité du catalogue n'a pas encore d'auteur nommé).
enum CreatorIdentity: Hashable {
    case author(CourseAuthor)
    case house

    static func forCourse(_ courseId: String) -> CreatorIdentity {
        if let author = AuthorStore.author(forCourseId: courseId) { return .author(author) }
        return .house
    }

    var author: CourseAuthor? {
        if case .author(let author) = self { return author }
        return nil
    }

    var slug: String? { author?.slug }

    var name: String {
        switch self {
        case .author(let author): author.name
        case .house: "Sophia"
        }
    }

    var isVerified: Bool {
        switch self {
        case .author(let author): author.isVerified
        case .house: true
        }
    }

    func pedigree(language: AppLanguage) -> String? {
        switch self {
        case .author(let author): author.title(for: language)
        case .house: AppLocalizable.string("creator.house.pedigree", language: language)
        }
    }

    /// Les créateurs peuvent être suivis ; l'équipe Sophia n'a pas de page.
    var isFollowable: Bool { author != nil }
}

/// Portrait ou initiales d'un auteur ; la marque Sophia pour les cours maison.
struct CreatorAvatar: View {
    let identity: CreatorIdentity
    var size: CGFloat = 36

    var body: some View {
        switch identity {
        case .author(let author):
            AuthorAvatarView(author: author, size: size)
        case .house:
            ZStack {
                Circle().fill(EventPalette.navy)
                houseGlyph
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .accessibilityHidden(true)
        }
    }

    /// Le symbole seul : `sophia_mark` est le logo complet (symbole + « Sophia », 1192 × 334),
    /// dont on ne garde que le quart gauche.
    private var houseGlyph: some View {
        let glyphHeight: CGFloat = size * 0.6
        return Image("sophia_mark")
            .resizable()
            .frame(width: glyphHeight * (1192.0 / 334.0), height: glyphHeight)
            .frame(width: glyphHeight * 0.88, height: glyphHeight, alignment: .leading)
            .clipped()
    }
}

/// Coche bleue des experts vérifiés, à côté du nom.
struct VerifiedCheck: View {
    var size: CGFloat = 14

    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: size, weight: .semibold))
            .symbolRenderingMode(.palette)
            .foregroundStyle(Color.white, DS.accent)
            .accessibilityLabel(Text(AppLocalizable.string("creator.badge.verified", language: AppLanguage.currentPersisted())))
    }
}

/// « Expert vérifié » (bleu) ou « Créateur » (violet) : le statut d'un créateur, en capsule.
struct CreatorBadge: View {
    let verified: Bool

    private var language: AppLanguage { AppLanguage.currentPersisted() }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: verified ? "checkmark.circle" : "pencil.line")
                .font(.system(size: 13, weight: .bold))
            Text(AppLocalizable.string(verified ? "creator.badge.verified" : "creator.badge.creator", language: language))
                .font(DS.sans(.footnote, .bold))
        }
        .foregroundStyle(verified ? DS.accent : Color(red: 0.30, green: 0.11, blue: 0.58))
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(
            Capsule().fill(verified ? DS.accentTint : Color(red: 0.95, green: 0.93, blue: 0.98))
        )
    }
}

/// Avatar, nom avec coche, pedigree : la ligne « qui a écrit ça » des cartes et des fiches.
struct CreatorLine: View {
    let identity: CreatorIdentity
    var avatarSize: CGFloat = 34
    var showsPedigree = true
    var onTap: (() -> Void)? = nil

    private var language: AppLanguage { AppLanguage.currentPersisted() }

    var body: some View {
        let content = HStack(spacing: 10) {
            CreatorAvatar(identity: identity, size: avatarSize)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(identity.name)
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(DS.ink)
                        .lineLimit(1)
                    if identity.isVerified { VerifiedCheck(size: 13) }
                }
                if showsPedigree, let pedigree = identity.pedigree(language: language) {
                    Text(pedigree)
                        .font(DS.sans(.caption))
                        .foregroundStyle(DS.inkSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())

        if let onTap, identity.isFollowable {
            Button {
                onTap()
            } label: { content }
            .buttonStyle(.pressable)
            .accessibilityLabel(Text(identity.name))
        } else {
            content
        }
    }
}

/// « Suivre » plein ou « Abonné » en contour. Le geste reste local jusqu'au prompt 6.
struct FollowButton: View {
    let isFollowing: Bool
    var compact = false
    let action: () -> Void

    private var language: AppLanguage { AppLanguage.currentPersisted() }
    private var height: CGFloat { compact ? 44 : 46 }

    var body: some View {
        Button {
            // Suivre est une petite victoire (vibration franche) ; se désabonner, un simple appui.
            if isFollowing { Haptics.tap() } else { Haptics.confirm() }
            action()
        } label: {
            Text(AppLocalizable.string(isFollowing ? "creator.following" : "creator.follow", language: language))
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(isFollowing ? DS.accent : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 16)
                .frame(height: height)
                .frame(maxWidth: compact ? nil : .infinity)
                .background { fillShape }
                .contentTransition(.opacity)
        }
        .buttonStyle(PressableStyle(scale: 0.94, haptic: false))
        .animation(DS.Motion.snappy, value: isFollowing)
    }

    @ViewBuilder
    private var fillShape: some View {
        if isFollowing {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DS.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(DS.hairline, lineWidth: 1.5)
                }
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DS.accent)
        }
    }
}

// MARK: - Pastilles et chips

/// Pastille blanche « ● Histoire » (point de la couleur de la matière), avec un complément
/// optionnel (« · 1916 »).
struct SubjectPill: View {
    let subject: Subject
    var extra: String? = nil

    private var language: AppLanguage { AppLanguage.currentPersisted() }

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(subject.color).frame(width: 8, height: 8)
            Text(extra.map { "\(subject.localizedShortName(language: language)) · \($0)" } ?? subject.localizedShortName(language: language))
                .font(DS.sans(.caption, .bold))
                .foregroundStyle(DS.ink)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .frame(height: 26)
        .background(Capsule().fill(DS.surface))
        .overlay(Capsule().strokeBorder(DS.hairline, lineWidth: 1))
    }
}

/// Étiquette pleine : « Nouveau » (bleu nuit) ou le nom d'un événement (or).
struct TagPill: View {
    enum Style { case accent, warm }
    let text: String
    var style: Style = .accent

    var body: some View {
        Text(text)
            .font(DS.sans(.caption, .bold))
            .foregroundStyle(style == .accent ? .white : DS.ink)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(Capsule().fill(style == .accent ? DS.accent : DS.warm))
            .lineLimit(1)
    }
}

/// Icône + valeur, pour les lignes de statistiques des cartes (lectures, j'aime, durée).
struct StatChip: View {
    let systemImage: String
    let text: String
    var tint: Color = DS.inkSecondary

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .medium))
            Text(text)
                .font(DS.sans(.footnote, .semibold))
                .monospacedDigit()
        }
        .foregroundStyle(tint)
    }
}

/// Les trois compteurs du profil : icône sur fond teinté, valeur, libellé.
struct StatCounter: View {
    let systemImage: String
    let iconTint: Color
    let iconBackground: Color
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(iconBackground)
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconTint)
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(DS.title(.headline, .heavy))
                    .foregroundStyle(DS.ink)
                    .monospacedDigit()
                    .lineLimit(1)
                Text(label)
                    .font(DS.sans(.caption))
                    .foregroundStyle(DS.inkSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Cours

/// Couverture d'un cours : l'image du catalogue, sinon l'icône de la matière sur fond doux.
struct CourseCover: View {
    let course: Course
    var cornerRadius: CGFloat = 14

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(DS.surfaceMuted)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: course.subject.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(course.subject.color)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onAppear {
            if image == nil { image = CourseImageMap.loadImage(for: course.id) }
        }
        .task(id: course.id) {
            // Un cours arrivé en ligne après le build n'a pas sa couverture dans le bundle : le
            // catalogue donne le nom de l'objet, le bucket `course-images` l'image.
            guard image == nil, let slug = CatalogStore.shared.coverSlug(courseId: course.id) else { return }
            image = await CourseImageLoader.image(for: slug)
        }
        .accessibilityHidden(true)
    }
}

/// Ligne compacte d'une liste de cours : couverture 64, titre sur deux lignes, une ligne de
/// détail, et un ornement à droite (coche « lu », chevron…).
struct CompactCourseRow<Trailing: View>: View {
    let course: Course
    let meta: String
    var secondMeta: String? = nil
    let onTap: () -> Void
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                CourseCover(course: course, cornerRadius: 10)
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 3) {
                    Text(course.title.withoutInlineMarkup)
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(DS.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(meta)
                        .font(DS.sans(.footnote))
                        .foregroundStyle(DS.inkSecondary)
                        .lineLimit(1)
                    if let secondMeta {
                        Text(secondMeta)
                            .font(DS.sans(.caption))
                            .foregroundStyle(DS.inkSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 6)
                trailing()
            }
            .padding(.leading, 10)
            .padding(.trailing, 12)
            .padding(.vertical, 10)
            .homeCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }
}

extension CompactCourseRow where Trailing == EmptyView {
    init(course: Course, meta: String, secondMeta: String? = nil, onTap: @escaping () -> Void) {
        self.course = course
        self.meta = meta
        self.secondMeta = secondMeta
        self.onTap = onTap
        self.trailing = { EmptyView() }
    }
}

/// Disque vert plein avec une coche blanche : « lu ».
struct ReadCheck: View {
    var body: some View {
        // La coche se dessine à l'apparition de la ligne.
        DSCheckBadge(size: 22)
            .frame(width: 22, height: 22)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(AppLocalizable.string("common.read", language: AppLanguage.currentPersisted())))
    }
}

// MARK: - Segments et titres

/// Sélecteur à pastilles : chaque segment est une pastille bleu pâle, l'active est bleue pleine
/// et glisse d'un segment à l'autre (« Populaires / Récents / Séries », « À lire / Lus / Aimés »).
struct SegmentedPills: View {
    let items: [String]
    @Binding var selection: Int
    /// Un point bleu sur un segment : quelque chose de nouveau derrière.
    var dotOn: Int? = nil

    @Namespace private var pill
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                segment(index: index, title: item)
            }
        }
    }

    private func segment(index: Int, title: String) -> some View {
        let selected: Bool = selection == index
        return Button {
            guard selection != index else { return }
            Haptics.select()
            if reduceMotion {
                selection = index
            } else {
                withAnimation(DS.Motion.snappy) { selection = index }
            }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(selected ? Color.white : DS.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if dotOn == index, !selected {
                    Circle().fill(DS.accent).frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DS.accentTint)
                    if selected {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(DS.accent)
                            .matchedGeometryEffect(id: "pill", in: pill)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

/// Titre de section des nouveaux écrans (graisse moyenne), avec un complément gris (« · 3 »).
struct NewGenSectionTitle: View {
    let text: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text)
                .font(DS.title(.headline, .semibold))
                .foregroundStyle(DS.ink)
            if let trailing {
                Text(trailing)
                    .font(DS.title(.headline, .semibold))
                    .foregroundStyle(DS.inkSecondary)
            }
            Spacer(minLength: 0)
        }
    }
}

/// Bouton rond blanc (retour, fermer, partager) des nouveaux écrans.
struct RoundIconButton: View {
    let systemImage: String
    var size: CGFloat = 44
    var accessibilityLabel: String? = nil
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DS.ink)
                .frame(width: size, height: size)
                .background(Circle().fill(DS.surface))
                .overlay(Circle().strokeBorder(DS.hairline, lineWidth: 1.5))
                .contentShape(Circle())
        }
        .buttonStyle(PressableStyle(scale: 0.92))
        .accessibilityLabel(Text(accessibilityLabel ?? ""))
    }
}

// MARK: - Formats

enum NewGenFormat {
    /// « 7 min » dans la langue de l'app.
    static func minutes(_ minutes: Int, language: AppLanguage = AppLanguage.currentPersisted()) -> String {
        String(format: AppLocalizable.string("common.minutesShort", language: language), minutes)
    }

    /// « section 3 sur 5 ».
    static func section(_ index: Int, of count: Int, language: AppLanguage = AppLanguage.currentPersisted()) -> String {
        String(format: AppLocalizable.string("common.sectionOf", language: language), index, count)
    }

    /// Jour et mois courts dans la langue de l'app : « 30 nov. ».
    static func shortDay(_ date: Date, language: AppLanguage = AppLanguage.currentPersisted()) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.foundationLocale
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter.string(from: date)
    }

    /// Jour et mois longs : « 30 novembre ».
    static func longDay(_ date: Date, language: AppLanguage = AppLanguage.currentPersisted()) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.foundationLocale
        formatter.setLocalizedDateFormatFromTemplate("d MMMM")
        return formatter.string(from: date)
    }

    /// « 6 h » ou « 45 min » de lecture cumulée.
    static func readingTime(seconds: Int, language: AppLanguage = AppLanguage.currentPersisted()) -> String {
        let hours = seconds / 3_600
        if hours >= 1 {
            return String(format: AppLocalizable.string("common.hoursShort", language: language), hours)
        }
        return minutes(max(0, seconds / 60), language: language)
    }
}

// MARK: - Le cœur animé

extension DS {
    /// Le rose des cœurs allumés (fil, fiche, fin de cours).
    static var liked: Color { Color(red: 0.839, green: 0.200, blue: 0.424) }
}

/// Le cœur d'un bouton « j'aime » : il rebondit quand il s'allume et lâche un éclat de petites
/// particules. `burst` est incrémenté par le parent à chaque nouveau « j'aime » pour rejouer
/// l'éclat (jamais au retrait).
struct LikeHeartIcon: View {
    let liked: Bool
    let burst: Int
    var size: CGFloat = 16
    var idleTint: Color = DS.inkSecondary

    @State private var scale: CGFloat = 1
    @State private var burstProgress: CGFloat = 0

    var body: some View {
        Image(systemName: liked ? "heart.fill" : "heart")
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(liked ? DS.liked : idleTint)
            .contentTransition(.symbolEffect(.replace))
            .scaleEffect(scale)
            .background {
                HeartBurst(progress: burstProgress)
                    .frame(width: size * 3.4, height: size * 3.4)
            }
            .onChange(of: burst) { _, _ in play() }
    }

    private func play() {
        burstProgress = 0
        withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) { scale = 1.5 }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(0.14)) { scale = 1 }
        withAnimation(.easeOut(duration: 0.6)) { burstProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { burstProgress = 0 }
        }
    }
}

/// Huit particules qui partent du centre, rose et or en alternance, et s'éteignent en route.
/// `progress` va de 0 (rien n'est visible) à 1 (éclat terminé).
struct HeartBurst: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) / 2
            let travel = 0.25 + 0.75 * progress
            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    let angle = Double(index) / 8 * 2 * .pi
                    Circle()
                        .fill(index.isMultiple(of: 2) ? DS.liked : DS.warm)
                        .frame(width: 5, height: 5)
                        .scaleEffect(1 - 0.6 * progress)
                        .offset(x: cos(angle) * radius * travel, y: sin(angle) * radius * travel)
                        .opacity(progress == 0 ? 0 : Double(1 - progress))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
    }
}

/// Le grand cœur blanc du double-tap, au centre de la carte : il surgit, puis s'efface.
struct BigHeartOverlay: View {
    let trigger: Int

    @State private var visible = false
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 96, weight: .bold))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.28), radius: 14, y: 4)
            .scaleEffect(scale)
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onChange(of: trigger) { _, _ in
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) { scale = 0.5 }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                    visible = true
                    scale = 1.1
                }
                withAnimation(.easeIn(duration: 0.3).delay(0.55)) {
                    visible = false
                    scale = 1.3
                }
            }
    }
}
