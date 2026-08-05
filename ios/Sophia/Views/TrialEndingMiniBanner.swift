import SwiftUI

/// Tiny top strip shown once when the user opens the app the day before trial end.
/// Auto-dismisses after 1 second — not tappable, not a push notification.
struct TrialEndingMiniBanner: View {
    @Environment(LanguageManager.self) private var languageManager

    var body: some View {
        Text(languageManager.text("trial.endingSoon.banner"))
            .font(DS.sans(.caption2, .medium))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(DS.accent.opacity(0.94))
    }
}
