import SwiftUI

/// La fin d'une partie (maquette AEr25). L'écran s'ouvre sur les deux joueurs face à face : leurs
/// bonnes réponses défilent de zéro à leur total, de plus en plus lentement, puis l'issue se
/// dévoile (titre, couronne, confettis pour une victoire ; plus calme pour une défaite ou une
/// égalité). Viennent ensuite les trophées qui défilent jusqu'à leur nouveau total, la jauge de
/// ligue qui avance, et la montée de ligue quand un seuil tombe. Le score est connu tout de
/// suite ; les trophées arrivent avec la réponse du serveur (`result`), qui fait foi.
/// « Revoir les questions » ouvre la relecture de la partie (`DuelReviewView`).
struct DuelResultView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let summary: DuelSummary
    let player: DuelPlayerIdentity
    let home: DuelHome?
    let result: DuelResult?
    let resultFailed: Bool
    let onRetrySend: () -> Void
    let onPlayAgain: () -> Void
    let onDone: () -> Void

    @State private var appeared = false
    /// Les bonnes réponses affichées pendant le décompte d'ouverture.
    @State private var shownPlayerScore = 0
    @State private var shownOpponentScore = 0
    /// Le décompte est fini : le titre, la couronne et les confettis se montrent.
    @State private var revealed = false
    @State private var showReview = false
    @State private var shownTrophies = 0
    @State private var barProgress: Double = 0
    @State private var shownLeaguePosition: Int?
    @State private var showDelta = false
    @State private var promotedLeague: DuelLeague?

    private var won: Bool { result?.won ?? summary.won }
    /// Duel entre amis : aucun trophée en jeu, la carte des trophées laisse place à une note.
    private var friendly: Bool { summary.friendly }
    private var opponent: DuelOpponent { summary.match.opponent }

    private var shownLeague: DuelLeague? {
        guard let position = shownLeaguePosition else { return home?.currentLeague }
        return home?.league(position: position)
    }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headline
                    faces
                    trophyCard
                    reviewButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 44)
                .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .bottom, spacing: 0) { actions }

            if won && revealed && !reduceMotion {
                PathConfettiBurst(colors: DuelTheme.confetti, pieceCount: 120, duration: 3.0, origin: CGPoint(x: 0.5, y: 0.22))
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            if let promotedLeague {
                DuelPromotionView(league: promotedLeague) {
                    withAnimation(.easeInOut(duration: 0.35)) { self.promotedLeague = nil }
                }
                .transition(.opacity)
                .zIndex(2)
            }

            if showReview {
                DuelReviewView(
                    entries: summary.review,
                    questionCount: summary.match.questionCount,
                    player: player,
                    opponent: opponent,
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.3)) { showReview = false }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(3)
            }
        }
        .onAppear {
            // Les exploits de la partie (score, écart, question décisive) comptent pour les badges.
            BadgeCounters.record(summary)
        }
        .task { await playOpening() }
        // Les trophées défilent une fois l'issue dévoilée, dès que le serveur a répondu.
        .task(id: trophiesKey) {
            guard let result else { return }
            if revealed {
                await playTrophies(result)
            } else {
                // La carte, encore cachée, part de l'ancien total : elle n'a pas à défiler depuis zéro.
                shownTrophies = result.trophiesBefore
                shownLeaguePosition = result.leagueBefore
                barProgress = home?.leagueProgress(forTrophies: result.trophiesBefore) ?? 0
            }
        }
    }

    private var trophiesKey: String {
        "\(result?.matchId.uuidString ?? "-")|\(revealed)"
    }

    // MARK: - Ouverture

    /// Les deux scores défilent ensemble de zéro à leur total (le plus petit s'arrête le premier),
    /// vite puis de plus en plus lentement, avec un cran de vibration par point ; l'issue se
    /// dévoile ensuite. Avec « Réduire les animations », tout est en place d'emblée.
    private func playOpening() async {
        let playerTotal = max(summary.playerScore, 0)
        let opponentTotal = max(summary.opponentScore, 0)
        guard !reduceMotion else {
            shownPlayerScore = playerTotal
            shownOpponentScore = opponentTotal
            appeared = true
            revealed = true
            outcomeHaptic()
            return
        }
        withAnimation(.easeOut(duration: 0.35)) { appeared = true }
        try? await Task.sleep(for: .seconds(0.55))
        guard !Task.isCancelled else { return }

        let steps = max(playerTotal, opponentTotal)
        if steps > 0 {
            for step in 1...steps {
                let progress = Double(step) / Double(steps)
                withAnimation(.snappy(duration: 0.16)) {
                    shownPlayerScore = min(step, playerTotal)
                    shownOpponentScore = min(step, opponentTotal)
                }
                DuelHaptics.trophyTick(progress: progress)
                // De 55 ms au départ à 330 ms sur les derniers points.
                try? await Task.sleep(for: .milliseconds(55 + Int(275 * progress * progress)))
                guard !Task.isCancelled else { return }
            }
        }
        try? await Task.sleep(for: .seconds(0.25))
        guard !Task.isCancelled else { return }
        // Un ressort amorti : le titre se pose sans rebondir à l'excès.
        withAnimation(.spring(response: 0.5, dampingFraction: 0.74)) { revealed = true }
        outcomeHaptic()
    }

    private func outcomeHaptic() {
        if won {
            Haptics.celebrate()
        } else if !summary.draw {
            DuelHaptics.defeat()
        }
    }

    // MARK: - Titre et score

    private var headlineKey: String {
        if summary.abandoned { return "duel.result.abandoned" }
        if summary.draw { return "duel.result.draw" }
        return won ? "duel.result.victory" : "duel.result.defeat"
    }

    private var headline: some View {
        VStack(spacing: 6) {
            Text(languageManager.text(headlineKey))
                .font(DS.title(.largeTitle, .heavy))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                // Une victoire arrive de plus loin qu'une défaite ou une égalité.
                .scaleEffect(revealed ? 1 : (won ? 0.55 : 0.9))
                .opacity(revealed ? 1 : 0)
            if summary.forfeit {
                Text(String(format: languageManager.text("duel.friend.left"), opponent.handle))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(revealed ? 1 : 0)
            } else if summary.tiebreak && !summary.abandoned {
                Text(languageManager.text("duel.result.suddenDeath"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .opacity(revealed ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity)
        // Tant que l'issue n'est pas dévoilée, le titre n'est pas lu non plus.
        .accessibilityHidden(!revealed)
    }

    private var faces: some View {
        HStack(alignment: .center, spacing: 18) {
            face(
                avatarId: player.avatarId,
                initial: player.initial,
                name: "@\(player.handle)",
                crowned: revealed && won && !summary.draw,
                faded: revealed && !won && !summary.draw
            )
            Text("\(shownPlayerScore) – \(shownOpponentScore)")
                .font(DS.title(.largeTitle, .heavy))
                .monospacedDigit()
                .foregroundStyle(DS.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
                .environment(\.layoutDirection, .leftToRight)
                .accessibilityLabel(Text("\(summary.playerScore) – \(summary.opponentScore)"))
            face(
                avatarId: opponent.avatarId,
                initial: opponent.initial,
                name: "@\(opponent.handle) \(opponent.flag)",
                crowned: revealed && !won && !summary.draw,
                faded: revealed && won && !summary.draw
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
    }

    /// Un joueur : le vainqueur porte la couronne et un cercle safran, le perdant passe en gris.
    private func face(avatarId: String?, initial: String, name: String, crowned: Bool, faded: Bool) -> some View {
        VStack(spacing: 4) {
            AvatarCircle(avatarId: avatarId, initial: initial, size: 76)
                .overlay(
                    Circle().strokeBorder(crowned ? DuelPalette.saffron : DS.hairline, lineWidth: crowned ? 3 : 1.5)
                )
                .saturation(faded ? 0 : 1)
                .opacity(faded ? 0.7 : 1)
                // Le vainqueur grandit un peu quand l'issue tombe.
                .scaleEffect(crowned ? 1.06 : 1)
                .overlay(alignment: .top) {
                    if crowned {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(DuelPalette.saffron)
                            .offset(y: -20)
                            .transition(.scale(scale: 0.2, anchor: .bottom).combined(with: .opacity))
                    }
                }
            Text(name)
                .font(.jakarta(size: 13, weight: .bold))
                .foregroundStyle(DS.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }

    // MARK: - Trophées

    private var trophyCard: some View {
        VStack(spacing: 10) {
            if friendly {
                friendlyNote
            } else if let result {
                trophyCount(result)
                leagueGauge
            } else if resultFailed {
                syncFailedNote
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
            }
        }
        .dsCard(padding: 16)
        .opacity(revealed ? 1 : 0)
        .offset(y: revealed ? 0 : 40)
    }

    /// « Revoir les questions » : la relecture de la partie, question par question.
    @ViewBuilder
    private var reviewButton: some View {
        if !summary.review.isEmpty {
            Button {
                DuelHaptics.tap()
                withAnimation(.easeInOut(duration: 0.3)) { showReview = true }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(DS.accent)
                    Text(languageManager.text("duel.review.open"))
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(DS.ink)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.inkTertiary)
                }
                .dsCard(padding: 16, shadow: false)
                .contentShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
            }
            .buttonStyle(PressableStyle(scale: 0.97, haptic: false))
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 40)
            .disabled(!revealed)
        }
    }

    private var friendlyNote: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(DS.accent)
                .frame(width: 52, height: 52)
                .background(Circle().fill(DS.accentTint))
            Text(languageManager.text("duel.friend.noTrophies"))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    /// L'illustration du trophée, le total qui défile et le gain (ou la perte) de la partie.
    private func trophyCount(_ result: DuelResult) -> some View {
        HStack(spacing: 12) {
            Image("duel_trophy")
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .rotationEffect(.degrees(showDelta && won ? -4 : 0))
                .scaleEffect(showDelta && won ? 1.06 : 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(languageManager.text("duel.trophies.title").uppercased())
                    .font(.jakarta(size: 12, weight: .heavy))
                    .tracking(0.8)
                    .foregroundStyle(DS.inkSecondary)
                Text(shownTrophies.formatted(language: languageManager.current))
                    .font(.jakarta(size: 26, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(DS.ink)
                    .contentTransition(.numericText(countsDown: result.trophiesDelta < 0))
            }
            Spacer(minLength: 0)
            if showDelta {
                deltaChip(result.trophiesDelta)
                    .transition(.scale(scale: 0.3, anchor: .trailing).combined(with: .opacity))
            }
        }
    }

    /// La ligue affichée, le seuil de la suivante, la jauge et ce qu'il reste à gagner.
    private var leagueGauge: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(DuelFormat.leagueName(shownLeague, language: languageManager.current))
                    .font(.jakarta(size: 13, weight: .bold))
                    .foregroundStyle(DS.ink)
                Spacer()
                if let next = home?.nextLeague(after: shownLeague) {
                    DuelTrophyCount(value: next.minTrophies, size: 13, color: DS.ink)
                }
            }
            DuelProgressBar(progress: barProgress, tint: DuelPalette.saffron, track: DS.ink.opacity(0.12), height: 8)
            Text(nextLeagueCaption)
                .font(.jakarta(size: 13, weight: .regular))
                .foregroundStyle(DS.inkSecondary)
        }
    }

    private var syncFailedNote: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(DS.inkTertiary)
            Text(languageManager.text("duel.result.syncFailed"))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
            Button(languageManager.text("duel.match.retry")) {
                DuelHaptics.tap()
                onRetrySend()
            }
            .font(DS.sans(.subheadline, .bold))
            .foregroundStyle(DS.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var nextLeagueCaption: String {
        guard let next = home?.nextLeague(after: shownLeague) else {
            return languageManager.text("duel.league.top")
        }
        let missing = max(next.minTrophies - shownTrophies, 0)
        return String(
            format: languageManager.text("duel.league.toNext"),
            missing,
            DuelFormat.leagueName(next, language: languageManager.current)
        )
    }

    /// Le gain de la partie, qui défile de zéro à sa valeur pendant que le total avance. Sans
    /// vibration propre : le défilement du total vibre déjà (`DuelHaptics.trophyTick`).
    private func deltaChip(_ delta: Int) -> some View {
        let color = delta > 0 ? DS.success : (delta < 0 ? DS.danger : DS.inkTertiary)
        let tint = delta > 0 ? DS.successTint : (delta < 0 ? DS.dangerTint : DS.accentTint)
        return DSCountUp(
            value: delta,
            duration: 0.8,
            font: .jakarta(size: 15, weight: .heavy),
            color: color,
            prefix: delta > 0 ? "+" : "",
            haptics: false
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(tint))
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                DuelHaptics.countdown(final: false)
                onPlayAgain()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text(languageManager.text(friendly ? "duel.friend.rematch" : "duel.result.again"))
                }
            }
            .buttonStyle(DuelPlayButtonStyle())

            // Le bouton secondaire vibre de lui-même.
            Button {
                onDone()
            } label: {
                Text(languageManager.text("duel.result.done"))
            }
            .buttonStyle(DSSecondaryButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(DS.canvas)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Le compteur

    /// Les trophées défilent de l'ancien total au nouveau, la jauge suit, puis la nouvelle ligue
    /// s'annonce si un seuil vient de tomber.
    private func playTrophies(_ result: DuelResult) async {
        shownTrophies = result.trophiesBefore
        shownLeaguePosition = result.leagueBefore
        barProgress = home?.leagueProgress(forTrophies: result.trophiesBefore) ?? 0
        try? await Task.sleep(for: .seconds(0.6))
        guard !Task.isCancelled else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { showDelta = true }
        let delta = result.trophiesDelta
        let steps = min(abs(delta), 28)
        if steps > 0 {
            for step in 1...steps {
                let progress = Double(step) / Double(steps)
                let eased = 1 - (1 - progress) * (1 - progress)
                withAnimation(.snappy(duration: 0.12)) {
                    shownTrophies = result.trophiesBefore + Int((Double(delta) * eased).rounded())
                }
                DuelHaptics.trophyTick(progress: progress)
                try? await Task.sleep(for: .milliseconds(26 + Int(46 * progress)))
                guard !Task.isCancelled else { return }
            }
        }
        shownTrophies = result.trophiesAfter
        DuelHaptics.trophyLanded()

        withAnimation(.spring(response: 0.9, dampingFraction: 0.85)) {
            barProgress = result.promoted ? 1 : (home?.leagueProgress(forTrophies: result.trophiesAfter) ?? 0)
        }
        guard result.promoted, let league = home?.league(position: result.leagueAfter) else { return }
        try? await Task.sleep(for: .seconds(1.0))
        guard !Task.isCancelled else { return }
        withAnimation(.easeInOut(duration: 0.45)) { promotedLeague = league }
        DuelHaptics.promotion()
        // Sous l'annonce, la carte passe à la nouvelle ligue, jauge repartie de son seuil.
        shownLeaguePosition = result.leagueAfter
        barProgress = home?.leagueProgress(forTrophies: result.trophiesAfter) ?? 0
    }
}

/// L'annonce d'une montée de ligue : l'illustration de la nouvelle ligue en plein écran, son nom
/// qui se pose, des confettis.
struct DuelPromotionView: View {
    @Environment(LanguageManager.self) private var languageManager
    let league: DuelLeague
    let onContinue: () -> Void

    @State private var revealed = false

    var body: some View {
        ZStack {
            DuelLeagueBackdrop(league: league)
                .scaleEffect(revealed ? 1 : 1.25)
                .ignoresSafeArea()
            LinearGradient(
                colors: [.clear, DuelTheme.scrim.opacity(0.35), DuelTheme.scrim.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                Spacer()
                Text(languageManager.text("duel.promotion.title").uppercased())
                    .font(.jakarta(size: 13, weight: .heavy))
                    .tracking(1.6)
                    .foregroundStyle(DuelPalette.saffron)
                    .opacity(revealed ? 1 : 0)
                    .offset(y: revealed ? 0 : 16)
                Text(DuelFormat.leagueName(league, language: languageManager.current))
                    .font(.jakarta(size: 40, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .scaleEffect(revealed ? 1 : 0.5)
                    .opacity(revealed ? 1 : 0)
                HStack(spacing: 8) {
                    Text(String(format: languageManager.text("duel.league.position"), league.position))
                        .font(DS.sans(.subheadline, .semibold))
                        .foregroundStyle(DuelTheme.onArtSecondary)
                    Text("·")
                        .foregroundStyle(.white.opacity(0.5))
                    DuelTrophyCount(value: league.minTrophies, size: 15, color: .white)
                }
                .opacity(revealed ? 1 : 0)

                Button {
                    DuelHaptics.tap()
                    onContinue()
                } label: {
                    Text(languageManager.text("duel.promotion.continue"))
                }
                .buttonStyle(DuelPlayButtonStyle())
                .padding(.top, 18)
                .opacity(revealed ? 1 : 0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)

            PathConfettiBurst(colors: DuelPalette.confetti, pieceCount: 160, duration: 3.4, origin: CGPoint(x: 0.5, y: 0.45))
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.3)) { revealed = true }
        }
    }
}
