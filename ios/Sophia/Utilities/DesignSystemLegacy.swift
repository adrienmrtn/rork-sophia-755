import SwiftUI
import UIKit

/// **Ancien** design system (navy calme, capsules, ombres douces), figé le 12/11/2026.
///
/// Conservé tel quel pour les écrans qui ne passent pas au design « Elevate arrondi » :
/// la fin de l'onboarding (atouts, étapes de l'essai, rappel) et tous les paywalls. Ne pas
/// l'utiliser ailleurs ; le design courant est `DS`.
///
/// Central design system for the calm / minimalist ("wellbeing") art direction.
///
/// Single source of truth for colors, typography, spacing, and the shared card /
/// button styles. Adjusting a token here propagates everywhere the design system
/// is wired in. The goal is a serene, editorial reading experience: soft off-white
/// canvas, navy ink, one calm blue accent, generous whitespace, hairline borders and
/// gentle diffuse shadows instead of the previous heavy neo-brutalist look.
enum DSLegacy {

    // MARK: - Colors
    //
    // Tokens are dynamic: they resolve against the current trait collection so the
    // same `DSLegacy.canvas` / `DSLegacy.ink` call sites adapt when the user picks Night (or
    // Automatic) in Settings. Light values are the existing editorial palette.

    /// App background — soft cool off-white / deep navy at night.
    static let uiCanvas = DSAdaptive.color(light: (0.969, 0.973, 0.980), dark: (0.071, 0.090, 0.129))
    static let canvas = Color(uiColor: uiCanvas)

