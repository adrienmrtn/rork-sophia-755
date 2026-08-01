import SwiftUI

/// Design tokens et composants partagés du nouvel onboarding (V2).
///
/// Direction artistique : calme, sérieux, premium. On s'appuie sur le design system `DS`
/// (fond off-white, encre navy, bleu calme) — pas de `BrutalPalette` (rose/cream ludique).
enum OV2 {
    static let bg = DS.canvas
    static let ink = DS.ink
    static let inkSecondary = DS.inkSecondary
    static let inkTertiary = DS.inkTertiary
    static let accent = DS.accent
    static let accentSoft = DS.accentSoft
    static let surface = DS.surface
    static let hairline = DS.hairline

    /// Jaune doux réutilisé pour la cloche / éléments d'accent chaleureux.
    static let warm = Color(red: 0.90, green: 0.70, blue: 0.20)
    static let danger = Color(red: 0.86, green: 0.35, blue: 0.36)
    static let success = DS.success
}

// MARK: - Transition douce (fondu + léger glissement vertical)

/// Modifieur d'état pour la transition V2 : léger décalage vertical + opacité.
private struct OV2Shift: ViewModifier {
    let y: CGFloat
    let opacity: Double
    func body(content: Content) -> some View {
        content.offset(y: y).opacity(opacity)
    }
}

extension AnyTransition {
    /// Entrée depuis le haut, sortie vers le bas — fondu + glissement léger (« premium »).
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
}

// MARK: - Bouton primaire V2

/// CTA plein, capsule navy, retour haptique doux — cohérent avec `DSPrimaryButtonStyle`.
struct OnboardingV2Button: View {
    let title: String
    var enabled: Bool = true
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
                .font(DS.sans(.headline, .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .padding(.horizontal, 12)
                .background(
                    Capsule(style: .continuous)
                        .fill(enabled ? OV2.accent : OV2.accent.opacity(0.35))
                )
        }
        .buttonStyle(SoftPressButtonStyle())
        .disabled(!enabled)
        .sensoryFeedback(.impact(weight: .medium), trigger: tap)
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
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

    /// Fond plein cadre V2.
    func ov2Background() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(OV2.bg.ignoresSafeArea())
    }
}
