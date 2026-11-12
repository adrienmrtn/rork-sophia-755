import SwiftUI

// MARK: - Options (QCM, vrai/faux, portrait)

/// L'état d'une option à l'écran.
enum DuelOptionState {
    /// Le chrono tourne, rien n'est choisi.
    case idle
    /// Choisie par le joueur, en attente de la révélation.
    case selected
    /// La bonne réponse, dévoilée.
    case correct
    /// Un mauvais choix dévoilé : celui du joueur, ou celui de l'adversaire.
    case wrong
    /// Une option ni choisie ni juste : en retrait.
    case dimmed
}

/// Une réponse en carte : blanche bordée au repos, bleue une fois choisie, verte avec sa coche
/// quand elle est juste, rouge quand elle est fausse. À la révélation, « Toi » marque le choix
/// du joueur et l'avatar de l'adversaire le sien.
struct DuelOptionButton: View {
    @Environment(LanguageManager.self) private var languageManager
    let text: String
    let state: DuelOptionState
    /// L'avatar de l'adversaire, posé sur l'option qu'il a choisie à la révélation.
    var opponentAvatarId: String?
    var opponentInitial: String = ""
    var showsOpponent: Bool = false
    var systemImage: String? = nil
    var minHeight: CGFloat = 56
    /// Le pseudo de l'adversaire, écrit à côté de son avatar quand la carte est assez large.
    var opponentHandle: String = ""
    /// L'option que le joueur a choisie.
    var isPlayerChoice: Bool = false
    /// Carte étroite (grille 2 × 2, vrai/faux) : les marques se réduisent aux pastilles.
    var compact: Bool = false
    let action: () -> Void

    private var cardState: DSOptionState {
        switch state {
        case .idle: .idle
        case .selected: .selected
        case .correct: .correct
        case .wrong: .wrong
        case .dimmed: .dimmed
        }
    }

    private var foreground: Color {
        switch state {
        case .idle, .selected, .wrong: DS.ink
        case .correct: DS.success
        case .dimmed: DS.inkTertiary
        }
    }

    private var textWeight: Font.Weight {
        switch state {
        case .idle, .wrong: .semibold
        case .selected: .bold
        case .correct: .heavy
        case .dimmed: .medium
        }
    }

    /// La couleur des marques (« Toi », pseudo de l'adversaire) sur une carte dévoilée.
    private var tagColor: Color {
        switch state {
        case .correct: DS.success
        case .wrong: DS.danger
        case .idle, .selected, .dimmed: DS.inkSecondary
        }
    }

    /// Le joueur a choisi cette option et son verdict est tombé.
    private var playerRevealed: Bool {
        isPlayerChoice && (state == .correct || state == .wrong)
    }

    var body: some View {
        Button(action: action) {
            label
        }
        // Le verrouillage de la réponse vibre déjà (`DuelHaptics.lock`).
        .buttonStyle(PressableStyle(scale: 0.97, haptic: false))
        .disabled(state != .idle)
    }

    private var label: some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .bold))
            }
            Text(text)
                .font(DS.sans(.callout, textWeight))
                .multilineTextAlignment(.leading)
                .lineLimit(compact ? 3 : 2)
                .minimumScaleFactor(0.75)
                .layoutPriority(1)
            Spacer(minLength: 0)
            opponentMark
            verdictMark
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, compact ? 12 : 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
        .dsOptionCard(cardState)
        .contentShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
    }

    /// L'avatar de l'adversaire (et son pseudo quand il y a la place) sur l'option qu'il a choisie.
    @ViewBuilder
    private var opponentMark: some View {
        if showsOpponent {
            HStack(spacing: 6) {
                if !compact && !playerRevealed && !opponentHandle.isEmpty {
                    Text("@\(opponentHandle)")
                        .font(DS.sans(.caption, .bold))
                        .foregroundStyle(tagColor)
                        .lineLimit(1)
                        .frame(maxWidth: 110, alignment: .trailing)
                }
                AvatarCircle(avatarId: opponentAvatarId, initial: opponentInitial, size: 26)
                    .overlay(Circle().strokeBorder(DuelPalette.saffron, lineWidth: 2))
            }
            .transition(.scale(scale: 0.2).combined(with: .opacity))
        }
    }

    /// La coche de la bonne réponse, ou la croix du mauvais choix du joueur, précédée de « Toi ».
    @ViewBuilder
    private var verdictMark: some View {
        if state == .correct || (state == .wrong && isPlayerChoice) {
            HStack(spacing: 6) {
                if playerRevealed && !compact {
                    Text(languageManager.text("duel.you"))
                        .font(DS.sans(.caption, .bold))
                        .foregroundStyle(tagColor)
                        .lineLimit(1)
                }
                if state == .correct {
                    DSCheckBadge(size: 26, fill: DS.success)
                } else {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(DS.danger))
                        .dsPopIn()
                }
            }
            .transition(.scale(scale: 0.4).combined(with: .opacity))
        }
    }
}

