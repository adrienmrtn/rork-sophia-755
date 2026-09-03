import SwiftUI

/// Feuille de résolution de conflit de progression, affichée quand une progression locale et
/// une progression cloud non vides divergent au moment de lier un compte. L'utilisateur choisit.
struct ProgressConflictView: View {
    @Environment(LanguageManager.self) private var languageManager
    let conflict: ProgressConflict
    var onResolve: (_ keepLocal: Bool) -> Void

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(DS.accent)
                    Text(languageManager.text("sync.conflict.title"))
                        .font(DS.title(.title2, .semibold))
                        .foregroundStyle(DS.ink)
                        .multilineTextAlignment(.center)
                    Text(languageManager.text("sync.conflict.body"))
                        .font(DS.sans(.subheadline, .medium))
                        .foregroundStyle(DS.inkSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                .padding(.horizontal, 24)

                optionCard(
                    title: languageManager.text("sync.conflict.local"),
                    progress: conflict.local,
                    keepLocal: true
                )
                optionCard(
                    title: languageManager.text("sync.conflict.remote"),
                    progress: conflict.remote,
                    keepLocal: false
                )

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .interactiveDismissDisabled(true)
    }

    private func optionCard(title: String, progress: UserProgress, keepLocal: Bool) -> some View {
        Button {
            onResolve(keepLocal)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(DS.title(.headline, .semibold))
                    .foregroundStyle(DS.ink)
                Text(summary(for: progress))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsCard()
        }
        .buttonStyle(SoftPressButtonStyle())
    }

    private func summary(for progress: UserProgress) -> String {
        let completed = progress.courseProgress.values.filter(\.isCompleted).count
        let level = ProgressManager.globalLevelProgress(for: progress.globalXP).level
        return String(
            format: languageManager.text("sync.conflict.summary"),
            completed, level, progress.streak
        )
    }
}
