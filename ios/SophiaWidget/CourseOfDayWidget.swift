import WidgetKit
import SwiftUI

struct CourseOfDayWidget: Widget {
    let kind = "CourseOfDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CourseOfDayProvider()) { entry in
            CourseOfDayWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetSubjectStyle.cream
                }
        }
        .configurationDisplayName("Cours du jour")
        .description("Un cours aléatoire chaque jour, parmi tes matières accessibles.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
