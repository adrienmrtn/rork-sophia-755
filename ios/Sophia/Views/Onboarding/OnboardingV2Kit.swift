import SwiftUI

/// Design tokens et composants partagés du nouvel onboarding (V2).
///
/// Direction artistique « Elevate arrondi » : fond blanc, cartes bordées, un seul bleu
/// d'accent. Tout s'appuie sur le design system `DS` et les briques d'`ElevateKit`.
enum OV2 {
    static let bg = DS.canvas
    static let ink = DS.ink
    static let inkSecondary = DS.inkSecondary
    static let inkTertiary = DS.inkTertiary
    static let accent = DS.accent
    static let accentSoft = DS.accentSoft
    static let surface = DS.surface
    static let hairline = DS.hairline

    /// Ambre des étoiles et des éléments d'accent chaleureux.
    static let warm = DS.warm
    static let danger = DS.danger
    static let success = DS.success
    /// Rose des mots mis en avant par `OV2Markup.highlighted` (pages qui le demandent encore).
    static let pink = Color(red: 0.95, green: 0.33, blue: 0.56)

    /// Largeur maximale du contenu d'un écran d'onboarding ou d'un paywall.
    ///
    /// Les mises en page sont une colonne unique, dessinée pour un iPhone. Étirées sur un
    /// iPad en paysage, elles cessent de ressembler au design et le bouton finit hors écran.
    /// Sur iPhone, la borne est plus large que l'écran et ne change donc rien.
    static let readableWidth: CGFloat = 440

    /// Largeur de la barre (progression ou segments) centrée dans l'en-tête.
    static let headerBarWidth: CGFloat = 200
    /// Hauteur de la rangée d'en-tête (flèche retour + barre).
    static let headerHeight: CGFloat = 44
}

// MARK: - Transitions entre écrans

/// Modifieur d'état pour l'ancienne transition V2 : léger décalage vertical + opacité.
private struct OV2Shift: ViewModifier {
    let y: CGFloat
    let opacity: Double
    func body(content: Content) -> some View {
        content.offset(y: y).opacity(opacity)
    }
}

/// Modifieur d'état de la transition horizontale : décalage en x + opacité.
private struct OV2SlideState: ViewModifier {
    let x: CGFloat
    let opacity: Double
    func body(content: Content) -> some View {
        content.offset(x: x).opacity(opacity)
    }
}

extension AnyTransition {
    /// Entrée depuis le haut, sortie vers le bas — fondu + glissement léger. Encore utilisée
    /// hors de l'onboarding principal.
    static var ov2: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: OV2Shift(y: -40, opacity: 0),
                identity: OV2Shift(y: 0, opacity: 1)
            ),
            removal: .modifier(
                active: OV2Shift(y: 44, opacity: 0),
                identity: OV2Shift(y: 0, opacity: 1)
            )
        )
    }

    /// Glissement horizontal + fondu entre deux écrans de l'onboarding : le nouvel écran
    /// arrive du côté de la lecture quand on avance, de l'autre quand on revient.
    ///
    /// - Parameters:
    ///   - forward: `true` quand on avance dans le déroulé.
    ///   - mirrored: `true` pour une langue qui s'écrit de droite à gauche.
    ///   - distance: course du glissement ; 0 donne un simple fondu (« Réduire les animations »).
    static func ov2Slide(forward: Bool, mirrored: Bool = false, distance: CGFloat = 64) -> AnyTransition {
        let sign: CGFloat = (forward != mirrored) ? 1 : -1
        return .asymmetric(
            insertion: .modifier(
                active: OV2SlideState(x: sign * distance, opacity: 0),
                identity: OV2SlideState(x: 0, opacity: 1)
            ),
            removal: .modifier(
                active: OV2SlideState(x: -sign * distance, opacity: 0),
                identity: OV2SlideState(x: 0, opacity: 1)
            )
        )
    }
}

// MARK: - Bouton primaire V2

/// Évite de doubler la vibration du CTA par celle du changement d'écran : le coordinateur
/// consulte `justConfirmed` avant de vibrer à son tour.
enum OV2HapticGate {
    private static var lastConfirm: Date = .distantPast

    static func markConfirm() {
        lastConfirm = Date()
    }

    /// `true` pendant le quart de seconde qui suit l'appui sur un `OnboardingV2Button`.
    static var justConfirmed: Bool {
        Date().timeIntervalSince(lastConfirm) < 0.25
    }
}

/// Pression élastique du CTA, sans vibration propre (le bouton vibre une seule fois, à
/// l'action).
private struct OV2CTAPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(DS.Motion.press, value: configuration.isPressed)
    }
}

