import SwiftUI

struct LanguagePickerControl: View {
    @Environment(LanguageManager.self) private var languageManager
    @State private var isExpanded: Bool = false

    /// Compact dropdown width for onboarding overlays.
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(languageManager.current.flag)
                        .font(.jakarta(size: 20))
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.jakarta(size: 11, weight: .semibold))
                        .foregroundStyle(DS.inkSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(DS.surface, in: Capsule())
                .overlay { Capsule().strokeBorder(DS.hairline, lineWidth: 1) }
            }
            .buttonStyle(SoftPressButtonStyle())
            .accessibilityLabel(languageManager.current.displayName)

            if isExpanded {
                dropdown
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var dropdown: some View {
        VStack(spacing: 0) {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        languageManager.setLanguage(language)
                        isExpanded = false
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(language.flag)
                            .font(.jakarta(size: 18))
                        Text(language.displayName)
                            .font(DS.sans(.subheadline, .medium))
                            .foregroundStyle(DS.ink)
                            .lineLimit(1)
                        if languageManager.current == language {
                            Spacer(minLength: 8)
                            Image(systemName: "checkmark")
                                .font(.jakarta(size: 12, weight: .semibold))
                                .foregroundStyle(DS.accent)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        languageManager.current == language ? DS.accentTint : DS.surface
                    )
                }
                .buttonStyle(.plain)

                if language != AppLanguage.allCases.last {
                    Rectangle()
                        .fill(DS.hairline)
                        .frame(height: 1)
                }
            }
        }
        .background(DS.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
        .dsSoftShadow()
        .fixedSize(horizontal: true, vertical: true)
        .frame(maxWidth: compact ? nil : 220, alignment: .leading)
    }
}
