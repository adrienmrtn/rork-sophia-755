import SwiftUI

/// Briques « Elevate arrondi » propres à la zone profil : progression, amis, badges, réglages
/// et compte. Tout ce qui est commun à toute l'app vit dans `ElevateKit` ; ici, seulement ce que
/// ces écrans partagent entre eux (identité du lecteur, titres de section, rangées, barres qui
/// se remplissent à l'apparition, compteurs qui respectent « Réduire les animations »).

// MARK: - Identité du lecteur

/// Les deux lignes d'identité qui ne viennent pas du compte : le titre tiré des centres
/// d'intérêt (« Amoureux de Littérature ») et le mois d'arrivée dans l'app.
enum ProfileIdentity {
    /// Le titre choisi à l'onboarding d'après la première matière cochée ; sinon le titre par défaut.
    static func rankTitle(languageManager: LanguageManager) -> String {
        let interests: Set<String> = OnboardingViewModel.userInterestKeys()
        let keys: [String] = Subject.allCases.map(\.storageKey).filter { interests.contains($0) }
        guard let first = keys.first else {
            return languageManager.text("onboarding.program.nickname.default")
        }
        return languageManager.text("onboarding.program.nickname.\(first)")
    }

    /// Le mois du premier cours ouvert, faute de date de création de compte ; `nil` tant
    /// qu'aucun cours n'a été ouvert (la ligne « membre depuis » est alors omise).
    static func memberSince(progressManager: ProgressManager, language: AppLanguage) -> String? {
        let starts: [String] = progressManager.progress.courseProgress.values.compactMap(\.startedAt).sorted()
        guard let first = starts.first, let date = Campaign.parseDay(String(first.prefix(10))) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = language.foundationLocale
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: date)
    }
}

// MARK: - Titres

/// Titre de section des écrans du profil (« Par matière », « Badges ») : graisse moyenne, avec
/// un complément gris facultatif (« · 2 », « 0/5 »).
struct ProfileSectionHeader<Trailing: View>: View {
    let title: String
    var detail: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .font(DS.title(.title3, .semibold))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let detail {
                Text(detail)
                    .font(DS.title(.title3, .semibold))
                    .foregroundStyle(DS.inkSecondary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            trailing()
        }
        .accessibilityAddTraits(.isHeader)
    }
}

extension ProfileSectionHeader where Trailing == EmptyView {
    init(title: String, detail: String? = nil) {
        self.title = title
        self.detail = detail
        self.trailing = { EmptyView() }
    }
}

/// Sur-titre de groupe des réglages (« COMPTE », « LANGUE ») : petites capitales espacées, grises.
struct ProfileGroupLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercasedInApp())
            .font(DS.sans(.caption, .heavy))
            .tracking(0.8)
            .foregroundStyle(DS.inkSecondary)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Lien de fin de titre (« Tout voir › », « Voir plus › ») : gras bleu, avec son chevron.
struct ProfileHeaderLink: View {
    let title: String
    var showsChevron: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Text(title)
                    .font(DS.sans(.subheadline, .bold))
                    .lineLimit(1)
                if showsChevron {
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 11, weight: .bold))
                }
            }
            .foregroundStyle(DS.accent)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }
}

// MARK: - Boutons ronds et rangées

/// Bouton rond blanc de 44 pt (fermer, retour, réglages) : bordure nette, pression élastique.
struct ProfileRoundButton: View {
    let systemImage: String
    var accessibilityLabel: String? = nil
    let action: () -> Void

    var body: some View {
        // Sans libellé fourni, VoiceOver garde celui du pictogramme (« Retour », « Fermer »).
        if let accessibilityLabel {
            button.accessibilityLabel(Text(accessibilityLabel))
        } else {
            button
        }
    }

    private var button: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(DS.surface))
                .overlay(Circle().strokeBorder(DS.hairline, lineWidth: 1.5))
                .contentShape(Circle())
        }
        .buttonStyle(.pressable)
    }
}

/// Filet entre deux rangées d'une même carte.
struct ProfileRowDivider: View {
    var leading: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(DS.hairline)
            .frame(height: 1)
            .padding(.leading, leading)
    }
}

/// Pression douce d'une rangée de liste : le fond se teinte et la rangée s'enfonce à peine,
/// avec la vibration légère du style. À poser sur les rangées d'une carte groupée.
struct ProfileRowPressStyle: ButtonStyle {
    var haptic: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? DS.accentTint.opacity(0.55) : Color.clear)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(DS.Motion.press, value: configuration.isPressed)
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: configuration.isPressed) { _, pressed in
                haptic && pressed
            }
    }
}

