import SwiftUI

/// Un duel entre amis en plein écran : l'attente de la réponse à un défi (15 secondes), le
/// compte à rebours commun, la partie en direct, puis le résultat. Aucun trophée en jeu.
struct DuelFriendFlowView: View {
    @Environment(LanguageManager.self) private var languageManager
    let entry: DuelFriendEntry
    let onClose: () -> Void

    private enum Stage: Equatable {
        /// Le défi est parti, on attend la réponse de l'ami.
        case waiting
        /// Refusé, sans réponse, ami occupé, ou envoi impossible.
        case failed
        /// La partie est créée : 3, 2, 1.
        case countdown
        case playing
        case result
    }

    @State private var stage: Stage = .waiting
    @State private var me: DuelOpponent?
    @State private var friend: DuelOpponent?
    @State private var friendOnline = false
    @State private var inviteId: UUID?
    @State private var waitingDeadline: Date?
    @State private var failureKey = "duel.friend.noAnswer"
    @State private var countdown: Int?
    @State private var game: DuelGameModel?
    @State private var summary: DuelSummary?
    /// Numéro de la tentative : une revanche repart d'un défi neuf.
    @State private var attempt = 0
    /// L'ami à défier pour cette tentative (l'adversaire de la partie finie, pour une revanche).
    @State private var target: (userId: UUID, handle: String, avatarId: String?)?

    private let service = DuelLiveService.shared

    private var player: DuelPlayerIdentity {
        DuelPlayerIdentity(
            handle: me?.handle ?? DuelService.shared.home?.handle ?? SocialService.shared.myHandle ?? "",
            avatarId: me?.avatarId,
            trophies: me?.trophies ?? DuelService.shared.home?.profile.trophies ?? 0
        )
    }

