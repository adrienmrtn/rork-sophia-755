import SwiftUI

/// Flags « déjà vu » pour les explications de première ouverture (par installation).
/// Stockés dans `UserDefaults` (indépendants de la progression synchronisée) : chaque
/// explication n'apparaît qu'une seule fois.
enum TutorialFlags {
    enum ID: String {
        case homeSwipe = "sophia_tut_home_swipe"
        case courseTerms = "sophia_tut_course_terms"
        case collections = "sophia_tut_collections"
        case training = "sophia_tut_training"
    }

    static func seen(_ id: ID) -> Bool {
        UserDefaults.standard.bool(forKey: id.rawValue)
    }

    static func markSeen(_ id: ID) {
        UserDefaults.standard.set(true, forKey: id.rawValue)
    }
}

/// Explication de première ouverture : l'écran s'assombrit lentement puis l'icône et le texte
/// apparaissent en douceur, l'un après l'autre (reveal lent et calme, sans carte). Pas de CTA —
/// un appui n'importe où la fait disparaître.
struct FirstOpenExplanation: View {
    @Environment(LanguageManager.self) private var languageManager

    let icon: String
    let title: String
    let message: String
    let onDismiss: () -> Void

    @State private var dim = false
    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showMessage = false
    @State private var showHint = false
    @State private var leaving = false
    @State private var tapCount = 0

    var body: some View {
        ZStack {
            // Écran grisé, fondu lent.
            Color.black.opacity(dim ? 0.64 : 0)
                .ignoresSafeArea()

            VStack(spacing: 26) {
                ZStack {
                    Circle().fill(.white.opacity(0.10)).frame(width: 96, height: 96)
                    Circle().strokeBorder(.white.opacity(0.16), lineWidth: 1).frame(width: 96, height: 96)
                    Image(systemName: icon)
                        .font(.jakarta(size: 34, weight: .light))
                        .foregroundStyle(.white)
                }
                .scaleEffect(showIcon ? 1 : 0.7)
                .opacity(showIcon ? 1 : 0)

                VStack(spacing: 14) {
                    Text(title)
                        .font(DS.title(.title, .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 14)

                    Text(message)
                        .font(DS.sans(.body))
                        .foregroundStyle(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(showMessage ? 1 : 0)
                        .offset(y: showMessage ? 0 : 12)
                }
            }
            .padding(.horizontal, 44)

            VStack {
                Spacer()
                Text(languageManager.text("explain.tapToClose"))
                    .font(DS.sans(.footnote, .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .opacity(showHint ? 1 : 0)
                    .padding(.bottom, 48)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .sensoryFeedback(.impact(weight: .light), trigger: tapCount)
        .onAppear { runReveal() }
    }

    private func runReveal() {
        withAnimation(.easeInOut(duration: 0.8)) { dim = true }
        withAnimation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.4)) { showIcon = true }
        withAnimation(.easeOut(duration: 0.9).delay(0.9)) { showTitle = true }
        withAnimation(.easeOut(duration: 1.0).delay(1.45)) { showMessage = true }
        withAnimation(.easeIn(duration: 0.8).delay(2.2)) { showHint = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    private func dismiss() {
        guard dim, !leaving else { return }
        leaving = true
        tapCount += 1
        withAnimation(.easeOut(duration: 0.4)) {
            dim = false
            showIcon = false
            showTitle = false
            showMessage = false
            showHint = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) { onDismiss() }
    }
}

/// Coachmark contextuel affiché quand l'utilisateur voit son premier mot surligné :
/// il met en avant CE mot précis (rendu souligné, comme dans le texte) et explique qu'on
/// peut appuyer dessus. Pas de CTA — un appui n'importe où le ferme.
struct GlossaryCoachmark: View {
    @Environment(LanguageManager.self) private var languageManager

    let term: String
    let onDismiss: () -> Void

    @State private var dim = false
    @State private var showTerm = false
    @State private var showTitle = false
    @State private var showMessage = false
    @State private var showHint = false
    @State private var leaving = false
    @State private var tapCount = 0

    var body: some View {
        ZStack {
            Color.black.opacity(dim ? 0.64 : 0)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Le mot exact, mis en avant (souligné accent, comme dans le cours).
                Text(term)
                    .font(DS.title(.title, .semibold))
                    .foregroundStyle(.white)
                    .underline(true, color: DS.accentSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))
                    .scaleEffect(showTerm ? 1 : 0.8)
                    .opacity(showTerm ? 1 : 0)

                VStack(spacing: 12) {
                    Text(languageManager.text("explain.course.title"))
                        .font(DS.title(.title3, .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 12)

                    Text(String(format: languageManager.text("explain.course.termBody"), term))
                        .font(DS.sans(.body))
                        .foregroundStyle(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(showMessage ? 1 : 0)
                        .offset(y: showMessage ? 0 : 12)
                }
            }
            .padding(.horizontal, 44)

            VStack {
                Spacer()
                Text(languageManager.text("explain.tapToClose"))
                    .font(DS.sans(.footnote, .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .opacity(showHint ? 1 : 0)
                    .padding(.bottom, 48)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .sensoryFeedback(.impact(weight: .light), trigger: tapCount)
        .onAppear { runReveal() }
    }

    private func runReveal() {
        withAnimation(.easeInOut(duration: 0.8)) { dim = true }
        withAnimation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.4)) { showTerm = true }
        withAnimation(.easeOut(duration: 0.9).delay(0.95)) { showTitle = true }
        withAnimation(.easeOut(duration: 1.0).delay(1.5)) { showMessage = true }
        withAnimation(.easeIn(duration: 0.8).delay(2.25)) { showHint = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    private func dismiss() {
        guard dim, !leaving else { return }
        leaving = true
        tapCount += 1
        withAnimation(.easeOut(duration: 0.4)) {
            dim = false
            showTerm = false
            showTitle = false
            showMessage = false
            showHint = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) { onDismiss() }
    }
}
