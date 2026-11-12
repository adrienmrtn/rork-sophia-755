import SwiftUI
import UIKit

/// Écran 3 — Leçons. Une pile de livres (« un livre entier, des heures de lecture ») face à
/// la carte d'une vraie leçon du catalogue (« une leçon Sophia, 10 minutes »), puis la
/// promesse : des leçons de 10 minutes passionnantes, faites pour toi.
struct OnboardingV2Lessons: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onNext: () -> Void

    @State private var course: Course?
    @State private var cover: UIImage?
    /// Nombre de livres posés sur la pile (ils tombent un à un, celui du bas d'abord).
    @State private var booksShown = 0
    @State private var arrowIn = false
    @State private var cardIn = false
    @State private var titleIn = false

    /// Durée d'une leçon, en minutes (le « 10 min » affiché partout dans l'onboarding).
    private static let lessonMinutes = 10

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
        .onAppear { loadCourse() }
        .task { await play() }
    }

    // MARK: - Livre contre leçon

    private var comparison: some View {
        HStack(alignment: .bottom, spacing: 12) {
            bookColumn
                .frame(maxWidth: 132)

            Image(systemName: "arrow.forward")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(DS.accent)
                .padding(.bottom, 72)
                .opacity(arrowIn ? 1 : 0)
                .offset(x: arrowIn || reduceMotion ? 0 : -10)
                .accessibilityHidden(true)

            lessonColumn
                .frame(maxWidth: 150)
        }
        .frame(maxWidth: .infinity)
    }

    private var bookColumn: some View {
        VStack(spacing: 14) {
            caption(
                title: languageManager.text("onboardingV2.elevate.lessons.book.title"),
                detail: languageManager.text("onboardingV2.elevate.lessons.book.caption"),
                color: OV2.inkSecondary,
                detailWeight: .regular
            )

            VStack(spacing: 5) {
                ForEach(Array(Self.books.enumerated()), id: \.offset) { index, book in
                    bookBar(book, landed: Self.books.count - index <= booksShown)
                }
            }
            .frame(height: 168, alignment: .bottom)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }

    private func bookBar(_ book: Book, landed: Bool) -> some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(book.color)
            .frame(width: book.width, height: book.height)
            .opacity(landed ? 1 : 0)
            .offset(y: landed || reduceMotion ? 0 : -26)
    }

    private var lessonColumn: some View {
        VStack(spacing: 14) {
            caption(
                title: languageManager.text("onboardingV2.elevate.lessons.lesson.title"),
                detail: String(format: languageManager.text("onboardingV2.elevate.lessons.lesson.caption"), Self.lessonMinutes),
                color: DS.accent,
                detailWeight: .semibold
            )

            lessonCard
                .scaleEffect(cardIn || reduceMotion ? 1 : 0.6, anchor: .bottom)
                .opacity(cardIn ? 1 : 0)
        }
        .accessibilityElement(children: .combine)
    }

    /// La carte d'une vraie leçon : sa couverture et son titre, bordée du bleu d'accent.
    private var lessonCard: some View {
        VStack(spacing: 9) {
            Color.clear
                .frame(height: 112)
                .overlay {
                    if let cover {
                        Image(uiImage: cover)
                            .resizable()
                            .scaledToFill()
                    } else {
                        DS.accentTint
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .accessibilityHidden(true)

            Text(course?.title ?? "")
                .font(DS.sans(.footnote, .bold))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 7)
        .padding(.top, 7)
        .padding(.bottom, 12)
        .frame(width: 138)
        .ov2Card(border: DS.accent, lip: 1.5)
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

    private func loadCourse() {
        guard course == nil else { return }
        let picked: Course? = OnboardingV2IntroCatalog.course(
            preferring: OnboardingV2IntroCatalog.dreamCourseId,
            language: languageManager.current
        )
        course = picked
        if let picked {
            cover = OnboardingV2IntroCatalog.coverThumbnail(for: picked.id)
        }
    }

    /// Les livres tombent sur la pile, la flèche part, la leçon se pose : des heures de
    /// lecture ramenées à dix minutes.
    private func play() async {
        guard !cardIn else { return }
        if reduceMotion {
            booksShown = Self.books.count
            arrowIn = true
            cardIn = true
            titleIn = true
            return
        }

        withAnimation(DS.Motion.reveal.delay(0.1)) {
            titleIn = true
        }
        await pause(0.3)
        for count in 1...Self.books.count {
            if Task.isCancelled { return }
            withAnimation(DS.Motion.snappy) {
                booksShown = count
            }
            Haptics.tick(0.35)
            await pause(0.1)
        }
        await pause(0.12)
        if Task.isCancelled { return }
        withAnimation(DS.Motion.reveal) {
            arrowIn = true
        }
        await pause(0.22)
        if Task.isCancelled { return }
        withAnimation(DS.Motion.pop) {
            cardIn = true
        }
        Haptics.soft()
    }

    private func pause(_ seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
