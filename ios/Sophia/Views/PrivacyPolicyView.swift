import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageManager.self) private var languageManager

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

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

/// Shared neo-brutalist header for legal sheets.
struct LegalHeader: View {
    let title: String
    let onClose: () -> Void
    private let ink = BrutalPalette.ink

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(ink)
                    .frame(width: 38, height: 38)
                    .background(Color.white, in: Circle())
                    .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ink)
                .frame(height: 2.5)
        }
    }
}