/// CTA plein « Elevate arrondi » : rectangle arrondi (16 pt) bleu, texte blanc, pression
/// élastique et une vibration franche à l'action.
struct OnboardingV2Button: View {
    let title: String
    var enabled: Bool = true
    /// Marge sous le bouton ; les paywalls la réduisent pour coller la note de prix.
    var bottomPadding: CGFloat = 20
    let action: () -> Void

    var body: some View {
        Button {
            guard enabled else { return }
            OV2HapticGate.markConfirm()
            Haptics.confirm()
            action()
        } label: {
            Text(title)
                .font(DS.sans(.callout, .semibold))
                .tracking(0.4)
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .frame(minHeight: 54)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                        .fill(enabled ? OV2.accent : OV2.accent.opacity(0.35))
                )
                .animation(DS.Motion.snappy, value: enabled)
        }
        .buttonStyle(OV2CTAPressStyle())
        .disabled(!enabled)
        .padding(.horizontal, 24)
        .padding(.bottom, bottomPadding)
    }
}

// MARK: - En-tête (flèche retour + barre centrée)

/// Flèche retour de l'en-tête : zone tactile de 44 pt, pression élastique et vibration douce.
struct OnboardingV2BackButton: View {
    /// Libellé lu par VoiceOver (« Retour »).
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.backward")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(OV2.ink)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle(scale: 0.88))
        .accessibilityLabel(Text(label))
    }
}

/// En-tête commun de l'onboarding : la flèche retour à gauche et, centré, ce que l'écran
/// montre de sa progression (rien, une barre de 200 pt, les segments du carrousel).
///
/// Posé par le coordinateur avec `safeAreaInset(edge: .top)` : les écrans se décalent sous
/// lui sans rien savoir de sa présence.
struct OnboardingV2Header<Center: View>: View {
    var showsBack: Bool = true
    let backLabel: String
    let onBack: () -> Void
    @ViewBuilder let center: () -> Center

    var body: some View {
        ZStack {
            center()
                .frame(width: OV2.headerBarWidth)

            HStack(spacing: 0) {
                if showsBack {
                    OnboardingV2BackButton(label: backLabel, action: onBack)
                        .transition(.opacity.combined(with: .scale(scale: 0.7)))
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: OV2.headerHeight)
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .frame(maxWidth: OV2.readableWidth)
        .frame(maxWidth: .infinity)
        .background(OV2.bg.ignoresSafeArea(edges: .top))
    }
}

/// Barre à segments du carrousel de présentation : les pages passées sont pleines, le
/// segment courant se remplit pendant la durée d'affichage de la page.
struct OnboardingV2StorySegments: View {
    let count: Int
    let current: Int
    /// Instant où la page courante est apparue.
    let startedAt: Date
    var duration: TimeInterval = 5
    /// `false` quand la page ne défile pas seule : son segment est alors montré plein.
    var isRunning: Bool = true
    var height: CGFloat = 5

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isRunning)) { context in
            let fraction: Double = isRunning ? progress(at: context.date) : 1
            HStack(spacing: 5) {
                ForEach(0..<max(count, 1), id: \.self) { index in
                    segment(fill: fill(for: index, fraction: fraction))
                }
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityValue(Text("\(min(current + 1, count)) / \(count)"))
    }

    private func progress(at date: Date) -> Double {
        guard duration > 0 else { return 1 }
        let elapsed: TimeInterval = date.timeIntervalSince(startedAt)
        return min(max(elapsed / duration, 0), 1)
    }

    private func fill(for index: Int, fraction: Double) -> Double {
        if index < current { return 1 }
        if index == current { return fraction }
        return 0
    }

    private func segment(fill: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(DS.accentTint)
                Capsule()
                    .fill(DS.accent)
                    .frame(width: geo.size.width * CGFloat(fill))
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
    }
}

// MARK: - Mots mis en avant

/// Les textes marquent entre `**` les mots à mettre en avant : « Get **smarter** with… ».
/// Le marqueur voyage avec la traduction : chaque langue met en avant ses propres mots, sans
/// rien changer au code.
enum OV2Markup {
    /// Mots marqués dans une couleur (rose par défaut), sans changer la graisse.
    static func highlighted(_ source: String, color: Color = OV2.pink) -> Text {
        var result = Text(verbatim: "")
        for (index, part) in source.components(separatedBy: "**").enumerated() where !part.isEmpty {
            let piece = Text(verbatim: part)
            // Les morceaux impairs sont ceux entre deux marqueurs.
            result = result + (index.isMultiple(of: 2) ? piece : piece.foregroundStyle(color))
        }
        return result
    }

