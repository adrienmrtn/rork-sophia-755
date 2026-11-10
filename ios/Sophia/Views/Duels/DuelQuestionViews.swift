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
    /// Le mauvais choix du joueur, dévoilé.
    case wrong
    /// Une option ni choisie ni juste : en retrait.
    case dimmed
}

struct DuelOptionButton: View {
    let text: String
    let state: DuelOptionState
    /// L'avatar de l'adversaire, posé sur l'option qu'il a choisie à la révélation.
    var opponentAvatarId: String?
    var opponentInitial: String = ""
    var showsOpponent: Bool = false
    var systemImage: String? = nil
    var minHeight: CGFloat = 56
    let action: () -> Void

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
        case .idle, .dimmed: DS.hairline
        case .selected: DS.accent
        case .correct: DS.success
        case .wrong: DS.danger
        }
    }

    private var foreground: Color {
        switch state {
        case .idle, .selected: DS.ink
        case .correct: DS.success
        case .wrong: DS.danger
        case .dimmed: DS.inkTertiary
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .bold))
                }
                Text(text)
                    .font(DS.sans(.callout, .semibold))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
                if state == .correct {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                } else if state == .wrong {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
                if showsOpponent {
                    AvatarCircle(avatarId: opponentAvatarId, initial: opponentInitial, size: 26)
                        .overlay(Circle().strokeBorder(DuelPalette.coral, lineWidth: 2))
                        .transition(.scale(scale: 0.2).combined(with: .opacity))
                }
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous).fill(fill))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .strokeBorder(border, lineWidth: state == .idle || state == .dimmed ? 1 : 2)
            )
            .scaleEffect(state == .correct ? 1.02 : (state == .selected ? 0.985 : 1))
            .opacity(state == .dimmed ? 0.55 : 1)
        }
        .buttonStyle(SoftPressButtonStyle())
        .disabled(state != .idle)
    }
}

/// Les options d'une question à choix : une colonne pour un QCM, une grille 2 × 2 sous un
/// portrait, deux grandes tuiles pour un vrai/faux.
struct DuelChoiceAnswers: View {
    let model: DuelGameModel
    let question: DuelQuestion

    private func state(for option: Int) -> DuelOptionState {
        if model.phase == .reveal {
            if option == question.correctIndex { return .correct }
            if option == model.selectedChoice { return .wrong }
            return .dimmed
        }
        if model.playerLocked {
            return option == model.selectedChoice ? .selected : .dimmed
        }
        return .idle
    }

    private func button(_ option: Int, text: String, systemImage: String? = nil, minHeight: CGFloat = 56) -> some View {
        DuelOptionButton(
            text: text,
            state: state(for: option),
            opponentAvatarId: model.match.opponent.avatarId,
            opponentInitial: model.match.opponent.initial,
            showsOpponent: model.phase == .reveal && model.botAnswer.choice == option,
            systemImage: systemImage,
            minHeight: minHeight
        ) {
            model.choose(option)
        }
    }

    var body: some View {
        let options = question.options ?? []
        Group {
            switch question.kind {
            case .trueFalse:
                HStack(spacing: 12) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, text in
                        button(index, text: text, systemImage: index == 0 ? "checkmark" : "xmark", minHeight: 84)
                    }
                }
            case .portrait:
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, text in
                        button(index, text: text, minHeight: 60)
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
                .foregroundStyle(DS.ink)
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
                Button {
                    model.lockSlider()
                } label: {
                    Text(languageManager.text(model.playerLocked ? "duel.game.locked" : "duel.game.lock"))
                }
                .buttonStyle(DuelPlayButtonStyle(
                    fill: model.playerLocked ? DS.surfaceMuted : DuelPalette.saffron,
                    edge: model.playerLocked ? DS.hairline : Color(red: 0.74, green: 0.50, blue: 0.08),
                    foreground: model.playerLocked ? DS.inkSecondary : DuelPalette.night
                ))
                .disabled(model.playerLocked)
            }
        }
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
                .overlay(Circle().strokeBorder(DS.hairline, lineWidth: 1))
        }
        .buttonStyle(SoftPressButtonStyle())
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
                    .fill(DS.surfaceMuted)
                    .frame(height: 12)
                Capsule()
                    .fill(DS.accentSoft.opacity(0.55))
                    .frame(width: thumb / 2 + usable * fraction(model.sliderValue), height: 12)

                if revealed, let correct = question.correctValue {
                    marker(color: DS.success, systemImage: "checkmark")
                        .offset(x: usable * fraction(correct) + thumb / 2 - 13, y: -30)
                        .transition(.scale(scale: 0.2, anchor: .bottom).combined(with: .opacity))
                }
                if revealed, let theirs = model.botAnswer.value {
                    AvatarCircle(
                        avatarId: model.match.opponent.avatarId,
                        initial: model.match.opponent.initial,
                        size: 26
                    )
                    .overlay(Circle().strokeBorder(DuelPalette.coral, lineWidth: 2))
                    .offset(x: usable * fraction(theirs) + thumb / 2 - 13, y: 30)
                    .transition(.scale(scale: 0.2, anchor: .top).combined(with: .opacity))
                }

                Circle()
                    .fill(model.playerLocked ? DS.accent : .white)
                    .overlay(Circle().strokeBorder(DS.accent, lineWidth: 3))
                    .frame(width: thumb, height: thumb)
                    .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
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

    private func marker(color: Color, systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 12, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(Circle().fill(color))
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

/// Le cadran du chrono : un anneau qui se vide, et les secondes restantes au centre. Il vire au
/// rouge dans les trois dernières secondes.
struct DuelTimerRing: View {
    let model: DuelGameModel
    var size: CGFloat = 58

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: model.phase != .answering)) { timeline in
            let fraction = model.remainingFraction(at: timeline.date)
            let seconds = Int((fraction * model.question.timeLimit).rounded(.up))
            let urgent = model.phase == .answering && seconds <= 3
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(urgent ? DuelPalette.coral : DuelPalette.saffron, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(seconds)")
                    .font(.jakarta(size: size * 0.38, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(urgent ? DuelPalette.coral : .white)
                    .contentTransition(.numericText(countsDown: true))
            }
            .frame(width: size, height: size)
            .scaleEffect(urgent ? 1.08 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: seconds)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Fil du score

/// Les 20 questions en une ligne de segments par camp : vert quand il a marqué, rouge sinon,
/// vide tant que la question n'est pas jouée.
struct DuelScoreStrip: View {
    let marks: [Bool?]
    let current: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(marks.enumerated()), id: \.offset) { index, mark in
                Capsule()
                    .fill(color(for: mark, isCurrent: index == current))
                    .frame(height: 5)
            }
        }
        .accessibilityHidden(true)
    }

    private func color(for mark: Bool?, isCurrent: Bool) -> Color {
        switch mark {
        case .some(true): Color(red: 0.36, green: 0.80, blue: 0.56)
        case .some(false): DuelPalette.coral
        case .none: isCurrent ? Color.white.opacity(0.75) : Color.white.opacity(0.2)
        }
    }
}
