import Foundation

/// Home tab card stack presentation.
///
/// Set `style` to `.legacy` to restore the previous home cards UI instantly
/// (compact stack, symmetric swipe, start button, swipe tutorial).
enum HomeCardPresentation {
    static let style: Style = .tinder

    enum Style {
        case legacy
        case tinder
    }
}
