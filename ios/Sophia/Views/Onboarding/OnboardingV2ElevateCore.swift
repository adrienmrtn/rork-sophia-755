import SwiftUI
import UIKit

/// Briques partagées par le cœur de l'onboarding (prénom → choix des cours) dans le style
/// « Elevate arrondi » : titres, illustration ronde, rangée d'option, case à cocher, conteneur
/// de page. Tout ce qui est commun à l'app entière reste dans `ElevateKit` ; ne vit ici que ce
/// qui n'a de sens que pour ces écrans.

// MARK: - Mesures

enum OV2CoreMetrics {
    /// Marge entre l'en-tête du parcours (flèche retour + barre de progression, posé par le
    /// coordinateur) et le titre de la page.
    static let topInset: CGFloat = 20
    /// Marge latérale des pages.
    static let sideInset: CGFloat = 24

    /// Taille de l'illustration ronde selon la place réellement libre : pleine taille quand
    /// tout tient, réduite quand l'écran est court ou que le clavier est sorti, absente (0)
    /// quand il ne resterait qu'une vignette. `reserved` est la hauteur du reste de la page.
    static func artSize(base: CGFloat, available: CGFloat, reserved: CGFloat) -> CGFloat {
        let room = available - reserved
        if room >= base { return base }
        return room >= 64 ? room : 0
    }

    /// Style de texte des phrases en très grand (« Personnalisons ton contenu », « transforme
    /// ce temps en… ») : le plus grand qui laisse tenir le mot le plus long sur une ligne de
    /// `width`, taille de texte de l'utilisateur comprise. Les mots y sont posés un par un,
    /// à largeur fixe : un mot plus large que l'écran serait coupé.
    static func sentenceStyle(words: [String], width: CGFloat) -> Font.TextStyle {
        let longest: Int = words.map(\.count).max() ?? 0
        let candidates: [(style: Font.TextStyle, metrics: UIFont.TextStyle, size: CGFloat)] = [
            (.largeTitle, .largeTitle, 34),
            (.title, .title1, 28),
            (.title2, .title2, 22),
        ]
        for candidate in candidates {
            let scaled: CGFloat = UIFontMetrics(forTextStyle: candidate.metrics).scaledValue(for: candidate.size)
            // Largeur moyenne d'un caractère en graisse forte : environ 0,64 em.
            if CGFloat(longest) * 0.64 * scaled <= width { return candidate.style }
        }
        return .title3
    }
}

// MARK: - Mouvement

/// Animations du début de l'onboarding : posées, sans rebond. Les ressorts de `DS.Motion`
/// (`snappy`, `pop`) dépassent leur cible avant d'y revenir ; ici tout arrive à sa place d'un
/// seul geste.
enum OV2CoreMotion {
    /// Changement d'état (sélection, bascule, compteur) : court, en décélération.
    static let select = Animation.easeOut(duration: 0.22)
    /// Arrivée d'un élément (carte, portrait, illustration) : ressort à amortissement critique.
    static let settle = Animation.spring(response: 0.45, dampingFraction: 1)
    /// Arrivée d'un bloc de contenu : plus ample, toujours sans dépassement.
    static let reveal = Animation.spring(response: 0.55, dampingFraction: 1)
}

/// Apparition d'une illustration : un léger agrandissement et un fondu, sans rebond (le
/// pendant calme de `dsPopIn`).
private struct OV2CoreSoftInModifier: ViewModifier {
    let delay: Double
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(shown || reduceMotion ? 1 : 0.86)
            .opacity(shown ? 1 : 0)
            .onAppear {
                guard !shown else { return }
                withAnimation(OV2CoreMotion.settle.delay(delay)) { shown = true }
            }
    }
}

extension View {
    /// Apparition calme d'une illustration, après `delay` secondes.
    func ov2CoreSoftIn(delay: Double = 0) -> some View {
        modifier(OV2CoreSoftInModifier(delay: delay))
    }

