import Foundation

/// Home tab card stack presentation.
///
/// Set `style` back to `.legacy` or `.tinder` to roll back instantly.
/// - `.legacy`: compact stack, symmetric swipe, start button, swipe tutorial.
/// - `.tinder`: full-bleed stack, swipe right opens the course, swipe left skips.
/// - `.tiktok`: full-bleed horizontal pager (native page TabView) — swiping only
///   browses between courses, opening one always goes through the explicit
///   "Commencer" CTA.
enum HomeCardPresentation {
    static let style: Style = .tiktok

    enum Style {
        case legacy
        case tinder
        case tiktok
    }
}