    var body: some View {
        ZStack {
            DuelPalette.night.ignoresSafeArea()

            switch stage {
            case .waiting, .failed, .countdown:
                lobby
                    .transition(.opacity)
            case .playing:
                if let game {
                    DuelGameView(
                        model: game,
                        player: player,
                        onFinished: {
                            if stage == .playing { finish(game.summary) }
                        },
                        onAbandon: { abandon(game) }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            case .result:
                if let summary {
                    DuelResultView(
                        summary: summary,
                        player: player,
                        home: DuelService.shared.home,
                        result: nil,
                        resultFailed: false,
                        onRetrySend: {},
                        onPlayAgain: rematch,
                        onDone: onClose
                    )
                    .id(summary.match.matchId)
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: stage)
        .statusBarHidden()
        .task(id: attempt) { await run() }
        // « Occupé » tant qu'un défi attend ou qu'une partie se joue ; sur l'écran de résultat, on
        // redevient défiable (c'est ce qui permet la revanche), et le serveur l'apprend tout de suite.
        .onChange(of: stage, initial: true) { _, value in
            let busy = value == .waiting || value == .countdown || value == .playing
            service.isInFriendDuel = busy
            if !busy { service.pingNow() }
        }
        .onDisappear {
            // Écran fermé autrement que par ses boutons : on ne laisse ni invitation ni partie en plan.
            if stage == .playing, let game {
                let matchId = game.match.matchId
                Task { await service.leave(matchId: matchId) }
            }
            if let inviteId {
                Task { await service.cancelInvite(inviteId) }
            }
            service.isInFriendDuel = false
            service.pingNow()
        }
    }

    // MARK: - Attente et compte à rebours

    private var lobby: some View {
        ZStack {
            DuelLeagueBackdrop(league: DuelService.shared.home?.currentLeague)
                .ignoresSafeArea()
            LinearGradient(
                colors: [DuelPalette.night.opacity(0.72), DuelPalette.night.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Text(languageManager.text("duel.friend.title").uppercased())
                    .font(DS.sans(.caption, .bold))
                    .tracking(1.6)
                    .foregroundStyle(DuelPalette.saffron)
                    .padding(.top, 18)

                Spacer(minLength: 12)
                card(friend, fallbackHandle: target?.handle, fallbackAvatar: target?.avatarId, ring: DuelPalette.coral, online: friendOnline && stage == .waiting)
                badge
                    .padding(.vertical, 26)
                card(me, fallbackHandle: player.handle, fallbackAvatar: player.avatarId, ring: DuelPalette.saffron, online: false)
                Spacer(minLength: 12)

                footer
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    private func card(_ who: DuelOpponent?, fallbackHandle: String?, fallbackAvatar: String?, ring: Color, online: Bool) -> some View {
        let handle = who?.handle ?? fallbackHandle ?? ""
        return VStack(spacing: 12) {
            DuelAvatar(
                avatarId: who?.avatarId ?? fallbackAvatar,
                initial: String(handle.prefix(1)).uppercased(),
                size: 104,
                ring: ring,
                ringWidth: 4
            )
            .overlay(alignment: .bottomTrailing) {
                if online {
                    DuelOnlineDot(size: 20)
                        .offset(x: -4, y: -4)
                }
            }
            VStack(spacing: 6) {
                Text("@\(handle)")
                    .font(.jakarta(size: 22, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let who {
                    DuelTrophyCount(value: who.trophies, size: 16, color: .white)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Le rond central : les secondes qui restent à l'ami pour répondre, puis 3, 2, 1.
    private var badge: some View {
        ZStack {
            Circle()
                .fill(stage == .failed ? Color.white.opacity(0.2) : DuelPalette.saffron)
                .frame(width: 72, height: 72)
                .shadow(color: DuelPalette.saffron.opacity(stage == .failed ? 0 : 0.5), radius: 18, x: 0, y: 0)
            if let countdown {
                Text("\(countdown)")
                    .font(.jakarta(size: 38, weight: .heavy))
                    .foregroundStyle(DuelPalette.night)
                    .id(countdown)
                    .transition(.scale(scale: 2.2).combined(with: .opacity))
            } else if stage == .waiting, let waitingDeadline {
                TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
                    Text("\(max(Int(waitingDeadline.timeIntervalSince(timeline.date).rounded(.up)), 0))")
                        .font(.jakarta(size: 30, weight: .heavy))
                        .monospacedDigit()
                        .foregroundStyle(DuelPalette.night)
                        .contentTransition(.numericText(countsDown: true))
                }
            } else {
                Text("VS")
                    .font(.jakarta(size: 24, weight: .heavy))
                    .foregroundStyle(stage == .failed ? .white : DuelPalette.night)
            }
        }
        .scaleEffect(stage == .countdown ? 1.12 : 1)
    }

    @ViewBuilder
    private var footer: some View {
        switch stage {
        case .waiting where target == nil:
            // Invitation acceptée : la partie arrive, rien à attendre ni à annuler.
            Color.clear.frame(height: 40)
        case .waiting:
            VStack(spacing: 14) {
                Text(String(format: languageManager.text("duel.game.waiting"), friend?.handle ?? target?.handle ?? ""))
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                Button {
                    DuelHaptics.tap()
                    cancel()
                } label: {
                    Text(languageManager.text("duel.friend.cancel"))
                        .font(DS.sans(.headline, .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Capsule().fill(Color.white.opacity(0.16)))
                }
                .buttonStyle(SoftPressButtonStyle())
            }
        case .failed:
            VStack(spacing: 14) {
                Text(String(format: languageManager.text(failureKey), friend?.handle ?? target?.handle ?? ""))
                    .font(DS.sans(.body, .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Button {
                    DuelHaptics.tap()
                    onClose()
                } label: {
                    Text(languageManager.text("common.close"))
                }
                .buttonStyle(DuelPlayButtonStyle())
            }
        default:
            Text(languageManager.text("duel.friend.ready"))
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(minHeight: 40)
        }
    }

    // MARK: - Déroulé

    private func run() async {
        if attempt == 0, case .incoming(let start) = entry {
            // Invitation acceptée : la partie existe déjà.
            await begin(start)
            return
        }
        if target == nil, case .challenge(let userId, let handle, let avatarId) = entry {
            target = (userId, handle, avatarId)
        }
        guard let target else { return }

        withAnimation { stage = .waiting }
        countdown = nil
        inviteId = nil
        waitingDeadline = nil

        let sent: DuelSentInvite
        do {
            // L'envoi va jusqu'au bout même si l'écran se ferme entre-temps : l'invitation
            // créée côté serveur peut alors être annulée, au lieu de rester sans personne.
            let friendId = target.userId
            sent = try await Task { try await DuelLiveService.shared.invite(friend: friendId) }.value
        } catch let error as DuelInviteError {
            fail(error == .friendBusy ? "duel.friend.busy" : (error == .friendUnavailable ? "duel.friend.unavailable" : "duel.friend.failed"))
            return
        } catch {
            fail("duel.friend.failed")
            return
        }
        guard !Task.isCancelled else {
            Task { await DuelLiveService.shared.cancelInvite(sent.inviteId) }
            return
        }
        me = sent.me
        friend = sent.friend
        friendOnline = sent.online
        inviteId = sent.inviteId
        waitingDeadline = Date().addingTimeInterval(Double(sent.expiresInMs) / 1000)

        // On interroge le serveur chaque seconde jusqu'à la réponse de l'ami.
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled else { return }
            guard let outcome = try? await service.inviteStatus(sent.inviteId) else {
                if let waitingDeadline, Date() > waitingDeadline.addingTimeInterval(8) {
                    fail("duel.friend.noAnswer")
                    return
                }
                continue
            }
            switch outcome.status {
            case "pending":
                continue
            case "accepted":
                if let start = outcome.match {
                    inviteId = nil
                    await begin(start)
                    return
                }
            case "declined":
                fail("duel.friend.declined")
                return
            case "busy":
                fail("duel.friend.busy")
                return
            default:
                fail("duel.friend.noAnswer")
                return
            }
        }
    }

    private func fail(_ key: String) {
        inviteId = nil
        failureKey = key
        DuelHaptics.wrong()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { stage = .failed }
    }

    /// La partie est créée : les deux joueurs la démarrent au même instant.
    private func begin(_ start: DuelFriendStart) async {
        let startsAt = Date().addingTimeInterval(Double(max(start.startsInMs, 0)) / 1000)
        me = start.me
        friend = start.opponent
        let images = start.match.allQuestions.compactMap(\.imageURL)
        Task {
            for url in images {
                _ = await RemoteImageLoader.image(url)
            }
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { stage = .countdown }
        DuelHaptics.opponentFound()

        for value in [3, 2, 1] {
            let showAt = startsAt.addingTimeInterval(-Double(value))
            let wait = showAt.timeIntervalSinceNow
            if wait > 0 {
                try? await Task.sleep(for: .seconds(wait))
            }
            guard !Task.isCancelled else { return }
            if startsAt.timeIntervalSinceNow > Double(value) - 1 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { countdown = value }
                DuelHaptics.countdown(final: false)
            }
        }
        let wait = startsAt.timeIntervalSinceNow
        if wait > 0 {
            try? await Task.sleep(for: .seconds(wait))
        }
        guard !Task.isCancelled else { return }
        DuelHaptics.countdown(final: true)
        game = DuelGameModel(match: start.match, live: DuelLiveLink(matchId: start.matchId, startsAt: startsAt))
        stage = .playing
    }

    private func cancel() {
        if let inviteId {
            Task { await service.cancelInvite(inviteId) }
        }
        onClose()
    }

    private func finish(_ summary: DuelSummary) {
        self.summary = summary
        stage = .result
    }

    /// Quitter en pleine partie : j'ai perdu ; mon ami la finit seul.
    private func abandon(_ game: DuelGameModel) {
        let matchId = game.match.matchId
        Task { await service.leave(matchId: matchId) }
        finish(DuelSummary(
            match: game.match,
            playerScore: game.playerScore,
            opponentScore: game.opponentScore,
            won: false,
            abandoned: true,
            tiebreak: false,
            answers: game.answers,
            friendly: true
        ))
    }

    /// Revanche : un nouveau défi au même ami.
    private func rematch() {
        guard let opponent = summary?.match.opponent, let userId = opponent.userId else {
            onClose()
            return
        }
        target = (userId, opponent.handle, opponent.avatarId)
        game = nil
        summary = nil
        attempt += 1
    }
}

/// La pastille verte d'un ami qui a l'app ouverte.
struct DuelOnlineDot: View {
    var size: CGFloat = 12

    var body: some View {
        Circle()
            .fill(Color(red: 0.25, green: 0.78, blue: 0.47))
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(.white, lineWidth: max(size * 0.16, 1.5)))
            .accessibilityHidden(true)
    }
}
