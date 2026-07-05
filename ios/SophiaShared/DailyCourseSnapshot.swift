import Foundation

struct DailyCourseSnapshot: Codable, Equatable {
    let courseId: String
    let title: String
    let subjectKey: String
    let subjectLabel: String
    let dayKey: String
    let imageFileName: String?
    let deepLinkURL: String

    static let placeholder = DailyCourseSnapshot(
        courseId: "placeholder",
        title: "Cours du jour",
        subjectKey: "histoire",
        subjectLabel: "Histoire",
        dayKey: "",
        imageFileName: nil,
        deepLinkURL: "sophia://course/placeholder"
    )
}

enum DailyCourseStore {
    static func load() -> DailyCourseSnapshot? {
        guard let url = WidgetAppGroup.snapshotURL,
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(DailyCourseSnapshot.self, from: data)
    }

    static func save(_ snapshot: DailyCourseSnapshot) throws {
        guard let url = WidgetAppGroup.snapshotURL else {
            throw StoreError.missingContainer
        }
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: url, options: .atomic)
    }

    static func imageURL(for snapshot: DailyCourseSnapshot) -> URL? {
        guard let fileName = snapshot.imageFileName else { return nil }
        return WidgetAppGroup.imagesDirectoryURL?.appendingPathComponent(fileName)
    }

    enum StoreError: Error {
        case missingContainer
    }
}
