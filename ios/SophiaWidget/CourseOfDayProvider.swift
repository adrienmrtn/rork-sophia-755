import WidgetKit
import SwiftUI

struct CourseOfDayEntry: TimelineEntry {
    let date: Date
    let snapshot: DailyCourseSnapshot
}

struct CourseOfDayProvider: TimelineProvider {
    func placeholder(in context: Context) -> CourseOfDayEntry {
        CourseOfDayEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CourseOfDayEntry) -> Void) {
        let snapshot = DailyCourseStore.load() ?? .placeholder
        completion(CourseOfDayEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CourseOfDayEntry>) -> Void) {
        let snapshot = DailyCourseStore.load() ?? .placeholder
        let entry = CourseOfDayEntry(date: .now, snapshot: snapshot)
        let nextRefresh = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}