    /// Pour un bouton qui ne doit arriver qu'à un moment donné (fin d'une animation, délai) :
    /// sa place est réservée dès le départ, pour que rien ne saute, mais tant que `shown` est
    /// faux il est invisible, insensible au toucher et ignoré de VoiceOver.
    func ov2CoreAppears(_ shown: Bool) -> some View {
        opacity(shown ? 1 : 0)
            .allowsHitTesting(shown)
            .accessibilityHidden(!shown)
            .animation(.easeOut(duration: 0.3), value: shown)
    }
}

// MARK: - Textes

/// Accès aux textes de la table `elevateOnboardingCore`.
enum OV2CoreText {
    /// Texte nouveau de la zone : la langue courante, sinon l'anglais.
    static func string(_ key: String, language: AppLanguage) -> String {
        guard let entry = AppLocalizableAdditions.elevateOnboardingCore[key] else { return key }
        return entry[language.rawValue] ?? entry["en"] ?? key
    }

    /// Le titre existant `titleKey`, avec son passage fort entouré de `**` (rendu en gras bleu
    /// par `OV2CoreHighlightTitle`). Le passage vient de la table, langue par langue ; s'il manque
    /// ou ne figure plus dans le titre, le titre revient tel quel, sans passage surligné.
    static func marked(_ titleKey: String, highlightKey: String, language: AppLanguage) -> String {
        let title = AppLocalizable.string(titleKey, language: language)
        return marked(text: title, highlightKey: highlightKey, language: language)
    }

    static func marked(text: String, highlightKey: String, language: AppLanguage) -> String {
        guard !text.contains("**"),
              let passage = AppLocalizableAdditions.elevateOnboardingCore[highlightKey]?[language.rawValue],
              !passage.isEmpty,
              let range = text.range(of: passage)
        else { return text }
        return text.replacingCharacters(in: range, with: "**" + passage + "**")
    }

    /// Le texte sans la ponctuation finale donnée (« : » d'un titre qui n'introduit plus une
    /// liste, point final d'une phrase posée dans une pastille).
    static func trimmingTrailing(_ characters: String, from text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        while let last = result.last, characters.contains(last) || last.isWhitespace {
            result.removeLast()
        }
        return result
    }
}

// MARK: - Conteneur de page

/// Contenu défilant + pied épinglé, comme `OV2ScrollableContent`, mais qui donne au contenu la
/// hauteur réellement disponible : les pages s'en servent pour réduire leur illustration sur
/// un petit écran (ou clavier sorti) plutôt que de faire défiler, et pour se centrer.
struct OV2CorePage<Content: View, Footer: View>: View {
    private let content: (CGFloat) -> Content
    private let footer: () -> Footer

    init(
        @ViewBuilder content: @escaping (_ availableHeight: CGFloat) -> Content,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.content = content
        self.footer = footer
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                ScrollView(.vertical) {
                    content(proxy.size.height)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: proxy.size.height, alignment: .top)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }

            footer()
        }
    }
}

// MARK: - Titres

/// Titre centré d'une page question (graisse moyenne) et son sous-titre gris.
struct OV2CoreQuestionTitle: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(DS.title(.title2, .medium))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(DS.sans(.subheadline, .regular))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, OV2CoreMetrics.sideInset)
    }
}

/// Titre à passage fort : graisse légère, et le passage entre `**` en gras bleu. Même principe
/// que `DSHighlightTitle`, avec une taille libre (les pages en veulent 25 à 26 pt, entre deux
/// styles de texte) et un alignement à gauche par défaut.
struct OV2CoreHighlightTitle: View {
    let text: String
    var size: CGFloat = 25
    var alignment: TextAlignment = .leading

    var body: some View {
        styled
            .foregroundStyle(DS.ink)
            .multilineTextAlignment(alignment)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
            .accessibilityAddTraits(.isHeader)
    }

