import Foundation
import ImageIO
import UniformTypeIdentifiers
import WidgetKit

/// Prépare le widget « Question du jour » : les questions des jours à venir, traduites, et
/// une vignette de chaque couverture, dans l'App Group. Le widget n'a pas le catalogue :
/// il affiche ce qu'on lui écrit ici et passe au jour suivant tout seul à minuit.
///
/// Appelé par `DailyCourseReminder.refresh()`, avec les mêmes jours que les notifications :
/// rien pendant l'essai gratuit, le widget n'y montre alors que Sophia.
enum DailyQuestionWidgetWriter {
    /// Côté le plus long d'une vignette, en pixels. Un widget refuse les images trop grandes.
    private nonisolated static let thumbnailMaxPixels = 360

    static func update(days: [(day: DailyQuestion.Day, courseId: String)], language: AppLanguage) {
        var entries: [DailyQuestionWidgetDay] = []
        var covers: [(source: URL, fileName: String)] = []
        for (day, courseId) in days {
            guard let course = ContentCatalog.course(withId: courseId, language: language) else { continue }
            var fileName: String?
            if let name = CourseImageMap.imageName(for: courseId), let source = coverURL(named: name) {
                fileName = "\(name).jpg"
                covers.append((source, "\(name).jpg"))
            }
            entries.append(DailyQuestionWidgetDay(
                day: day.key,
                courseId: courseId,
                question: course.title.withoutInlineMarkup,
                subject: course.subject.localizedShortName(language: language),
                imageFile: fileName
            ))
        }

        let payload = DailyQuestionWidgetPayload(
            label: AppLocalizable.string("dailyQuestion.badge", language: language),
            galleryName: AppLocalizable.string("dailyQuestion.badge", language: language),
            galleryDescription: AppLocalizable.string("dailyQuestion.widget.description", language: language),
            days: entries
        )
        let changed = DailyQuestionWidgetStore.load() != payload
        if changed {
            DailyQuestionWidgetStore.save(payload)
        }

        let wanted = covers
        Task.detached(priority: .utility) {
            let wroteImages = writeThumbnails(wanted)
            if changed || wroteImages {
                WidgetCenter.shared.reloadTimelines(ofKind: DailyQuestionWidgetStore.widgetKind)
            }
        }
    }

    private static func coverURL(named name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: "CourseImages")
            ?? Bundle.main.url(forResource: name, withExtension: "jpg")
    }

    /// Écrit les vignettes manquantes et supprime celles qui ne servent plus. Vrai si une
    /// vignette a été ajoutée.
    private nonisolated static func writeThumbnails(_ covers: [(source: URL, fileName: String)]) -> Bool {
        guard let directory = DailyQuestionWidgetStore.imageDirectory else { return false }
        let fileManager = FileManager.default
        let keep = Set(covers.map(\.fileName))
        if let existing = try? fileManager.contentsOfDirectory(atPath: directory.path) {
            for file in existing where !keep.contains(file) {
                try? fileManager.removeItem(at: directory.appendingPathComponent(file))
            }
        }

        var wrote = false
        for cover in covers {
            let destination = directory.appendingPathComponent(cover.fileName)
            guard !fileManager.fileExists(atPath: destination.path) else { continue }
            if writeThumbnail(from: cover.source, to: destination) { wrote = true }
        }
        return wrote
    }

    private nonisolated static func writeThumbnail(from source: URL, to destination: URL) -> Bool {
        guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil) else { return false }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: thumbnailMaxPixels,
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary),
              let output = CGImageDestinationCreateWithURL(
                destination as CFURL,
                UTType.jpeg.identifier as CFString,
                1,
                nil
              ) else { return false }
        CGImageDestinationAddImage(output, thumbnail, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        return CGImageDestinationFinalize(output)
    }
}
