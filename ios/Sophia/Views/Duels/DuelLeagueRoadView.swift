import SwiftUI

/// La route des ligues : les 30 ligues de la plus haute (en haut) à la première (en bas), chacune
/// avec son illustration et le nombre de trophées qu'elle demande. Les ligues atteintes sont en
/// couleur, celle du joueur est mise en avant avec sa jauge, les suivantes sont voilées. La page
/// s'ouvre sur la ligue du joueur ; toucher une ligue l'affiche en grand.
struct DuelLeagueRoadView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    let home: DuelHome

    @State private var preview: DuelLeague?

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
                VStack(spacing: 0) {
                    ForEach(Array(home.leagues.reversed())) { league in
                        row(league)
                            .id(league.position)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .onAppear {
                proxy.scrollTo(currentPosition, anchor: .center)
                DispatchQueue.main.async {
                    proxy.scrollTo(currentPosition, anchor: .center)
                }
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
        HStack(spacing: 12) {
            RoundIconButton(systemImage: "chevron.left", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
            Text(languageManager.text("duel.league.road"))
                .font(DS.title(.title2, .heavy))
                .foregroundStyle(DS.ink)
            Spacer()
            DuelTrophyCount(value: home.profile.trophies, size: 16)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(DS.canvas)
    }

    /// Une ligue : le repère sur la route à gauche, sa carte à droite.
    private func row(_ league: DuelLeague) -> some View {
        let reached = league.position <= currentPosition
        let isCurrent = league.position == currentPosition
        return Button {
            DuelHaptics.tap()
            preview = league
        } label: {
            card(league, reached: reached, isCurrent: isCurrent)
        }
        .buttonStyle(SoftPressButtonStyle())
        .padding(.vertical, 7)
        .padding(.leading, 42)
        .overlay(alignment: .leading) {
            rail(reached: reached, isCurrent: isCurrent, isTop: league.position == home.leagues.count, isBottom: league.position == 1)
        }
    }

    private func rail(reached: Bool, isCurrent: Bool, isTop: Bool, isBottom: Bool) -> some View {
        ZStack {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isTop ? Color.clear : (reached && !isCurrent ? DuelPalette.saffron : DS.hairline))
                    .frame(width: 4)
                Rectangle()
                    .fill(isBottom ? Color.clear : (reached ? DuelPalette.saffron : DS.hairline))
                    .frame(width: 4)
            }
            Circle()
                .fill(reached ? DuelPalette.saffron : DS.surface)
                .overlay(Circle().strokeBorder(reached ? DuelPalette.saffron : DS.hairline, lineWidth: 3))
                .frame(width: isCurrent ? 26 : 16, height: isCurrent ? 26 : 16)
                .overlay {
                    if isCurrent {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(DuelPalette.night)
                    }
                }
        }
        .frame(width: 28)
    }

    private func card(_ league: DuelLeague, reached: Bool, isCurrent: Bool) -> some View {
        ZStack(alignment: .bottomLeading) {
            DuelLeagueBackdrop(league: league, thumb: true)
                .saturation(reached ? 1 : 0)
            LinearGradient(
                colors: [DuelPalette.night.opacity(reached ? 0.05 : 0.45), DuelPalette.night.opacity(reached ? 0.8 : 0.9)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                if isCurrent {
                    Text(languageManager.text("duel.league.here").uppercased())
                        .font(DS.sans(.caption2, .bold))
                        .tracking(1.2)
                        .foregroundStyle(DuelPalette.night)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(DuelPalette.saffron))
                }
                Text(DuelFormat.leagueName(league, language: languageManager.current))
                    .font(.jakarta(size: isCurrent ? 24 : 20, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if isCurrent {
                    // Sa propre ligue : les trophées du joueur (et non le seuil de la ligue, 0
                    // pour la première), puis le seuil de la suivante au bout de la jauge.
                    HStack(spacing: 8) {
                        DuelTrophyCount(value: home.profile.trophies, size: 15, color: .white)
                        Spacer(minLength: 0)
                        if let next = home.nextLeague(after: league) {
                            DuelTrophyCount(value: next.minTrophies, size: 13, color: .white.opacity(0.75))
                        }
                    }
                    DuelProgressBar(progress: home.leagueProgress(forTrophies: home.profile.trophies), height: 8)
                } else {
                    HStack(spacing: 8) {
                        DuelTrophyCount(value: league.minTrophies, size: 14, color: .white)
                        if !reached {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
            }
            .padding(14)
        }
        .frame(height: isCurrent ? 176 : 124)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(isCurrent ? DuelPalette.saffron : Color.clear, lineWidth: 3)
        )
        .overlay(alignment: .topTrailing) {
            Text("\(league.position)")
                .font(.jakarta(size: 13, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(minWidth: 28, minHeight: 28)
                .background(Circle().fill(DuelPalette.night.opacity(0.55)))
                .padding(10)
        }
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
                colors: [DuelPalette.night.opacity(0.25), .clear, DuelPalette.night.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Spacer()
                    Button {
                        DuelHaptics.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(DuelPalette.night.opacity(0.5)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(languageManager.text("common.close")))
                }
                Spacer()
                Text(String(format: languageManager.text("duel.league.position"), league.position).uppercased())
                    .font(DS.sans(.caption, .bold))
                    .tracking(1.6)
                    .foregroundStyle(DuelPalette.saffron)
                Text(DuelFormat.leagueName(league, language: languageManager.current))
                    .font(.jakarta(size: 40, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                if let standing {
                    caption("duel.league.yourTrophies")
                    DuelTrophyCount(value: standing.trophies, size: 26, color: .white)
                    DuelProgressBar(progress: standing.progress)
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
                    .font(DS.sans(.footnote, .semibold))
                    .foregroundStyle(.white.opacity(0.85))
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
            .font(DS.sans(.footnote, .semibold))
            .foregroundStyle(.white.opacity(0.75))
            .padding(.top, 4)
    }
}
