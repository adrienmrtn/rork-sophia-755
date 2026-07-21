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

/// Explication légère de première ouverture : voile sombre + carte calme (icône, titre,
/// phrase courte). Pas de CTA — un appui n'importe où la fait disparaître.
struct FirstOpenExplanation: View {
    @Environment(LanguageManager.self) private var languageManager

    let icon: String
    let title: String
    let message: String
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var tapCount = 0

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.5 : 0)
                .ignoresSafeArea()

            card
                .padding(.horizontal, 36)
                .scaleEffect(appeared ? 1 : 0.92)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
        }
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .sensoryFeedback(.impact(weight: .light), trigger: tapCount)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.1)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        }
    }

    private var card: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(DS.accentTint).frame(width: 72, height: 72)
                Image(systemName: icon)
                    .font(.jakarta(size: 30, weight: .regular))
                    .foregroundStyle(DS.accent)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(DS.title(.title2, .semibold))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(languageManager.text("explain.tapToClose"))
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(DS.inkTertiary)
                .padding(.top, 2)
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
        .dsSoftShadow()
    }

    private func dismiss() {
        guard appeared else { return }
        tapCount += 1
        withAnimation(.easeOut(duration: 0.3)) { appeared = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { onDismiss() }
    }
}
