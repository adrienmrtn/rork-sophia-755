import SwiftUI

struct LanguagePickerControl: View {
    @Environment(LanguageManager.self) private var languageManager

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        languageManager.setLanguage(language)
                    }
                } label: {
                    Text(language.flag)
                        .font(.system(size: 20))
                        .frame(width: 40, height: 40)
                        .background(
                            languageManager.current == language ? BrutalPalette.ink : Color.white,
                            in: Circle()
                        )
                        .overlay {
                            Circle().strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(language.displayName)
            }
        }
    }
}
