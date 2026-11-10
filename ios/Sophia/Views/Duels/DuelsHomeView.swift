import SwiftUI

/// L'onglet Duels : la ligue du joueur et ses trophées, le bouton qui lance une partie, ses
/// statistiques, le classement des trophées entre amis et ses dernières parties. Sans compte,
/// la page invite à se connecter : trophées et parties sont gardés côté serveur.
struct DuelsHomeView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AuthService.self) private var auth
    let progressManager: ProgressManager
    /// L'onglet est celui affiché. Il reste en vie quand on en change (une partie en cours ne
    /// doit pas se fermer) : c'est donc ce signal, et non `onAppear`, qui rafraîchit la page.
    var isActive: Bool = true

    @State private var service = DuelService.shared
    @State private var showFlow = false
    @State private var showLeagues = false
    @State private var playPulse = false

    private var handle: String {
        service.home?.handle ?? SocialService.shared.myHandle ?? "you"
    }

    var body: some View {
        NavigationStack {
            Group {
                if auth.isBootstrapping && !auth.isSignedIn {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !auth.isSignedIn {
                    signedOut
                } else if let home = service.home {
                    content(home)
                } else if service.homeFailed {
                    failed
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(DS.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showLeagues) {
                if let home = service.home {
                    DuelLeagueRoadView(home: home)
                        .toolbar(.hidden, for: .navigationBar)
                }
            }
        }
        .task(id: auth.isSignedIn) { await refresh() }
        .onChange(of: auth.isBootstrapping) { _, _ in
            Task { await refresh() }
        }
        .onChange(of: isActive) { _, active in
            if active, !showFlow {
                Task { await refresh() }
            }
        }
        .fullScreenCover(isPresented: $showFlow) {
            DuelFlowView(handle: handle, avatarId: progressManager.avatarId, service: service)
                .sophiaColorScheme()
        }
    }

    private func refresh() async {
        guard auth.isSignedIn else {
            // Au lancement, la session n'est pas encore relue : la page gardée reste en place.
            if !auth.isBootstrapping {
                service.clearLocalState()
            }
            return
        }
        await service.refreshHome()
        await service.refreshLeaderboard()
    }

    // MARK: - Page

    private func content(_ home: DuelHome) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .center) {
                    Text(languageManager.text("tab.duels"))
                        .font(DS.title(.largeTitle, .heavy))
                        .foregroundStyle(DS.ink)
                    Spacer()
                    DuelTrophyCount(value: home.profile.trophies, size: 17)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(DS.surface))
                        .overlay(Capsule().strokeBorder(DS.hairline, lineWidth: 1))
                }

                leagueHero(home)
                playButton
                stats(home.profile)
                leaderboardSection
                if !home.recent.isEmpty {
                    recentSection(home.recent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .refreshable { await refresh() }
    }

    /// La carte de ligue : l'illustration, le nom, les trophées et la jauge vers la suivante.
    private func leagueHero(_ home: DuelHome) -> some View {
        let league = home.currentLeague
        let next = home.nextLeague(after: league)
        return Button {
            DuelHaptics.tap()
            showLeagues = true
        } label: {
            ZStack(alignment: .bottomLeading) {
                DuelLeagueBackdrop(league: league)
                LinearGradient(
                    colors: [.clear, DuelPalette.night.opacity(0.25), DuelPalette.night.opacity(0.88)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(String(format: languageManager.text("duel.league.position"), league?.position ?? 1).uppercased())
                        .font(DS.sans(.caption, .bold))
                        .tracking(1.4)
                        .foregroundStyle(DuelPalette.saffron)
                    Text(DuelFormat.leagueName(league, language: languageManager.current))
                        .font(.jakarta(size: 30, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    DuelProgressBar(progress: home.leagueProgress(forTrophies: home.profile.trophies))
                    HStack(spacing: 6) {
                        if let next {
                            Text(String(
                                format: languageManager.text("duel.league.toNext"),
                                max(next.minTrophies - home.profile.trophies, 0),
                                DuelFormat.leagueName(next, language: languageManager.current)
                            ))
                        } else {
                            Text(languageManager.text("duel.league.top"))
                        }
                        Spacer(minLength: 0)
                    }
                    .font(DS.sans(.footnote, .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                }
                .padding(18)
            }
            .frame(height: 280)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 4) {
                    Text(languageManager.text("duel.league.all"))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .heavy))
                }
                .font(DS.sans(.caption, .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(DuelPalette.night.opacity(0.55)))
                .padding(14)
            }
            .dsSoftShadow()
        }
        .buttonStyle(SoftPressButtonStyle())
    }

    private var playButton: some View {
        VStack(spacing: 8) {
            Button {
                DuelHaptics.countdown(final: true)
                showFlow = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18, weight: .heavy))
                    Text(languageManager.text("duel.play"))
                }
            }
            .buttonStyle(DuelPlayButtonStyle())
            .scaleEffect(playPulse ? 1.015 : 1)
            .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: playPulse)
            .onAppear { playPulse = true }

            Text(languageManager.text("duel.play.caption"))
                .font(DS.sans(.footnote, .medium))
                .foregroundStyle(DS.inkSecondary)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Statistiques

    private func stats(_ profile: DuelProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("duel.stats.title")
            HStack(spacing: 10) {
                statTile(value: "\(profile.games)", label: "duel.stats.games")
                statTile(value: "\(profile.wins)", label: "duel.stats.wins", color: DS.success)
                statTile(value: "\(profile.losses)", label: "duel.stats.losses", color: DS.danger)
                statTile(value: profile.winRate.map { "\($0) %" } ?? "–", label: "duel.stats.winRate")
            }
            HStack(spacing: 10) {
                statRow(systemImage: "flame.fill", label: "duel.stats.streak", value: "\(profile.winStreak)")
                statRow(systemImage: "trophy.fill", label: "duel.stats.best", value: profile.bestTrophies.formatted(language: languageManager.current))
            }
        }
    }

    private func statTile(value: String, label: String, color: Color = DS.ink) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.jakarta(size: 22, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(languageManager.text(label))
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(DS.inkTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
    }

    private func statRow(systemImage: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(DuelPalette.saffron)
            Text(languageManager.text(label))
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(DS.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 4)
            Text(value)
                .font(DS.sans(.subheadline, .bold))
                .monospacedDigit()
                .foregroundStyle(DS.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
    }

    private func sectionTitle(_ key: String) -> some View {
        Text(languageManager.text(key).uppercased())
            .font(DS.sans(.caption, .semibold))
            .foregroundStyle(DS.inkTertiary)
            .tracking(1.1)
    }

    // MARK: - Classement entre amis

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("duel.friends.title")
            VStack(spacing: 0) {
                if service.leaderboard.filter({ !$0.isMe }).isEmpty {
                    Text(languageManager.text("duel.friends.empty"))
                        .font(DS.sans(.subheadline, .medium))
                        .foregroundStyle(DS.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                } else {
                    ForEach(Array(service.leaderboard.enumerated()), id: \.element.id) { index, entry in
                        if index > 0 {
                            Rectangle().fill(DS.hairline).frame(height: 1)
                        }
                        leaderboardRow(rank: index + 1, entry: entry)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
            .dsCard(padding: 0)
        }
    }

    private func leaderboardRow(rank: Int, entry: DuelLeaderboardEntry) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(rank == 1 ? DuelPalette.saffron : DS.inkTertiary)
                .monospacedDigit()
                .frame(width: 22, alignment: .leading)
            AvatarCircle(avatarId: entry.avatarId, initial: String(entry.handle.prefix(1)).uppercased(), size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text("@\(entry.handle)")
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                if let league = service.home?.league(position: entry.leaguePosition) {
                    Text(DuelFormat.leagueName(league, language: languageManager.current))
                        .font(DS.sans(.caption, .medium))
                        .foregroundStyle(DS.inkTertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            DuelTrophyCount(value: entry.trophies, size: 15)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(entry.isMe ? DS.accentTint.opacity(0.6) : Color.clear)
    }

    // MARK: - Dernières parties

    private func recentSection(_ matches: [DuelRecentMatch]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("duel.recent.title")
            VStack(spacing: 0) {
                ForEach(Array(matches.enumerated()), id: \.element.id) { index, match in
                    if index > 0 {
                        Rectangle().fill(DS.hairline).frame(height: 1)
                    }
                    recentRow(match)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
            .dsCard(padding: 0)
        }
    }

    private func recentRow(_ match: DuelRecentMatch) -> some View {
        let outcomeKey = match.abandoned ? "duel.result.abandoned" : (match.won ? "duel.result.victory" : "duel.result.defeat")
        let deltaText = match.trophiesDelta > 0 ? "+\(match.trophiesDelta)" : "\(match.trophiesDelta)"
        return HStack(spacing: 12) {
            AvatarCircle(avatarId: match.opponent.avatarId, initial: match.opponent.initial, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text("@\(match.opponent.handle) \(match.opponent.flag)")
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                Text(match.abandoned
                     ? languageManager.text(outcomeKey)
                     : "\(languageManager.text(outcomeKey)) · \(match.playerScore) – \(match.opponentScore)")
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(match.won ? DS.success : DS.danger)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            HStack(spacing: 4) {
                Text(deltaText)
                    .font(DS.sans(.subheadline, .bold))
                    .monospacedDigit()
                    .foregroundStyle(match.trophiesDelta > 0 ? DS.success : (match.trophiesDelta < 0 ? DS.danger : DS.inkTertiary))
                DuelTrophyIcon(size: 12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Sans compte, sans réseau

    private var signedOut: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image("duel_trophy")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 168, height: 168)
                    .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                    .dsSoftShadow()
                    .padding(.top, 36)
                VStack(spacing: 10) {
                    Text(languageManager.text("duel.signedOut.title"))
                        .font(DS.title(.title, .heavy))
                        .foregroundStyle(DS.ink)
                        .multilineTextAlignment(.center)
                    Text(languageManager.text("duel.signedOut.body"))
                        .font(DS.sans(.body, .medium))
                        .foregroundStyle(DS.inkSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                AuthProvidersView(onSignedIn: {})
                    .padding(.top, 6)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
    }

    private var failed: some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(DS.inkTertiary)
            Text(languageManager.text("duel.load.failed"))
                .font(DS.sans(.body, .medium))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
            Button(languageManager.text("duel.match.retry")) {
                DuelHaptics.tap()
                Task { await refresh() }
            }
            .buttonStyle(DSSecondaryButtonStyle())
            .frame(maxWidth: 220)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
