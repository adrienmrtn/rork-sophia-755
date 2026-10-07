import SwiftUI

/// Pages de présentation de l'app, juste après le choix de la langue : quatre « petits
/// points » reliés par les points en bas de l'écran, un seul bouton « Continuer ». Les pages
/// se parcourent au bouton ou au doigt ; la dernière mène à l'écran « Rejoins les 500 000
/// utilisateurs » (`OnboardingV2SocialProof`).
///
/// Leçons (quatre cartes) · Vrais chercheurs (profs et universités) · Quiz (images de cours)
/// · Parcours personnalisé (aperçu du Parcours).
struct OnboardingV2IntroCarousel: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var page = 0

    private static let pageCount = 4

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                OnboardingV2IntroLessonsPage(isActive: page == 0)
                    .tag(0)
                OnboardingV2IntroResearchersPage(isActive: page == 1)
                    .tag(1)
                OnboardingV2IntroQuizzesPage(isActive: page == 2)
                    .tag(2)
                OnboardingV2IntroRoutePage(isActive: page == 3)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            OnboardingV2PagerDots(count: Self.pageCount, current: page)
                .padding(.vertical, 18)

            OnboardingV2Button(title: languageManager.text("common.continue"), action: advance)
        }
        .ov2Background()
    }

    /// « Continuer » fait défiler les pages, puis quitte le carrousel après la dernière.
    private func advance() {
        if page < Self.pageCount - 1 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                page += 1
            }
        } else {
            onNext()
        }
    }
}

// MARK: - Points de pagination (bas d'écran)

/// Les petits points sous les pages de présentation : le point courant en encre, les autres
/// estompés. Distincts des points de progression du haut (`OnboardingV2ProgressDots`).
struct OnboardingV2PagerDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(i == current ? OV2.ink : OV2.ink.opacity(0.18))
                    .frame(width: 8, height: 8)
                    .scaleEffect(i == current ? 1 : 0.85)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(current + 1) / \(count)")
    }
}

// MARK: - Mots en rose

/// Les textes des pages marquent entre `**` les mots à montrer en rose : « Get **smarter**
/// with… ». Le marqueur voyage avec la traduction : chaque langue met en avant ses propres
/// mots, sans rien changer au code.
enum OV2Markup {
    static func highlighted(_ source: String, color: Color = OV2.pink) -> Text {
        var result = Text(verbatim: "")
        for (index, part) in source.components(separatedBy: "**").enumerated() where !part.isEmpty {
            let piece = Text(verbatim: part)
            // Les morceaux impairs sont ceux entre deux marqueurs.
            result = result + (index.isMultiple(of: 2) ? piece : piece.foregroundStyle(color))
        }
        return result
    }
}

// MARK: - Activation d'une page

/// Lance `action` une seule fois, quand la page devient la page courante du carrousel (ou si
/// elle l'est déjà à l'apparition). Un `TabView` paginé prépare la page voisine avant qu'elle
/// soit visible : `onAppear` seul jouerait les animations hors écran.
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
