import SwiftUI
import UIKit
import WidgetKit

// Widget « Question du jour ». Il n'a ni le catalogue ni les traductions de l'app : il
// affiche ce que l'app lui a écrit dans l'App Group (`DailyQuestionWidgetStore`), une
// question par jour, et passe à la suivante à minuit sans que l'app soit ouverte.
//
// Pendant l'essai gratuit l'app n'écrit aucune question : le widget ne montre alors que
// Sophia, sans question ni lien vers un cours.

@main
struct SophiaWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyQuestionWidget()
    }
}

struct DailyQuestionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: DailyQuestionWidgetStore.widgetKind, provider: DailyQuestionProvider()) { entry in
            DailyQuestionWidgetView(entry: entry)
        }
        .configurationDisplayName(Self.galleryName)
        .description(Self.galleryDescription)
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }

    /// Dans la langue de l'app, écrite par l'app ; en anglais tant qu'elle n'a rien écrit.
    private static var galleryName: String {
        DailyQuestionWidgetStore.load()?.galleryName ?? "Question of the day"
    }

    private static var galleryDescription: String {
        DailyQuestionWidgetStore.load()?.galleryDescription ?? "One question a day, answered in five minutes."
    }
}

// MARK: - Timeline

struct DailyQuestionEntry: TimelineEntry {
    let date: Date
    let label: String
    /// Nil : pas de question ce jour-là (essai gratuit, ou l'app n'a pas encore écrit).
    let question: DailyQuestionWidgetDay?
}

struct DailyQuestionProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyQuestionEntry {
        DailyQuestionEntry(date: Date(), label: "Question of the day", question: Self.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyQuestionEntry) -> Void) {
        completion(entries(from: Date()).first ?? DailyQuestionEntry(date: Date(), label: "", question: nil))
    }

    /// Une entrée pour maintenant, puis une à chaque minuit. L'app recharge la timeline
    /// quand les questions changent.
    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyQuestionEntry>) -> Void) {
        completion(Timeline(entries: entries(from: Date()), policy: .never))
    }

    private func entries(from now: Date) -> [DailyQuestionEntry] {
        let payload = DailyQuestionWidgetStore.load()
        let label = payload?.label ?? ""
        var byDay: [String: DailyQuestionWidgetDay] = [:]
        for day in payload?.days ?? [] where byDay[day.day] == nil {
            byDay[day.day] = day
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let today = calendar.startOfDay(for: now)
        var entries = [DailyQuestionEntry(
            date: now,
            label: label,
            question: byDay[DailyQuestionWidgetStore.dayKey(for: today)]
        )]
        for offset in 1...31 {
            guard let start = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            entries.append(DailyQuestionEntry(
                date: start,
                label: label,
                question: byDay[DailyQuestionWidgetStore.dayKey(for: start)]
            ))
        }
        return entries
    }

    /// Pour l'emplacement réservé pendant le chargement ; jamais affiché comme vraie question.
    private static let sample = DailyQuestionWidgetDay(
        day: "",
        courseId: "",
        question: "Why does soap kill bacteria?",
        subject: "Sciences",
        imageFile: nil
    )
}

// MARK: - Vues

private enum WidgetPalette {
    static let canvas = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.071, green: 0.090, blue: 0.129, alpha: 1)
            : UIColor(red: 0.969, green: 0.973, blue: 0.980, alpha: 1)
    })
    static let ink = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.925, green: 0.937, blue: 0.957, alpha: 1)
            : UIColor(red: 0.086, green: 0.149, blue: 0.239, alpha: 1)
    })
    static let inkSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.655, green: 0.698, blue: 0.757, alpha: 1)
            : UIColor(red: 0.333, green: 0.388, blue: 0.478, alpha: 1)
    })
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.480, green: 0.655, blue: 0.960, alpha: 1)
            : UIColor(red: 0.180, green: 0.384, blue: 0.769, alpha: 1)
    })
}

struct DailyQuestionWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DailyQuestionEntry

    var body: some View {
        content
            .widgetURL(entry.question.flatMap { DailyQuestionWidgetStore.courseURL(courseId: $0.courseId) })
            .containerBackground(for: .widget) {
                if isAccessory {
                    Color.clear
                } else {
                    WidgetPalette.canvas
                }
            }
    }

    private var isAccessory: Bool {
        family == .accessoryRectangular || family == .accessoryInline || family == .accessoryCircular
    }

    @ViewBuilder
    private var content: some View {
        if let question = entry.question {
            switch family {
            case .accessoryInline:
                Text(question.question)
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.label.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .widgetAccentable()
                    Text(question.question)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .systemMedium:
                HStack(spacing: 12) {
                    cover(question)
                    textBlock(question, lines: 4)
                }
            default:
                textBlock(question, lines: 5)
            }
        } else {
            brandOnly
        }
    }

    private func textBlock(_ question: DailyQuestionWidgetDay, lines: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                Text(entry.label.uppercased())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(WidgetPalette.accent)

            Text(question.question)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(WidgetPalette.ink)
                .lineLimit(lines)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            Text(question.subject.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(WidgetPalette.inkSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func cover(_ question: DailyQuestionWidgetDay) -> some View {
        if let file = question.imageFile,
           let url = DailyQuestionWidgetStore.imageURL(file),
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 118)
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    /// Sans question : juste Sophia, qui ouvre l'app.
    @ViewBuilder
    private var brandOnly: some View {
        switch family {
        case .accessoryInline:
            Text("Sophia")
        case .accessoryRectangular:
            Label("Sophia", systemImage: "books.vertical.fill")
                .font(.system(size: 14, weight: .semibold))
        default:
            VStack(spacing: 8) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(WidgetPalette.accent)
                Text("Sophia")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(WidgetPalette.ink)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
