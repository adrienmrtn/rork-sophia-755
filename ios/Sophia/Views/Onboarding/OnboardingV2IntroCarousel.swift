import SwiftUI
import UIKit

// MARK: - État partagé du carrousel

/// Page courante et horloge du carrousel de présentation. Le coordinateur le possède : il
/// en tire les segments de l'en-tête, et sa flèche retour remonte d'abord les pages.
@Observable
@MainActor
final class OnboardingV2CarouselModel {
    static let pageCount = 4
    /// Temps d'affichage d'une page avant de passer seule à la suivante.
    static let pageDuration: TimeInterval = 5

    private(set) var page: Int = 0
    /// Instant où la page courante est apparue : le segment de l'en-tête se remplit depuis là.
    private(set) var pageStartedAt: Date = Date()
    /// La page courante attend l'utilisateur (on y est revenu en arrière) : la faire
    /// repartir seule le renverrait d'où il vient.
    private(set) var holdsCurrentPage = false
    /// Défilement automatique coupé pour tout le carrousel (« Réduire les animations »,
    /// VoiceOver) : un contenu qui change seul gêne ces lecteurs.
    var autoAdvanceDisabled = false

    /// La page courante défile-t-elle seule ?
    var isRunning: Bool {
        !holdsCurrentPage && !autoAdvanceDisabled
    }

    func go(to newPage: Int, hold: Bool = false) {
        page = min(max(newPage, 0), Self.pageCount - 1)
        pageStartedAt = Date()
        holdsCurrentPage = hold
    }

    /// Remet l'horloge de la page à zéro (apparition du carrousel, retour au premier plan).
    func restartClock() {
        pageStartedAt = Date()
    }
}

// MARK: - Carrousel

/// Écrans 5 à 8 — quatre pages de présentation (quiz, parcours, duels, audio) qui défilent
/// seules toutes les cinq secondes. Toucher ou glisser avance aussi ; « Continuer » passe à
/// la page suivante, puis à l'écran suivant ; la fin de la quatrième page avance d'elle-même.
///
/// Même mise en page sur les quatre : illustration (flexible), titre et sous-titre de
/// hauteur fixe, bouton. Les segments et la flèche retour vivent dans l'en-tête du
/// coordinateur, nourris par `model`.
struct OnboardingV2IntroCarousel: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.scenePhase) private var scenePhase

    let model: OnboardingV2CarouselModel
    let onNext: () -> Void

    private var lastPage: Int { OnboardingV2CarouselModel.pageCount - 1 }

    var body: some View {
        VStack(spacing: 0) {
            pages

            OnboardingV2Button(title: languageManager.text("common.continue")) {
                goNext(auto: false)
            }
            .padding(.top, 20)
        }
        .ov2Background()
        .onAppear {
            model.autoAdvanceDisabled = reduceMotion || UIAccessibility.isVoiceOverRunning
            model.restartClock()
        }
        .onChange(of: scenePhase) { _, phase in
            // De retour au premier plan, la page reprend ses cinq secondes entières.
            if phase == .active { model.restartClock() }
        }
        .task(id: timerKey) {
            await runTimer()
        }
    }

    // MARK: - Pages

    /// Les quatre pages restent montées, superposées : la page courante est opaque, les
    /// autres attendent décalées de chaque côté. Le sens du glissement suit ainsi toujours
    /// celui de la navigation, en avant comme en arrière.
    private var pages: some View {
        ZStack {
            slot(0) { OnboardingV2IntroQuizPage(isActive: model.page == 0) }
            slot(1) { OnboardingV2IntroRoutePage(isActive: model.page == 1) }
            slot(2) { OnboardingV2IntroDuelsPage(isActive: model.page == 2) }
            slot(3) { OnboardingV2IntroAudioPage(isActive: model.page == 3) }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            userAdvance()
        }
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    handleDrag(value.translation.width)
                }
        )
        .animation(reduceMotion ? Animation.easeInOut(duration: 0.2) : DS.Motion.reveal, value: model.page)
    }

    private func slot<Content: View>(_ index: Int, @ViewBuilder content: () -> Content) -> some View {
        let isCurrent: Bool = index == model.page
        return content()
            .opacity(isCurrent ? 1 : 0)
            .offset(x: slotOffset(index))
            .allowsHitTesting(isCurrent)
            .accessibilityHidden(!isCurrent)
    }

    /// Les pages à venir attendent du côté de la lecture, les pages passées de l'autre.
    private func slotOffset(_ index: Int) -> CGFloat {
        guard !reduceMotion, index != model.page else { return 0 }
        let side: CGFloat = index > model.page ? 1 : -1
        let mirror: CGFloat = layoutDirection == .rightToLeft ? -1 : 1
        return side * mirror * 26
    }

    // MARK: - Navigation

    /// Change à chaque nouvelle page, à chaque remise à zéro de l'horloge et quand le
    /// défilement automatique s'arrête ou reprend : la minuterie repart alors de zéro.
    private var timerKey: String {
        "\(model.page)|\(model.pageStartedAt.timeIntervalSinceReferenceDate)|\(model.isRunning)|\(scenePhase == .active)"
    }

    private func runTimer() async {
        guard model.isRunning, scenePhase == .active else { return }
        do {
            try await Task.sleep(nanoseconds: UInt64(OnboardingV2CarouselModel.pageDuration * 1_000_000_000))
        } catch {
            return
        }
        guard !Task.isCancelled else { return }
        goNext(auto: true)
    }

    /// Page suivante, ou écran suivant après la dernière.
    private func goNext(auto: Bool) {
        if model.page < lastPage {
            if auto { Haptics.tick(0.5) }
            model.go(to: model.page + 1)
        } else {
            onNext()
        }
    }

    /// Toucher la page : comme « Continuer », avec une vibration légère (la sortie du
    /// carrousel a déjà celle du changement d'écran).
    private func userAdvance() {
        if model.page < lastPage { Haptics.tap() }
        goNext(auto: false)
    }

    private func goPrevious() {
        guard model.page > 0 else { return }
        Haptics.tap()
        model.go(to: model.page - 1, hold: true)
    }

    /// Glisser vers le début de la ligne avance, vers la fin revient (inversé de droite à gauche).
    private func handleDrag(_ width: CGFloat) {
        let towardNext: CGFloat = layoutDirection == .rightToLeft ? width : -width
        if towardNext > 40 {
            userAdvance()
        } else if towardNext < -40 {
            goPrevious()
        }
    }
}

// MARK: - Activation d'une page

/// Lance `action` une seule fois, quand la page devient la page courante du carrousel (ou si
/// elle l'est déjà à l'apparition). Les quatre pages sont montées dès le départ : `onAppear`
/// seul jouerait les animations des pages encore cachées.
private struct OnboardingV2IntroActivation: ViewModifier {
    let isActive: Bool
    let action: () -> Void
    @State private var fired = false

    func body(content: Content) -> some View {
        content
            .onAppear { fireIfNeeded() }
            .onChange(of: isActive) { _, _ in fireIfNeeded() }
    }

    private func fireIfNeeded() {
        guard isActive, !fired else { return }
        fired = true
        action()
    }
}

extension View {
    func onIntroPageActivated(_ isActive: Bool, perform action: @escaping () -> Void) -> some View {
        modifier(OnboardingV2IntroActivation(isActive: isActive, action: action))
    }
}
