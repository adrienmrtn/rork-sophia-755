import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageManager.self) private var languageManager

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                LegalHeader(title: languageManager.text("legal.privacy.title"), onClose: { dismiss() })

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        ForEach(LegalDocumentContent.privacy(language: languageManager.current)) { section in
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

/// Shared calm header for legal / support sheets (Terms, Privacy, Feedback, Ambassador).
struct LegalHeader: View {
    let title: String
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(DS.title(.largeTitle, .semibold))
                .foregroundStyle(DS.ink)

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.jakarta(size: 14, weight: .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(width: 38, height: 38)
                    .background(DS.surface, in: Circle())
                    .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
            }
            .buttonStyle(SoftPressButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DS.hairline)
                .frame(height: 1)
        }
    }
}
