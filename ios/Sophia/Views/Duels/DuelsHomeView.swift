import SwiftUI

/// L'onglet Duels : la ligue du joueur et ses trophées, le bouton qui lance une partie, ses
/// statistiques, le classement des trophées entre amis et ses dernières parties. Sans compte,
/// la page invite à se connecter : trophées et parties sont gardés côté serveur.
struct DuelsHomeView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AuthService.self) private var auth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let progressManager: ProgressManager
    /// L'onglet est celui affiché. Il reste en vie quand on en change (une partie en cours ne
    /// doit pas se fermer) : c'est donc ce signal, et non `onAppear`, qui rafraîchit la page.
    var isActive: Bool = true

    @State private var service = DuelService.shared
    @State private var showFlow = false
    @State private var showLeagues = false
    /// L'ami dont le profil est ouvert depuis le classement.
    @State private var selectedFriend: DuelLeaderboardEntry?
    @State private var playPulse = false
    /// Nombre de parties montrées dans « Derniers duels » : cinq, puis cinq de plus à la demande.
    @State private var recentShown = DuelsHomeView.recentPage
    /// L'anneau de réussite se dessine à la première apparition des statistiques.
    @State private var statsRevealed = false
    /// Au retour d'une victoire, la carte de ligue montre ces valeurs le temps que la jauge se
    /// remplisse de l'ancien total de trophées au nouveau.
    @State private var heroGain: HeroGain?
    @State private var heroPulse = false
    @State private var showGainChip = false
    @State private var gainTask: Task<Void, Never>?
    /// Change pour ramener la page en haut, sur la carte de ligue.
    @State private var scrollTopToken = 0

    private static let recentPage = 5
    private static let topAnchor = "duels.top"

    /// Ce que la carte de ligue affiche pendant l'animation d'une victoire.
    private struct HeroGain: Equatable {
        var trophies: Int
        var league: DuelLeague?
        var progress: Double
        let delta: Int
    }

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
            .navigationDestination(item: $selectedFriend) { entry in
                FriendProfileView(userId: entry.userId, fallbackHandle: entry.handle)
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
        .task(id: isActive) {
            // Les pastilles « en ligne » du classement : rafraîchies tant que l'onglet est affiché.
            guard isActive else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled, auth.isSignedIn, !showFlow else { continue }
                await service.refreshLeaderboard()
            }
        }
        .onChange(of: showFlow) { _, shown in
            // Dès que l'écran de partie se referme (pas à la fin de sa fermeture) : la carte de
            // ligue repart de l'ancien total avant d'être visible.
            if shown {
                stopLeagueGain()
            } else {
                startLeagueGain()
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
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    pageHeader(home)
                        .id(Self.topAnchor)

                    leagueHero(home)
                        .padding(.top, 14)
                        .dsStagger(0)
                    playButton
                        .padding(.top, 14)
                        .dsStagger(1)
                    stats(home.profile)
                        .padding(.top, 24)
                        .dsStagger(2)
                    leaderboardSection
                        .padding(.top, 24)
                        .dsStagger(3)
                    if !home.recent.isEmpty {
                        recentSection(home.recent)
                            .padding(.top, 24)
                            .dsStagger(4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .refreshable { await refresh() }
            .onChange(of: scrollTopToken) { _, _ in
                proxy.scrollTo(Self.topAnchor, anchor: .top)
            }
        }
    }

    /// Le titre de l'onglet et, à droite, les trophées du joueur dans leur pastille.
    private func pageHeader(_ home: DuelHome) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(languageManager.text("tab.duels"))
                .font(DS.title(.largeTitle, .medium))
                .foregroundStyle(DS.ink)
            Spacer()
            DuelTrophyCount(value: heroGain?.trophies ?? home.profile.trophies, size: 14)
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(Capsule().fill(DS.accentTint))
        }
    }

    // MARK: - Retour d'une victoire

    /// Au retour d'une partie gagnée : la jauge de ligue se remplit de l'ancien total au nouveau,
    /// avec une vibration à chaque cran et une salve si une ligue tombe. Une seule fois : le
    /// service oublie le gain dès qu'il est pris.
    private func startLeagueGain() {
        // Le gain doit mener au total que la page affiche : sinon (résultat arrivé après coup,
        // autre partie entre-temps) on ne rejoue rien.
        guard let gain = service.takePendingLeagueGain(), gain.after > gain.before,
              let home = service.home, home.profile.trophies == gain.after else { return }
        gainTask?.cancel()
        let league = home.league(forTrophies: gain.before)
        var progress = 0.0
        if let league {
            progress = home.progress(forTrophies: gain.before, in: league)
        }
        heroGain = HeroGain(trophies: gain.before, league: league, progress: progress, delta: gain.after - gain.before)
        showGainChip = false
        scrollTopToken += 1
        gainTask = Task { await playLeagueGain(gain, home: home) }
    }

    private func stopLeagueGain() {
        gainTask?.cancel()
        gainTask = nil
        heroGain = nil
        heroPulse = false
        showGainChip = false
    }

    private func playLeagueGain(_ gain: DuelLeagueGain, home: DuelHome) async {
        // Le temps que l'écran de partie finisse de se refermer.
        try? await Task.sleep(for: .seconds(0.75))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { showGainChip = true }

        var league = home.league(forTrophies: gain.before)
        let delta = gain.after - gain.before
        let steps = min(delta, 30)
        if steps > 0 {
            for step in 1...steps {
                let fraction = Double(step) / Double(steps)
                let eased = 1 - (1 - fraction) * (1 - fraction)
                let value = gain.before + Int((Double(delta) * eased).rounded())
                // Un seuil tombe : la jauge va au bout, la ligue suivante prend la carte.
                while let current = league, let next = home.nextLeague(after: current), value >= next.minTrophies {
                    withAnimation(.easeOut(duration: 0.3)) {
                        heroGain?.trophies = next.minTrophies
                        heroGain?.progress = 1
                    }
                    try? await Task.sleep(for: .seconds(0.4))
                    guard !Task.isCancelled else { return }
                    DuelHaptics.promotion()
                    league = next
                    heroGain?.progress = 0
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) {
                        heroGain?.league = next
                        heroPulse = true
                    }
                    try? await Task.sleep(for: .seconds(0.45))
                    guard !Task.isCancelled else { return }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { heroPulse = false }
                    try? await Task.sleep(for: .seconds(0.45))
                    guard !Task.isCancelled else { return }
                }
                var progress = 0.0
                if let current = league {
                    progress = home.progress(forTrophies: value, in: current)
                }
                let reached = progress
                withAnimation(.linear(duration: 0.1)) {
                    heroGain?.trophies = value
                    heroGain?.progress = reached
                }
                DuelHaptics.trophyTick(progress: fraction)
                try? await Task.sleep(for: .milliseconds(34 + Int(56 * fraction)))
                guard !Task.isCancelled else { return }
            }
        }
        DuelHaptics.trophyLanded()
        try? await Task.sleep(for: .seconds(1.8))
        guard !Task.isCancelled else { return }
        // La carte rend la main au profil, qui porte déjà le nouveau total.
        withAnimation(.easeInOut(duration: 0.35)) {
            showGainChip = false
            heroGain = nil
        }
    }

    /// La carte de ligue : l'illustration, le nom, les trophées et la jauge vers la suivante.
    private func leagueHero(_ home: DuelHome) -> some View {
        let trophies = heroGain?.trophies ?? home.profile.trophies
        let league = heroGain?.league ?? home.currentLeague
        let next = home.nextLeague(after: league)
        let progress = heroGain?.progress ?? home.leagueProgress(forTrophies: trophies)
        let gained = heroGain?.delta ?? 0
        // La carte vibre d'elle-même à la pression (`PressableStyle`).
        return Button {
            showLeagues = true
        } label: {
            ZStack(alignment: .bottomLeading) {
                DuelLeagueBackdrop(league: league)
                LinearGradient(
                    colors: [DuelTheme.scrim.opacity(0.32), DuelTheme.scrim.opacity(0.5), DuelTheme.scrim.opacity(0.82)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                heroLabels(league: league, next: next, trophies: trophies, progress: progress, gained: gained)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }
            .frame(height: 210)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 4) {
                    Text(languageManager.text("duel.league.all"))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .heavy))
                }
                .font(.jakarta(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.2)))
                .padding(12)
            }
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .strokeBorder(DuelPalette.saffron, lineWidth: 3)
                    .opacity(heroPulse ? 1 : 0)
            )
            .scaleEffect(heroPulse ? 1.03 : 1)
        }
        .buttonStyle(PressableStyle(scale: 0.98))
    }

    /// Le texte posé en bas de la carte de ligue.
    private func heroLabels(league: DuelLeague?, next: DuelLeague?, trophies: Int, progress: Double, gained: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(format: languageManager.text("duel.league.position"), league?.position ?? 1).uppercased())
                .font(.jakarta(size: 12, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(.white)
            Text(DuelFormat.leagueName(league, language: languageManager.current))
                .font(.jakarta(size: 24, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            // Les trophées du joueur à gauche, le seuil de la ligue suivante à droite.
            HStack(spacing: 8) {
                DuelTrophyCount(value: trophies, size: 14, color: .white)
                if showGainChip, gained > 0 {
                    Text("+\(gained)")
                        .font(.jakarta(size: 13, weight: .heavy))
                        .monospacedDigit()
                        .foregroundStyle(DuelPalette.night)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(DuelPalette.saffron))
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                }
                Spacer(minLength: 0)
                if let next {
                    DuelTrophyCount(value: next.minTrophies, size: 13, color: .white)
                }
            }
            DuelProgressBar(progress: progress, height: 8)
            Group {
                if let next {
                    Text(String(
                        format: languageManager.text("duel.league.toNext"),
                        max(next.minTrophies - trophies, 0),
                        DuelFormat.leagueName(next, language: languageManager.current)
                    ))
                } else {
                    Text(languageManager.text("duel.league.top"))
                }
            }
            .font(.jakarta(size: 13, weight: .medium))
            .foregroundStyle(DuelTheme.onArtSecondary)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var playButton: some View {
        VStack(spacing: 8) {
            Button {
                DuelHaptics.countdown(final: true)
                showFlow = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text(languageManager.text("duel.play"))
                }
            }
            .buttonStyle(DuelPlayButtonStyle())
            .scaleEffect(playPulse ? 1.015 : 1)
            .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: playPulse)
            .onAppear {
                guard !reduceMotion else { return }
                playPulse = true
            }

            Text(languageManager.text("duel.play.caption"))
                .font(DS.sans(.footnote, .regular))
                .foregroundStyle(DS.inkSecondary)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Statistiques

    /// Les statistiques en une carte : l'anneau de réussite et le partage victoires / défaites
    /// en haut, les séries et le record de trophées en bas.
    private func stats(_ profile: DuelProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("duel.stats.title")
            VStack(spacing: 12) {
                HStack(alignment: .center, spacing: 16) {
                    winRateRing(profile)
                    statsSummary(profile)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Rectangle().fill(DS.hairline).frame(height: 1)

                HStack(alignment: .top, spacing: 6) {
                    statCell(systemImage: "flame", tint: DuelPalette.saffron, label: "duel.stats.streak") {
                        DSCountUp(value: profile.winStreak, duration: 0.6, font: Self.statValueFont, color: DS.ink, haptics: false)
                    }
                    statCell(systemImage: "bolt", tint: DS.accent, label: "duel.stats.bestStreak") {
                        DSCountUp(value: profile.bestWinStreak, duration: 0.6, font: Self.statValueFont, color: DS.ink, haptics: false)
                    }
                    statCell(systemImage: "trophy", tint: DuelPalette.saffron, label: "duel.stats.best") {
                        Text(profile.bestTrophies.formatted(language: languageManager.current))
                            .font(Self.statValueFont)
                            .monospacedDigit()
                            .foregroundStyle(DS.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
            }
            .dsCard(padding: 16)
            .onAppear { statsRevealed = true }
        }
    }

    private static let statValueFont: Font = .jakarta(size: 16, weight: .heavy)

    /// « 12 Duels », puis la barre victoires / défaites et sa légende (ou l'invitation à jouer).
    private func statsSummary(_ profile: DuelProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                DSCountUp(value: profile.games, duration: 0.7, font: .jakarta(size: 20, weight: .heavy), color: DS.ink, haptics: false)
                Text(languageManager.text("duel.stats.games"))
                    .font(.jakarta(size: 20, weight: .heavy))
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            if profile.games > 0 {
                winLossBar(profile)
                HStack(spacing: 8) {
                    splitLegend(color: DS.success, value: profile.wins, label: "duel.stats.wins")
                    Spacer(minLength: 4)
                    splitLegend(color: DS.danger, value: profile.losses, label: "duel.stats.losses")
                }
            } else {
                Text(languageManager.text("duel.stats.empty"))
                    .font(DS.sans(.footnote, .regular))
                    .foregroundStyle(DS.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// L'anneau de réussite : la part de victoires en vert, le reste en rouge pâle.
    private func winRateRing(_ profile: DuelProfile) -> some View {
        let fraction = profile.games > 0 ? min(max(Double(profile.wins) / Double(profile.games), 0), 1) : 0
        return ZStack {
            Circle()
                .stroke(profile.games > 0 ? DS.dangerTint : DS.accentTint, lineWidth: 7)
                .padding(3.5)
            Circle()
                .trim(from: 0, to: statsRevealed ? fraction : 0)
                .stroke(DS.success, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(3.5)
                .animation(.easeOut(duration: 0.9), value: statsRevealed)
                .animation(.easeOut(duration: 0.6), value: fraction)
            VStack(spacing: 0) {
                Text(profile.winRate.map { "\($0) %" } ?? "–")
                    .font(.jakarta(size: 18, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(languageManager.text("duel.stats.winRate"))
                    .font(.jakarta(size: 10, weight: .regular))
                    .foregroundStyle(DS.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 12)
        }
        .frame(width: 76, height: 76)
        .accessibilityElement(children: .combine)
    }

    /// La barre partagée : victoires à gauche, défaites à droite, à proportion.
    private func winLossBar(_ profile: DuelProfile) -> some View {
        let total = max(profile.wins + profile.losses, 1)
        let share = Double(profile.wins) / Double(total)
        return GeometryReader { proxy in
            let gap: CGFloat = profile.wins > 0 && profile.losses > 0 ? 3 : 0
            let winsWidth: CGFloat = max((proxy.size.width - gap) * CGFloat(share), 0)
            HStack(spacing: gap) {
                if profile.wins > 0 {
                    Capsule().fill(DS.success).frame(width: winsWidth)
                }
                if profile.losses > 0 {
                    Capsule().fill(DS.danger)
                }
                if profile.wins == 0 && profile.losses == 0 {
                    Capsule().fill(DS.hairline)
                }
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }

    private func splitLegend(color: Color, value: Int, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text("\(value)")
                .font(DS.sans(.footnote, .bold))
                .monospacedDigit()
                .foregroundStyle(DS.ink)
            Text(languageManager.text(label))
                .font(DS.sans(.caption, .medium))
                .foregroundStyle(DS.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    /// Une case du bas de la carte : le pictogramme, la valeur, puis son libellé.
    private func statCell<Value: View>(
        systemImage: String,
        tint: Color,
        label: String,
        @ViewBuilder value: () -> Value
    ) -> some View {
        VStack(spacing: 3) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(height: 20)
            value()
            Text(languageManager.text(label))
                .font(.jakarta(size: 11, weight: .regular))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func sectionTitle(_ key: String) -> some View {
        DuelSectionTitle(text: languageManager.text(key))
    }

    // MARK: - Classement entre amis

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("duel.friends.title")
            VStack(spacing: 4) {
                if service.leaderboard.filter({ !$0.isMe }).isEmpty {
                    Text(languageManager.text("duel.friends.empty"))
                        .font(DS.sans(.footnote, .regular))
                        .foregroundStyle(DS.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                } else {
                    ForEach(Array(service.leaderboard.enumerated()), id: \.element.id) { index, entry in
                        leaderboardRow(rank: index + 1, entry: entry)
                    }
                }
            }
            .dsCard(padding: 8)
        }
    }

    /// Une ligne du classement : toucher la ligne ouvre le profil de l'ami, l'éclair le défie.
    private func leaderboardRow(rank: Int, entry: DuelLeaderboardEntry) -> some View {
        HStack(spacing: 10) {
            Text("\(rank)")
                .font(.jakarta(size: 14, weight: .heavy))
                .foregroundStyle(rank == 1 ? DuelPalette.saffron : DS.inkSecondary)
                .monospacedDigit()
                .frame(width: 18, alignment: .leading)
            AvatarCircle(avatarId: entry.avatarId, initial: String(entry.handle.prefix(1)).uppercased(), size: 36)
                .overlay(alignment: .bottomTrailing) {
                    if entry.online {
                        DuelOnlineDot(size: 12)
                            .offset(x: 2, y: 2)
                    }
                }
            VStack(alignment: .leading, spacing: 1) {
                Text("@\(entry.handle)")
                    .font(.jakarta(size: 14, weight: .bold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                if let league = service.home?.league(position: entry.leaguePosition) {
                    Text(DuelFormat.leagueName(league, language: languageManager.current))
                        .font(.jakarta(size: 12, weight: .regular))
                        .foregroundStyle(DS.inkSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            DuelTrophyCount(value: entry.trophies, size: 14)
            if entry.canChallenge {
                Button {
                    DuelHaptics.countdown(final: true)
                    DuelFriendPresenter.present(.challenge(userId: entry.userId, handle: entry.handle, avatarId: entry.avatarId))
                } label: {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(DuelPalette.night)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(DuelPalette.saffron))
                }
                // Le lancement du défi vibre déjà (`DuelHaptics.countdown`).
                .buttonStyle(PressableStyle(scale: 0.92, haptic: false))
                .accessibilityLabel(Text(languageManager.text("duel.friend.challenge")))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(entry.isMe ? DS.accentTint : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard !entry.isMe else { return }
            DuelHaptics.tap()
            selectedFriend = entry
        }
    }

    // MARK: - Dernières parties

    /// Les dernières parties : cinq d'abord, puis « Voir plus » en ajoute cinq à chaque fois
    /// (le serveur en garde dix) ; une fois tout montré, le bouton replie la liste.
    private func recentSection(_ matches: [DuelRecentMatch]) -> some View {
        let shown = Array(matches.prefix(max(recentShown, Self.recentPage)))
        let canExpand = shown.count < matches.count
        let canCollapse = !canExpand && matches.count > Self.recentPage
        return VStack(alignment: .leading, spacing: 8) {
            sectionTitle("duel.recent.title")
            VStack(spacing: 0) {
                ForEach(Array(shown.enumerated()), id: \.element.id) { index, match in
                    if index > 0 {
                        Rectangle().fill(DS.hairline).frame(height: 1)
                    }
                    recentRow(match)
                }
                if canExpand || canCollapse {
                    Rectangle().fill(DS.hairline).frame(height: 1)
                    Button {
                        DuelHaptics.tap()
                        withAnimation(DS.Motion.snappy) {
                            recentShown = canExpand ? shown.count + Self.recentPage : Self.recentPage
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(languageManager.text(canExpand ? "duel.recent.more" : "duel.recent.less"))
                            Image(systemName: canExpand ? "chevron.down" : "chevron.up")
                                .font(.system(size: 11, weight: .heavy))
                        }
                        .font(.jakarta(size: 14, weight: .bold))
                        .foregroundStyle(DS.accent)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 16)
            .dsCard(padding: 0)
        }
    }

    private func recentRow(_ match: DuelRecentMatch) -> some View {
        let outcomeKey = match.abandoned ? "duel.result.abandoned" : (match.won ? "duel.result.victory" : "duel.result.defeat")
        let deltaText = match.trophiesDelta > 0 ? "+\(match.trophiesDelta)" : "\(match.trophiesDelta)"
        return HStack(spacing: 10) {
            AvatarCircle(avatarId: match.opponent.avatarId, initial: match.opponent.initial, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text("@\(match.opponent.handle) \(match.opponent.flag)")
                    .font(.jakarta(size: 14, weight: .bold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                Text(match.abandoned
                     ? languageManager.text(outcomeKey)
                     : "\(languageManager.text(outcomeKey)) · \(match.playerScore) – \(match.opponentScore)")
                    .font(.jakarta(size: 13, weight: .bold))
                    .foregroundStyle(match.won ? DS.success : DS.danger)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            HStack(spacing: 4) {
                Text(deltaText)
                    .font(.jakarta(size: 14, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(match.trophiesDelta > 0 ? DS.success : (match.trophiesDelta < 0 ? DS.danger : DS.inkTertiary))
                DuelTrophyIcon(size: 12)
            }
        }
        .padding(.vertical, 10)
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
                    .padding(.top, 36)
                    .dsPopIn()
                VStack(spacing: 10) {
                    Text(languageManager.text("duel.signedOut.title"))
                        .font(DS.title(.title, .semibold))
                        .foregroundStyle(DS.ink)
                        .multilineTextAlignment(.center)
                    Text(languageManager.text("duel.signedOut.body"))
                        .font(DS.sans(.body, .regular))
                        .foregroundStyle(DS.inkSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .dsStagger(1)
                AuthProvidersView(onSignedIn: {})
                    .padding(.top, 6)
                    .dsStagger(2)
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
            // Le bouton secondaire vibre de lui-même.
            Button(languageManager.text("duel.match.retry")) {
                Task { await refresh() }
            }
            .buttonStyle(DSSecondaryButtonStyle())
            .frame(maxWidth: 220)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
