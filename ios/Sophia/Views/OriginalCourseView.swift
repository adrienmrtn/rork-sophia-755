import SwiftUI

/// « Voir l'original » : le cours dans la langue où il a été écrit, en lecture seule, ouvert
/// depuis le bas du cours. Le texte est téléchargé à la demande (`CatalogStore`), comme
/// n'importe quel cours dans une autre langue ; il se lit d'une traite, sans pages ni quiz.
struct OriginalCourseView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    let courseId: String
    let language: AppLanguage

    @State private var content: CourseContentV2?
    @State private var isLoading = true
    @State private var attempt = 0

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                if let content {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 40) {
                            ForEach(Array(content.sections.enumerated()), id: \.offset) { index, section in
                                BlockContentView(
                                    content: content,
                                    section: section,
                                    isFirst: index == 0,
                                    accent: DS.accentSoft,
                                    courseId: courseId,
                                    courseTitle: content.title,
                                    onGlossaryTap: { _ in },
                                    isLast: index == content.sections.count - 1
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .scrollIndicators(.hidden)
                    // Le texte suit le sens d'écriture de sa langue, pas celui de l'app.
                    .environment(\.layoutDirection, language.layoutDirection)
                } else if isLoading {
                    ProgressView()
                        .tint(DS.accent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    unavailable
                }
            }
        }
        .presentationDragIndicator(.visible)
        .task(id: attempt) {
            isLoading = true
            content = await CatalogStore.shared.ensureContent(courseId: courseId, language: language)
            isLoading = false
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "globe")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.accent)
            Text(language.displayName)
                .font(DS.sans(.callout, .heavy))
                .foregroundStyle(DS.ink)
            Spacer()
            RoundIconButton(systemImage: "xmark", size: 38, accessibilityLabel: languageManager.text("common.close")) { dismiss() }
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    /// Hors ligne, et l'original n'a jamais été téléchargé.
    private var unavailable: some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(DS.inkTertiary)
            Text(languageManager.text("course.offline.body"))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
            Button(languageManager.text("course.offline.retry")) {
                attempt += 1
            }
            .buttonStyle(DSSecondaryButtonStyle())
            .frame(maxWidth: 220)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
