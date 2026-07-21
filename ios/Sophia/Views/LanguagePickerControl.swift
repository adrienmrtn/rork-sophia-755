import SwiftUI

/// Language selector rendered as a native `Menu` dropdown. Using `Menu` (instead of a custom
/// inline expanding panel) gives a stable, system-standard popover that doesn't push the
/// surrounding layout around or glitch inside a `ScrollView`, and shows the current language
/// clearly (flag + name) on the trigger.
struct LanguagePickerControl: View {
    @Environment(LanguageManager.self) private var languageManager

    /// Compact trigger (flag only) for tight onboarding overlays.
    var compact: Bool = false

    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    languageManager.setLanguage(language)
                } label: {
                    if languageManager.current == language {
                        Label("\(language.flag)  \(language.displayName)", systemImage: "checkmark")
                    } else {
                        Text("\(language.flag)  \(language.displayName)")
                    }
                }
            }
        } label: {
            trigger
        }
        .accessibilityLabel(languageManager.current.displayName)
    }

    private var trigger: some View {
        HStack(spacing: 8) {
            Text(languageManager.current.flag)
                .font(.jakarta(size: 20))
            if !compact {
                Text(languageManager.current.displayName)
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
            }
            Image(systemName: "chevron.up.chevron.down")
                .font(.jakarta(size: 11, weight: .semibold))
                .foregroundStyle(DS.inkSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(DS.surface, in: Capsule())
        .overlay { Capsule().strokeBorder(DS.hairline, lineWidth: 1) }
    }
}
