import SwiftUI

/// La route des ligues (maquette AEr23) : les 30 ligues de la plus haute (en haut) à la première
/// (en bas), chacune avec son illustration et le nombre de trophées qu'elle demande. Les ligues
/// atteintes sont en couleur, celle du joueur est mise en avant avec sa jauge, les suivantes sont
/// en gris. À l'ouverture, la route se remplit de safran jusqu'à la ligue du joueur, sur laquelle
/// la page s'ouvre ; toucher une ligue l'affiche en grand.
struct DuelLeagueRoadView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let home: DuelHome

    @State private var preview: DuelLeague?
    /// La route est remplie (les repères des ligues atteintes passent au safran, de bas en haut).
    @State private var roadFilled = false

    private var currentPosition: Int { home.currentLeague?.position ?? 1 }

    /// Où en est le joueur dans sa ligue : ses trophées, la jauge et la ligue suivante.
    private var standing: DuelLeagueStanding {
        DuelLeagueStanding(
            trophies: home.profile.trophies,
            progress: home.leagueProgress(forTrophies: home.profile.trophies),
            next: home.nextLeague(after: home.currentLeague)
        )
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                // Trente lignes : une pile simple (non paresseuse), pour que l'ouverture sur la
                // ligue du joueur soit fiable dès le premier affichage.
                VStack(spacing: 12) {
                    ForEach(Array(home.leagues.reversed())) { league in
                        row(league)
                            .id(league.position)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .onAppear {
                proxy.scrollTo(currentPosition, anchor: .center)
                DispatchQueue.main.async {
                    proxy.scrollTo(currentPosition, anchor: .center)
                }
                fillRoad()
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .background(DS.canvas.ignoresSafeArea())
        .fullScreenCover(item: $preview) { league in
            DuelLeaguePreview(
                league: league,
                reached: league.position <= currentPosition,
                standing: league.position == currentPosition ? standing : nil
            )
            .sophiaColorScheme()
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            RoundIconButton(systemImage: "chevron.left", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
            Text(languageManager.text("duel.league.road"))
                .font(.jakarta(size: 16, weight: .heavy))
                .foregroundStyle(DS.ink)
                .frame(maxWidth: .infinity)
            DuelTrophyCount(value: home.profile.trophies, size: 15)
                .frame(minWidth: 44, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(DS.canvas)
    }

    // MARK: - La route qui se remplit

    /// Lance le remplissage de la route, puis un cran quand il atteint la ligue du joueur.
    private func fillRoad() {
        guard !roadFilled else { return }
        if reduceMotion {
            roadFilled = true
            return
        }
        withAnimation(DS.Motion.reveal) { roadFilled = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.fillDelay(distance: 0) + 0.3) {
            Haptics.soft()
        }
    }

    /// Le retard du repère d'une ligue atteinte, selon sa distance à celle du joueur : les
    /// ligues du bas d'abord, celle du joueur en dernier.
    private static func fillDelay(distance: Int) -> Double {
        let near = 4
        return 0.2 + Double(near - min(max(distance, 0), near)) * 0.11
    }

    /// Une ligue : le repère sur la route à gauche, sa carte à droite.
    private func row(_ league: DuelLeague) -> some View {
        let reached = league.position <= currentPosition
        let isCurrent = league.position == currentPosition
        let distance = currentPosition - league.position
        // La carte vibre d'elle-même à la pression (`PressableStyle`).
        return HStack(spacing: 12) {
            rail(reached: reached, distance: distance)
            Button {
                preview = league
            } label: {
                card(league, reached: reached, isCurrent: isCurrent)
            }
            .buttonStyle(PressableStyle(scale: 0.98))
        }
        .dsStagger(min(abs(distance), 5), step: 0.05, base: 0.02, offset: 10)
    }

    /// Le repère de la route : gris, et safran une fois la ligue atteinte (il se remplit du bas).
    private func rail(reached: Bool, distance: Int) -> some View {
        Capsule()
            .fill(DS.ink.opacity(0.14))
            .overlay(alignment: .bottom) {
                if reached {
                    Capsule()
                        .fill(DuelPalette.saffron)
                        .scaleEffect(x: 1, y: roadFilled ? 1 : 0, anchor: .bottom)
                        .animation(reduceMotion ? nil : DS.Motion.reveal.delay(Self.fillDelay(distance: distance)), value: roadFilled)
                }
            }
            .frame(width: 6)
            .accessibilityHidden(true)
    }

    private func card(_ league: DuelLeague, reached: Bool, isCurrent: Bool) -> some View {
        ZStack(alignment: .bottomLeading) {
            DuelLeagueBackdrop(league: league, thumb: true)
                .saturation(reached ? 1 : 0)
            cardScrim(reached: reached)
            cardLabels(league, reached: reached, isCurrent: isCurrent)
                .padding(.horizontal, 14)
                .padding(.bottom, isCurrent ? 14 : 12)
        }
        .frame(height: isCurrent ? 200 : 110)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .overlay(alignment: .topLeading) {
            if isCurrent {
                Text(languageManager.text("duel.league.here").uppercased())
                    .font(.jakarta(size: 12, weight: .heavy))
                    .tracking(0.6)
                    .foregroundStyle(DuelPalette.night)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(DuelPalette.saffron))
                    .padding(.leading, 14)
                    .padding(.top, 12)
            }
        }
        .overlay(alignment: .topTrailing) {
            Text("\(league.position)")
                .font(.jakarta(size: 13, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(minWidth: 28, minHeight: 28)
                .background(Circle().fill(Color.white.opacity(0.25)))
                .padding(10)
        }
    }

    /// Le voile qui rend le texte lisible : uni sur une ligue pas encore atteinte, en dégradé
    /// (l'illustration reste visible en haut) sur une ligue atteinte.
    @ViewBuilder
    private func cardScrim(reached: Bool) -> some View {
        if reached {
            LinearGradient(
                colors: [DuelTheme.scrim.opacity(0.18), DuelTheme.scrim.opacity(0.74)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            DuelTheme.scrim.opacity(0.55)
        }
    }

    private func cardLabels(_ league: DuelLeague, reached: Bool, isCurrent: Bool) -> some View {
        VStack(alignment: .leading, spacing: isCurrent ? 6 : 2) {
            Text(DuelFormat.leagueName(league, language: languageManager.current))
                .font(.jakarta(size: isCurrent ? 22 : 18, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if isCurrent {
                // Sa propre ligue : les trophées du joueur (et non le seuil de la ligue, 0
                // pour la première), puis le seuil de la suivante au bout de la jauge.
                HStack(spacing: 8) {
                    DuelTrophyCount(value: home.profile.trophies, size: 13, color: .white)
                    Spacer(minLength: 0)
                    if let next = home.nextLeague(after: league) {
                        DuelTrophyCount(value: next.minTrophies, size: 13, color: .white)
                    }
                }
                // La jauge se remplit une fois la route arrivée à la ligue du joueur.
                DuelProgressBar(progress: roadFilled ? home.leagueProgress(forTrophies: home.profile.trophies) : 0, height: 8)
                    .animation(reduceMotion ? nil : DS.Motion.reveal.delay(Self.fillDelay(distance: 0) + 0.25), value: roadFilled)
            } else {
                HStack(spacing: 5) {
                    DuelTrophyCount(value: league.minTrophies, size: 13, color: .white)
                    if !reached {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Où en est le joueur dans sa ligue : ce que la ligue en grand montre quand c'est la sienne.
nonisolated struct DuelLeagueStanding: Sendable, Equatable {
    let trophies: Int
    let progress: Double
    let next: DuelLeague?
}

/// Une ligue en grand : son illustration plein écran, son nom et son seuil de trophées. Pour la
/// ligue du joueur, ses propres trophées et sa jauge passent devant : le seuil seul (0 pour la
/// première ligue) se lisait comme « tu as 0 trophée ».
struct DuelLeaguePreview: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    let league: DuelLeague
    let reached: Bool
    /// Renseigné seulement pour la ligue du joueur.
    var standing: DuelLeagueStanding? = nil

    @State private var revealed = false

    var body: some View {
        ZStack {
            DuelLeagueBackdrop(league: league)
                .scaleEffect(revealed ? 1 : 1.12)
                .ignoresSafeArea()
            LinearGradient(
                colors: [DuelTheme.scrim.opacity(0.25), .clear, DuelTheme.scrim.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Spacer()
                    // Le bouton rond vibre de lui-même.
                    RoundIconButton(systemImage: "xmark", accessibilityLabel: languageManager.text("common.close")) {
                        dismiss()
                    }
                }
                Spacer()
                Text(String(format: languageManager.text("duel.league.position"), league.position).uppercased())
                    .font(.jakarta(size: 12, weight: .heavy))
                    .tracking(0.8)
                    .foregroundStyle(DuelPalette.saffron)
                Text(DuelFormat.leagueName(league, language: languageManager.current))
                    .font(.jakarta(size: 36, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                if let standing {
                    caption("duel.league.yourTrophies")
                    DuelTrophyCount(value: standing.trophies, size: 26, color: .white)
                    DuelProgressBar(progress: revealed ? standing.progress : 0, height: 8)
                        .animation(DS.Motion.reveal.delay(0.35), value: revealed)
                    Group {
                        if let next = standing.next {
                            Text(String(
                                format: languageManager.text("duel.league.toNext"),
                                max(next.minTrophies - standing.trophies, 0),
                                DuelFormat.leagueName(next, language: languageManager.current)
                            ))
                        } else {
                            Text(languageManager.text("duel.league.top"))
                        }
                    }
                    .font(DS.sans(.footnote, .medium))
                    .foregroundStyle(DuelTheme.onArtSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                } else {
                    caption("duel.league.required")
                    HStack(spacing: 10) {
                        DuelTrophyCount(value: league.minTrophies, size: 18, color: .white)
                        if !reached {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }
                }
            }
            .padding(24)
            .opacity(revealed ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { revealed = true }
        }
    }

    /// La petite ligne qui dit ce que compte le nombre de trophées en dessous.
    private func caption(_ key: String) -> some View {
        Text(languageManager.text(key))
            .font(DS.sans(.footnote, .medium))
            .foregroundStyle(DuelTheme.onArtSecondary)
            .padding(.top, 4)
    }
}
