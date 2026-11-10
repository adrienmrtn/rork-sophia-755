import SwiftUI

// MARK: - Médaillon

/// Le rond d'un badge : son illustration en papier découpé (embarquée, ou hébergée pour un
/// événement), cerclée d'or quand il est gagné, grisée sinon. Tant que l'illustration n'existe
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
        .overlay {
            Circle().strokeBorder(earned ? DS.warm : DS.hairline, lineWidth: earned ? max(2, size * 0.045) : 1)
        }
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
        let badges = BadgeCatalog.all(language: language)
        let stats = BadgeStats(progressManager: progressManager)
        let earnedCount = badges.filter { progressManager.isBadgeEarned($0.id) }.count
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(languageManager.text("profile.badges"))
                            .font(DS.title(.title, .heavy))
                            .foregroundStyle(DS.ink)
                        Text(String(format: languageManager.text("badge.progress"), earnedCount, badges.count))
                            .font(DS.sans(.subheadline, .semibold))
                            .foregroundStyle(DS.inkSecondary)
                            .monospacedDigit()
                    }
                    Spacer(minLength: 0)
                    RoundIconButton(systemImage: "xmark", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
                }

                featuredCard

                ForEach(BadgeFamily.allCases, id: \.self) { family in
                    let items = badges.filter { $0.family == family }
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            NewGenSectionTitle(
                                text: languageManager.text(family.titleKey),
                                trailing: "\(items.filter { progressManager.isBadgeEarned($0.id) }.count)/\(items.count)"
                            )
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(items) { badge in
                                    cell(badge, stats: stats)
                                }
                            }
                        }
                    }
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

    /// Les trois emplacements du profil : les badges choisis, puis des ronds vides.
    private var featuredCard: some View {
        let featured = progressManager.featuredBadgeIds.compactMap { BadgeCatalog.badge(id: $0) }
        return VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.text("badges.featured.title"))
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(DS.ink)
            HStack(spacing: 14) {
                ForEach(0..<ProgressManager.maxFeaturedBadges, id: \.self) { index in
                    if index < featured.count {
                        Button { selected = featured[index] } label: {
                            BadgeMedal(badge: featured[index], earned: true, size: 60)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(featured[index].title(language: language)))
                    } else {
                        Circle()
                            .strokeBorder(DS.inkTertiary, style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                            .frame(width: 60, height: 60)
                            .accessibilityHidden(true)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
    }

    /// Une case de la grille. Toutes ont la même taille : le titre réserve toujours deux lignes
    /// et la ligne d'avancement garde sa place même quand elle est vide (badge gagné).
    private func cell(_ badge: Badge, stats: BadgeStats) -> some View {
        let earned = progressManager.isBadgeEarned(badge.id)
        let showsProgress = !earned && badge.target > 1 && badge.metric != .league
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selected = badge
        } label: {
            VStack(spacing: 8) {
                BadgeMedal(badge: badge, earned: earned, size: 68)
                Text(badge.title(language: language))
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(earned ? DS.ink : DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
                Text(showsProgress ? String(format: languageManager.text("badge.progress"), stats.progress(for: badge), badge.target) : " ")
                    .font(DS.sans(.caption2, .semibold))
                    .foregroundStyle(DS.inkTertiary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .opacity(showsProgress ? 1 : 0)
                    .accessibilityHidden(!showsProgress)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, alignment: .top)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(DS.surface))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
    /// La hauteur du contenu, mesurée : la feuille s'arrête là, sans vide en dessous.
    @State private var contentHeight: CGFloat = 360

    private var language: AppLanguage { languageManager.current }

    var body: some View {
        let earned = progressManager.isBadgeEarned(badge.id)
        let featured = progressManager.featuredBadgeIds.contains(badge.id)
        let stats = BadgeStats(progressManager: progressManager)
        VStack(spacing: 14) {
            BadgeMedal(badge: badge, earned: earned, size: 120)
                .padding(.top, 28)
            Text(badge.title(language: language))
                .font(DS.title(.title2, .heavy))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
            Text(badge.condition(language: language))
                .font(DS.sans(.subheadline, .medium))
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
                        CalmProgressBar(fraction: Double(stats.progress(for: badge)) / Double(badge.target))
                            .frame(maxWidth: 220)
                    }
                    Text(languageManager.text("badges.locked"))
                        .font(DS.sans(.footnote, .semibold))
                        .foregroundStyle(DS.inkTertiary)
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
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    let changed = progressManager.toggleFeaturedBadge(badge.id)
                    withAnimation(.easeInOut(duration: 0.2)) { showFull = !changed }
                } label: {
                    Text(languageManager.text(featured ? "badges.featured.remove" : "badges.featured.add"))
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(featured ? DS.ink : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(featured ? DS.surface : DS.accent))
                        .overlay {
                            if featured {
                                RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
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
            ForEach(badges) { badge in
                let content = VStack(spacing: 8) {
                    BadgeMedal(badge: badge, earned: earned(badge), size: 60)
                    Text(badge.title(language: languageManager.current))
                        .font(DS.sans(.footnote, .bold))
                        .foregroundStyle(DS.ink)
                        .multilineTextAlignment(.center)
                        // Deux lignes toujours réservées : toutes les cases ont la même hauteur.
                        .lineLimit(2, reservesSpace: true)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, alignment: .top)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(DS.surface))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
                if let onTap {
                    Button { onTap(badge) } label: { content }.buttonStyle(.plain)
                } else {
                    content
                }
            }
        }
    }
}
