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
                        .font(.system(size: 22))
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white, in: Capsule())
                .overlay { Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2.5) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(languageManager.current.displayName)

            if isExpanded {
                brutalDropdown
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var brutalDropdown: some View {
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
                            .font(.system(size: 20))
                        Text(language.displayName)
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                            .lineLimit(1)
                        if languageManager.current == language {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundStyle(BrutalPalette.ink)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        languageManager.current == language ? BrutalPalette.pink.opacity(0.35) : Color.white
                    )
                }
                .buttonStyle(.plain)

                if language != AppLanguage.allCases.last {
                    Rectangle()
                        .fill(BrutalPalette.ink.opacity(0.12))
                        .frame(height: 2)
                }
            }
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
        }
        .background(alignment: .top) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(BrutalPalette.ink)
                .offset(y: 3)
        }
        .padding(.bottom, 3)
        .fixedSize(horizontal: true, vertical: true)
        .frame(maxWidth: compact ? nil : 220, alignment: .leading)
    }
}