// MARK: - Onglets en pastilles

/// Onglets en pastilles de la maquette (« 7 jours · Tout », « À lire · Lus · Aimés ») : la
/// pastille active en bleu plein, les autres en bleu pâle. `fills` les étire sur la largeur.
struct ProfilePillTabs: View {
    let items: [String]
    let selectedIndex: Int
    var fills: Bool = false
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                pill(index: index, title: item)
            }
            if !fills {
                Spacer(minLength: 0)
            }
        }
    }

    private func pill(index: Int, title: String) -> some View {
        let selected: Bool = index == selectedIndex
        return Button {
            guard !selected else { return }
            Haptics.select()
            onSelect(index)
        } label: {
            Text(title)
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(selected ? Color.white : DS.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 14)
                .frame(maxWidth: fills ? .infinity : nil)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(selected ? DS.accent : DS.accentTint)
                )
                .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(PressableStyle(haptic: false))
        .animation(DS.Motion.snappy, value: selected)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

// MARK: - Barre qui se remplit

/// Barre de progression arrondie qui se remplit à l'apparition (XP d'un niveau, d'une matière,
/// avancement d'un badge), puis suit sa valeur. Immédiate quand « Réduire les animations » est actif.
struct ProfileFillBar: View {
    /// Avancement entre 0 et 1.
    let fraction: Double
    var height: CGFloat = 8
    var tint: Color = DS.accent
    var track: Color = DS.hairline
    /// Retard du remplissage, pour une cascade de barres.
    var delay: Double = 0.2

    @State private var shown: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: CGFloat { CGFloat(min(1, max(0, fraction))) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(tint)
                    .frame(width: fillWidth(in: geo.size.width))
            }
        }
        .frame(height: height)
        .animation(DS.Motion.reveal, value: fraction)
        .onAppear {
            guard !shown else { return }
            if reduceMotion {
                shown = true
            } else {
                withAnimation(DS.Motion.reveal.delay(delay)) { shown = true }
            }
        }
        .accessibilityHidden(true)
    }

    private func fillWidth(in total: CGFloat) -> CGFloat {
        guard shown, clamped > 0 else { return 0 }
        return max(height, total * clamped)
    }
}

// MARK: - Compteur

/// Un nombre qui défile jusqu'à sa valeur (`DSCountUp`), figé quand « Réduire les animations »
/// est actif. `format` est un format à un entier (« %d j ») : le nombre défile, le reste ne bouge pas.
struct ProfileCountText: View {
    let value: Int
    var format: String? = nil
    var suffix: String = ""
    var font: Font = DS.title(.title2, .heavy)
    var color: Color = DS.ink
    var haptics: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Ce qui entoure le nombre dans le texte formaté ; `nil` si le nombre n'y figure pas tel quel.
    private var affixes: (prefix: String, suffix: String)? {
        guard let format else { return (prefix: "", suffix: suffix) }
        let rendered: String = String(format: format, value)
        guard let range = rendered.range(of: "\(value)") else { return nil }
        return (prefix: String(rendered[..<range.lowerBound]), suffix: String(rendered[range.upperBound...]))
    }

    private var plainText: String {
        if let format { return String(format: format, value) }
        return "\(value)\(suffix)"
    }

    var body: some View {
        if !reduceMotion, value > 0, let affixes {
            DSCountUp(
                value: value,
                duration: 0.7,
                font: font,
                color: color,
                prefix: affixes.prefix,
                suffix: affixes.suffix,
                haptics: haptics
            )
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        } else {
            Text(plainText)
                .font(font)
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

// MARK: - Carte illustrée

/// Carte d'entrée illustrée du profil (« Entraînement », « Ma progression », « Anti-scroll ») :
/// vignette en papier découpé, titre, une ligne, chevron.
struct ProfilePosterCard: View {
    let image: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DS.title(.headline, .semibold))
                        .foregroundStyle(DS.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(DS.sans(.footnote))
                        .foregroundStyle(DS.inkSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.inkSecondary)
            }
            .padding(.leading, 10)
            .padding(.trailing, 14)
            .padding(.vertical, 10)
            .dsCard(padding: 0)
            .contentShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        }
        .buttonStyle(.pressable)
    }
}
