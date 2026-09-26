import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Draws the full-screen shield iOS puts over TikTok.
///
/// Runs in its own process, without the app's assets or localisation tables: the copy
/// comes from `TikTokBlockerShared` (App Group), the icon is an SF Symbol. Apple owns the
/// layout; we only fill in colours, icon, two lines of text and two buttons.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        sophiaShield()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        sophiaShield()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        sophiaShield()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        sophiaShield()
    }

    private func sophiaShield() -> ShieldConfiguration {
        let copy = TikTokBlockerShared.shieldCopy()
        // "Open Sophia" was tapped a moment ago: the shield now points at the app, so a
        // missed notification never leaves the user wondering what happened.
        let subtitle = TikTokBlockerShared.isRequestPending ? copy.pendingSubtitle : copy.subtitle
        // Sophia's navy accent (`DS.accent`, light).
        let accent = UIColor(red: 0.102, green: 0.227, blue: 0.420, alpha: 1)
        let icon = UIImage(systemName: "book.closed.fill")?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
            .applyingSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 44, weight: .bold))

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: accent.withAlphaComponent(0.94),
            icon: icon,
            title: ShieldConfiguration.Label(text: copy.title, color: .white),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: UIColor.white.withAlphaComponent(0.82)),
            primaryButtonLabel: ShieldConfiguration.Label(text: copy.primaryButton, color: accent),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: ShieldConfiguration.Label(text: copy.secondaryButton, color: UIColor.white.withAlphaComponent(0.85))
        )
    }
}
