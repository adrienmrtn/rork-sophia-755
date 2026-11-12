import SwiftUI

// MARK: - Médaillon

/// Le rond d'un badge : son illustration en papier découpé (embarquée, ou hébergée pour un
/// événement), en couleur quand il est gagné, grisée sinon. Tant que l'illustration n'existe
/// pas, le symbole du badge sur un fond uni.
struct BadgeMedal: View {
    let badge: Badge
    let earned: Bool
    var size: CGFloat = 64

    private var bundled: UIImage? {
        badge.imageName.flatMap { UIImage(named: $0) }
    }

    var body: some View {
        ZStack {
            Circle().fill(earned ? DS.accent : DS.surfaceMuted)
            if let bundled {
                Image(uiImage: bundled)
                    .resizable()
                    .scaledToFill()
            } else if let url = badge.imageURL {
                RemoteImage(url: url)
            } else {
                Image(systemName: badge.symbol)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(earned ? DS.warm : DS.inkTertiary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        // Pas encore gagné : l'image reste reconnaissable, mais éteinte.
        .saturation(earned ? 1 : 0)
        .opacity(earned ? 1 : 0.45)
        .accessibilityHidden(true)
    }
}

// MARK: - Page « Badges »

/// Toute la collection : les badges affichés sur le profil (trois au plus) en tête, puis chaque
/// famille en grille, gagnés en couleur, les autres grisés avec leur avancement. Toucher un badge
/// ouvre son détail, d'où on l'ajoute au profil ou on l'en retire.
struct BadgesPageView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    let progressManager: ProgressManager

    @State private var selected: Badge?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: 3)
    private var language: AppLanguage { languageManager.current }

    var body: some View {
        let badges: [Badge] = BadgeCatalog.all(language: language)
        let stats = BadgeStats(progressManager: progressManager)
        let earnedCount: Int = badges.filter { progressManager.isBadgeEarned($0.id) }.count
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(earnedCount: earnedCount, total: badges.count)
                    .dsStagger(0)

                featuredCard
                    .dsStagger(1)

                ForEach(BadgeFamily.allCases, id: \.self) { family in
                    familySection(family, badges: badges, stats: stats)
                }
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(DS.canvas.ignoresSafeArea())
        .onAppear { progressManager.refreshBadges() }
        .sheet(item: $selected) { badge in
            // La feuille se règle elle-même à la hauteur de son contenu.
            BadgeDetailSheet(badge: badge, progressManager: progressManager)
        }
    }

    private func header(earnedCount: Int, total: Int) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(languageManager.text("profile.badges"))
                    .font(DS.title(.title, .semibold))
                    .foregroundStyle(DS.ink)
                Text(String(format: languageManager.text("badge.progress"), earnedCount, total))
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .monospacedDigit()
            }
            Spacer(minLength: 8)
            ProfileRoundButton(systemImage: "xmark", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
        }
    }

    /// Une famille de badges : son titre, son décompte, sa grille. Rien si la famille est vide.
    @ViewBuilder
    private func familySection(_ family: BadgeFamily, badges: [Badge], stats: BadgeStats) -> some View {
        let items: [Badge] = badges.filter { $0.family == family }
        if !items.isEmpty {
            let earnedInFamily: Int = items.filter { progressManager.isBadgeEarned($0.id) }.count
            VStack(alignment: .leading, spacing: 10) {
                ProfileSectionHeader(
                    title: languageManager.text(family.titleKey),
                    detail: "\(earnedInFamily)/\(items.count)"
                )
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, badge in
                        cell(badge, stats: stats, index: index)
                    }
                }
            }
        }
    }

    /// Les trois emplacements du profil : les badges choisis, puis des ronds vides.
    private var featuredCard: some View {
        let featured: [Badge] = progressManager.featuredBadgeIds.compactMap { BadgeCatalog.badge(id: $0) }
        return VStack(alignment: .leading, spacing: 10) {
            Text(languageManager.text("badges.featured.title"))
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(DS.ink)
            HStack(spacing: 14) {
                ForEach(0..<ProgressManager.maxFeaturedBadges, id: \.self) { index in
                    if index < featured.count {
                        Button { selected = featured[index] } label: {
                            BadgeMedal(badge: featured[index], earned: true, size: 60)
                                .dsPopIn(delay: 0.15 + Double(index) * 0.07)
                        }
                        .buttonStyle(.pressable)
                        .accessibilityLabel(Text(featured[index].title(language: language)))
                    } else {
                        Circle()
                            .strokeBorder(DS.inkSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                            .frame(width: 60, height: 60)
                            .accessibilityHidden(true)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .dsCard(padding: 0)
    }

    /// Une case de la grille. Toutes ont la même taille : le titre réserve toujours deux lignes
    /// et la ligne d'avancement garde sa place même quand elle est vide (badge gagné).
    /// Les cases arrivent en cascade ; le médaillon d'un badge gagné « pop » en plus.
    private func cell(_ badge: Badge, stats: BadgeStats, index: Int) -> some View {
        let earned: Bool = progressManager.isBadgeEarned(badge.id)
        let showsProgress: Bool = !earned && badge.target > 1 && badge.metric != .league
        // La grille est paresseuse : la cascade repart de zéro tous les neuf badges.
        let order: Int = index % 9
        return Button {
            selected = badge
        } label: {
            VStack(spacing: 6) {
                cellMedal(badge, earned: earned, order: order)
                Text(badge.title(language: language))
                    .font(DS.sans(.caption, .bold))
                    .foregroundStyle(earned ? DS.ink : DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
                Text(showsProgress ? String(format: languageManager.text("badge.progress"), stats.progress(for: badge), badge.target) : " ")
                    .font(DS.sans(.caption2))
                    .foregroundStyle(DS.inkSecondary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .opacity(showsProgress ? 1 : 0)
                    .accessibilityHidden(!showsProgress)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, alignment: .top)
            .dsCard(padding: 0)
            .contentShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        }
        .buttonStyle(.pressable)
        .dsStagger(order, step: 0.035)
    }

    @ViewBuilder
    private func cellMedal(_ badge: Badge, earned: Bool, order: Int) -> some View {
        if earned {
            BadgeMedal(badge: badge, earned: true, size: 60)
                .dsPopIn(delay: 0.18 + Double(order) * 0.035)
        } else {
            BadgeMedal(badge: badge, earned: false, size: 60)
        }
    }
}

// MARK: - Détail d'un badge

/// Le badge en grand, sa condition, la date où il a été gagné (ou l'avancement), et le bouton
/// qui l'affiche sur le profil ou l'en retire.
struct BadgeDetailSheet: View {
    @Environment(LanguageManager.self) private var languageManager
    let badge: Badge
    let progressManager: ProgressManager

    @State private var showFull = false
    /// Secousse du bouton quand les trois emplacements du profil sont déjà pris.
    @State private var fullShake = 0
    /// La hauteur du contenu, mesurée : la feuille s'arrête là, sans vide en dessous.
    @State private var contentHeight: CGFloat = 360

    private var language: AppLanguage { languageManager.current }

    var body: some View {
        let earned = progressManager.isBadgeEarned(badge.id)
        let featured = progressManager.featuredBadgeIds.contains(badge.id)
        let stats = BadgeStats(progressManager: progressManager)
        VStack(spacing: 14) {
            BadgeMedal(badge: badge, earned: earned, size: 120)
                .dsPopIn(delay: 0.1)
                .padding(.top, 28)
            Text(badge.title(language: language))
                .font(DS.title(.title2, .semibold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
            Text(badge.condition(language: language))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if earned {
                if let date = progressManager.badgeEarnedDate(badge.id) {
                    Text(String(format: languageManager.text("badges.earnedOn"), date.formatted(.dateTime.day().month(.wide).year().locale(languageManager.locale))))
                        .font(DS.sans(.footnote, .semibold))
                        .foregroundStyle(DS.success)
                }
            } else {
                VStack(spacing: 8) {
                    if badge.target > 1, badge.metric != .league {
                        ProfileFillBar(fraction: Double(stats.progress(for: badge)) / Double(badge.target), height: 8)
                            .frame(maxWidth: 220)
                    }
                    Text(languageManager.text("badges.locked"))
                        .font(DS.sans(.footnote, .semibold))
                        .foregroundStyle(DS.inkSecondary)
                }
            }

            if earned {
                if showFull {
                    Text(languageManager.text("badges.featured.full"))
                        .font(DS.sans(.caption, .medium))
                        .foregroundStyle(DS.danger)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button {
                    let changed = progressManager.toggleFeaturedBadge(badge.id)
                    if !changed {
                        // Trois badges déjà affichés : le bouton refuse, et le dit.
                        Haptics.warning()
                        fullShake += 1
                    }
                    withAnimation(DS.Motion.snappy) { showFull = !changed }
                } label: {
                    Text(languageManager.text(featured ? "badges.featured.remove" : "badges.featured.add"))
                        .font(DS.sans(.headline, .semibold))
                        .foregroundStyle(featured ? DS.ink : Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                                .fill(featured ? DS.surface : DS.accent)
                        )
                        .overlay {
                            if featured {
                                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                                    .strokeBorder(DS.hairline, lineWidth: 1.5)
                            }
                        }
                        .contentShape(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
                }
                .buttonStyle(.pressable)
                .dsShake(trigger: fullShake)
                .animation(DS.Motion.snappy, value: featured)
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            // Bornée à l'écran : au-delà (très grands caractères), la feuille reste grande.
            if height > 0 { contentHeight = min(height.rounded(.up), UIScreen.main.bounds.height * 0.9) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(DS.canvas.ignoresSafeArea())
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Rangée de badges (profil, profil d'un ami)

/// Quelques médaillons avec leur nom, côte à côte : les badges qu'une personne affiche.
struct BadgeRow: View {
    @Environment(LanguageManager.self) private var languageManager
    let badges: [Badge]
    /// Gagnés ou non, un par badge (le profil d'un ami ne montre que des badges gagnés).
    var earned: (Badge) -> Bool = { _ in true }
    var onTap: ((Badge) -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ForEach(Array(badges.enumerated()), id: \.element.id) { index, badge in
                if let onTap {
                    Button { onTap(badge) } label: { tile(badge, index: index) }
                        .buttonStyle(.pressable)
                } else {
                    tile(badge, index: index)
                }
            }
        }
    }

    /// Une case : le médaillon (qui « pop » s'il est gagné) et le nom du badge.
    private func tile(_ badge: Badge, index: Int) -> some View {
        let isEarned: Bool = earned(badge)
        return VStack(spacing: 6) {
            medal(badge, isEarned: isEarned, index: index)
            Text(badge.title(language: languageManager.current))
                .font(DS.sans(.caption, .bold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                // Deux lignes toujours réservées : toutes les cases ont la même hauteur.
                .lineLimit(2, reservesSpace: true)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, alignment: .top)
        .dsCard(padding: 0)
        .contentShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
    }

    @ViewBuilder
    private func medal(_ badge: Badge, isEarned: Bool, index: Int) -> some View {
        if isEarned {
            BadgeMedal(badge: badge, earned: true, size: 60)
                .dsPopIn(delay: 0.15 + Double(index) * 0.07)
        } else {
            BadgeMedal(badge: badge, earned: false, size: 60)
        }
    }
}
