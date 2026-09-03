import SwiftUI
import UIKit

/// Three-way appearance control (Light / Night / Automatic) used in Settings.
struct AppearancePickerControl: View {
    @Environment(AppearanceManager.self) private var appearance
    @Environment(LanguageManager.self) private var languageManager

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppearancePreference.allCases) { option in
                let selected = appearance.preference == option
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    appearance.setPreference(option)
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: option.systemImage)
                            .font(.jakarta(size: 16, weight: .semibold))
                        Text(languageManager.text(option.localizationKey))
                            .font(DS.sans(.caption, .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(selected ? DS.ink : DS.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(selected ? DS.surface : Color.clear)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(selected ? DS.hairline : Color.clear, lineWidth: 1)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
                .accessibilityLabel(languageManager.text(option.localizationKey))
            }
        }
        .padding(4)
        .background(DS.surfaceMuted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(languageManager.text("settings.section.appearance"))
    }
}
