import SwiftUI
import UIKit

/// Briques communes du design « Elevate arrondi » : vibrations, pressions, cartes d'option,
/// barres de progression, titres à mot surligné et petites animations de récompense.
///
/// Tout écran redessiné passe par ici plutôt que de recréer ses propres ressorts : une seule
/// famille de courbes (`DS.Motion`) et un seul vocabulaire haptique (`Haptics`).

// MARK: - Vibrations

/// Vocabulaire haptique de l'app. Un geste = une sensation, toujours la même :
/// `tap` pour un bouton, `select` pour un choix, `success` / `error` pour un verdict.
enum Haptics {
    /// Appui sur un bouton ou une carte.
    static func tap() { impact(.light, 0.7) }
    /// Choix dans une liste, onglet, bascule.
    static func select() { UISelectionFeedbackGenerator().selectionChanged() }
    /// Action principale validée (CTA).
    static func confirm() { impact(.medium, 0.9) }
    /// Élément qui se pose (carte, pastille, étape franchie).
    static func soft() { impact(.soft, 0.8) }
    /// Butée nette (seuil franchi, verrou).
    static func rigid() { impact(.rigid, 0.85) }
    /// Bonne réponse, étape réussie.
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    /// Mauvaise réponse.
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    /// Avertissement (temps presque écoulé, action bloquée).
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }

    /// Récompense : succès suivi d'un coup franc, pour les fins de cours, badges, victoires.
    static func celebrate() {
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { impact(.heavy, 1) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { impact(.rigid, 0.7) }
    }

    /// Petit cran répété pendant qu'un compteur défile.
    static func tick(_ intensity: CGFloat = 0.45) { impact(.light, intensity) }

    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, _ intensity: CGFloat) {
        UIImpactFeedbackGenerator(style: style).impactOccurred(intensity: intensity)
    }
}

// MARK: - Mouvement posé

/// Animations sans dépassement (ressorts à amortissement critique, sorties en douceur) :
/// elles remplacent les rebonds de `DS.Motion` là où `dsCalmMotion` est posé.
enum DSCalmMotion {
    /// Pression d'un bouton ou d'une carte.
    static let press = Animation.easeOut(duration: 0.16)
    /// Changement d'état (sélection, bascule).
    static let state = Animation.easeOut(duration: 0.22)
    /// Apparition d'un bloc de contenu.
    static let reveal = Animation.spring(response: 0.5, dampingFraction: 1)
    /// Élément qui se pose (coche, pastille, badge) : il arrive à sa taille sans la dépasser.
    static let settle = Animation.spring(response: 0.4, dampingFraction: 1)
}

private struct DSCalmMotionKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    /// `true` dans un parcours qui ne veut aucun rebond (l'onboarding) : les apparitions
    /// (`dsStagger`, `dsPopIn`, `DSCheckBadge`) et la pression (`PressableStyle`) passent
    /// alors par `DSCalmMotion`. Faux partout ailleurs, où rien ne change.
    var dsCalmMotion: Bool {
        get { self[DSCalmMotionKey.self] }
        set { self[DSCalmMotionKey.self] = newValue }
    }
}

// MARK: - Pression

/// Style de bouton neutre : le contenu s'enfonce légèrement avec un ressort et vibre au
/// toucher. À poser sur toute carte ou rangée cliquable qui dessine son propre fond.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    var haptic: Bool = true
    @Environment(\.dsCalmMotion) private var calmMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(calmMotion ? DSCalmMotion.press : DS.Motion.press, value: configuration.isPressed)
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: configuration.isPressed) { _, pressed in
                haptic && pressed
            }
    }
}

extension ButtonStyle where Self == PressableStyle {
    /// Pression élastique + vibration douce.
    static var pressable: PressableStyle { PressableStyle() }
}

// MARK: - Cartes d'option

/// État visuel d'une carte de choix (réponse de quiz, option d'onboarding…).
enum DSOptionState {
    case idle
    case selected
    case correct
    case wrong
    /// Choix écarté une fois le verdict tombé.
    case dimmed
}

private struct DSOptionCardModifier: ViewModifier {
    let state: DSOptionState
    let cornerRadius: CGFloat

    private var fill: Color {
        switch state {
        case .idle, .dimmed: DS.surface
        case .selected: DS.accentTint
        case .correct: DS.successTint
        case .wrong: DS.dangerTint
        }
    }

    private var border: Color {
        switch state {
        case .idle: DS.hairline
        case .dimmed: DS.hairline.opacity(0.7)
        case .selected: DS.accent
        case .correct: DS.success
        case .wrong: DS.danger
        }
    }

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
                    .offset(y: 1.5)
            )
            .opacity(state == .dimmed ? 0.6 : 1)
            .scaleEffect(state == .correct || state == .selected ? 1.0 : (state == .dimmed ? 0.99 : 1))
            .animation(DS.Motion.snappy, value: state)
    }
}

