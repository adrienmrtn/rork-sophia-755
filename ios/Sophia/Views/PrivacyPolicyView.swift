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
                            VStack(alignment: .leading, spacing: 8) {
                                sectionTitle(section.title)
                                sectionBody(section.body)
                            }
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
            .lineSpacing(5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
    }
}

/// Shared calm header for legal / support sheets (Terms, Privacy, Feedback, Ambassador):
/// the title in a medium weight, and the round close button of the design.
struct LegalHeader: View {
    let title: String
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(DS.title(.title, .semibold))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 8)

            ProfileRoundButton(
                systemImage: "xmark",
                accessibilityLabel: AppLocalizable.string("common.close", language: AppLanguage.currentPersisted()),
                action: onClose
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 14)
    }
}
