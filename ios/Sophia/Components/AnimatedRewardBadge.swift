import SwiftUI

/// Les « emotes » de la gamification, traitées comme la flamme des streaks : un pictogramme
/// en dégradé chaud, un halo, un battement doux. Une seule famille pour l'XP, les trophées,
/// les niveaux, les collections, les quiz et les cours lus, pour que chaque récompense se
/// reconnaisse d'un coup d'œil et donne envie de la revoir.
struct AnimatedRewardBadge: View {
    enum Kind {
        /// Les points d'expérience : une étoile dorée.
        case xp
        /// Un quiz terminé, un classement : un trophée doré.
        case trophy
        /// Un niveau gagné : un éclair violet-rose.
        case levelUp
        /// Une collection ou une session terminée : un sceau vert-menthe.
        case seal
        /// Les cours lus : des livres bleu-turquoise.
        case courses
        /// La précision aux quiz : une cible rose-orange.
        case target

        var symbol: String {
            switch self {
            case .xp: "star.fill"
            case .trophy: "trophy.fill"
            case .levelUp: "bolt.fill"
            case .seal: "checkmark.seal.fill"
            case .courses: "books.vertical.fill"
            case .target: "target"
            }
        }

        /// Du bas vers le haut du pictogramme.
        var colors: [Color] {
            switch self {
            case .xp, .trophy:
                [Color(red: 0.98, green: 0.60, blue: 0.10), Color(red: 1.0, green: 0.82, blue: 0.22), Color(red: 1.0, green: 0.93, blue: 0.55)]
            case .levelUp:
                [Color(red: 0.55, green: 0.30, blue: 0.95), Color(red: 0.85, green: 0.35, blue: 0.80), Color(red: 0.98, green: 0.55, blue: 0.70)]
            case .seal:
                [Color(red: 0.16, green: 0.60, blue: 0.42), Color(red: 0.30, green: 0.80, blue: 0.58), Color(red: 0.62, green: 0.94, blue: 0.78)]
            case .courses:
                [Color(red: 0.18, green: 0.40, blue: 0.90), Color(red: 0.25, green: 0.65, blue: 0.95), Color(red: 0.45, green: 0.88, blue: 0.90)]
            case .target:
                [Color(red: 0.96, green: 0.30, blue: 0.56), Color(red: 1.0, green: 0.55, blue: 0.30), Color(red: 1.0, green: 0.78, blue: 0.40)]
            }
        }

        /// La couleur du halo et de l'ombre : le ton du milieu.
        var glow: Color { colors[1] }
    }

    let kind: Kind
    var size: CGFloat = 24
    var showGlow: Bool = true
    /// `false` pour un pictogramme coloré mais immobile (l'en-tête de l'accueil).
    var animated: Bool = true

    @State private var pulse = false

    var body: some View {
        ZStack {
            if showGlow {
                Circle()
                    .fill(kind.glow.opacity(pulse ? 0.45 : 0.28))
                    .frame(width: size * 1.7, height: size * 1.7)
                    .blur(radius: size * 0.22)
            }

            Image(systemName: kind.symbol)
                .font(.jakarta(size: size, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(colors: kind.colors, startPoint: .bottom, endPoint: .top)
                )
                .symbolEffect(.variableColor.iterative.reversing, isActive: animated)
                .shadow(color: kind.glow.opacity(0.35), radius: size * 0.14, y: size * 0.06)
                .scaleEffect(pulse ? 1.08 : 1)
        }
        .frame(width: size * 1.4, height: size * 1.4)
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
