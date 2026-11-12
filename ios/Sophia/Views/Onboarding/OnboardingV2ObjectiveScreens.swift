import SwiftUI
import UIKit

// MARK: - Questions (« Me cultiver au quotidien »)

/// « Avec Sophia, tu sauras répondre à ces questions » — les questions arrivent une à une,
/// en **bulles** de conversation : une à gauche (bleu pâle), la suivante à droite (bleu plein),
/// chacune avec la vignette du cours qui y répond. Quand l'écran est plein, la plus ancienne
/// s'efface par le haut et une nouvelle se pose en bas, si bien que les dix questions défilent
/// en boucle tant que la page est visible.
/// Montré à tout le monde (page « me cultiver au quotidien »), quel que soit l'objectif choisi.
struct OnboardingV2QuestionsScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let onNext: () -> Void

    /// Nombre de bulles déjà envoyées. Ne « reboucle » jamais : chaque bulle garde ainsi une
    /// identité stable (son rang), et le contenu boucle par un modulo sur la liste.
    @State private var sent: Int = 0

    /// Cadence : les premières bulles se suivent vite pour remplir l'écran, puis la
    /// conversation se pose.
    private static let fastInterval: UInt64 = 480_000_000
    private static let mediumInterval: UInt64 = 800_000_000
    private static let slowInterval: UInt64 = 2_400_000_000

    /// Le cours qui répond à chaque question (dans l'ordre des clés `q1`…`q10`) : sa
    /// couverture sert de vignette ; à défaut, la vignette de la matière.
    private static let covers: [(courseId: String?, subject: Subject)] = [
        ("course_41_pourquoi_le_ciel_est_il_bleu", .sciences),
        ("course_12_la_strategie_de_napoleon_a_ulm_1805", .histoire),
        ("course_67_qu_est_ce_qu_un_trou_noir", .sciences),
        ("course_122_la_naissance_de_l_impressionnisme", .art),
        ("course_216_la_dette_mondiale", .comprendreLeMonde),
        ("course_65_pourquoi_la_lune_ne_tombe_t_elle_pas_sur", .sciences),
        (nil, .histoire),
        ("course_61_le_big_bang", .sciences),
        ("course_42_pourquoi_reve_t_on", .sciences),
        ("course_68_la_theorie_de_la_relativite_pour_tous", .sciences),
    ]

    private var questions: [String] {
        (1...10).map { languageManager.text("onboardingV2.questions.q\($0)") }
    }

    /// « Avec Sophia, tu sauras **répondre à ces questions** » : le titre existant, sans ses
    /// deux-points finaux (les bulles ne sont plus une liste), son cœur en gras bleu.
    private var title: String {
        let base: String = OV2CoreText.trimmingTrailing(
            ":：",
            from: languageManager.text("onboardingV2.questions.title")
        )
        return OV2CoreText.marked(
            text: base,
            highlightKey: "elevateOnboardingCore.questions.titleHighlight",
            language: languageManager.current
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            OV2CoreHighlightTitle(text: title, size: 25)
                .padding(.horizontal, OV2CoreMetrics.sideInset)
                .padding(.top, OV2CoreMetrics.topInset)
                .dsStagger(0)

            GeometryReader { geo in
                feed(capacity: capacity(for: geo.size.height))
                    .padding(.horizontal, OV2CoreMetrics.sideInset)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                    .clipped()
            }
            .padding(.top, 10)

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
                .padding(.top, 14)
        }
        .ov2Background()
        .onAppear {
            CourseImageMap.preloadImages(for: Self.covers.compactMap { $0.courseId })
        }
        .task {
            await runConversation()
        }
    }

    // MARK: - Conversation

    /// Envoie une bulle après l'autre tant que l'écran est visible. Reprend où elle en était
    /// si la page réapparaît.
    private func runConversation() async {
        if sent == 0 {
            try? await Task.sleep(nanoseconds: 350_000_000)
        }
        while !Task.isCancelled {
            withAnimation(reduceMotion ? nil : DS.Motion.reveal) {
                sent += 1
            }
            // Une vibration par bulle le temps d'un tour complet, puis le défilement se tait.
            if sent <= questions.count {
                Haptics.soft()
            }
            try? await Task.sleep(nanoseconds: interval(after: sent))
        }
    }

    private func interval(after count: Int) -> UInt64 {
        if count < 4 { return Self.fastInterval }
        if count < 6 { return Self.mediumInterval }
        return Self.slowInterval
    }

    /// Nombre de bulles affichées à la fois, selon la hauteur libre et la taille du texte.
    private func capacity(for height: CGFloat) -> Int {
        // Hauteur moyenne d'une bulle (une à deux lignes) et de l'espace qui la suit.
        let slot: CGFloat = dynamicTypeSize >= .xLarge ? 98 : 72
        return min(6, max(2, Int(height / slot)))
    }

    private func feed(capacity: Int) -> some View {
        let all: [String] = questions
        let count: Int = max(all.count, 1)
        let first: Int = max(0, sent - capacity)
        let visible: [Int] = Array(first..<max(first, sent))
        return VStack(spacing: 12) {
            ForEach(visible, id: \.self) { rank in
                bubble(text: all.isEmpty ? "" : all[rank % count], rank: rank)
                    .transition(bubbleTransition(leading: rank % 2 == 0))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func bubbleTransition(leading: Bool) -> AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .scale(scale: 0.6, anchor: leading ? .bottomLeading : .bottomTrailing)
                .combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }

    // MARK: - Bulle

    private func bubble(text: String, rank: Int) -> some View {
        let leading: Bool = rank % 2 == 0
        let cover = Self.covers[rank % Self.covers.count]
        return HStack(alignment: .top, spacing: 10) {
            if leading {
                OV2QuestionCover(courseId: cover.courseId, subject: cover.subject)
                bubbleText(text, leading: true)
                Spacer(minLength: 24)
            } else {
                Spacer(minLength: 24)
                bubbleText(text, leading: false)
                OV2QuestionCover(courseId: cover.courseId, subject: cover.subject)
            }
        }
    }

    private func bubbleText(_ text: String, leading: Bool) -> some View {
        Text(text)
            .font(DS.sans(.subheadline, .semibold))
            .foregroundStyle(leading ? DS.ink : Color.white)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 15)
            .padding(.vertical, 11)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: leading ? 4 : 18,
                    bottomLeadingRadius: 18,
                    bottomTrailingRadius: 18,
                    topTrailingRadius: leading ? 18 : 4,
                    style: .continuous
                )
                .fill(leading ? DS.accentTint : DS.accent)
            )
    }
}

// MARK: - Vignette d'une question

/// Vignette ronde à côté d'une bulle : la couverture du cours, sinon la vignette de sa matière,
/// cerclée de blanc puis d'un filet.
private struct OV2QuestionCover: View {
    let courseId: String?
    let subject: Subject

    private static let size: CGFloat = 40

    private var coverImage: UIImage? {
        guard let courseId else { return nil }
        return CourseImageMap.loadImage(for: courseId)
    }

    var body: some View {
        ZStack {
            if let image = coverImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Self.size, height: Self.size)
                    .clipShape(Circle())
            } else {
                OV2CoreSubjectBadge(subject: subject, size: Self.size)
            }
        }
        .frame(width: Self.size, height: Self.size)
        .padding(2)
        .background(Circle().fill(DS.surface))
        .overlay(Circle().strokeBorder(DS.hairline, lineWidth: 1.5))
        .accessibilityHidden(true)
    }
}