    /// Mots marqués en gras et en bleu d'accent : le titre du style « Elevate arrondi ». Le
    /// `Text` rendu accepte `lineLimit` et `minimumScaleFactor`, contrairement à
    /// `DSHighlightTitle` qui impose sa hauteur idéale.
    static func elevate(_ source: String, weight: Font.Weight = .bold, color: Color = DS.accent) -> Text {
        var result = Text(verbatim: "")
        for (index, part) in source.components(separatedBy: "**").enumerated() where !part.isEmpty {
            let piece = Text(verbatim: part)
            if index.isMultiple(of: 2) {
                result = result + piece
            } else {
                result = result + piece.fontWeight(weight).foregroundStyle(color)
            }
        }
        return result
    }

    /// Le texte sans ses marqueurs, pour VoiceOver et les mesures.
    static func plain(_ source: String) -> String {
        source.replacingOccurrences(of: "**", with: "")
    }
}

// MARK: - Contenu scrollable + CTA épinglé

/// Contenu vertical qui devient scrollable dès qu'il dépasse l'écran, avec un CTA
/// **toujours** visible en bas.
///
/// Les écrans de l'OB empilent des éléments de hauteur fixe (badges, cartes, chips). Sur un
/// petit iPhone, avec une grande taille de texte (Dynamic Type) ou une traduction longue, la
/// pile dépasse la hauteur disponible : le `VStack` déborde, le CTA se retrouve sous le bord
/// de l'écran et l'utilisateur est **bloqué**. Ce conteneur évite ce cas : le contenu défile,
/// le CTA reste épinglé.
struct OV2ScrollableContent<Content: View, Footer: View>: View {
    private let content: () -> Content
    private let footer: () -> Footer

    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.content = content
        self.footer = footer
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                ScrollView(.vertical) {
                    content()
                        .frame(maxWidth: .infinity)
                        // Contenu calé en haut quand il tient (mise en page d'origine),
                        // scrollable dès qu'il dépasse.
                        .frame(minHeight: proxy.size.height, alignment: .top)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }

            footer()
        }
    }
}

// MARK: - Carte bordée

private struct OV2CardModifier: ViewModifier {
    let border: Color
    let fill: Color
    let cornerRadius: CGFloat
    let lip: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(border, lineWidth: 1.5)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(border)
                    .offset(y: lip)
            )
    }
}

extension View {
    /// Fond de carte du style (bordure 1,5 pt, petit rebord bas, pas d'ombre) sans padding ni
    /// largeur imposée, à la couleur de bordure libre : `dsCard()` pour les cartes des
    /// illustrations, qui règlent elles-mêmes leurs marges.
    func ov2Card(
        border: Color = DS.hairline,
        fill: Color = DS.surface,
        cornerRadius: CGFloat = DS.Radius.card,
        lip: CGFloat = 1
    ) -> some View {
        modifier(OV2CardModifier(border: border, fill: fill, cornerRadius: cornerRadius, lip: lip))
    }
}

// MARK: - Illustration ajustée à la hauteur disponible

/// Montre `content` à sa taille naturelle quand elle tient dans la hauteur reçue, et le
/// réduit d'un seul bloc sinon (petit iPhone, grande taille de texte). Les illustrations
/// des pages de présentation sont des maquettes d'interface à dimensions fixes : les
/// réduire garde leurs proportions, là où les comprimer les déformerait.
struct OnboardingV2FitHeight<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @State private var naturalHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let scale: CGFloat = fitScale(available: geo.size.height)
            content()
                .frame(width: geo.size.width)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    naturalHeight = height
                }
                .scaleEffect(scale, anchor: .center)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
    }

    private func fitScale(available: CGFloat) -> CGFloat {
        guard naturalHeight > 0, available > 0 else { return 1 }
        return min(1, max(0.5, available / naturalHeight))
    }
}

// MARK: - Points de progression

struct OnboardingV2ProgressDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? OV2.accent : OV2.accent.opacity(0.15))
                    .frame(width: i == current ? 22 : 7, height: 6)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: current)
            }
        }
    }
}

// MARK: - Reveal helper

/// Petit modifieur : anime `appeared` à l'apparition après un délai, pour un reveal doux
/// une fois la transition de page terminée.
struct OnboardingV2Reveal: ViewModifier {
    let delay: TimeInterval
    @State private var appeared = false
    var yOffset: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : yOffset)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                        appeared = true
                    }
                }
            }
    }
}

extension View {
    func ov2Reveal(delay: TimeInterval = 0.12, yOffset: CGFloat = 16) -> some View {
        modifier(OnboardingV2Reveal(delay: delay, yOffset: yOffset))
    }

