import SwiftUI

// Briques « Elevate arrondi » propres à l'accueil, à l'onglet Explorer et aux pages événement /
// créateur : le cadre de carte qui rogne son contenu (couvertures), les onglets soulignés du
// fil, le libellé de CTA posé dans une carte déjà cliquable, la petite pulsation au toucher et
// l'apparition pilotée par l'écran (pour les piles paresseuses, où `dsStagger` rejouerait).

// MARK: - Cadre de carte

/// Carte du style : fond blanc, contenu rogné au rayon, bordure nette de 1,5 pt et léger rebord
/// bas. Contrairement à `dsCard()`, n'ajoute ni padding ni largeur maximale : elle épouse la
/// taille de son contenu (cartes de carrousel à largeur fixe, cartes à couverture).
private struct HomeCardChrome: ViewModifier {
    let cornerRadius: CGFloat
    let fill: Color
    let border: Color

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(fill))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(border, lineWidth: 1.5)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(border)
                    .offset(y: 1)
            )
    }
}

extension View {
    /// Habille la vue en carte « Elevate arrondi » (voir `HomeCardChrome`).
    func homeCard(
        cornerRadius: CGFloat = DS.Radius.card,
        fill: Color = DS.surface,
        border: Color = DS.hairline
    ) -> some View {
        modifier(HomeCardChrome(cornerRadius: cornerRadius, fill: fill, border: border))
    }
}

// MARK: - Onglets soulignés

/// Les onglets du fil (« Pour toi » / « Abonnements ») : chacun prend la même largeur, sur
/// toute la ligne, et un trait bleu glisse sous l'onglet actif. Un point signale du nouveau
/// derrière un onglet qui n'est pas affiché.
struct HomeFeedTabs: View {
    let items: [String]
    @Binding var selection: Int
    /// Indice de l'onglet qui porte le point « nouveautés ».
    var dotOn: Int? = nil
    /// Ce que VoiceOver dit du point.
    var dotLabel: String? = nil

    @Namespace private var underline
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let height: CGFloat = 46

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                tab(index: index, title: item)
            }
        }
        .frame(height: Self.height)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DS.hairline).frame(height: 1)
        }
    }

    private func tab(index: Int, title: String) -> some View {
        let selected: Bool = selection == index
        let showsDot: Bool = dotOn == index && !selected
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
                    .font(DS.sans(.subheadline, selected ? .bold : .semibold))
                    .foregroundStyle(selected ? DS.ink : DS.inkTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                if showsDot {
                    Circle()
                        .fill(DS.accent)
                        .frame(width: 7, height: 7)
                        .accessibilityLabel(Text(dotLabel ?? ""))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Self.height)
            .overlay(alignment: .bottom) {
                if selected {
                    Capsule()
                        .fill(DS.accent)
                        .frame(width: 56, height: 3)
                        .matchedGeometryEffect(id: "underline", in: underline)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

// MARK: - CTA posé dans une carte

/// L'apparence du CTA bleu (54 pt, rayon 16) pour une carte entièrement cliquable : ce n'est pas
/// un bouton, c'est la carte qui reçoit le geste.
struct HomeCTALabel: View {
    let text: String
    /// Symbole après le texte (chevron) ; `leadingSystemImage` le place avant.
    var systemImage: String? = nil
    var leadingSystemImage: String? = nil

    var body: some View {
        HStack(spacing: 7) {
            if let leadingSystemImage {
                Image(systemName: leadingSystemImage)
                    .font(.system(size: 15, weight: .semibold))
            }
            Text(text)
                .font(DS.sans(.callout, .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .bold))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous).fill(DS.accent))
    }
}

// MARK: - Pulsation au toucher

/// Pression élastique pour une vue qui reçoit ses taps par un geste (pas par un `Button`) : à
/// chaque incrément de `trigger`, elle s'enfonce un instant puis revient avec un ressort.
private struct HomeTapPulse: ViewModifier {
    let trigger: Int
    let scale: CGFloat
    @State private var pressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? scale : 1)
            .onChange(of: trigger) { _, _ in
                guard !reduceMotion else { return }
                withAnimation(.easeOut(duration: 0.09)) { pressed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(DS.Motion.pop) { pressed = false }
                }
            }
    }
}

// MARK: - Apparition pilotée

/// Apparition en cascade dont l'état vit chez le parent : dans une pile paresseuse, l'élément
/// peut être détruit puis recréé au défilement sans rejouer son entrée.
private struct HomeReveal: ViewModifier {
    let shown: Bool
    let index: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 16)
            .animation(DS.Motion.reveal.delay(0.04 + Double(index) * 0.08), value: shown)
    }
}

extension View {
    /// Voir `HomeTapPulse`.
    func homeTapPulse(trigger: Int, scale: CGFloat = 0.975) -> some View {
        modifier(HomeTapPulse(trigger: trigger, scale: scale))
    }

    /// Voir `HomeReveal`. `index` décale l'entrée (0 d'abord, puis 1…).
    func homeReveal(_ shown: Bool, index: Int = 0) -> some View {
        modifier(HomeReveal(shown: shown, index: index))
    }
}
