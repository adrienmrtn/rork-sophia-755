import SwiftUI

struct TermsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageManager.self) private var languageManager

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            VStack(spacing: 0) {
                LegalHeader(title: languageManager.text("legal.terms.title"), onClose: { dismiss() })

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        ForEach(LegalDocumentContent.terms(language: languageManager.current)) { section in
                            sectionTitle(section.title)
                            sectionBody(section.body)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 48)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(.title3, design: .rounded, weight: .heavy))
            .foregroundStyle(ink)
    }

    private func sectionBody(_ text: String) -> some View {
        Text(text)
            .font(.system(.subheadline, design: .rounded, weight: .medium))
            .foregroundStyle(ink.opacity(0.75))
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
    }
}