extension View {
    /// Fond de carte d'option : blanc bordé au repos, teinté et bordé à la couleur de l'état
    /// sinon, avec le petit rebord bas du style. N'ajoute aucun padding.
    func dsOptionCard(_ state: DSOptionState = .idle, cornerRadius: CGFloat = DS.Radius.card) -> some View {
        modifier(DSOptionCardModifier(state: state, cornerRadius: cornerRadius))
    }
}

// MARK: - Barres de progression

/// Barre de progression fine et arrondie, animée au changement de valeur.
struct DSProgressBar: View {
    /// Avancement entre 0 et 1.
    let value: Double
    var height: CGFloat = 5
    var tint: Color = DS.accent
    var track: Color = DS.accentTint

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(tint)
                    .frame(width: max(height, geo.size.width * min(max(value, 0), 1)))
            }
        }
        .frame(height: height)
        .animation(DS.Motion.reveal, value: value)
        .accessibilityElement()
        .accessibilityValue(Text("\(Int((min(max(value, 0), 1)) * 100)) %"))
    }
}

/// Progression en segments (question 2 sur 8, cours 2 sur 5…).
struct DSSegmentedProgress: View {
    let total: Int
    /// Nombre de segments remplis.
    let filled: Int
    var height: CGFloat = 6
    var spacing: CGFloat = 4
    var tint: Color = DS.accent
    var track: Color = DS.hairline.opacity(0.75)

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<max(total, 1), id: \.self) { index in
                Capsule()
                    .fill(index < filled ? tint : track)
                    .frame(height: height)
                    .animation(DS.Motion.snappy.delay(Double(index) * 0.02), value: filled)
            }
        }
        .accessibilityElement()
        .accessibilityValue(Text("\(filled) / \(total)"))
    }
}

// MARK: - Titre à mot surligné

/// Titre du style : graisse légère, avec les passages entre `**` en gras et en bleu
/// (« Comment définit-on un **trou noir** ? »).
struct DSHighlightTitle: View {
    let text: String
    var style: Font.TextStyle = .title2
    var weight: Font.Weight = .regular
    var highlightWeight: Font.Weight = .bold
    var highlight: Color = DS.accent
    var alignment: TextAlignment = .center

    var body: some View {
        attributed
            .font(DS.title(style, weight))
            .foregroundStyle(DS.ink)
            .multilineTextAlignment(alignment)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var attributed: Text {
        let parts = text.components(separatedBy: "**")
        var result = Text("")
        for (index, part) in parts.enumerated() where !part.isEmpty {
            if index % 2 == 1 {
                result = result + Text(part).font(DS.title(style, highlightWeight)).foregroundColor(highlight)
            } else {
                result = result + Text(part)
            }
        }
        return result
    }
}

// MARK: - Apparitions

private struct DSStaggerModifier: ViewModifier {
    let index: Int
    let step: Double
    let base: Double
    let offset: CGFloat
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dsCalmMotion) private var calmMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : offset)
            .scaleEffect(shown || reduceMotion ? 1 : 0.97)
            .onAppear {
                guard !shown else { return }
                let animation: Animation = calmMotion ? DSCalmMotion.reveal : DS.Motion.reveal
                withAnimation(animation.delay(base + Double(index) * step)) {
                    shown = true
                }
            }
    }
}

private struct DSPopInModifier: ViewModifier {
    let delay: Double
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dsCalmMotion) private var calmMotion

    func body(content: Content) -> some View {
        content
            // En mouvement posé, l'élément part de moins loin et ne dépasse pas sa taille.
            .scaleEffect(shown || reduceMotion ? 1 : (calmMotion ? 0.86 : 0.4))
            .opacity(shown ? 1 : 0)
            .onAppear {
                guard !shown else { return }
                let animation: Animation = calmMotion ? DSCalmMotion.settle : DS.Motion.pop
                withAnimation(animation.delay(delay)) { shown = true }
            }
    }
}

nonisolated private struct DSShakeEffect: GeometryEffect {
    var travel: CGFloat = 7
    var shakes: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: travel * sin(animatableData * .pi * shakes * 2), y: 0))
    }
}

extension View {
    /// Apparition en cascade : l'élément n° `index` d'une liste monte et se révèle après
    /// ses prédécesseurs.
    func dsStagger(_ index: Int, step: Double = 0.06, base: Double = 0.05, offset: CGFloat = 14) -> some View {
        modifier(DSStaggerModifier(index: index, step: step, base: base, offset: offset))
    }

    /// Apparition « pop » avec rebond (coche, badge, pastille de score).
    func dsPopIn(delay: Double = 0) -> some View {
        modifier(DSPopInModifier(delay: delay))
    }

    /// Secousse horizontale à chaque incrément de `trigger` (mauvaise réponse, champ refusé).
    func dsShake(trigger: Int) -> some View {
        modifier(DSShakeEffect(animatableData: CGFloat(trigger)))
            .animation(.linear(duration: 0.38), value: trigger)
    }
}

