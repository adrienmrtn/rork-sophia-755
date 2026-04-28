import CoreXLSX
import Foundation

enum ExcelCourseContentLoader {
    static func loadCourses(baseCourses: [Course]) -> [Course] {
        do {
            return try loadCoursesThrowing(baseCourses: baseCourses)
        } catch {
            return baseCourses
        }
    }

    private static func loadCoursesThrowing(baseCourses: [Course]) throws -> [Course] {
        let baseByNumber = Dictionary(uniqueKeysWithValues: baseCourses.compactMap { (course) -> (Int, Course)? in
            guard let n = courseNumber(from: course.id) else { return nil }
            return (n, course)
        })
        let baseByTitleKey: [String: Course] = {
            var out: [String: Course] = [:]
            var dupes = Set<String>()
            for course in baseCourses {
                let key = titleKey(course.title)
                if key.isEmpty { continue }
                if out[key] != nil {
                    dupes.insert(key)
                } else {
                    out[key] = course
                }
            }
            for key in dupes {
                out[key] = nil
            }
            return out
        }()

        let contentRows = try readRowsAllSheets(
            xlsxResource: "Excel_cours",
            preferredSheetNames: ["Sheet1", "Feuil1", "Cours", "Tous les cours"],
            subdirectory: "data"
        )

        let quizRows = try readRowsAllSheets(
            xlsxResource: "Excel_QCM",
            preferredSheetNames: ["Tous les cours", "Sheet1", "Feuil1", "QCM", "Quiz"],
            subdirectory: "data"
        )

        var updatedById = Dictionary(uniqueKeysWithValues: baseCourses.map { ($0.id, $0) })
        var excelNumberToCourseId: [Int: String] = [:]

        for row in contentRows {
            guard let idValue = firstValue(in: row, keys: ["id"]) ?? firstValueContaining(in: row, substrings: ["id"]) else { continue }
            guard let number = parseCourseNumber(idValue) else { continue }

            let subjectValue = firstValue(in: row, keys: ["matiere"]) ?? firstValueContaining(in: row, substrings: ["matiere"]) ?? ""
            let title = normalized(row["titre"]) ?? "Cours \(number)"
            let titleKeyValue = titleKey(title)
            let base = baseByNumber[number] ?? (titleKeyValue.isEmpty ? nil : baseByTitleKey[titleKeyValue])
            let courseId = base?.id ?? "course_\(number)"
            excelNumberToCourseId[number] = courseId

            let subject = parseSubject(subjectValue) ?? base?.subject ?? .histoire
            let subcategory = normalized(firstValue(in: row, keys: ["sous categorie"]) ?? firstValueContaining(in: row, substrings: ["sous", "categorie"])) ?? base?.subcategory ?? ""

            let intro = normalized(row["intro"]) ?? ""
            var lessonPages: [LessonPage] = []

            if !intro.isEmpty {
                lessonPages.append(
                    LessonPage(
                        id: "\(courseId)_intro",
                        title: "Introduction",
                        content: intro,
                        emoji: base?.lessons.first?.emoji ?? defaultEmoji(for: subject)
                    )
                )
            }

            for index in 1...10 {
                let titleKey = "partie\(index) titre"
                let contentKey = "partie\(index) contenu"
                guard let pageTitle = normalized(row[titleKey]), !pageTitle.isEmpty else { continue }
                guard let pageContent = normalized(row[contentKey]), !pageContent.isEmpty else { continue }

                let emoji = base?.lessons[safe: lessonPages.count]?.emoji ?? base?.lessons[safe: index]?.emoji ?? defaultEmoji(for: subject)
                lessonPages.append(
                    LessonPage(
                        id: "\(courseId)_p\(index)",
                        title: pageTitle,
                        content: pageContent,
                        emoji: emoji
                    )
                )
            }

            let description = makeDescription(from: intro.isEmpty ? (lessonPages.first?.content ?? "") : intro)

            let merged = Course(
                id: courseId,
                title: title,
                description: description.isEmpty ? (base?.description ?? "") : description,
                subject: subject,
                subcategory: subcategory,
                lessons: lessonPages.isEmpty ? (base?.lessons ?? []) : lessonPages,
                quiz: updatedById[courseId]?.quiz ?? base?.quiz ?? []
            )

            updatedById[courseId] = merged
        }

        var quizByCourseId: [String: [QuizQuestion]] = [:]

        for row in quizRows {
            guard
                let idValue =
                    firstValue(in: row, keys: ["id", "cours", "course", "numero"]) ??
                    firstValueContaining(in: row, substrings: ["id", "cours", "numero"])
            else { continue }
            guard let number = parseCourseNumber(idValue) else { continue }
            let courseId = excelNumberToCourseId[number] ?? baseByNumber[number]?.id ?? "course_\(number)"

            var questions: [QuizQuestion] = []
            for qIndex in 1...20 {
                let qKey = "qcm\(qIndex) question"
                let goodKey = "qcm\(qIndex) bonne reponse"
                let w1Key = "qcm\(qIndex) mauvaise 1"
                let w2Key = "qcm\(qIndex) mauvaise 2"
                let w3Key = "qcm\(qIndex) mauvaise 3"

                guard let qText = normalized(row[qKey]), !qText.isEmpty else { continue }
                guard let good = normalized(row[goodKey]), !good.isEmpty else { continue }

                let wrong1 = normalized(row[w1Key]) ?? ""
                let wrong2 = normalized(row[w2Key]) ?? ""
                let wrong3 = normalized(row[w3Key]) ?? ""
                let options = [good, wrong1, wrong2, wrong3].filter { !$0.isEmpty }

                guard options.count >= 2 else { continue }

                questions.append(
                    QuizQuestion(
                        id: "\(courseId)_q\(qIndex)",
                        question: qText,
                        options: options,
                        correctIndex: 0
                    )
                )
            }

            guard !questions.isEmpty else { continue }

            if let existing = quizByCourseId[courseId] {
                if questions.count > existing.count {
                    quizByCourseId[courseId] = questions
                }
            } else {
                quizByCourseId[courseId] = questions
            }
        }

        for (courseId, questions) in quizByCourseId {
            if let existing = updatedById[courseId] {
                updatedById[courseId] = Course(
                    id: existing.id,
                    title: existing.title,
                    description: existing.description,
                    subject: existing.subject,
                    subcategory: existing.subcategory,
                    lessons: existing.lessons,
                    quiz: questions
                )
            } else if let base = baseCourses.first(where: { $0.id == courseId }) {
                updatedById[courseId] = Course(
                    id: base.id,
                    title: base.title,
                    description: base.description,
                    subject: base.subject,
                    subcategory: base.subcategory,
                    lessons: base.lessons,
                    quiz: questions
                )
            }
        }

        var result: [Course] = []
        var seen = Set<String>()
        for base in baseCourses {
            if let updated = updatedById[base.id] {
                result.append(updated)
                seen.insert(updated.id)
            } else {
                result.append(base)
                seen.insert(base.id)
            }
        }

        let extras = updatedById.values.filter { !seen.contains($0.id) }.sorted { $0.id < $1.id }
        result.append(contentsOf: extras)

        return result
    }

