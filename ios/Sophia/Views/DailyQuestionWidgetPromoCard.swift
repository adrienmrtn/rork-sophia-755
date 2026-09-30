import SwiftUI
import WidgetKit

/// Quand proposer d'ajouter le widget « Question du jour ».
///
/// iOS ne permet pas à une app d'ajouter un widget elle-même : on explique le geste, une
/// fois qu'une question du jour a été lue (la personne sait ce qu'elle mettrait sur son
/// écran). Jamais pendant l'essai gratuit, jamais quand le widget est déjà posé, et plus
/// du tout une fois la carte fermée.
enum DailyQuestionWidgetPromo {
    private static let dismissedKey = "sophia_daily_question_widget_promo_dismissed"

    static func shouldShow(isInFreeTrial: Bool, isCompleted: (String) -> Bool) async -> Bool {
        guard !isInFreeTrial,
              !UserDefaults.standard.bool(forKey: dismissedKey),
              DailyQuestion.hasReadAQuestionOfTheDay(isCompleted: isCompleted) else { return false }
        return await !isWidgetInstalled()
    }

    static func dismiss() {
        UserDefaults.standard.set(true, forKey: dismissedKey)
    }

    private static func isWidgetInstalled() async -> Bool {
        await withCheckedContinuation { continuation in
            // `@Sendable` : WidgetKit rappelle hors du fil principal.
            WidgetCenter.shared.getCurrentConfigurations { @Sendable result in
                let installed = (try? result.get())?.contains {
                    $0.kind == DailyQuestionWidgetStore.widgetKind
                } ?? false
                continuation.resume(returning: installed)
            }
        }
    }
}

/// Carte de la Biblio, sous « À la une » : comment poser le widget.
struct DailyQuestionWidgetPromoCard: View {
    @Environment(LanguageManager.self) private var languageManager
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "square.text.square")
                .font(.jakarta(size: 18, weight: .medium))
                .foregroundStyle(DS.accentSoft)
                .frame(width: 44, height: 44)
                .background(DS.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(DS.hairline, lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(languageManager.text("dailyQuestion.widgetPromo.title"))
                    .font(DS.title(.headline, .semibold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(languageManager.text("dailyQuestion.widgetPromo.body"))
                    .font(DS.sans(.caption, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.jakarta(size: 12, weight: .semibold))
                    .foregroundStyle(DS.inkTertiary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(languageManager.text("dailyQuestion.widgetPromo.close"))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.accentTint, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
    }
}
