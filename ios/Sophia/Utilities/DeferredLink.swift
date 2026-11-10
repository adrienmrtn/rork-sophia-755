import UIKit

/// Reprise après installation : quelqu'un reçoit le lien d'un cours, n'a pas Sophia, l'installe
/// depuis la page du site, et doit retrouver ce cours à la fin de l'onboarding.
///
/// L'App Store ne transmet rien à l'app installée. Le seul relais sans service tiers est le
/// presse-papiers : sur la page d'un cours ou d'un auteur, le bouton du store y copie l'adresse
/// de la page (`web/src/components/StoreButtons.tsx`). Au tout premier lancement, l'app regarde
/// si le presse-papiers contient une adresse web (`detectPatterns`, sans rien lire ni rien
/// afficher) ; seulement dans ce cas elle la lit, ce qui fait apparaître la demande « Autoriser
/// le collage » d'iOS. Une adresse qui n'est pas une page de cours ou d'auteur du site est
/// ignorée. Le contrôle n'a lieu qu'une fois, et jamais pour une app déjà utilisée.
enum DeferredLink {
    private static let checkedKey = "sophia_deferred_link_checked"
    private static let pendingKey = "sophia_deferred_link_url"

    /// À appeler au lancement. Ne fait quelque chose que la première fois, onboarding pas fini.
    static func captureAtFirstLaunch() async {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: checkedKey) else { return }
        defaults.set(true, forKey: checkedKey)
        guard !OnboardingViewModel.isOnboardingCompleted else { return }

        let patterns: Set<UIPasteboard.DetectionPattern> = [.probableWebURL]
        let hasWebURL: Bool = await withCheckedContinuation { continuation in
            UIPasteboard.general.detectPatterns(for: patterns) { (result: Result<Set<UIPasteboard.DetectionPattern>, Error>) in
                let found = (try? result.get())?.contains(.probableWebURL) ?? false
                continuation.resume(returning: found)
            }
        }
        guard hasWebURL,
              let text = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: text),
              SophiaDeepLink.webTarget(from: url) != nil
        else { return }
        defaults.set(url.absoluteString, forKey: pendingKey)
    }

    /// À la fin de l'onboarding (ou au lancement suivant s'il a été fini sans passer par là) :
    /// le lien gardé part au routeur, qui ouvre le cours ou la page du créateur.
    static func openPendingIfAny() {
        let defaults = UserDefaults.standard
        guard let text = defaults.string(forKey: pendingKey) else { return }
        defaults.removeObject(forKey: pendingKey)
        guard let url = URL(string: text) else { return }
        if DeepLinkRouter.shared.open(url) {
            AnalyticsService.shared.pendingCourseOpenSource = .sharedLink
        }
    }
}