    /// Canvas resolved against an explicit scheme — use on modal chrome so the
    /// sheet background is not sampled from a still-light presentation trait.
    static func resolvedCanvas(for scheme: ColorScheme) -> Color {
        let traits = UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light)
        return Color(uiColor: uiCanvas.resolvedColor(with: traits))
    }

    /// Primary surface (cards, panels).
    static let uiSurface = DSAdaptive.color(light: (1, 1, 1), dark: (0.118, 0.145, 0.192))
    static let surface = Color(uiColor: uiSurface)
    /// Muted surface — pale blue hero cards / raised night panels.
    static let uiSurfaceMuted = DSAdaptive.color(light: (0.914, 0.937, 0.973), dark: (0.145, 0.184, 0.247))
    static let surfaceMuted = Color(uiColor: uiSurfaceMuted)

    /// Primary text — deep navy / off-white at night.
    static let uiInk = DSAdaptive.color(light: (0.086, 0.149, 0.239), dark: (0.925, 0.937, 0.957))
    static let ink = Color(uiColor: uiInk)
    /// Secondary text — muted slate.
    static let uiInkSecondary = DSAdaptive.color(light: (0.333, 0.388, 0.478), dark: (0.655, 0.698, 0.757))
    static let inkSecondary = Color(uiColor: uiInkSecondary)
    /// Tertiary text — light slate (captions, hints, credits).
    static let uiInkTertiary = DSAdaptive.color(light: (0.604, 0.643, 0.698), dark: (0.475, 0.522, 0.588))
    static let inkTertiary = Color(uiColor: uiInkTertiary)

    /// Primary accent — deep navy CTA by day; lifted blue at night for contrast.
    static let uiAccent = DSAdaptive.color(light: (0.102, 0.227, 0.420), dark: (0.310, 0.490, 0.855))
    static let accent = Color(uiColor: uiAccent)
    /// Softer accent — medium blue for links, counts, underlines.
    static let uiAccentSoft = DSAdaptive.color(light: (0.180, 0.384, 0.769), dark: (0.480, 0.655, 0.960))
    static let accentSoft = Color(uiColor: uiAccentSoft)
    /// Subtle accent fill / selected states.
    static let uiAccentTint = DSAdaptive.color(light: (0.914, 0.937, 0.973), dark: (0.145, 0.196, 0.298))
    static let accentTint = Color(uiColor: uiAccentTint)

    /// Hairline separators & subtle borders.
    static let uiHairline = DSAdaptive.color(light: (0.894, 0.906, 0.925), dark: (0.212, 0.247, 0.310))
    static let hairline = Color(uiColor: uiHairline)

    /// Muted sage green — success / correct-answer semantics (quiz, completions).
    static let uiSuccess = DSAdaptive.color(light: (0.220, 0.490, 0.353), dark: (0.380, 0.690, 0.510))
    static let success = Color(uiColor: uiSuccess)
    /// Very light green tint for success surfaces.
    static let uiSuccessTint = DSAdaptive.color(light: (0.878, 0.929, 0.898), dark: (0.129, 0.216, 0.176))
    static let successTint = Color(uiColor: uiSuccessTint)

    /// Muted terracotta — error / incorrect-answer semantics.
    static let uiDanger = DSAdaptive.color(light: (0.694, 0.310, 0.259), dark: (0.890, 0.455, 0.400))
    static let danger = Color(uiColor: uiDanger)
    /// Very light warm tint for error surfaces.
    static let uiDangerTint = DSAdaptive.color(light: (0.965, 0.906, 0.894), dark: (0.259, 0.149, 0.141))
    static let dangerTint = Color(uiColor: uiDangerTint)

    /// Warm amber — App Store star ratings.
    static let uiWarm = DSAdaptive.color(light: (0.90, 0.70, 0.20), dark: (0.95, 0.76, 0.32))
    static let warm = Color(uiColor: uiWarm)

    // MARK: - Typography
    //
    // Plus Jakarta Sans (Google Fonts) throughout — a single variable font file
    // (`Resources/Fonts/PlusJakartaSans.ttf`, registered via `UIAppFonts` in Info.plist)
    // spanning weights 200–800, so `.weight(_:)` picks the matching cut on the fly:
    // .regular=400, .medium=500, .semibold=600, .bold=700, .heavy=800. Titles default to
    // ExtraBold (800) for strong hierarchy; body copy stays Regular (400), with SemiBold
    // (600) reserved for emphasis. Built on relative text styles so Dynamic Type still works.

    private static let fontFamily = "Plus Jakarta Sans"

    /// Apple's default point size for each Dynamic Type text style at the base content
    /// size — used as the anchor for `Font.custom(..., relativeTo:)` so our custom font
    /// still scales correctly with the user's preferred text size. Shared with the
    /// `Font.jakarta` shims below so every call site (not just `DSLegacy.title`/`DSLegacy.sans`) can
    /// reuse the exact same sizing table.
    static func baseSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
    }

    /// Titles / headings — Plus Jakarta Sans, ExtraBold (800) by default for strong
    /// hierarchy; pass an explicit lighter weight where a quieter title is needed.
    static func title(_ style: Font.TextStyle, _ weight: Font.Weight = .heavy) -> Font {
        .custom(fontFamily, size: baseSize(for: style), relativeTo: style).weight(weight)
    }

    /// Sans font for body copy and UI chrome — Plus Jakarta Sans, Regular (400) by
    /// default; pass `.semibold` (600) for emphasis within body text.
    static func sans(_ style: Font.TextStyle, _ weight: Font.Weight = .regular) -> Font {
        .custom(fontFamily, size: baseSize(for: style), relativeTo: style).weight(weight)
    }

    // MARK: - Metrics

    enum Radius {
        static let card: CGFloat = 22
        static let control: CGFloat = 16
        static let small: CGFloat = 12
    }

    enum Space {
        static let xs: CGFloat = 6
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 20
        static let xl: CGFloat = 28
    }

    /// Gentle diffuse shadow used on elevated surfaces.
    struct SoftShadow {
        static let color = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.black.withAlphaComponent(0.45)
                : UIColor.black.withAlphaComponent(0.06)
        })
        static let radius: CGFloat = 18
        static let y: CGFloat = 10
    }
}

// MARK: - View helpers

extension View {
    /// Applies the standard gentle, diffuse elevation shadow.
    func dsLegacySoftShadow() -> some View {
        shadow(color: DSLegacy.SoftShadow.color, radius: DSLegacy.SoftShadow.radius, x: 0, y: DSLegacy.SoftShadow.y)
    }