/// Les options d'une question à choix : une colonne pour un QCM, une grille 2 × 2 sous un
/// portrait, deux grandes tuiles pour un vrai/faux.
struct DuelChoiceAnswers: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let model: DuelGameModel
    let question: DuelQuestion

    /// S'incrémente quand le mauvais choix du joueur est dévoilé : sa carte tremble.
    @State private var shakes = 0

    private func state(for option: Int) -> DuelOptionState {
        if model.phase == .reveal {
            if option == question.correctIndex { return .correct }
            if option == model.selectedChoice { return .wrong }
            // Le mauvais choix de l'adversaire se lit aussi en rouge, sous son avatar.
            if option == model.botAnswer.choice { return .wrong }
            return .dimmed
        }
        if model.playerLocked {
            return option == model.selectedChoice ? .selected : .dimmed
        }
        return .idle
    }

    private func button(
        _ option: Int,
        text: String,
        systemImage: String? = nil,
        minHeight: CGFloat = 56,
        compact: Bool = false
    ) -> some View {
        let mine: Bool = model.selectedChoice == option
        let theirs: Bool = model.phase == .reveal && model.botAnswer.choice == option
        return DuelOptionButton(
            text: text,
            state: state(for: option),
            opponentAvatarId: model.match.opponent.avatarId,
            opponentInitial: model.match.opponent.initial,
            showsOpponent: theirs,
            systemImage: systemImage,
            minHeight: minHeight,
            opponentHandle: model.match.opponent.handle,
            isPlayerChoice: mine,
            compact: compact
        ) {
            model.choose(option)
        }
        .dsShake(trigger: mine ? shakes : 0)
        .dsStagger(option, step: 0.05, base: 0.06, offset: 10)
    }

    var body: some View {
        let options: [String] = question.options ?? []
        Group {
            switch question.kind {
            case .trueFalse:
                HStack(spacing: 12) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, text in
                        button(index, text: text, systemImage: index == 0 ? "checkmark" : "xmark", minHeight: 84, compact: true)
                    }
                }
            case .portrait:
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, text in
                        button(index, text: text, minHeight: 60, compact: true)
                    }
                }
            default:
                VStack(spacing: 10) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, text in
                        button(index, text: text)
                    }
                }
            }
        }
        .onChange(of: model.phase) { _, phase in
            // La vibration du verdict vient du déroulé (`DuelHaptics.wrong`) ; ici, la secousse.
            guard phase == .reveal, !reduceMotion, let choice = model.selectedChoice,
                  choice != question.correctIndex else { return }
            shakes += 1
        }
    }
}

// MARK: - Curseur

/// Une question au curseur : une valeur à estimer, le plus proche de la bonne marque. Le joueur
/// glisse (ou ajuste d'un cran avec − et +), puis valide. À la révélation, la bonne valeur et
/// celle de l'adversaire viennent se poser sur la piste.
struct DuelSliderAnswer: View {
    @Environment(LanguageManager.self) private var languageManager
    let model: DuelGameModel
    let question: DuelQuestion

    private var lower: Double { question.sliderMin ?? 0 }
    private var upper: Double { question.sliderMax ?? 100 }
    private var revealed: Bool { model.phase == .reveal }

    private func fraction(_ value: Double) -> CGFloat {
        guard upper > lower else { return 0 }
        return CGFloat(min(max((value - lower) / (upper - lower), 0), 1))
    }

    var body: some View {
        VStack(spacing: 18) {
            Text(DuelFormat.sliderValue(model.sliderValue, unit: question.unit))
                .font(.jakarta(size: 44, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(DS.accent)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.18), value: model.sliderValue)

            HStack(spacing: 12) {
                stepButton(systemImage: "minus", steps: -1)
                track
                stepButton(systemImage: "plus", steps: 1)
            }

            HStack {
                Text(DuelFormat.sliderValue(lower, unit: question.unit))
                Spacer()
                Text(DuelFormat.sliderValue(upper, unit: question.unit))
            }
            .font(DS.sans(.caption, .semibold))
            .foregroundStyle(DS.inkTertiary)
            .padding(.horizontal, 56)

            if revealed {
                revealSummary
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                lockButton
            }
        }
    }

