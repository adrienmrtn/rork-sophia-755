import SwiftUI
import UIKit

// MARK: - Questions (« Me cultiver au quotidien »)

/// « Avec Sophia, tu sauras répondre à ces questions » — les questions arrivent une à une,
/// en **bulles** de conversation : une à gauche (bleu pâle), la suivante à droite (bleu plein),
/// chacune avec l'avatar de la personne qui la pose. Quand l'écran est plein, la plus ancienne
/// s'efface par le haut et une nouvelle se pose en bas, si bien que les dix questions défilent
/// en boucle tant que la page est visible. Le bouton « Continuer » arrive après une seconde.
/// Montré à tout le monde (page « me cultiver au quotidien »), quel que soit l'objectif choisi.
struct OnboardingV2QuestionsScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let onNext: () -> Void

    /// Nombre de bulles déjà envoyées. Ne « reboucle » jamais : chaque bulle garde ainsi une
    /// identité stable (son rang), et le contenu boucle par un modulo sur la liste.
    @State private var sent: Int = 0
    /// Le bouton « Continuer » est là (une seconde après l'ouverture de la page).
    @State private var canContinue = false

    /// Cadence : les premières bulles se suivent vite pour remplir l'écran, puis la
    /// conversation se pose.
    private static let fastInterval: UInt64 = 480_000_000
    private static let mediumInterval: UInt64 = 800_000_000
    private static let slowInterval: UInt64 = 2_400_000_000
    /// Temps laissé aux premières bulles avant que le bouton « Continuer » n'arrive.
    private static let continueDelay: TimeInterval = 1

    /// La personne qui pose chaque question (dans l'ordre des clés `q1`…`q10`) : dix avatars
    /// de l'app, toujours les mêmes, d'âges et d'origines variés.
    private static let askers: [String] = [
        "avatar_05", "avatar_15", "avatar_10", "avatar_28", "avatar_17",
        "avatar_29", "avatar_37", "avatar_54", "avatar_55", "avatar_02",
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
                .ov2CoreAppears(canContinue)
                .padding(.top, 14)
        }
        .ov2Background()
        .onAppear {
            guard !canContinue else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.continueDelay) {
                canContinue = true
            }
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
            withAnimation(reduceMotion ? nil : OV2CoreMotion.reveal) {
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
            insertion: .scale(scale: 0.9, anchor: leading ? .bottomLeading : .bottomTrailing)
                .combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }

    // MARK: - Bulle

    private func bubble(text: String, rank: Int) -> some View {
        let leading: Bool = rank % 2 == 0
        let asker: String = Self.askers[rank % Self.askers.count]
        return HStack(alignment: .top, spacing: 10) {
            if leading {
                OV2QuestionAsker(avatarId: asker)
                bubbleText(text, leading: true)
                Spacer(minLength: 24)
            } else {
                Spacer(minLength: 24)
                bubbleText(text, leading: false)
                OV2QuestionAsker(avatarId: asker)
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

// MARK: - Avatar d'une question

/// L'avatar rond à côté d'une bulle, comme si une personne posait la question : un avatar de
/// l'app (`avatar_XX`), cerclé de blanc puis d'un filet.
private struct OV2QuestionAsker: View {
    let avatarId: String

    private static let size: CGFloat = 40

    var body: some View {
        AvatarCircle(avatarId: avatarId, initial: "", size: Self.size)
            .padding(2)
            .background(Circle().fill(DS.surface))
            .overlay(Circle().strokeBorder(DS.hairline, lineWidth: 1.5))
            .accessibilityHidden(true)
    }
}
