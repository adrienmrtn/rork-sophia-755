import Foundation

/// Home tab card stack presentation.
///
/// Set `style` to `.legacy` or `.tinder` for one-flag rollback.
enum HomeCardPresentation {
    static let style: Style = .feed

    enum Style {
        case legacy
        case tinder
        case feed
    }
}
