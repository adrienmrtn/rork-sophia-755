import SwiftUI
import UIKit

/// Page 1 — Bienvenue. Un mur de couvertures de cours qui défile lentement, le logo Sophia,
/// la phrase d'accroche, le CTA « Commencer » et la porte « J'ai déjà un compte ».
struct OnboardingV2Welcome: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void
    /// Tapped by someone who is reinstalling or switching phone. Optional so the
    /// screen still renders in a preview that has no coordinator behind it.
    var onExistingAccount: (() -> Void)? = nil
    /// Délai avant l'entrée de la page : le temps que le logo animé du lancement ait joué.
    var entranceDelay: TimeInterval = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var covers: [UIImage] = []
    @State private var wallIn = false
    @State private var textIn = false
    @State private var actionsIn = false

    /// Cours dont la couverture garnit le mur : les plus lus et les plus parlants en image,
    /// trois par colonne. Une couverture absente du bundle est simplement sautée.
    private static let coverCourseIds: [String] = [
        "course_67_qu_est_ce_qu_un_trou_noir",
        "course_241_pourquoi_voulait_on_demolir_la_tour_eiffel",
        "course_42_pourquoi_reve_t_on",
        "course_150_la_nuit_etoilee_van_gogh",
        "course_149_la_joconde",
        "course_281_comment_meurt_une_etoile",
        "course_264_qui_a_vraiment_construit_les_pyramides",
        "course_101_1984_george_orwell",
        "course_290_comment_les_etats_unis_ont_ils_gagne_la",
        "course_161_la_naissance_des_dieux_grecs_cronos_zeus",
        "course_247_pourquoi_les_momies_font_elles_peur",
        "course_11_la_prise_de_la_bastille_1789",
    ]

    var body: some View {
        GeometryReader { geo in
            let wallHeight: CGFloat = Self.wallHeight(for: geo.size.height)

            VStack(alignment: .leading, spacing: 0) {
                Color.clear
                    .frame(height: wallHeight)

                Spacer(minLength: 8)

                textBlock
                    .padding(.horizontal, 24)

                Spacer(minLength: 16)

                actions
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(alignment: .top) {
                OnboardingV2CoverWall(images: covers)
                    .frame(height: wallHeight + geo.safeAreaInsets.top)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .ignoresSafeArea(edges: .top)
                    .opacity(wallIn ? 1 : 0)
                    .scaleEffect(wallIn || reduceMotion ? 1 : 1.05, anchor: .top)
            }
        }
        .ov2Background()
        .task { await loadCovers() }
        .onAppear { enter() }
    }

    /// Le mur prend la moitié haute de l'écran, bornée pour laisser le texte et les boutons
    /// respirer sur un petit iPhone.
    private static func wallHeight(for screenHeight: CGFloat) -> CGFloat {
        max(200, min(410, screenHeight * 0.5))
    }

    // MARK: - Texte

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            logo

            OV2Markup.elevate(languageManager.text("onboardingV2.welcome.title"), highlightFont: DS.title(.title, .bold))
                .font(DS.title(.title, .regular))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text(languageManager.text("onboardingV2.welcome.subtitle"))
                .font(DS.sans(.subheadline, .regular))
                .foregroundStyle(OV2.inkSecondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(textIn ? 1 : 0)
        .offset(y: textIn || reduceMotion ? 0 : 16)
    }

    /// Le logo complet (symbole + « Sophia ») ; à défaut d'image, le nom en toutes lettres.
    @ViewBuilder
    private var logo: some View {
        if UIImage(named: "sophia_mark") != nil {
            Image("sophia_mark")
                .resizable()
                .scaledToFit()
                .frame(width: 136)
                .accessibilityLabel(Text(verbatim: "Sophia"))
        } else {
            Text(verbatim: "Sophia")
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
        }
    }

    // MARK: - Boutons

    // No spacing of its own: `OnboardingV2Button` already carries its bottom padding,
    // which is the gap between the two.
    private var actions: some View {
        VStack(spacing: 0) {
            OnboardingV2Button(
                title: languageManager.text("onboardingV2.welcome.cta"),
                bottomPadding: onExistingAccount == nil ? 20 : 6,
                action: onNext
            )

            // Quiet on purpose: this is the door for people who already know the
            // app, and it must not compete with "Get started" for a new one.
            if let onExistingAccount {
                Button(action: onExistingAccount) {
                    Text(languageManager.text("onboardingV2.welcome.existingAccount"))
                        .font(DS.sans(.subheadline, .semibold))
                        .tracking(0.3)
                        .foregroundStyle(OV2.accent)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
        }
        .opacity(actionsIn ? 1 : 0)
        .offset(y: actionsIn || reduceMotion ? 0 : 14)
    }

    // MARK: - Entrée

    private func enter() {
        guard !wallIn else { return }
        let base: TimeInterval = max(0, entranceDelay)
        withAnimation(.easeOut(duration: 0.7).delay(base)) {
            wallIn = true
        }
        withAnimation(DS.Motion.reveal.delay(base + 0.15)) {
            textIn = true
        }
        withAnimation(DS.Motion.reveal.delay(base + 0.3)) {
            actionsIn = true
        }
    }

    /// Les couvertures sont décodées une à une, à la taille du mur, en rendant la main entre
    /// deux : douze images de 1024 px ne doivent ni saccader l'entrée ni rester en mémoire.
    private func loadCovers() async {
        guard covers.isEmpty else { return }
        var loaded: [UIImage] = []
        for courseId in Self.coverCourseIds {
            if let image = CourseImageMap.loadImage(for: courseId) {
                loaded.append(OnboardingV2CoverWall.thumbnail(of: image))
            }
            await Task.yield()
        }
        covers = loaded
    }
}

// MARK: - Mur de couvertures

/// Quatre colonnes de couvertures de cours, décalées en hauteur, qui défilent lentement en
/// sens alternés et se fondent dans le blanc en bas. Immobile quand « Réduire les
/// animations » est actif ; des pavés teintés tiennent la place tant que les images chargent.
struct OnboardingV2CoverWall: View {
    let images: [UIImage]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()

    private static let columnCount = 4
    private static let coversPerColumn = 3
    private static let coverHeight: CGFloat = 136
    private static let gap: CGFloat = 10
    /// Débord du mur de chaque côté de l'écran, comme sur la maquette.
    private static let bleed: CGFloat = 28
    /// Décalage de départ de chaque colonne.
    private static let phases: [CGFloat] = [34, 96, 52, 12]
    /// Vitesse de chaque colonne en points par seconde ; le signe donne le sens.
    private static let speeds: [CGFloat] = [7, -5.5, 6.5, -7.5]

    /// Hauteur d'un tour complet d'une colonne : après elle, la copie suivante est
    /// exactement là où était la précédente.
    private static var period: CGFloat {
        CGFloat(coversPerColumn) * (coverHeight + gap)
    }

    var body: some View {
        GeometryReader { geo in
            let columnWidth: CGFloat = Self.columnWidth(for: geo.size.width)
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
                let elapsed: TimeInterval = reduceMotion ? 0 : context.date.timeIntervalSince(start)
                HStack(alignment: .top, spacing: Self.gap) {
                    ForEach(0..<Self.columnCount, id: \.self) { column in
                        OnboardingV2CoverColumn(
                            images: columnImages(column),
                            width: columnWidth,
                            coverHeight: Self.coverHeight,
                            gap: Self.gap,
                            slots: Self.coversPerColumn
                        )
                        .offset(y: Self.offset(column: column, elapsed: elapsed))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
        }
        .clipped()
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [OV2.bg.opacity(0), OV2.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 130)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { start = Date() }
    }

    private static func columnWidth(for width: CGFloat) -> CGFloat {
        let total: CGFloat = width + bleed * 2 - gap * CGFloat(columnCount - 1)
        return max(60, total / CGFloat(columnCount))
    }

    /// Décalage vertical d'une colonne : sa phase de départ plus le chemin parcouru, bouclé
    /// sur un tour.
    private static func offset(column: Int, elapsed: TimeInterval) -> CGFloat {
        let phase: CGFloat = phases[column % phases.count]
        let speed: CGFloat = speeds[column % speeds.count]
        let travel: CGFloat = phase + CGFloat(elapsed) * speed
        let wrapped: CGFloat = travel.truncatingRemainder(dividingBy: period)
        let positive: CGFloat = wrapped < 0 ? wrapped + period : wrapped
        return -positive
    }

    /// Les images de la colonne : une sur quatre, en partant de son rang.
    private func columnImages(_ column: Int) -> [UIImage] {
        var result: [UIImage] = []
        var index = column
        while index < images.count, result.count < Self.coversPerColumn {
            result.append(images[index])
            index += Self.columnCount
        }
        return result
    }

    /// La couverture ramenée à la taille du mur (au plus 360 px de côté), proportions gardées.
    static func thumbnail(of image: UIImage) -> UIImage {
        let longest: CGFloat = max(image.size.width, image.size.height)
        guard longest > 360 else { return image }
        let ratio: CGFloat = 360 / longest
        let target = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        return image.preparingThumbnail(of: target) ?? image
    }
}

/// Une colonne du mur : ses couvertures, répétées trois fois pour boucler sans raccord.
private struct OnboardingV2CoverColumn: View {
    let images: [UIImage]
    let width: CGFloat
    let coverHeight: CGFloat
    let gap: CGFloat
    /// Nombre de couvertures par tour, même quand certaines images manquent.
    let slots: Int

    private static let copies = 3

    var body: some View {
        VStack(spacing: gap) {
            ForEach(0..<(slots * Self.copies), id: \.self) { index in
                cover(at: index % max(slots, 1))
            }
        }
        .frame(width: width)
    }

    @ViewBuilder
    private func cover(at slot: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        ZStack {
            if images.indices.contains(slot) {
                Image(uiImage: images[slot])
                    .resizable()
                    .scaledToFill()
            } else {
                DS.accentTint
            }
        }
        .frame(width: width, height: coverHeight)
        .clipShape(shape)
        .overlay(shape.strokeBorder(DS.hairline, lineWidth: 1.5))
    }
}
