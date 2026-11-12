import SwiftUI

/// Briques propres aux duels dans le design « Elevate arrondi » : les quelques teintes que les
/// maquettes ajoutent aux jetons `DS`, et les animations d'attente (recherche d'un adversaire,
/// réponse d'un ami).

// MARK: - Teintes

/// Les teintes de l'écran de duel qui n'existent pas dans `DS` (maquette AEr24). Les couleurs
/// des ligues et des trophées restent dans `DuelPalette`.
enum DuelTheme {
    /// Fond gris très clair du bloc de score.
    static let scoreBlock = Color(red: 0.957, green: 0.965, blue: 0.980)
    /// Filet à l'intérieur du bloc de score.
    static let scoreRule = Color(red: 0.882, green: 0.898, blue: 0.922)
    /// Piste de l'anneau du minuteur.
    static let timerTrack = Color(red: 0.835, green: 0.863, blue: 0.910)
    /// Case d'une question à venir.
    static let stripIdle = Color(red: 0.867, green: 0.886, blue: 0.918)
    /// Case d'une question réussie.
    static let stripRight = Color(red: 0.247, green: 0.749, blue: 0.561)
    /// Case d'une question ratée, et minuteur dans les dernières secondes.
    static let stripWrong = Color(red: 0.878, green: 0.337, blue: 0.290)
    /// Étiquette d'une manche qui n'est pas en cours.
    static let faint = Color(red: 0.639, green: 0.671, blue: 0.722)
    /// Voile posé sur l'illustration d'une ligue pour y lire du texte blanc.
    static let scrim = Color(red: 0.051, green: 0.094, blue: 0.176)
    /// Texte secondaire sur l'illustration d'une ligue.
    static let onArtSecondary = Color(red: 0.835, green: 0.863, blue: 0.961)

    /// Confettis lisibles sur fond blanc.
    static let confetti: [Color] = [DuelPalette.saffron, DuelPalette.coral, DS.accent, stripRight, DuelPalette.navy]
}

// MARK: - Recherche

/// L'attente autour d'un avatar : des ondes qui s'élargissent, un arc qui balaie le tour et
/// une pastille en orbite. Immobile quand « Réduire les animations » est actif.
struct DuelSearchRadar: View {
    var color: Color = DS.accent
    var size: CGFloat = 104
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let time: Double = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            ZStack {
                wave(phase: phase(time, index: 0))
                wave(phase: phase(time, index: 1))
                wave(phase: phase(time, index: 2))
                sweep(time)
                satellite(time)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    /// Avancement (0 → 1) de l'onde n° `index`, décalée d'un tiers de période.
    private func phase(_ time: Double, index: Int) -> Double {
        let shifted = time / 2.1 + Double(index) / 3
        return shifted - shifted.rounded(.down)
    }

    private func wave(phase: Double) -> some View {
        Circle()
            .stroke(color.opacity(0.42 * (1 - phase)), lineWidth: 2)
            .frame(width: size, height: size)
            .scaleEffect(1 + 0.5 * CGFloat(phase))
    }

    private func sweep(_ time: Double) -> some View {
        let turn = (time * 210).truncatingRemainder(dividingBy: 360)
        return Circle()
            .trim(from: 0, to: 0.2)
            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: size + 14, height: size + 14)
            .rotationEffect(.degrees(turn))
    }

    private func satellite(_ time: Double) -> some View {
        let turn = (time * 95).truncatingRemainder(dividingBy: 360)
        return Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .offset(y: -(size / 2 + 16))
            .rotationEffect(.degrees(-turn))
    }
}

/// Trois points qui sautillent l'un après l'autre : « en attente ».
struct DuelWaitingDots: View {
    var color: Color = DS.accent
    var size: CGFloat = 6
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let time: Double = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            HStack(spacing: size * 0.7) {
                dot(lift: lift(time, index: 0))
                dot(lift: lift(time, index: 1))
                dot(lift: lift(time, index: 2))
            }
        }
        .accessibilityHidden(true)
    }

    private func lift(_ time: Double, index: Int) -> Double {
        max(0, sin(time * 5.2 - Double(index) * 0.9))
    }

    private func dot(lift: Double) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(y: -size * 0.7 * CGFloat(lift))
            .opacity(0.45 + 0.55 * lift)
    }
}

// MARK: - Face-à-face

/// Le rond central d'un face-à-face : « VS », puis un nombre (secondes d'attente, 3, 2, 1).
struct DuelVersusBadge: View {
    /// Le nombre à afficher à la place de « VS ».
    var number: Int? = nil
    /// Le nombre est un compte à rebours de départ : il arrive en grand.
    var counting: Bool = false
    /// État éteint (défi refusé, pas d'adversaire).
    var muted: Bool = false
    var size: CGFloat = 68

    var body: some View {
        ZStack {
            Circle()
                .fill(muted ? DS.hairline : DS.accent)
                .frame(width: size, height: size)
            if let number {
                Text("\(number)")
                    .font(.jakarta(size: counting ? size * 0.5 : size * 0.42, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(countsDown: true))
                    .id(counting ? number : -1)
                    .transition(.scale(scale: 2.2).combined(with: .opacity))
            } else {
                Text("VS")
                    .font(.jakarta(size: size * 0.32, weight: .heavy))
                    .foregroundStyle(muted ? DS.inkSecondary : .white)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }
        }
    }
}

/// Un joueur dans un face-à-face : son avatar cerclé, son pseudo et ses trophées.
struct DuelVersusCard: View {
    let avatarId: String?
    let initial: String
    let handle: String
    /// Drapeau ou autre suffixe du pseudo.
    var suffix: String = ""
    var trophies: Int? = nil
    var ring: Color = DS.accent
    /// Pastille verte « en ligne » sur l'avatar.
    var online: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            DuelAvatar(avatarId: avatarId, initial: initial, size: 104, ring: ring, ringWidth: 4)
                .overlay(alignment: .bottomTrailing) {
                    if online {
                        DuelOnlineDot(size: 20)
                            .offset(x: -4, y: -4)
                    }
                }
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text("@\(handle)")
                        .font(DS.title(.title3, .bold))
                        .foregroundStyle(DS.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if !suffix.isEmpty {
                        Text(suffix).font(.system(size: 20))
                    }
                }
                if let trophies {
                    DuelTrophyCount(value: trophies, size: 15, color: DS.inkSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Titres de section

/// Sur-titre de section des pages de duel : petites capitales espacées, grises.
struct DuelSectionTitle: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.jakarta(size: 12, weight: .heavy))
            .tracking(0.8)
            .foregroundStyle(DS.inkSecondary)
    }
}
