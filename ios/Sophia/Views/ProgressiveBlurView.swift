import SwiftUI

/// Wraps content with a top-to-bottom progressive blur: crisp at the very top,
/// ramping to full blur by ~20% of the view's height, then staying fully blurred
/// to the bottom. Used to tease locked lesson content without an abrupt blur edge.
///
/// `compositingGroup()` before `.blur()` avoids the gray-edge clipping artifact
/// that plain `.blur()` produces on tall content.
struct ProgressiveBlurView<Content: View>: View {
    var blurRadius: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            content()
                .compositingGroup()

            content()
                .compositingGroup()
                .blur(radius: blurRadius)
                .compositingGroup()
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.2),
                            .init(color: .black, location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
}
