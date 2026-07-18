import SwiftUI
import UIKit

/// Central design system for the calm / minimalist ("wellbeing") art direction.
///
/// Single source of truth for colors, typography, spacing, and the shared card /
/// button styles. Adjusting a token here propagates everywhere the design system
/// is wired in. The goal is a serene, editorial reading experience: soft off-white
/// canvas, navy ink, one calm blue accent, generous whitespace, hairline borders and
/// gentle diffuse shadows instead of the previous heavy neo-brutalist look.
enum DS {

    // MARK: - Colors

    /// App background — soft, slightly cool off-white.
    static let canvas = Color(red: 0.969, green: 0.973, blue: 0.980)
    /// Primary surface (cards, panels).
    static let surface = Color.white
    /// Muted surface — the pale blue used for hero / featured cards.
    static let surfaceMuted = Color(red: 0.914, green: 0.937, blue: 0.973)

    /// Primary text — deep navy.
    static let ink = Color(red: 0.086, green: 0.149, blue: 0.239)
    /// Secondary text — muted slate.
    static let inkSecondary = Color(red: 0.333, green: 0.388, blue: 0.478)
    /// Tertiary text — light slate (captions, hints, credits).
    static let inkTertiary = Color(red: 0.604, green: 0.643, blue: 0.698)

    /// Primary accent — deep navy blue for solid CTAs.
    static let accent = Color(red: 0.102, green: 0.227, blue: 0.420)
    /// Softer accent — medium blue for links, counts, underlines.
    static let accentSoft = Color(red: 0.180, green: 0.384, blue: 0.769)
    /// Very light accent tint — subtle fills / selected states.
    static let accentTint = Color(red: 0.914, green: 0.937, blue: 0.973)

    /// Hairline separators & subtle borders.
    static let hairline = Color(red: 0.894, green: 0.906, blue: 0.925)

    /// Muted sage green — success / correct-answer semantics (quiz, completions).
    static let success = Color(red: 0.220, green: 0.490, blue: 0.353)
    /// Very light green tint for success surfaces.
    static let successTint = Color(red: 0.878, green: 0.929, blue: 0.898)

    /// Muted terracotta — error / incorrect-answer semantics.
    static let danger = Color(red: 0.694, green: 0.310, blue: 0.259)
    /// Very light warm tint for error surfaces.
    static let dangerTint = Color(red: 0.965, green: 0.906, blue: 0.894)

    // MARK: - UIKit colors (for UITextView-based prose)

    static let uiInk = UIColor(red: 0.086, green: 0.149, blue: 0.239, alpha: 1)
    static let uiInkSecondary = UIColor(red: 0.333, green: 0.388, blue: 0.478, alpha: 1)

    // MARK: - Typography
    //
    // Full sans-serif (SF) to match the calm Deepstash look: clean, neutral, modern.
    // Titles lean on semibold weight for hierarchy, body copy stays regular. No serif,
    // no rounded, no heavy/black. Built on relative text styles so Dynamic Type works.

    /// Titles / headings — clean sans with a strong-but-calm weight.
    static func title(_ style: Font.TextStyle, _ weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .default, weight: weight)
    }

    /// Sans font for body copy and UI chrome.
    static func sans(_ style: Font.TextStyle, _ weight: Font.Weight = .regular) -> Font {
        .system(style, design: .default, weight: weight)
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
        static let color = Color.black.opacity(0.06)
        static let radius: CGFloat = 18
        static let y: CGFloat = 10
    }
}

// MARK: - View helpers

extension View {
    /// Applies the standard gentle, diffuse elevation shadow.
    func dsSoftShadow() -> some View {
        shadow(color: DS.SoftShadow.color, radius: DS.SoftShadow.radius, x: 0, y: DS.SoftShadow.y)
    }

    /// Wraps content in the standard calm card: surface fill, rounded corners, a
    /// hairline border and a soft shadow. No heavy stroke, no offset plate.
    func dsCard(
        cornerRadius: CGFloat = DS.Radius.card,
        fill: Color = DS.surface,
        padding: CGFloat? = DS.Space.l,
        shadow: Bool = true
    ) -> some View {
        modifier(DSCardModifier(cornerRadius: cornerRadius, fill: fill, padding: padding, shadow: shadow))
    }
}

private struct DSCardModifier: ViewModifier {
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
                    .strokeBorder(DS.hairline, lineWidth: 1)
            )
            .modifier(ConditionalSoftShadow(enabled: shadow))
    }
}

private struct ConditionalSoftShadow: ViewModifier {
    let enabled: Bool
    func body(content: Content) -> some View {
        if enabled {
            content.dsSoftShadow()
        } else {
            content
        }
    }
}

// MARK: - Button styles

/// Solid navy CTA: filled capsule, white text, gentle press feedback. No offset plate.
struct DSPrimaryButtonStyle: ButtonStyle {
    var fill: Color = DS.accent
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.sans(.headline, .semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                Capsule(style: .continuous).fill(fill)
            )
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

/// Quiet secondary button: surface fill with a hairline border.
struct DSSecondaryButtonStyle: ButtonStyle {
    var foreground: Color = DS.ink

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.sans(.headline, .medium))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule(style: .continuous).fill(DS.surface)
            )
            .overlay(
                Capsule(style: .continuous).strokeBorder(DS.hairline, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
