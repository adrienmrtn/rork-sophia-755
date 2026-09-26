import AppIntents
import Foundation

/// The action a Shortcuts automation runs when TikTok opens.
///
/// The Screen Time shield cannot launch Sophia; a personal automation can ("When TikTok
/// is opened → run immediately → Sophia: Check TikTok lock"). The user sets it up once
/// from the blocker settings. From then on, opening TikTok brings Sophia to the front on
/// a course, with no notification and no tap.
///
/// The intent runs in the background first. If TikTok is not locked (blocker off, or an
/// unlock window is open, which is also the case right after "Back to TikTok"), it
/// returns and TikTok stays where it is. Otherwise it stamps the same request the shield
/// writes and asks iOS to bring Sophia to the foreground, where `ContentView` reads the
/// stamp and opens the course.
struct TikTokGateIntent: AppIntent, ForegroundContinuableIntent {
    static let title: LocalizedStringResource = "Check TikTok lock"
    static let description = IntentDescription(
        "Run it from an automation when TikTok opens: if TikTok is locked, Sophia opens on a course."
    )
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        guard TikTokBlockerShared.isEnabled,
              TikTokBlockerShared.hasSelection,
              !TikTokBlockerShared.isUnlockWindowOpen
        else {
            return .result()
        }
        TikTokBlockerShared.pendingRequestAt = Date()
        DeepLinkRouter.shared.requestUnlock()
        throw needsToContinueInForegroundError()
    }
}

/// Lists the action under Sophia in the Shortcuts app, so the automation guide's "pick
/// Sophia, then Check TikTok lock" matches what the user sees.
struct SophiaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TikTokGateIntent(),
            phrases: ["Check TikTok lock in \(.applicationName)"],
            shortTitle: "Check TikTok lock",
            systemImageName: "lock.fill"
        )
    }
}