    /// Wraps content in the standard calm card: surface fill, rounded corners, a
    /// hairline border and a soft shadow. No heavy stroke, no offset plate.
    func dsLegacyCard(
        cornerRadius: CGFloat = DSLegacy.Radius.card,
        fill: Color = DSLegacy.surface,
        padding: CGFloat? = DSLegacy.Space.l,
        shadow: Bool = true
    ) -> some View {
        modifier(DSLegacyCardModifier(cornerRadius: cornerRadius, fill: fill, padding: padding, shadow: shadow))
    }
}

private struct DSLegacyCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let fill: Color
    let padding: CGFloat?
    let shadow: Bool

    func body(content: Content) -> some View {
        content
            .padding(padding ?? 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(DSLegacy.hairline, lineWidth: 1)
            )
            .modifier(LegacyConditionalSoftShadow(enabled: shadow))
    }
}

private struct LegacyConditionalSoftShadow: ViewModifier {
    let enabled: Bool
    func body(content: Content) -> some View {
        if enabled {
            content.dsLegacySoftShadow()
        } else {
            content
        }
    }
}

// MARK: - Button styles

/// Solid navy CTA: filled capsule, white text, gentle press feedback. No offset plate.
struct DSLegacyPrimaryButtonStyle: ButtonStyle {
    var fill: Color = DSLegacy.accent
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DSLegacy.sans(.headline, .semibold))
            .foregroundStyle(foreground)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .padding(.horizontal, 12)
            .background(
                Capsule(style: .continuous).fill(fill)
            )
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

/// Quiet secondary button: surface fill with a hairline border.
struct DSLegacySecondaryButtonStyle: ButtonStyle {
    var foreground: Color = DSLegacy.ink

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DSLegacy.sans(.headline, .medium))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule(style: .continuous).fill(DSLegacy.surface)
            )
            .overlay(
                Capsule(style: .continuous).strokeBorder(DSLegacy.hairline, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Onboarding V2 (ancien style)

/// Jetons de l'onboarding V2 dans l'ancien style, pour les écrans figés (voir `DSLegacy`).
enum OV2Legacy {
    static let bg = DSLegacy.canvas
    static let ink = DSLegacy.ink
    static let inkSecondary = DSLegacy.inkSecondary
    static let inkTertiary = DSLegacy.inkTertiary
    static let accent = DSLegacy.accent
    static let accentSoft = DSLegacy.accentSoft
    static let surface = DSLegacy.surface
    static let hairline = DSLegacy.hairline
    static let warm = Color(red: 0.90, green: 0.70, blue: 0.20)
    static let danger = Color(red: 0.86, green: 0.35, blue: 0.36)
    static let success = DSLegacy.success
    static let pink = Color(red: 0.95, green: 0.33, blue: 0.56)
    static let readableWidth: CGFloat = 440
}

/// CTA plein en capsule navy de l'ancien onboarding, pour les écrans figés.
struct OnboardingV2LegacyButton: View {
    let title: String
    var enabled: Bool = true
    var bottomPadding: CGFloat = 20
    let action: () -> Void
    @State private var tap = 0

    var body: some View {
        Button {
            guard enabled else { return }
            tap += 1
            OnboardingHaptics.primaryCTA()
            action()
        } label: {
            Text(title)
                .font(DSLegacy.sans(.headline, .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .padding(.horizontal, 12)
                .background(
                    Capsule(style: .continuous)
                        .fill(enabled ? OV2Legacy.accent : OV2Legacy.accent.opacity(0.35))
                )
        }
        .buttonStyle(SoftPressButtonStyle())
        .disabled(!enabled)
        .sensoryFeedback(.impact(weight: .medium), trigger: tap)
        .padding(.horizontal, 24)
        .padding(.bottom, bottomPadding)
    }
}

extension View {
    /// Fond plein cadre de l'ancien onboarding (off-white), largeur de contenu bornée.
    func ov2LegacyBackground() -> some View {
        frame(maxWidth: OV2Legacy.readableWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(OV2Legacy.bg.ignoresSafeArea())
    }
}
