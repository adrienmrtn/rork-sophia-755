import SwiftUI
import UIKit

/// Écran 3 — Leçons. Une pile de livres (« un livre entier, des heures de lecture ») face à
/// la carte d'une vraie leçon du catalogue (« une leçon Sophia, 10 minutes »), puis la
/// promesse : des leçons de 10 minutes passionnantes, faites pour toi. La leçon montrée
/// change toutes les 1,5 seconde : les cours les plus lus se relaient dans la carte.
struct OnboardingV2Lessons: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onNext: () -> Void

    /// Les leçons qui se relaient dans la carte, dans l'ordre de passage.
    @State private var lessons: [Course] = []
    /// Les couvertures déjà décodées, par identifiant de cours.
    @State private var covers: [String: UIImage] = [:]
    /// Rang de la leçon montrée dans `lessons`.
    @State private var lessonIndex = 0
    /// Nombre de livres posés sur la pile (ils se posent un à un, celui du bas d'abord).
    @State private var booksShown = 0
    @State private var arrowIn = false
    @State private var cardIn = false
    @State private var titleIn = false

    /// Durée d'une leçon, en minutes (le « 10 min » affiché partout dans l'onboarding).
    private static let lessonMinutes = 10
    /// Temps d'affichage d'une leçon avant de laisser la place à la suivante.
    private static let lessonInterval: TimeInterval = 1.5
    /// Largeur maximale de la comparaison, et de la carte de leçon dans sa colonne.
    private static let comparisonWidth: CGFloat = 340
    private static let cardWidth: CGFloat = 138
    /// Largeur de la case centrale, celle de la flèche.
    private static let arrowSlot: CGFloat = 28

    /// Un livre de la pile : largeur, épaisseur et gris de l'illustration.
    private struct Book {
        let width: CGFloat
        let height: CGFloat
        let color: Color
    }

    private static let books: [Book] = [
        Book(width: 84, height: 20, color: Color(red: 0.835, green: 0.855, blue: 0.886)),
        Book(width: 106, height: 24, color: Color(red: 0.682, green: 0.710, blue: 0.753)),
        Book(width: 92, height: 20, color: Color(red: 0.855, green: 0.867, blue: 0.886)),
        Book(width: 114, height: 26, color: Color(red: 0.745, green: 0.773, blue: 0.812)),
        Book(width: 98, height: 22, color: Color(red: 0.804, green: 0.824, blue: 0.855)),
    ]

    /// La leçon montrée en ce moment.
    private var currentLesson: Course? {
        guard !lessons.isEmpty else { return nil }
        return lessons[lessonIndex % lessons.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 44) {
                comparison
                title
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear { loadLessons() }
        .task {
            await play()
            await loadRemainingCovers()
            await rotateLessons()
        }
    }

    // MARK: - Livre contre leçon

    /// Deux rangées qui partagent les mêmes colonnes (livre, flèche, leçon) : les deux
    /// légendes partent de la même ligne en haut, les deux illustrations se posent sur la même
    /// ligne en bas. Empilées colonne par colonne, les légendes se décalaient dès que la pile
    /// de livres et la carte n'avaient pas la même hauteur.
    private var comparison: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 8) {
                caption(
                    title: languageManager.text("onboardingV2.elevate.lessons.book.title"),
                    detail: languageManager.text("onboardingV2.elevate.lessons.book.caption"),
                    color: OV2.inkSecondary,
                    detailWeight: .regular
                )
                .frame(maxWidth: .infinity)

                Color.clear
                    .frame(width: Self.arrowSlot, height: 1)

                caption(
                    title: languageManager.text("onboardingV2.elevate.lessons.lesson.title"),
                    detail: String(format: languageManager.text("onboardingV2.elevate.lessons.lesson.caption"), Self.lessonMinutes),
                    color: DS.accent,
                    detailWeight: .semibold
                )
                .frame(maxWidth: .infinity)
            }

            HStack(alignment: .bottom, spacing: 8) {
                bookStack
                    .frame(maxWidth: .infinity)

                Image(systemName: "arrow.forward")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(DS.accent)
                    .frame(width: Self.arrowSlot)
                    .padding(.bottom, 72)
                    .opacity(arrowIn ? 1 : 0)
                    .offset(x: arrowIn || reduceMotion ? 0 : -8)
                    .accessibilityHidden(true)

                lessonCard
                    .opacity(cardIn ? 1 : 0)
                    .offset(y: cardIn || reduceMotion ? 0 : 12)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: Self.comparisonWidth)
        .frame(maxWidth: .infinity)
    }

    private var bookStack: some View {
        VStack(spacing: 5) {
            ForEach(Array(Self.books.enumerated()), id: \.offset) { index, book in
                bookBar(book, landed: Self.books.count - index <= booksShown)
            }
        }
        .frame(height: 168, alignment: .bottom)
        .accessibilityHidden(true)
    }

    private func bookBar(_ book: Book, landed: Bool) -> some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(book.color)
            .frame(width: book.width, height: book.height)
            .opacity(landed ? 1 : 0)
            .offset(y: landed || reduceMotion ? 0 : -14)
    }

    /// La carte d'une vraie leçon : sa couverture et son titre, bordée du bleu d'accent. Le
    /// cadre ne bouge pas ; seul son contenu change quand la leçon suivante arrive.
    private var lessonCard: some View {
        ZStack {
            lessonContent(currentLesson)
                .id(lessonIndex)
                .transition(lessonTransition)
        }
        .padding(.horizontal, 7)
        .padding(.top, 7)
        .padding(.bottom, 12)
        .frame(maxWidth: Self.cardWidth)
        .ov2Card(border: DS.accent, lip: 1.5)
        .accessibilityElement(children: .combine)
    }

    private func lessonContent(_ lesson: Course?) -> some View {
        VStack(spacing: 9) {
            Color.clear
                .frame(height: 112)
                .overlay {
                    if let lesson, let cover = covers[lesson.id] {
                        Image(uiImage: cover)
                            .resizable()
                            .scaledToFill()
                    } else {
                        DS.accentTint
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .accessibilityHidden(true)

            // Trois lignes toujours réservées : un titre court ou long, la carte garde sa
            // hauteur et rien ne saute d'une leçon à l'autre.
            Text(lesson?.title ?? "")
                .font(DS.sans(.footnote, .bold))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .lineLimit(3, reservesSpace: true)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
        }
    }

    /// La leçon suivante monte en fondu pendant que la précédente s'efface vers le haut.
    private var lessonTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 10)),
            removal: .opacity.combined(with: .offset(y: -10))
        )
    }

    private func caption(title: String, detail: String, color: Color, detailWeight: Font.Weight) -> some View {
        VStack(spacing: 1) {
            Text(title)
                .font(DS.sans(.subheadline, .bold))
            Text(detail)
                .font(DS.sans(.footnote, detailWeight))
        }
        .foregroundStyle(color)
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.8)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Titre

    private var title: some View {
        OV2Markup.elevate(languageManager.text("onboardingV2.intro.lessons.title"), highlightFont: DS.title(.title, .bold))
            .font(DS.title(.title, .regular))
            .foregroundStyle(OV2.ink)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .lineLimit(6)
            .minimumScaleFactor(0.7)
            .accessibilityAddTraits(.isHeader)
            .opacity(titleIn ? 1 : 0)
            .offset(y: titleIn || reduceMotion ? 0 : 14)
    }

    // MARK: - Données et animation

    /// Les cours mis en avant, dans la langue courante ; seule la couverture du premier est
    /// décodée tout de suite, les autres le sont une fois l'entrée jouée.
    private func loadLessons() {
        guard lessons.isEmpty else { return }
        let picked: [Course] = OnboardingV2IntroCatalog.featuredCourses(language: languageManager.current)
        lessons = picked
        if let first = picked.first, let cover = OnboardingV2IntroCatalog.coverThumbnail(for: first.id) {
            covers[first.id] = cover
        }
    }

    /// Décode les couvertures des leçons suivantes une à une, en rendant la main entre deux.
    private func loadRemainingCovers() async {
        for lesson in lessons where covers[lesson.id] == nil {
            if Task.isCancelled { return }
            if let cover = OnboardingV2IntroCatalog.coverThumbnail(for: lesson.id) {
                covers[lesson.id] = cover
            }
            await Task.yield()
        }
    }

    /// Les livres se posent sur la pile, la flèche part, la leçon arrive : des heures de
    /// lecture ramenées à dix minutes. Le tout tient en un peu plus d'une demi-seconde.
    private func play() async {
        guard !cardIn else { return }
        if reduceMotion {
            booksShown = Self.books.count
            arrowIn = true
            cardIn = true
            titleIn = true
            return
        }

        withAnimation(OV2CoreMotion.reveal.delay(0.05)) {
            titleIn = true
        }
        await pause(0.15)
        for count in 1...Self.books.count {
            if Task.isCancelled { return }
            withAnimation(OV2CoreMotion.select) {
                booksShown = count
            }
            await pause(0.06)
        }
        if Task.isCancelled { return }
        Haptics.tick(0.35)
        withAnimation(OV2CoreMotion.select) {
            arrowIn = true
        }
        await pause(0.12)
        if Task.isCancelled { return }
        withAnimation(OV2CoreMotion.settle) {
            cardIn = true
        }
        Haptics.soft()
    }

    /// Fait passer la leçon suivante dans la carte toutes les 1,5 seconde, en boucle, tant
    /// que la page est visible. Rien ne change seul avec « Réduire les animations » ou
    /// VoiceOver : un contenu qui se remplace tout seul gêne ces lecteurs.
    private func rotateLessons() async {
        guard !reduceMotion, !UIAccessibility.isVoiceOverRunning else { return }
        while !Task.isCancelled {
            await pause(Self.lessonInterval)
            if Task.isCancelled { return }
            guard lessons.count > 1 else { continue }
            withAnimation(.easeInOut(duration: 0.4)) {
                lessonIndex = (lessonIndex + 1) % lessons.count
            }
        }
    }

    private func pause(_ seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
