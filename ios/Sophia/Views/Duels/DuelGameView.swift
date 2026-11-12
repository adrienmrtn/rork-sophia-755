import SwiftUI

/// L'écran de jeu (maquette AEr24) : la manche et la question en sur-titre, le bloc de score
/// (les deux joueurs, le minuteur entre eux, les bandes de résultats par manche), puis la
/// question, ses réponses en cartes et le bandeau de verdict. On voit l'adversaire répondre
/// (pastille sur son avatar), puis ce qu'il a choisi et s'il a marqué à la révélation.
struct DuelGameView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let model: DuelGameModel
    let player: DuelPlayerIdentity
    let onFinished: () -> Void
    let onAbandon: () -> Void

    @State private var confirmQuit = false
    /// S'incrémente quand le joueur perd la question sans carte à secouer (temps écoulé,
    /// curseur) : c'est alors le bandeau de verdict qui tremble.
    @State private var verdictShake = 0

    private var opponent: DuelOpponent { model.match.opponent }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                scoreBlock
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                ScrollView {
                    questionArea
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 12)
                }
                .scrollBounceBehavior(.basedOnSize)
                verdictBanner
                    .padding(.horizontal, 24)
                    .padding(.top, 6)
                    .padding(.bottom, 10)
            }

            if model.phase == .roundIntro, let intro = model.roundIntro {
                // Le bouton de l'annonce vibre de lui-même.
                DuelRoundIntroView(model: model, intro: intro, opponentHandle: opponent.handle) {
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
        .onChange(of: model.phase) { _, phase in
            // La vibration du verdict vient du déroulé (`DuelHaptics.correct` / `.wrong`).
            guard phase == .reveal, !reduceMotion, let round = model.lastRound, !round.player else { return }
            if model.question.kind == .slider || model.selectedChoice == nil {
                verdictShake += 1
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

    /// Le bouton pour quitter, et au centre « MANCHE 2 SUR 4 » au-dessus de « Question 7 / 20 ».
    private var topBar: some View {
        HStack(spacing: 8) {
            RoundIconButton(systemImage: "xmark", accessibilityLabel: languageManager.text("duel.quit.title")) {
                confirmQuit = true
            }
            Spacer(minLength: 0)
            VStack(spacing: 1) {
                Text(roundEyebrow.uppercased())
                    .font(.jakarta(size: 11, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(DS.accent)
                if !model.isSuddenDeath {
                    questionCounter
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .animation(DS.Motion.snappy, value: model.index)
            Spacer(minLength: 0)
            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var roundEyebrow: String {
        if model.isSuddenDeath {
            return languageManager.text("duel.suddenDeath.title")
        }
        return String(format: languageManager.text("duel.round.of"), model.roundNumber, model.match.rounds.count)
    }

    /// « Question 7 / 20 » : le numéro en gras, le total en gris à partir de la barre oblique.
    private var questionCounter: Text {
        let number: Int = min(model.index + 1, model.questionCount)
        let full = String(format: languageManager.text("duel.game.counter"), number, model.questionCount)
        let strong: Font = .jakarta(size: 15, weight: .bold)
        guard let slash = full.range(of: "/") else {
            return Text(full).font(strong).foregroundColor(DS.ink)
        }
        let head = String(full[full.startIndex..<slash.lowerBound])
        let tail = String(full[slash.lowerBound...])
        let first = Text(head).font(strong).foregroundColor(DS.ink)
        let second = Text(tail).font(.jakarta(size: 15, weight: .medium)).foregroundColor(DS.inkTertiary)
        return first + second
    }

    // MARK: - Bloc de score

    private var scoreBlock: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                DuelScoreSide(
                    avatarId: player.avatarId,
                    initial: player.initial,
                    name: languageManager.text("duel.you"),
                    score: model.playerScore,
                    tint: DS.accent,
                    scoreColor: DS.accent,
                    isPlayer: true,
                    answered: model.playerLocked && model.phase == .answering,
                    scored: model.phase == .reveal ? model.lastRound?.player : nil,
                    mirrored: false
                )
                DuelTimerRing(model: model)
                DuelScoreSide(
                    avatarId: opponent.avatarId,
                    initial: opponent.initial,
                    name: "@\(opponent.handle)",
                    score: model.opponentScore,
                    tint: DuelPalette.saffron,
                    scoreColor: DS.inkTertiary,
                    isPlayer: false,
                    answered: model.opponentAnswered && model.phase == .answering,
                    scored: model.phase == .reveal ? model.lastRound?.opponent : nil,
                    mirrored: true
                )
            }

            Rectangle()
                .fill(DuelTheme.scoreRule)
                .frame(height: 1)

            DuelScoreBoard(
                playerMarks: model.playerMarks,
                opponentMarks: model.opponentMarks,
                current: model.index,
                currentRound: model.index < model.questionCount ? model.roundNumber : 0,
                opponentName: opponent.handle
            )
        }
        .padding(.top, 14)
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(DuelTheme.scoreBlock)
        )
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: - Question

    /// La manche en cours est le sprint final.
    private var isSprint: Bool {
        guard model.index < model.questionCount else { return false }
        let position = model.roundNumber - 1
        guard model.match.rounds.indices.contains(position) else { return false }
        return model.match.rounds[position].kind == .sprint
    }

    /// Le sur-titre de la question : la matière de la manche au choix, ou « Sprint final ».
    @ViewBuilder
    private var questionEyebrow: some View {
        if let subject = model.currentSubject {
            HStack(spacing: 6) {
                Image(systemName: DuelSubjects.icon(subject))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(DuelSubjects.color(subject)))
                Text(DuelSubjects.name(subject, language: languageManager.current).uppercased())
                    .font(.jakarta(size: 12, weight: .heavy))
                    .tracking(0.8)
                    .foregroundStyle(DS.accent)
            }
        } else if isSprint {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11, weight: .bold))
                Text(languageManager.text("duel.round.sprint.title").uppercased())
                    .font(.jakarta(size: 12, weight: .heavy))
                    .tracking(0.8)
            }
            .foregroundStyle(DS.accent)
        }
    }

    private var questionArea: some View {
        let question = model.question
        let long: Bool = question.question.count > 90
        let questionStyle: Font.TextStyle = (question.kind == .portrait || long) ? .title2 : .title
        return VStack(spacing: 12) {
            questionEyebrow

            if question.kind == .portrait {
                // L'image seule, entière et à ses proportions : ni cadre ni fond derrière elle.
                // Sans touches : elle ne doit pas couvrir les réponses.
                DuelQuestionImage(url: question.imageURL)
                    .frame(maxWidth: 280)
                    .frame(height: 230)
                    .allowsHitTesting(false)
            }

            Text(question.question)
                .font(DS.title(questionStyle, .bold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(1)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 10)

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

    // MARK: - Bandeau de verdict

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

    /// Le ton du bandeau : vert quand le joueur marque, rouge sinon, neutre hors verdict.
    private enum VerdictTone: Equatable {
        case neutral
        case good
        case bad
    }

    private var verdictTone: VerdictTone {
        guard model.phase == .reveal, !model.opponentForfeited, let round = model.lastRound else { return .neutral }
        return round.player ? .good : .bad
    }

    private var statusColor: Color {
        switch verdictTone {
        case .neutral: DS.inkSecondary
        case .good: DS.success
        case .bad: DS.danger
        }
    }

    private var verdictFill: Color {
        switch verdictTone {
        case .neutral: DuelTheme.scoreBlock
        case .good: DS.successTint
        case .bad: DS.dangerTint
        }
    }

    /// Où en est le score après la question : « tu mènes 4 à 3 ».
    private var standingText: String {
        let mine: Int = model.playerScore
        let theirs: Int = model.opponentScore
        if mine > theirs {
            return String(format: languageManager.text("duel.verdict.leading"), mine, theirs)
        }
        if theirs > mine {
            return String(format: languageManager.text("duel.verdict.trailing"), opponent.handle, theirs, mine)
        }
        return String(format: languageManager.text("duel.verdict.tied"), mine)
    }

    /// La partie droite du bandeau, à la révélation : « +1 point · tu mènes 4 à 3 ». Rien pour
    /// la question décisive, qui ne compte pas au score.
    private var verdictDetail: String? {
        guard model.phase == .reveal, !model.opponentForfeited, !model.isSuddenDeath,
              let round = model.lastRound else { return nil }
        var parts: [String] = []
        if round.player {
            parts.append(languageManager.text("duel.verdict.point"))
        }
        parts.append(standingText)
        return parts.joined(separator: " · ")
    }

    /// Le joueur a répondu et attend l'adversaire : trois points sautillent dans le bandeau.
    private var isWaitingForOpponent: Bool {
        model.phase == .answering && !model.opponentForfeited && !model.opponentLeft
            && model.playerLocked && !model.opponentAnswered
    }

    private var verdictBanner: some View {
        let text: String = statusText
        let visible: Bool = !text.trimmingCharacters(in: .whitespaces).isEmpty
        return HStack(spacing: 10) {
            Text(text)
                .font(DS.sans(.callout, .heavy))
                .foregroundStyle(statusColor)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .contentTransition(.opacity)
            Spacer(minLength: 0)
            if let detail = verdictDetail {
                Text(detail)
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(statusColor)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .transition(.opacity)
            } else if isWaitingForOpponent {
                DuelWaitingDots(color: DS.inkSecondary)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(verdictFill)
        )
        .opacity(visible ? 1 : 0)
        .scaleEffect(visible ? 1 : 0.97)
        .dsShake(trigger: verdictShake)
        .animation(DS.Motion.snappy, value: text)
        .animation(DS.Motion.snappy, value: verdictTone)
        .accessibilityElement(children: .combine)
        .accessibilityHidden(!visible)
    }

    // MARK: - Question décisive

    private var suddenDeathBanner: some View {
        ZStack {
            DS.canvas.opacity(0.97).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(DS.accent)
                    .frame(width: 88, height: 88)
                    .background(Circle().fill(DS.accentTint))
                    .dsPopIn(delay: 0.1)
                Text(languageManager.text("duel.suddenDeath.title"))
                    .font(DS.title(.largeTitle, .heavy))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)
                Text(String(format: languageManager.text("duel.suddenDeath.body"), model.playerScore, model.opponentScore))
                    .font(DS.sans(.body, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
    }
}

/// Un camp dans le bloc de score : l'avatar cerclé, le score en grand et le nom dessous. Le
/// score rebondit quand il monte ; le cercle passe au vert ou au rouge pendant la révélation.
private struct DuelScoreSide: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let avatarId: String?
    let initial: String
    let name: String
    let score: Int
    /// La couleur du camp (cercle de l'avatar).
    let tint: Color
    let scoreColor: Color
    let isPlayer: Bool
    /// Le camp a répondu, la révélation n'est pas encore tombée.
    let answered: Bool
    /// Vrai ou faux pendant la révélation, `nil` sinon.
    let scored: Bool?
    /// Le camp de droite : nom et score à gauche de l'avatar, alignés à droite.
    let mirrored: Bool

    @State private var bump = false

    private var ringColor: Color {
        guard let scored else { return tint }
        return scored ? DuelTheme.stripRight : DuelTheme.stripWrong
    }

    private var avatar: some View {
        AvatarCircle(avatarId: avatarId, initial: initial, size: 48)
            .overlay(Circle().strokeBorder(ringColor, lineWidth: scored == nil ? 3 : 4))
            .overlay(alignment: mirrored ? .bottomLeading : .bottomTrailing) {
                if answered {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(DS.accent))
                        .overlay(Circle().strokeBorder(DuelTheme.scoreBlock, lineWidth: 2))
                        .offset(x: mirrored ? -4 : 4, y: 4)
                        .transition(.scale(scale: 0.1).combined(with: .opacity))
                }
            }
            .scaleEffect(answered ? 1.06 : 1)
    }

    private var labels: some View {
        VStack(alignment: mirrored ? .trailing : .leading, spacing: 3) {
            Text("\(score)")
                .font(.jakarta(size: 36, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(scoreColor)
                .contentTransition(.numericText())
                .frame(height: 38)
                .scaleEffect(bump ? 1.3 : 1, anchor: mirrored ? .bottomTrailing : .bottomLeading)
            Text(name)
                .font(.jakarta(size: 12, weight: isPlayer ? .bold : .semibold))
                .foregroundStyle(isPlayer ? DS.ink : DS.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            if mirrored {
                labels
                avatar
            } else {
                avatar
                labels
            }
        }
        .frame(maxWidth: .infinity, alignment: mirrored ? .trailing : .leading)
        .onChange(of: score) { old, new in
            guard new > old, !reduceMotion else { return }
            withAnimation(DS.Motion.pop) { bump = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(DS.Motion.snappy) { bump = false }
            }
        }
    }
}

/// L'image d'une question (portrait, drapeau, tableau, monument) : montrée entière, à ses
/// proportions, coins arrondis, sans fond. Un drapeau arrive avec une marge beige cuite dans son
/// fichier : elle est rognée (`DuelImageTrimmer`) et le drapeau se pose à même la page, avec un
/// filet pour que ses bords blancs se détachent. L'image est déjà en cache, chargée pendant la
/// présentation de l'adversaire ; tant qu'elle n'est pas là, la place reste vide.
private struct DuelQuestionImage: View {
    let url: String?
    @State private var image: UIImage?
    /// Un drapeau rogné : coins moins ronds et filet.
    @State private var flat = false

    var body: some View {
        ZStack {
            if let image {
                let radius: CGFloat = flat ? 8 : 16
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(DS.hairline.opacity(flat ? 1 : 0), lineWidth: 1.5)
                    )
                    .padding(.vertical, flat ? 8 : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: url) {
            guard let url else {
                image = nil
                return
            }
            if let cached = RemoteImageLoader.cached(url) {
                show(cached, url: url)
                return
            }
            image = nil
            if let loaded = await RemoteImageLoader.image(url) {
                show(loaded, url: url)
            }
        }
        .accessibilityHidden(true)
    }

    private func show(_ loaded: UIImage, url: String) {
        let result = DuelImageTrimmer.trimmed(loaded, key: url)
        flat = result.flat
        image = result.image
    }
}