    private var styled: Text {
        let parts: [String] = text.components(separatedBy: "**")
        let regular: Font = Font.jakarta(size: size, weight: .regular)
        let strong: Font = Font.jakarta(size: size, weight: .bold)
        var result = Text("")
        for (index, part) in parts.enumerated() where !part.isEmpty {
            if index % 2 == 1 {
                result = result + Text(part).font(strong).foregroundColor(DS.accent)
            } else {
                result = result + Text(part).font(regular)
            }
        }
        return result
    }
}

/// « Appuie pour continuer », sur les pages sans bouton.
struct OV2CoreTapHint: View {
    let text: String
    var visible: Bool = true

    var body: some View {
        Text(text)
            .font(DS.sans(.subheadline, .semibold))
            .foregroundStyle(DS.inkSecondary)
            .multilineTextAlignment(.center)
            .opacity(visible ? 1 : 0)
            .padding(.horizontal, OV2CoreMetrics.sideInset)
    }
}

// MARK: - Illustrations

/// Illustration ronde d'une page. Chacune a une image dédiée dans le catalogue d'images
/// (`onb_art_*`, reprises des illustrations du site) ou une affiche déjà présente dans l'app ;
/// si l'image dédiée venait à manquer, une affiche existante la remplace.
struct OV2CoreIllustration: View {
    enum Art {
        case reader, mirror, growth, nightBook, trophy, path, phone

        var assetName: String {
            switch self {
            case .reader: "onb_art_reader"
            case .mirror: "onb_art_mirror"
            case .growth: "onb_art_growth"
            case .nightBook: "onb_art_nightbook"
            case .trophy: "duel_trophy"
            case .path: "path_poster"
            case .phone: "antiscroll_poster"
            }
        }

        /// Image de l'app affichée si `assetName` n'est pas dans le catalogue.
        var fallbackAssetName: String {
            switch self {
            case .reader: "progress_hero"
            case .mirror: "creator_poster"
            case .growth: "progress_poster"
            case .nightBook: "badge_subject_litterature"
            case .trophy: "progress_poster"
            case .path: "progress_hero"
            case .phone: "training_poster"
            }
        }
    }

    let art: Art
    var size: CGFloat = 116

    private var image: UIImage? {
        UIImage(named: art.assetName) ?? UIImage(named: art.fallbackAssetName)
    }

