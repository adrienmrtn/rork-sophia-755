import SwiftUI

/// La recherche d'un adversaire : les profils défilent, l'adversaire tiré par le serveur se pose,
/// puis 3, 2, 1 et la partie démarre. On peut annuler tant que la partie n'est pas créée.
struct DuelMatchmakingView: View {
    @Environment(LanguageManager.self) private var languageManager
    let player: DuelPlayerIdentity
    let league: DuelLeague?
    let onReady: (DuelMatch) -> Void
    let onCancel: () -> Void

    private enum Step: Equatable {
        case searching
        case found
        case failed
    }

    @State private var step: Step = .searching
    @State private var match: DuelMatch?
    @State private var canCancel = true
    @State private var shuffleAvatar = Avatars.all.randomElement()
    @State private var countdown: Int?
    @State private var attempt = 0
    @State private var appeared = false

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    if canCancel || step == .failed {
                        // Le bouton rond vibre de lui-même.
                        RoundIconButton(systemImage: "xmark", accessibilityLabel: languageManager.text("common.close")) {
                            onCancel()
                        }
                        .transition(.opacity)
                    }
                    Spacer()
                }
                .frame(height: 44)
                .overlay {
                    // La ligue dans laquelle la partie se joue.
                    if league != nil {
                        Text(DuelFormat.leagueName(league, language: languageManager.current).uppercased())
                            .font(.jakarta(size: 12, weight: .heavy))
                            .tracking(1)
                            .foregroundStyle(DS.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 56)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer(minLength: 12)

                opponentSlot
                    .offset(y: appeared ? 0 : -40)
                    .opacity(appeared ? 1 : 0)

                versusBadge
                    .padding(.vertical, 26)

                playerCard
                    .offset(y: appeared ? 0 : 40)
                    .opacity(appeared ? 1 : 0)

                Spacer(minLength: 12)

                footer
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
        .task(id: attempt) { await run() }
        .onAppear {
            withAnimation(DS.Motion.reveal) { appeared = true }
        }
    }

    // MARK: - Les deux camps

    /// L'emplacement de l'adversaire : les profils qui défilent au centre du radar pendant la
    /// recherche, puis l'adversaire tiré par le serveur.
    private var opponentSlot: some View {
        VStack(spacing: 12) {
            ZStack {
                if step == .searching {
                    DuelSearchRadar(color: DS.accent, size: 104)
                        .transition(.opacity)
                }
                if let opponent = match?.opponent, step == .found {
                    DuelAvatar(avatarId: opponent.avatarId, initial: opponent.initial, size: 104, ring: DuelPalette.saffron, ringWidth: 4)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                } else {
                    DuelAvatar(avatarId: shuffleAvatar, initial: "?", size: 104, ring: DS.surface, ringWidth: 4)
                        .blur(radius: step == .failed ? 6 : 1.5)
                        .opacity(step == .failed ? 0.4 : 0.9)
                }
            }
            .frame(height: 150)

            if let opponent = match?.opponent, step == .found {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text("@\(opponent.handle)")
                            .font(DS.title(.title3, .bold))
                            .foregroundStyle(DS.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(opponent.flag)
                            .font(.system(size: 20))
                    }
                    DuelTrophyCount(value: opponent.trophies, size: 15, color: DS.inkSecondary)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                VStack(spacing: 6) {
                    Text(languageManager.text(step == .failed ? "duel.match.failed.title" : "duel.match.searching"))
                        .font(DS.title(.title3, .bold))
                        .foregroundStyle(DS.ink)
                        .multilineTextAlignment(.center)
                    Text(languageManager.text(step == .failed ? "duel.match.failed.body" : "duel.match.searching.body"))
                        .font(DS.sans(.subheadline, .medium))
                        .foregroundStyle(DS.inkSecondary)
                        .multilineTextAlignment(.center)
                    if step == .searching {
                        DuelWaitingDots(color: DS.accent)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var playerCard: some View {
        DuelVersusCard(
            avatarId: player.avatarId,
            initial: player.initial,
            handle: player.handle,
            trophies: player.trophies,
            ring: DS.accent
        )
    }

    private var versusBadge: some View {
        DuelVersusBadge(number: countdown, counting: true)
            .scaleEffect(step == .found ? 1.12 : 1)
    }

    @ViewBuilder
    private var footer: some View {
        if step == .failed {
            Button {
                DuelHaptics.tap()
                attempt += 1
            } label: {
                Text(languageManager.text("duel.match.retry"))
            }
            .buttonStyle(DuelPlayButtonStyle())
        } else {
            Text(languageManager.text(step == .found ? "duel.match.found" : "duel.match.hint"))
                .font(DS.sans(.footnote, .semibold))
                .foregroundStyle(step == .found ? DS.accent : DS.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(minHeight: 40)
        }
    }

    // MARK: - Déroulé

    private func run() async {
        withAnimation(.easeOut(duration: 0.2)) {
            step = .searching
            match = nil
            countdown = nil
            canCancel = true
        }

        // Le défilement des profils, jusqu'à ce que l'adversaire soit connu.
        let shuffler = Task {
            while !Task.isCancelled {
                shuffleAvatar = Avatars.all.randomElement()
                DuelHaptics.tick()
                try? await Task.sleep(for: .milliseconds(120))
            }
        }
        defer { shuffler.cancel() }

        // Tant que la partie n'existe pas côté serveur, annuler ne coûte rien.
        try? await Task.sleep(for: .seconds(Double.random(in: 2.2...4.2)))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.2)) { canCancel = false }

        let fetched: DuelMatch
        do {
            fetched = try await startMatch()
        } catch {
            shuffler.cancel()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { step = .failed }
            DuelHaptics.wrong()
            return
        }
        guard !Task.isCancelled else { return }

        // Les portraits de la partie, chargés pendant la présentation de l'adversaire.
        let images = fetched.allQuestions.compactMap(\.imageURL)
        Task {
            for url in images {
                _ = await RemoteImageLoader.image(url)
            }
        }

        shuffler.cancel()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
            match = fetched
            step = .found
        }
        DuelHaptics.opponentFound()
        try? await Task.sleep(for: .seconds(1.7))
        guard !Task.isCancelled else { return }

        for value in [3, 2, 1] {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { countdown = value }
            DuelHaptics.countdown(final: false)
            try? await Task.sleep(for: .seconds(0.8))
            guard !Task.isCancelled else { return }
        }
        DuelHaptics.countdown(final: true)
        onReady(fetched)
    }
}

extension DuelMatchmakingView {
    /// Le lancement de la partie, borné dans le temps : une requête qui ne revient pas ne doit
    /// pas laisser le joueur devant une recherche sans fin ni bouton pour en sortir.
    private func startMatch() async throws -> DuelMatch {
        try await withThrowingTaskGroup(of: DuelMatch.self) { group in
            group.addTask { try await DuelService.shared.startMatch() }
            group.addTask {
                try await Task.sleep(for: .seconds(12))
                throw DuelError.underlying("timeout")
            }
            defer { group.cancelAll() }
            guard let match = try await group.next() else { throw DuelError.unavailable }
            return match
        }
    }
}

/// Des anneaux qui s'élargissent (l'adversaire choisit sa matière, un ami tarde à répondre).
/// Figés quand « Réduire les animations » est actif.
struct DuelPulseRings: View {
    var color: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animating = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 2)
                    .scaleEffect(animating ? 2.1 : 1)
                    .opacity(animating ? 0 : 0.7)
                    .animation(
                        .easeOut(duration: 1.8).repeatForever(autoreverses: false).delay(Double(index) * 0.6),
                        value: animating
                    )
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            animating = true
        }
        .accessibilityHidden(true)
    }
}
