import SwiftUI

struct GlossaryTermSheet: View {
    let entry: GlossaryEntry
    @Environment(\.dismiss) private var dismiss

    @State private var contentHeight: CGFloat = 280

    private let ink = Color.black
    private let cream = Color(red: 0.984, green: 0.961, blue: 0.918)

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(ink.opacity(0.15))
                .frame(width: 44, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 18)

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Text(entry.classification.localizedShortLabel(language: AppLanguage.currentPersisted()).uppercased())
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                        .tracking(0.6)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(entry.classification.pastel, in: Capsule())
                        .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }

                    Spacer()
                }

                Text(entry.displayTerm)
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(entry.explanation)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(ink.opacity(0.85))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
        .background {
            cream
                .ignoresSafeArea()
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: GlossarySheetHeightKey.self, value: geo.size.height)
                    }
                )
        }
        .onPreferenceChange(GlossarySheetHeightKey.self) { height in
            guard height > 0 else { return }
            contentHeight = min(max(height, 180), UIScreen.main.bounds.height * 0.82)
        }
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .presentationBackground(cream)
    }
}

private struct GlossarySheetHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