    private static func readRows(xlsxResource: String, sheetName: String, subdirectory: String) throws -> [[String: String]] {
        guard let url = Bundle.main.url(forResource: xlsxResource, withExtension: "xlsx", subdirectory: subdirectory) else {
            throw NSError(domain: "ExcelCourseContentLoader", code: 1)
        }
        guard let file = XLSXFile(filepath: url.path) else {
            throw NSError(domain: "ExcelCourseContentLoader", code: 2)
        }

        let sharedStrings = try? file.parseSharedStrings()
        guard let workbook = try file.parseWorkbooks().first else {
            throw NSError(domain: "ExcelCourseContentLoader", code: 3)
        }

        let pathsAndNames = try file.parseWorksheetPathsAndNames(workbook: workbook)
        let worksheetPath = pathsAndNames.first(where: { $0.name == sheetName })?.path ?? pathsAndNames.first?.path
        guard let worksheetPath else { return [] }

        let worksheet = try file.parseWorksheet(at: worksheetPath)
        let rows = worksheet.data?.rows ?? []

        guard let headerRow = rows.first else { return [] }
        let headerByColumn = Dictionary(uniqueKeysWithValues: headerRow.cells.compactMap { cell -> (String, String)? in
            let column = cell.reference.column.description
            guard let header = stringValue(cell: cell, sharedStrings: sharedStrings) else { return nil }
            let normalizedHeader = headerKey(header)
            guard !normalizedHeader.isEmpty else { return nil }
            return (column, normalizedHeader)
        })

        guard !headerByColumn.isEmpty else { return [] }

        return rows.dropFirst().map { row in
            var dict: [String: String] = [:]
            for cell in row.cells {
                let column = cell.reference.column.description
                guard let key = headerByColumn[column] else { continue }
                guard let value = stringValue(cell: cell, sharedStrings: sharedStrings) else { continue }
                dict[key] = value
            }
            return dict
        }
        .filter { !$0.isEmpty }
    }

