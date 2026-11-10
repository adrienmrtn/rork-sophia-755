import SwiftUI

/// L'écran de jeu : les deux joueurs et leur score en haut, le chrono entre eux, le fil des 20
/// questions, puis la question et ses réponses. On voit l'adversaire répondre (pastille sur son
/// avatar), puis ce qu'il a choisi et s'il a marqué à la révélation.
struct DuelGameView: View {
    @Environment(LanguageManager.self) private var languageManager
    let model: DuelGameModel
    let player: DuelPlayerIdentity
    let onFinished: () -> Void
    let onAbandon: () -> Void

    @State private var confirmQuit = false

    private var opponent: DuelOpponent { model.match.opponent }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView {
                    questionArea
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 12)
                }
                .scrollBounceBehavior(.basedOnSize)
                statusLine
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }

            if model.phase == .roundIntro, let intro = model.roundIntro {
                DuelRoundIntroView(model: model, intro: intro, opponentHandle: opponent.handle) {
                    DuelHaptics.tap()
                    confirmQuit = true
                }
                .transition(.opacity)
                .zIndex(1)
            }

            if model.phase == .suddenDeathIntro {
                suddenDeathBanner
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .task {
            await model.run()
            if model.phase == .finished {
                onFinished()
            }
        }
        .alert(languageManager.text("duel.quit.title"), isPresented: $confirmQuit) {
            Button(languageManager.text("duel.quit.confirm"), role: .destructive) { onAbandon() }
            Button(languageManager.text("duel.quit.stay"), role: .cancel) {}
        } message: {
            Text(languageManager.text("duel.quit.body"))
        }
    }

    // MARK: - En-tête

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    DuelHaptics.tap()
                    confirmQuit = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(0.14)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(languageManager.text("duel.quit.title")))

                Spacer()

                Text(counterText)
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .tracking(0.6)
                    .contentTransition(.numericText())

                Spacer()

                Color.clear.frame(width: 32, height: 32)
            }

            HStack(alignment: .center, spacing: 8) {
                side(
                    avatarId: player.avatarId,
                    initial: player.initial,
                    name: languageManager.text("duel.you"),
                    score: model.playerScore,
                    ring: DuelPalette.saffron,
                    answered: model.playerLocked && model.phase == .answering,
                    scored: model.phase == .reveal ? model.lastRound?.player : nil,
                    mirrored: false
                )
                DuelTimerRing(model: model)
                side(
                    avatarId: opponent.avatarId,
                    initial: opponent.initial,
                    name: "@\(opponent.handle)",
                    score: model.opponentScore,
                    ring: DuelPalette.coral,
                    answered: model.opponentAnswered && model.phase == .answering,
                    scored: model.phase == .reveal ? model.lastRound?.opponent : nil,
                    mirrored: true
                )
            }

            VStack(spacing: 5) {
                DuelScoreStrip(marks: model.playerMarks, current: model.index)
                DuelScoreStrip(marks: model.opponentMarks, current: model.index)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 14)
        .background(
            DuelPalette.night
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 26, bottomTrailingRadius: 26, style: .continuous))
                .ignoresSafeArea(edges: .top)
        )
        .environment(\.layoutDirection, .leftToRight)
    }

    private var counterText: String {
        if model.isSuddenDeath {
            return languageManager.text("duel.suddenDeath.title").uppercased()
        }
        // « Manche 2 · 7 / 20 »
        let round = String(format: languageManager.text("duel.round.title"), model.roundNumber)
        return "\(round) · \(min(model.index + 1, model.questionCount)) / \(model.questionCount)"
    }

    /// Un camp : avatar, nom, score. `scored` vaut vrai ou faux pendant la révélation.
    private func side(
        avatarId: String?,
        initial: String,
        name: String,
        score: Int,
        ring: Color,
        answered: Bool,
        scored: Bool?,
        mirrored: Bool
    ) -> some View {
        let avatar = DuelAvatar(
            avatarId: avatarId,
            initial: initial,
            size: 50,
            ring: scored == nil ? ring : (scored == true ? Color(red: 0.36, green: 0.80, blue: 0.56) : DuelPalette.coral),
            ringWidth: scored == nil ? 3 : 4
        )
        .overlay(alignment: mirrored ? .bottomLeading : .bottomTrailing) {
            if answered {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(DuelPalette.night)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(DuelPalette.saffron))
                    .overlay(Circle().strokeBorder(DuelPalette.night, lineWidth: 2))
                    .offset(x: mirrored ? -4 : 4, y: 4)
                    .transition(.scale(scale: 0.1).combined(with: .opacity))
            }
        }
        .scaleEffect(answered ? 1.06 : 1)

        let labels = VStack(alignment: mirrored ? .trailing : .leading, spacing: 0) {
            Text(name)
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("\(score)")
                .font(.jakarta(size: 30, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .scaleEffect(scored == true ? 1.18 : 1, anchor: mirrored ? .trailing : .leading)
        }

        return HStack(spacing: 10) {
            if mirrored {
                labels
                avatar
            } else {
                avatar
                labels
            }
        }
        .frame(maxWidth: .infinity, alignment: mirrored ? .trailing : .leading)
    }

    // MARK: - Question

    private var questionArea: some View {
        let question = model.question
        return VStack(spacing: 18) {
            if let subject = model.currentSubject {
                // La matière de la manche au choix en cours.
                HStack(spacing: 6) {
                    Image(systemName: DuelSubjects.icon(subject))
                        .font(.system(size: 11, weight: .bold))
                    Text(DuelSubjects.name(subject, language: languageManager.current))
                        .font(DS.sans(.caption, .bold))
                }
                .foregroundStyle(DS.accentSoft)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(DS.accentTint))
            }

            if question.kind == .portrait {
                DS.surfaceMuted
                    .frame(width: 184, height: 230)
                    // Sans touches : un portrait qui déborde de son cadre ne doit pas couvrir les réponses.
                    .overlay { RemoteImage(url: question.imageURL).allowsHitTesting(false) }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(DS.hairline, lineWidth: 1)
                    )
                    .dsSoftShadow()
            }

            Text(question.question)
                .font(DS.title(question.kind == .portrait ? .title3 : .title2, .heavy))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.vertical, question.kind == .portrait ? 0 : 10)

            if question.kind == .slider {
                DuelSliderAnswer(model: model, question: question)
            } else {
                DuelChoiceAnswers(model: model, question: question)
            }
        }
        .id(model.index)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - Ligne d'état

    private var statusText: String {
        // Duel classé : l'adversaire vient de se déconnecter, la victoire suit.
        if model.opponentForfeited {
            return String(format: languageManager.text("duel.friend.left"), opponent.handle)
        }
        switch model.phase {
        case .answering:
            if model.opponentLeft {
                return String(format: languageManager.text("duel.friend.left"), opponent.handle)
            }
            if model.playerLocked && !model.opponentAnswered {
                return String(format: languageManager.text("duel.game.waiting"), opponent.handle)
            }
            if model.opponentAnswered && !model.playerLocked {
                return String(format: languageManager.text("duel.game.theyAnswered"), opponent.handle)
            }
            return " "
        case .reveal:
            guard let round = model.lastRound else { return " " }
            if model.question.kind == .slider {
                if round.player && round.opponent { return languageManager.text("duel.game.sliderTie") }
                return round.player
                    ? languageManager.text("duel.game.sliderYou")
                    : String(format: languageManager.text("duel.game.sliderThem"), opponent.handle)
            }
            if round.player { return languageManager.text("duel.game.correct") }
            return languageManager.text(model.selectedChoice == nil ? "duel.game.timeUp" : "duel.game.wrong")
        case .roundIntro, .suddenDeathIntro, .finished:
            return " "
        }
    }

    private var statusColor: Color {
        guard model.phase == .reveal, let round = model.lastRound else { return DS.inkSecondary }
        return round.player ? DS.success : DS.danger
    }

    private var statusLine: some View {
        Text(statusText)
            .font(DS.sans(.subheadline, .bold))
            .foregroundStyle(statusColor)
            .frame(maxWidth: .infinity)
            .frame(height: 22)
            .contentTransition(.opacity)
            .animation(.easeOut(duration: 0.2), value: statusText)
    }

    // MARK: - Question décisive

    private var suddenDeathBanner: some View {
        ZStack {
            DuelPalette.night.opacity(0.92).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundStyle(DuelPalette.saffron)
                Text(languageManager.text("duel.suddenDeath.title"))
                    .font(.jakarta(size: 34, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(String(format: languageManager.text("duel.suddenDeath.body"), model.playerScore, model.opponentScore))
                    .font(DS.sans(.body, .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
    }
}