    var body: some View {
        ZStack {
            Circle().fill(DS.accentTint)
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Vignette ronde d'une matière : l'illustration du badge de la matière, sinon son emoji sur
/// un fond à sa couleur.
struct OV2CoreSubjectBadge: View {
    let subject: Subject
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            Circle().fill(subject.color.opacity(0.18))
            if let image = UIImage(named: "badge_subject_\(subject.storageKey)") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Text(subject.emoji)
                    .font(.system(size: size * 0.55))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Carrousel d'avatars

/// Tous les avatars de l'app sur une ligne qui défile et s'aimante : celui du centre est
/// l'avatar choisi, grand et cerclé de bleu ; ses voisins sont réduits et estompés. Même
/// principe que le carrousel de la page « Ton profil » (`OnboardingV2Account`), sans rebond.
struct OV2CoreAvatarCarousel: View {
    @Binding var avatarId: String
    /// Diamètre de l'avatar choisi, au centre.
    var avatarSize: CGFloat = 104

    private static let spacing: CGFloat = 18
    private static let neighbourScale: CGFloat = 0.615

    /// Largeur d'une case, plus étroite que l'avatar centré : les voisins, réduits, viennent
    /// se ranger tout près de lui.
    private var slot: CGFloat { avatarSize * 0.81 }

    /// L'avatar centré est l'avatar choisi : le défilement écrit dans `avatarId`, et changer
    /// `avatarId` (toucher un voisin) fait défiler jusqu'à lui.
    private var centered: Binding<String?> {
        Binding<String?>(
            get: { avatarId },
            set: { newValue in
                if let newValue, newValue != avatarId { avatarId = newValue }
            }
        )
    }

    var body: some View {
        GeometryReader { geo in
            let margin: CGFloat = max(0, (geo.size.width - slot) / 2)
            ScrollView(.horizontal) {
                HStack(spacing: Self.spacing) {
                    ForEach(Array(Avatars.all.enumerated()), id: \.element) { index, id in
                        item(id, number: index + 1)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: centered, anchor: .center)
            .contentMargins(.horizontal, margin, for: .scrollContent)
        }
        .frame(height: avatarSize)
        .sensoryFeedback(.selection, trigger: avatarId)
    }

    private func item(_ id: String, number: Int) -> some View {
        let selected: Bool = avatarId == id
        return Button {
            withAnimation(OV2CoreMotion.select) {
                avatarId = id
            }
        } label: {
            AvatarCircle(avatarId: id, initial: "", size: avatarSize)
                .overlay(
                    Circle()
                        .strokeBorder(DS.accent, lineWidth: 4)
                        .opacity(selected ? 1 : 0)
                )
                .scaleEffect(selected ? 1 : Self.neighbourScale)
                .opacity(selected ? 1 : 0.55)
                .animation(OV2CoreMotion.select, value: selected)
                .frame(width: slot, height: avatarSize)
        }
        .buttonStyle(.plain)
        .zIndex(selected ? 1 : 0)
        .accessibilityLabel(Text(verbatim: "Avatar \(number)"))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - Options

/// Case carrée d'une sélection multiple : la coche se dessine quand la case se remplit.
struct OV2CoreCheckSquare: View {
    let isOn: Bool
    var size: CGFloat = 22

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(isOn ? DS.accent : Color.clear)
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .strokeBorder(isOn ? DS.accent : DS.inkTertiary, lineWidth: 1.5)
            OV2CoreCheckMark()
                .trim(from: 0, to: isOn ? 1 : 0)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                .padding(size * 0.25)
        }
        .frame(width: size, height: size)
        .animation(OV2CoreMotion.select, value: isOn)
        .accessibilityHidden(true)
    }
}

private struct OV2CoreCheckMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.05))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.maxY - rect.height * 0.08))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.12))
        return path
    }
}

/// Une réponse parmi d'autres : pictogramme facultatif, libellé, et une case à droite pour les
/// sélections multiples. Le fond est la carte d'option du style (`dsOptionCard`), la vibration
/// celle d'un choix.
struct OV2CoreOptionRow<Leading: View>: View {
    private let label: String
    private let isSelected: Bool
    private let showsCheckbox: Bool
    private let minHeight: CGFloat
    private let action: () -> Void
    private let leading: Leading

    init(
        label: String,
        isSelected: Bool,
        showsCheckbox: Bool = false,
        minHeight: CGFloat = 52,
        action: @escaping () -> Void,
        @ViewBuilder leading: () -> Leading
    ) {
        self.label = label
        self.isSelected = isSelected
        self.showsCheckbox = showsCheckbox
        self.minHeight = minHeight
        self.action = action
        self.leading = leading()
    }

    var body: some View {
        Button {
            Haptics.select()
            action()
        } label: {
            HStack(spacing: 14) {
                leading
                Text(label)
                    .font(DS.sans(.callout, .semibold))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if showsCheckbox {
                    OV2CoreCheckSquare(isOn: isSelected)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minHeight: minHeight)
            .contentShape(Rectangle())
            .dsOptionCard(isSelected ? .selected : .idle)
        }
        .buttonStyle(PressableStyle(haptic: false))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension OV2CoreOptionRow where Leading == EmptyView {
    /// Rangée sans pictogramme.
    init(
        label: String,
        isSelected: Bool,
        showsCheckbox: Bool = false,
        minHeight: CGFloat = 52,
        action: @escaping () -> Void
    ) {
        self.init(
            label: label,
            isSelected: isSelected,
            showsCheckbox: showsCheckbox,
            minHeight: minHeight,
            action: action,
            leading: { EmptyView() }
        )
    }
}