// MARK: - Coche animée

/// Pastille ronde avec une coche qui se dessine : le verdict « bonne réponse » et les
/// étapes terminées.
struct DSCheckBadge: View {
    var size: CGFloat = 26
    var fill: Color = DS.success
    var delay: Double = 0
    @State private var drawn = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dsCalmMotion) private var calmMotion

    var body: some View {
        ZStack {
            Circle().fill(fill)
            CheckShape()
                .trim(from: 0, to: drawn ? 1 : 0)
                .stroke(.white, style: StrokeStyle(lineWidth: max(2, size * 0.11), lineCap: .round, lineJoin: .round))
                .padding(size * 0.27)
        }
        .frame(width: size, height: size)
        .scaleEffect(drawn || reduceMotion ? 1 : (calmMotion ? 0.8 : 0.5))
        .onAppear {
            guard !drawn else { return }
            if reduceMotion {
                drawn = true
            } else {
                let animation: Animation = calmMotion ? DSCalmMotion.settle : DS.Motion.pop
                withAnimation(animation.delay(delay)) { drawn = true }
            }
        }
        .accessibilityHidden(true)
    }

    private struct CheckShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.05))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.maxY - rect.height * 0.08))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.12))
            return path
        }
    }
}

// MARK: - Flamme de série

/// Flamme de série qui oscille doucement : un corps safran, un cœur plus clair et un halo
/// qui respire. Immobile quand « Réduire les animations » est actif.
struct DSFlame: View {
    var size: CGFloat = 84
    var color: Color = Color(red: 0.902, green: 0.698, blue: 0.200)
    var core: Color = Color(red: 0.969, green: 0.843, blue: 0.455)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            let sway = sin(t * 1.75)
            let breathe = sin(t * 2.6)
            ZStack(alignment: .bottom) {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.32), color.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.66
                        )
                    )
                    .frame(width: size * 1.32, height: size * 1.32)
                    .scaleEffect(1 + 0.06 * breathe)
                    .opacity(0.75 + 0.25 * breathe)
                    .offset(y: size * 0.12)

                Image(systemName: "flame.fill")
                    .font(.system(size: size * 0.86, weight: .regular))
                    .foregroundStyle(color)
                    .scaleEffect(x: 1 - 0.02 * sway, y: 1 + 0.035 * sway, anchor: .bottom)
                    .rotationEffect(.degrees(2 * sway), anchor: .bottom)

                Image(systemName: "flame.fill")
                    .font(.system(size: size * 0.42, weight: .regular))
                    .foregroundStyle(core)
                    .scaleEffect(x: 1 - 0.08 * breathe, y: 1 + 0.12 * breathe, anchor: .bottom)
                    .opacity(0.85 - 0.12 * breathe)
                    .offset(y: -size * 0.07)
            }
            .frame(width: size * 1.32, height: size * 1.2, alignment: .bottom)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Compteur animé

/// Nombre qui défile jusqu'à sa valeur (score, XP, trophées), avec de petits crans haptiques.
struct DSCountUp: View {
    let value: Int
    var duration: Double = 0.9
    var font: Font = DS.title(.largeTitle, .heavy)
    var color: Color = DS.ink
    var prefix: String = ""
    var suffix: String = ""
    var haptics: Bool = true
    @State private var shown = 0

    var body: some View {
        Text("\(prefix)\(shown)\(suffix)")
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
            .contentTransition(.numericText(value: Double(shown)))
            .task(id: value) { await run() }
    }

    private func run() async {
        let start = shown
        let delta = value - start
        guard delta != 0 else { return }
        let steps = min(abs(delta), 24)
        for step in 1...steps {
            try? await Task.sleep(for: .milliseconds(Int(duration * 1000) / steps))
            if Task.isCancelled { return }
            withAnimation(DS.Motion.snappy) {
                shown = start + Int((Double(delta) * Double(step) / Double(steps)).rounded())
            }
            if haptics, step % 3 == 0 { Haptics.tick(0.3 + 0.4 * CGFloat(step) / CGFloat(steps)) }
        }
        if haptics { Haptics.soft() }
    }
}

// MARK: - Pastille

/// Petite étiquette arrondie (catégorie, « À lire maintenant », combo…).
struct DSChip: View {
    let text: String
    var systemImage: String? = nil
    var foreground: Color = DS.accent
    var background: Color = DS.accentTint

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 11, weight: .bold))
            }
            Text(text).font(DS.sans(.caption, .bold))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule(style: .continuous).fill(background))
    }
}

/// Sur-titre en capitales espacées (« SCIENCES · QUESTION 2 SUR 8 »).
struct DSEyebrow: View {
    let text: String
    var color: Color = DS.accent

    var body: some View {
        Text(text.uppercased())
            .font(DS.sans(.caption2, .heavy))
            .tracking(0.9)
            .foregroundStyle(color)
    }
}
