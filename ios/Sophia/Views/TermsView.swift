import SwiftUI

struct TermsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageManager.self) private var languageManager

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

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
                .scrollIndicators(.hidden)
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(DS.title(.title3, .semibold))
            .foregroundStyle(DS.ink)
    }

    private func sectionBody(_ text: String) -> some View {
        Text(text)
            .font(DS.sans(.subheadline))
            .foregroundStyle(DS.inkSecondary)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
    }
}
