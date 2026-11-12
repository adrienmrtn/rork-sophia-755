import SwiftUI

/// Briques partagées par les derniers écrans de l'onboarding au design « Elevate arrondi »
/// (heure de lecture, courbe 90 jours, notifications, avis, préparation, profil, création de
/// compte, avatar, profs à suivre, bienvenue à bord).
enum OV2End {
    /// Marge latérale du contenu, celle des maquettes.
    static let side: CGFloat = 24
    /// Marge au-dessus du premier bloc, sous l'en-tête (retour + progression) que le
    /// coordinateur pose au-dessus de l'écran.
    static let top: CGFloat = 22
    /// Marge haute des écrans d'après « Profil », qui n'ont pas cet en-tête.
    static let topWithoutHeader: CGFloat = 36

    /// Version à passage surligné (`**…**`) d'un titre déjà traduit ailleurs sans balisage.
    ///
    /// Lue directement dans la table de la zone : quand la langue n'y est pas, c'est le texte
    /// existant (`fallback`) qui sert, sans surlignage, plutôt que l'anglais.
    static func marked(_ key: String, fallback: String, language: AppLanguage) -> String {
        if let text: String = AppLocalizableAdditions.elevateOnboardingEnd[key]?[language.rawValue] {
            return text
        }
        return fallback
    }
}

// MARK: - Titres

/// Titre centré des écrans à question ou à annonce (graisse moyenne, 23 pt sur la maquette).
struct OV2EndTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DS.title(.title2, .medium))
            .tracking(0.2)
            .foregroundStyle(DS.ink)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Texte secondaire centré sous un `OV2EndTitle`.
struct OV2EndSubtitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DS.sans(.subheadline, .regular))
            .foregroundStyle(DS.inkSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Étoiles

/// Cinq étoiles ambrées qui se posent l'une après l'autre.
struct OV2EndStars: View {
    var size: CGFloat = 17
    var spacing: CGFloat = 2
    var baseDelay: Double = 0.1

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: size))
                    .foregroundStyle(DS.warm)
                    .dsPopIn(delay: baseDelay + Double(index) * 0.07)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Carte

extension View {
    /// Carte du style (fond blanc, bordure 1,5 pt, rebord bas) sans padding ni largeur
    /// imposée : pour les blocs qui règlent eux-mêmes leurs marges.
    func ov2EndCard(
        cornerRadius: CGFloat = DS.Radius.card,
        fill: Color = DS.surface,
        border: Color = DS.hairline
    ) -> some View {
        self
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
                    .offset(y: 1.5)
            )
    }
}

/// Fondu vers le fond de page, à poser au-dessus d'un CTA épinglé pour que la liste qui
/// défile dessous s'efface au lieu d'être coupée net.
struct OV2EndBottomFade: View {
    var height: CGFloat = 44

    var body: some View {
        LinearGradient(
            colors: [DS.canvas.opacity(0), DS.canvas],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: height)
        .offset(y: -height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Mentions légales

/// « En continuant, tu acceptes nos Conditions générales · Politique de confidentialité »,
/// les deux liens ouvrant les feuilles de l'écran hôte.
struct OV2EndLegalNote: View {
    @Environment(LanguageManager.self) private var languageManager
    let onTerms: () -> Void
    let onPrivacy: () -> Void

    var body: some View {
        VStack(spacing: 3) {
            Text(languageManager.text("auth.legal.prefix"))
                .font(DS.sans(.caption, .regular))
                .foregroundStyle(DS.inkSecondary)
            HStack(spacing: 4) {
                Button(languageManager.text("settings.terms.title"), action: onTerms)
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(DS.ink)
                Text(verbatim: "·")
                    .font(DS.sans(.caption, .regular))
                    .foregroundStyle(DS.inkSecondary)
                Button(languageManager.text("settings.privacy.title"), action: onPrivacy)
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(DS.ink)
            }
        }
        .multilineTextAlignment(.center)
    }
}
