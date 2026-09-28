import SwiftUI

// The collections pages (list, featured and row cards, detail with its course list) lived
// here until the "Parcours" tab replaced them for good on 28/09/2026. What remains is what
// the rest of the app still uses: the shared press feedback and the collection cover.

// MARK: - Shared press feedback

/// Subtle press feedback (gentle scale) that doesn't intercept scroll gestures.
struct SoftPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Cover

struct CollectionCoverView: View {
    let collection: LearningCollection
    var accentIndex: Int = 0

    private var palette: (Color, Color) {
        let palettes: [(Color, Color)] = [
            (Color(red: 0.914, green: 0.937, blue: 0.973), Color(red: 0.831, green: 0.878, blue: 0.949)),
            (Color(red: 0.902, green: 0.925, blue: 0.965), Color(red: 0.784, green: 0.843, blue: 0.933)),
            (Color(red: 0.925, green: 0.949, blue: 0.976), Color(red: 0.808, green: 0.867, blue: 0.941)),
            (Color(red: 0.898, green: 0.933, blue: 0.973), Color(red: 0.769, green: 0.831, blue: 0.925)),
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