    private static func readRowsAllSheets(xlsxResource: String, preferredSheetNames: [String], subdirectory: String) throws -> [[String: String]] {
        guard let url = Bundle.main.url(forResource: xlsxResource, withExtension: "xlsx", subdirectory: subdirectory) else {
            throw NSError(domain: "ExcelCourseContentLoader", code: 1)
        }
        guard let file = XLSXFile(filepath: url.path) else {
            throw NSError(domain: "ExcelCourseContentLoader", code: 2)
        }

        let sharedStrings = try? file.parseSharedStrings()
        guard let workbook = try file.parseWorkbooks().first else {
            throw NSError(domain: "ExcelCourseContentLoader", code: 3)
        }

        let pathsAndNames = try file.parseWorksheetPathsAndNames(workbook: workbook)
        if pathsAndNames.isEmpty { return [] }

        var ordered: [(path: String, name: String?)] = []
        for preferred in preferredSheetNames {
            if let match = pathsAndNames.first(where: { $0.name == preferred }) {
                if !ordered.contains(where: { $0.path == match.path }) {
                    ordered.append((path: match.path, name: match.name))
                }
            }
        }
        for sheet in pathsAndNames where !ordered.contains(where: { $0.path == sheet.path }) {
            ordered.append((path: sheet.path, name: sheet.name))
        }

        var allRows: [[String: String]] = []
        allRows.reserveCapacity(ordered.count * 50)

        for sheet in ordered {
            let worksheet = try file.parseWorksheet(at: sheet.path)
            let rows = worksheet.data?.rows ?? []
            guard let headerRow = rows.first else { continue }

            let headerByColumn: [String: String] = Dictionary(uniqueKeysWithValues: headerRow.cells.compactMap { cell -> (String, String)? in
                let column = cell.reference.column.description
                guard let header = stringValue(cell: cell, sharedStrings: sharedStrings) else { return nil }
                let normalizedHeader = headerKey(header)
                guard !normalizedHeader.isEmpty else { return nil }
                return (column, normalizedHeader)
            })

            if headerByColumn.isEmpty { continue }

            let parsed = rows.dropFirst().map { row in
                var dict: [String: String] = [:]
                for cell in row.cells {
                    let column = cell.reference.column.description
                    guard let key = headerByColumn[column] else { continue }
                    guard let value = stringValue(cell: cell, sharedStrings: sharedStrings) else { continue }
                    dict[key] = value
                }
                return dict
            }
            .filter { !$0.isEmpty }

            allRows.append(contentsOf: parsed)
        }

        return allRows
    }

    private static func stringValue(cell: Cell, sharedStrings: SharedStrings?) -> String? {
        if let sharedStrings, let value = cell.stringValue(sharedStrings) {
            return value
        }
        if let inline = cell.inlineString?.text {
            return inline
        }
        if let value = cell.value {
            return value
        }
        return nil
    }

    private static func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let replaced = value
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\\n", with: "\n")
        let trimmed = replaced.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func headerKey(_ raw: String) -> String {
        let folded = raw
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\\n", with: " ")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

        let sanitized = folded.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) { return Character(scalar) }
            return " "
        }

        let parts = String(sanitized)
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)

        if parts.isEmpty { return "" }

        var out: [String] = []
        var i = 0
        while i < parts.count {
            let p = parts[i]
            if (p == "qcm" || p == "partie"), i + 1 < parts.count, let _ = Int(parts[i + 1]) {
                out.append(p + parts[i + 1])
                i += 2
                continue
            }
            out.append(p)
            i += 1
        }

        return out.joined(separator: " ")
    }

    private static func titleKey(_ raw: String) -> String {
        let folded = raw
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\\n", with: " ")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

        let sanitized = folded.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) { return Character(scalar) }
            return " "
        }

        return String(sanitized)
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }

    private static func firstValue(in row: [String: String], keys: [String]) -> String? {
        for key in keys {
            if let value = row[key] { return value }
        }
        return nil
    }

    private static func firstValueContaining(in row: [String: String], substrings: [String]) -> String? {
        for (key, value) in row {
            for s in substrings where key.contains(s) {
                return value
            }
        }
        return nil
    }

    private static func makeDescription(from text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count <= 140 { return cleaned }
        let idx = cleaned.index(cleaned.startIndex, offsetBy: 140)
        return String(cleaned[..<idx]) + "..."
    }

    private static func parseCourseNumber(_ raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let i = Int(trimmed) { return i }
        if let d = Double(trimmed) { return Int(d) }

        let digits = trimmed.filter { $0.isNumber }
        if let i = Int(digits), !digits.isEmpty { return i }

        return nil
    }

    private static func courseNumber(from courseId: String) -> Int? {
        guard courseId.hasPrefix("course_") else { return nil }
        let rest = courseId.dropFirst("course_".count)
        let digits = rest.prefix { $0.isNumber }
        return Int(digits)
    }

    private static func parseSubject(_ raw: String) -> Subject? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let s = Subject(rawValue: trimmed) { return s }

        let folded = trimmed.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        if folded == "science" || folded == "sciences" { return .sciences }
        if folded == "histoire" { return .histoire }
        if folded == "litterature" { return .litterature }
        if folded == "art" { return .art }
        if folded == "mythologie" { return .mythologie }
        if folded == "monde actuel" || folded == "comprendre le monde actuel" { return .comprendreLeMonde }
        return nil
    }

    private static func defaultEmoji(for subject: Subject) -> String {
        switch subject {
        case .histoire: "🏛️"
        case .sciences: "🔬"
        case .litterature: "📚"
        case .art: "🎨"
        case .mythologie: "⚡️"
        case .comprendreLeMonde: "🌍"
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        if index < 0 { return nil }
        if index >= count { return nil }
        return self[index]
    }
}
