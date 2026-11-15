import SwiftUI
import UIKit

// The collections pages (list, featured and row cards, detail with its course list) lived
// here until the "Parcours" tab replaced them for good on 28/09/2026. What remains is what
// the rest of the app still uses: the shared press feedback and the collection cover.

// MARK: - Shared press feedback

/// Subtle press feedback (gentle scale) that doesn't intercept scroll gestures. Used by many
/// screens, some of them frozen on the previous look: it stays discreet, and silent — most of
/// its call sites already vibrate in their own action.
struct SoftPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(DS.Motion.press, value: configuration.isPressed)
    }
}

// MARK: - Cover

struct CollectionCoverView: View {
    let collection: LearningCollection
    var accentIndex: Int = 0

    private var palette: (Color, Color) {
        // Dégradés bleu pâle le jour ; en mode Nuit, les mêmes en bleu nuit (un pavé pastel
        // ferait une tache claire sur le fond sombre).
        func pair(_ light: (CGFloat, CGFloat, CGFloat), _ dark: (CGFloat, CGFloat, CGFloat)) -> Color {
            Color(uiColor: DSAdaptive.color(light: light, dark: dark))
        }
        let palettes: [(Color, Color)] = [
            (pair((0.914, 0.937, 0.973), (0.165, 0.208, 0.286)), pair((0.831, 0.878, 0.949), (0.125, 0.161, 0.227))),
            (pair((0.902, 0.925, 0.965), (0.157, 0.196, 0.271)), pair((0.784, 0.843, 0.933), (0.118, 0.153, 0.220))),
            (pair((0.925, 0.949, 0.976), (0.173, 0.216, 0.294)), pair((0.808, 0.867, 0.941), (0.129, 0.169, 0.239))),
            (pair((0.898, 0.933, 0.973), (0.161, 0.204, 0.282)), pair((0.769, 0.831, 0.925), (0.114, 0.149, 0.216))),
        ]
        return palettes[accentIndex % palettes.count]
    }

    var body: some View {
        ZStack {
            if let image = UIImage(named: collection.coverAssetName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                fallbackCover
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var fallbackCover: some View {
        ZStack {
            LinearGradient(colors: [palette.0, palette.1], startPoint: .topLeading, endPoint: .bottomTrailing)

            Image(systemName: "square.stack.3d.up")
                .font(.jakarta(size: 40, weight: .light))
                .foregroundStyle(DS.accentSoft.opacity(0.55))
        }
    }
}
