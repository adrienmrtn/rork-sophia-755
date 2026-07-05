import Foundation
import UIKit
import WidgetKit

extension Notification.Name {
    static let sophiaWidgetDataShouldSync = Notification.Name("sophiaWidgetDataShouldSync")
}

enum WidgetDataSync {
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static func sync(
        isPremium: Bool,
        completedCourseIds: Set<String>,
        language: AppLanguage = .french
    ) {
        Task { @MainActor in
            performSync(
                isPremium: isPremium,
                completedCourseIds: completedCourseIds,
                language: language
            )
        }
    }

    @MainActor
    private static func performSync(
        isPremium: Bool,
        completedCourseIds: Set<String>,
        language: AppLanguage
    ) async {
        let dayKey = dayFormatter.string(from: Date())
        let unlockedSubjects = FreemiumGate.unlockedSubjects(isPremium: isPremium)
        let unlockedKeys = Set(unlockedSubjects.map(\.storageKey))
        let courses = ContentCatalog.courses(for: language)

        let eligible = courses.filter { course in
            !completedCourseIds.contains(course.id) &&
            unlockedKeys.contains(course.subject.storageKey)
        }

        let pool = eligible.isEmpty
            ? courses.filter { !completedCourseIds.contains($0.id) && unlockedKeys.contains($0.subject.storageKey) }
            : eligible

        let pickPool = pool.isEmpty ? courses : pool

        if let existing = DailyCourseStore.load(),
           existing.dayKey == dayKey,
           pickPool.contains(where: { $0.id == existing.courseId }) {
            return
        }

        guard let course = pickCourse(from: pickPool, dayKey: dayKey) else { return }

        let imageFileName = copyCourseImage(courseId: course.id)
        let snapshot = DailyCourseSnapshot(
            courseId: course.id,
            title: course.title,
            subjectKey: course.subject.storageKey,
            subjectLabel: course.subject.localizedShortName(language: language),
            dayKey: dayKey,
            imageFileName: imageFileName,
            deepLinkURL: WidgetDeepLink.courseURL(for: course.id)?.absoluteString ?? "sophia://course/\(course.id)"
        )

        do {
            try DailyCourseStore.save(snapshot)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            #if DEBUG
            print("[WidgetDataSync] save failed: \(error)")
            #endif
        }
    }

    private static func pickCourse(from pool: [Course], dayKey: String) -> Course? {
        guard !pool.isEmpty else { return nil }
        var generator = SeededRandomNumberGenerator(seed: stableSeed(for: dayKey))
        return pool.shuffled(using: &generator).first
    }

    private static func stableSeed(for dayKey: String) -> UInt64 {
        var hasher = Hasher()
        hasher.combine(dayKey)
        hasher.combine("sophia-daily-course")
        return UInt64(bitPattern: Int64(hasher.finalize()))
    }

    @discardableResult
    private static func copyCourseImage(courseId: String) -> String? {
        guard let imagesDir = WidgetAppGroup.imagesDirectoryURL else { return nil }
        let fileManager = FileManager.default

        do {
            try fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        } catch {
            return nil
        }

        guard let image = CourseImageMap.loadImage(for: courseId),
              let jpeg = image.jpegData(compressionQuality: 0.82) else {
            return nil
        }

        let fileName = "\(courseId).jpg"
        let destination = imagesDir.appendingPathComponent(fileName)
        do {
            try jpeg.write(to: destination, options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }
}

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x4D59544E : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