    private var lockButton: some View {
        Button {
            model.lockSlider()
        } label: {
            Text(languageManager.text(model.playerLocked ? "duel.game.locked" : "duel.game.lock"))
        }
        .buttonStyle(DuelPlayButtonStyle(
            fill: model.playerLocked ? DS.accentTint : DS.accent,
            edge: .clear,
            foreground: model.playerLocked ? DS.inkSecondary : .white
        ))
        .disabled(model.playerLocked)
    }

    private func stepButton(systemImage: String, steps: Double) -> some View {
        Button {
            model.nudgeSlider(by: steps)
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(DS.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(DS.surface))
                .overlay(Circle().strokeBorder(DS.hairline, lineWidth: 1.5))
        }
        // Chaque cran du curseur vibre déjà (`DuelHaptics.tick`).
        .buttonStyle(PressableStyle(scale: 0.94, haptic: false))
        .disabled(model.playerLocked || revealed)
        .opacity(model.playerLocked || revealed ? 0.4 : 1)
    }

    private var track: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let thumb: CGFloat = 34
            let usable = max(width - thumb, 1)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DS.accentTint)
                    .frame(height: 12)
                Capsule()
                    .fill(DS.accent)
                    .frame(width: thumb / 2 + usable * fraction(model.sliderValue), height: 12)

                if revealed, let correct = question.correctValue {
                    DSCheckBadge(size: 26, fill: DS.success)
                        .offset(x: usable * fraction(correct) + thumb / 2 - 13, y: -30)
                        .transition(.scale(scale: 0.2, anchor: .bottom).combined(with: .opacity))
                }
                if revealed, let theirs = model.botAnswer.value {
                    AvatarCircle(
                        avatarId: model.match.opponent.avatarId,
                        initial: model.match.opponent.initial,
                        size: 26
                    )
                    .overlay(Circle().strokeBorder(DuelPalette.saffron, lineWidth: 2))
                    .offset(x: usable * fraction(theirs) + thumb / 2 - 13, y: 30)
                    .transition(.scale(scale: 0.2, anchor: .top).combined(with: .opacity))
                }

                Circle()
                    .fill(model.playerLocked ? DS.accent : DS.surface)
                    .overlay(Circle().strokeBorder(DS.accent, lineWidth: 3))
                    .frame(width: thumb, height: thumb)
                    .offset(x: usable * fraction(model.sliderValue))
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let ratio = Double(min(max((drag.location.x - thumb / 2) / usable, 0), 1))
                        model.setSlider(lower + ratio * (upper - lower))
                    }
            )
        }
        .frame(height: 96)
        .environment(\.layoutDirection, .leftToRight)
    }

    private var revealSummary: some View {
        VStack(spacing: 6) {
            if let correct = question.correctValue {
                Text(String(format: languageManager.text("duel.game.sliderAnswer"), DuelFormat.sliderValue(correct, unit: question.unit)))
                    .font(DS.title(.headline, .bold))
                    .foregroundStyle(DS.success)
            }
            if let theirs = model.botAnswer.value {
                Text(String(
                    format: languageManager.text("duel.game.sliderTheirs"),
                    model.match.opponent.handle,
                    DuelFormat.sliderValue(theirs, unit: question.unit)
                ))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

// MARK: - Chrono

/// Le minuteur : un anneau bleu qui se vide, et les secondes restantes au centre. Dans les trois
/// dernières secondes il vire au rouge et bat une fois par seconde (l'avertissement haptique,
/// unique, vient de `DuelHaptics.clock`).
struct DuelTimerRing: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let model: DuelGameModel
    var size: CGFloat = 58

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: model.phase != .answering)) { timeline in
            let fraction: Double = model.remainingFraction(at: timeline.date)
            let remaining: Double = fraction * model.question.timeLimit
            let seconds: Int = Int(remaining.rounded(.up))
            let urgent: Bool = model.phase == .answering && seconds <= 3
            let tint: Color = urgent ? DuelTheme.stripWrong : DS.accent
            ZStack {
                Circle().fill(DS.surface)
                Circle()
                    .stroke(DuelTheme.timerTrack, lineWidth: 5)
                    .padding(2.5)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(tint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(2.5)
                Text("\(seconds)")
                    .font(.jakarta(size: size * 0.38, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(urgent ? DuelTheme.stripWrong : DS.ink)
                    .contentTransition(.numericText(countsDown: true))
            }
            .frame(width: size, height: size)
            .scaleEffect(beat(remaining: remaining, urgent: urgent))
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: seconds)
        }
        .accessibilityHidden(true)
    }

    /// Un battement par seconde dans les dernières secondes : nul à chaque seconde pleine,
    /// au plus fort à mi-chemin.
    private func beat(remaining: Double, urgent: Bool) -> CGFloat {
        guard urgent, !reduceMotion else { return 1 }
        let wave = sin(remaining * Double.pi)
        return 1 + 0.09 * CGFloat(wave * wave)
    }
}

// MARK: - Bandes de résultats

/// Une case d'une bande : verte quand le camp a marqué, rouge sinon, bleue pour la question en
/// cours, grise tant qu'elle est à venir. Elle « saute » au moment où elle prend sa couleur.
private struct DuelStripCell: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let mark: Bool?
    let isCurrent: Bool

    @State private var popped = false

    private var color: Color {
        switch mark {
        case .some(true): DuelTheme.stripRight
        case .some(false): DuelTheme.stripWrong
        case .none: isCurrent ? DS.accent : DuelTheme.stripIdle
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(color)
            .frame(height: 5)
            .scaleEffect(x: popped ? 1.15 : 1, y: popped ? 2.6 : 1)
            .animation(DS.Motion.snappy, value: isCurrent)
            .onChange(of: mark) { old, new in
                guard old == nil, new != nil, !reduceMotion else { return }
                withAnimation(.easeOut(duration: 0.12)) { popped = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                    withAnimation(DS.Motion.pop) { popped = false }
                }
            }
    }
}

/// Les questions d'un camp en une ligne de cases, regroupées par manche.
struct DuelScoreStrip: View {
    let marks: [Bool?]
    let current: Int

    /// Les cases sont groupées par manche (cinq questions), un espace entre deux manches.
    private var groups: [[Int]] {
        let size = DuelMatch.questionsPerRound
        return stride(from: 0, to: marks.count, by: size).map { Array($0..<min($0 + size, marks.count)) }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(groups, id: \.first) { group in
                HStack(spacing: 2) {
                    ForEach(group, id: \.self) { index in
                        DuelStripCell(mark: marks[index], isCurrent: index == current)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Les deux bandes de résultats (le joueur, puis l'adversaire) sous les étiquettes des manches
/// M1…Mn ; la manche en cours est en bleu.
struct DuelScoreBoard: View {
    @Environment(LanguageManager.self) private var languageManager
    let playerMarks: [Bool?]
    let opponentMarks: [Bool?]
    /// L'indice de la question en cours.
    let current: Int
    /// Le numéro de la manche en cours (à partir de 1) ; 0 quand aucune ne l'est (question décisive).
    let currentRound: Int
    let opponentName: String

    private static let labelWidth: CGFloat = 52

    private var roundCount: Int {
        let size = max(DuelMatch.questionsPerRound, 1)
        return max((playerMarks.count + size - 1) / size, 1)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Color.clear.frame(width: Self.labelWidth, height: 1)
                roundLabels
            }
            row(label: languageManager.text("duel.you"), strong: true, marks: playerMarks)
            row(label: opponentName, strong: false, marks: opponentMarks)
        }
        .accessibilityHidden(true)
    }

    private var roundLabels: some View {
        HStack(spacing: 8) {
            ForEach(1...roundCount, id: \.self) { number in
                Text(String(format: languageManager.text("duel.round.short"), number))
                    .font(.jakarta(size: 10, weight: .heavy))
                    .tracking(0.6)
                    .foregroundStyle(number == currentRound ? DS.accent : DuelTheme.faint)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .animation(DS.Motion.snappy, value: currentRound)
            }
        }
    }

    private func row(label: String, strong: Bool, marks: [Bool?]) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.jakarta(size: 11, weight: strong ? .bold : .semibold))
                .foregroundStyle(strong ? DS.ink : DS.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: Self.labelWidth, alignment: .leading)
            DuelScoreStrip(marks: marks, current: current)
        }
    }
}
