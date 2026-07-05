import Foundation

enum WidgetAppGroup {
    static let identifier = "group.app.rork.sophia"
    static let snapshotFileName = "daily_course_snapshot.json"
    static let imagesDirectoryName = "widget_images"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static var snapshotURL: URL? {
        containerURL?.appendingPathComponent(snapshotFileName)
    }

    static var imagesDirectoryURL: URL? {
        containerURL?.appendingPathComponent(imagesDirectoryName, isDirectory: true)
    }
}
