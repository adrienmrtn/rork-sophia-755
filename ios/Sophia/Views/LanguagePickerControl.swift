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
                    Haptics.select()
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

    /// Le déclencheur, en petite carte du style : drapeau, langue, chevron.
    private var trigger: some View {
        HStack(spacing: 8) {
            Text(languageManager.current.flag)
                .font(.jakarta(size: 20))
            if !compact {
                Text(languageManager.current.displayName)
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
            }
            Image(systemName: "chevron.forward")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DS.inkSecondary)
        }
        .padding(.horizontal, compact ? 14 : 18)
        .frame(height: 46)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous).fill(DS.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1.5)
        )
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .fill(DS.hairline)
                .offset(y: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
    }
}