    /// Fond plein cadre V2, avec une largeur de contenu bornée sur grand écran.
    ///
    /// L'app est publiée pour iPad et Apple teste sur iPad pendant la validation. En paysage,
    /// la grille des années s'étirait sur toute la largeur jusqu'à pousser le bouton à ~450pt
    /// sous l'écran : l'onboarding devenait infinissable. Le contenu est borné et centré, le
    /// fond reste plein cadre.
    func ov2Background() -> some View {
        frame(maxWidth: OV2.readableWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(OV2.bg.ignoresSafeArea())
    }

    /// Même bornage, pour les écrans qui peignent leur propre fond (paywalls en dégradé).
    func ov2ReadableWidth() -> some View {
        frame(maxWidth: OV2.readableWidth)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Lauriers (preuve sociale)

/// Deux lauriers autour d'un contenu (note, nombre d'utilisateurs…) : le motif de preuve
/// sociale repris sur les pages avis, preuve sociale, chargement et atouts.
struct OnboardingV2LaurelBadge<Content: View>: View {
    var size: CGFloat = 54
    var tint: Color = OV2.warm
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "laurel.leading")
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(tint)
            content()
            Image(systemName: "laurel.trailing")
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(tint)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Cinq étoiles, la note « 4,8 » au séparateur décimal de la langue, et une légende.
struct OnboardingV2RatingStack: View {
    @Environment(LanguageManager.self) private var languageManager
    let caption: String
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 2 : 3) {
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: compact ? 12 : 14))
                        .foregroundStyle(OV2.warm)
                }
            }
            Text((4.8).formatted(.number.precision(.fractionLength(1)).locale(languageManager.locale)))
                .font(DS.title(compact ? .title2 : .largeTitle, .heavy))
                .foregroundStyle(OV2.ink)
            Text(caption)
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(OV2.inkSecondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Lauriers « papier » (style Elevate)

/// Une branche de laurier dessinée feuille à feuille (sept feuilles en arc), dans le gris
/// bleuté des maquettes. `mirrored` donne la branche de droite.
struct OnboardingV2LaurelBranch: View {
    var height: CGFloat = 60
    var tint: Color = Color(red: 0.718, green: 0.753, blue: 0.812)
    var mirrored: Bool = false

    var body: some View {
        OnboardingV2LaurelShape()
            .fill(tint)
            .frame(width: height * 0.5, height: height)
            .scaleEffect(x: mirrored ? -1 : 1, y: 1)
            .accessibilityHidden(true)
    }
}

/// Les sept feuilles de la branche gauche, dans un repère de 32 × 64 (celui de la maquette).
private struct OnboardingV2LaurelShape: Shape {
    private struct Leaf {
        let x: CGFloat
        let y: CGFloat
        let degrees: CGFloat
    }

    private static let leaves: [Leaf] = [
        Leaf(x: 23.0, y: 8.4, degrees: 10),
        Leaf(x: 15.0, y: 14.3, degrees: -12),
        Leaf(x: 9.7, y: 22.7, degrees: -34),
        Leaf(x: 8.0, y: 32.5, degrees: -56),
        Leaf(x: 10.1, y: 42.2, degrees: -78),
        Leaf(x: 15.6, y: 50.4, degrees: -100),
        Leaf(x: 23.8, y: 55.9, degrees: -122),
    ]

    func path(in rect: CGRect) -> Path {
        let sx: CGFloat = rect.width / 32
        let sy: CGFloat = rect.height / 64
        var path = Path()
        for leaf in Self.leaves {
            let ellipse = CGRect(x: -3.4, y: -7.5, width: 6.8, height: 15)
            // Feuille tournée autour de son centre, placée dans le repère 32 × 64 (dont
            // l'origine en x est décalée de 2, comme le `viewBox` de la maquette), puis mise
            // à l'échelle du cadre.
            let transform = CGAffineTransform(scaleX: sx, y: sy)
                .translatedBy(x: leaf.x - 2, y: leaf.y)
                .rotated(by: leaf.degrees * .pi / 180)
            path.addPath(Path(ellipseIn: ellipse).applying(transform))
        }
        return path.offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

/// Deux branches de laurier autour d'un contenu, version « Elevate ».
struct OnboardingV2PaperLaurels<Content: View>: View {
    var height: CGFloat = 60
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 4) {
            OnboardingV2LaurelBranch(height: height)
            content()
                .padding(.horizontal, 2)
            OnboardingV2LaurelBranch(height: height, mirrored: true)
        }
        .accessibilityElement(children: .combine)
    }
}
