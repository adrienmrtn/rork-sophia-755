import SwiftUI

struct GlossaryTermSheet: View {
    let entry: GlossaryEntry
    @Environment(\.dismiss) private var dismiss

    @State private var contentHeight: CGFloat = 280

    private let ink = DS.ink
    private let cream = DS.canvas

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(DS.hairline)
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 18)

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Text(entry.classification.localizedShortLabel(language: AppLanguage.currentPersisted()).uppercased())
                        .font(DS.sans(.caption2, .semibold))
                        .foregroundStyle(DS.accentSoft)
                        .tracking(1.0)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(DS.accentTint, in: Capsule())

                    Spacer()
                }

                Text(entry.displayTerm)
                    .font(DS.serif(.title2, .semibold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(entry.explanation)
                    .font(DS.sans(.body))
                    .foregroundStyle(DS.inkSecondary)
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
