import Combine
import CoreXLSX
import SwiftUI

struct LessonContentBlock: Identifiable, Equatable {
    enum Kind: Equatable {
        case text(String)
        case image(String)
        case funFact(String)
        case highlight(String)
    }

    let id: UUID
    let kind: Kind
}

enum LessonContentParser {
    static func parse(_ raw: String) -> [LessonContentBlock] {
        let input = raw.replacingOccurrences(of: "\\n", with: "\n")
        var blocks: [LessonContentBlock] = []
        var paragraphLines: [String] = []
        var pendingBlocks: [LessonContentBlock.Kind] = []

        func flushParagraph() {
            let text = paragraphLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                blocks.append(LessonContentBlock(id: UUID(), kind: .text(text)))
            }
            for kind in pendingBlocks {
                blocks.append(LessonContentBlock(id: UUID(), kind: kind))
            }
            paragraphLines.removeAll(keepingCapacity: true)
            pendingBlocks.removeAll(keepingCapacity: true)
        }

        func parseStandaloneMarker(from trimmedLine: String) -> LessonContentBlock.Kind? {
            if trimmedLine.hasPrefix("["), trimmedLine.hasSuffix("]"), trimmedLine.count >= 2 {
                let inside = trimmedLine.dropFirst().dropLast().trimmingCharacters(in: .whitespacesAndNewlines)
                if !inside.isEmpty { return .image(String(inside)) }
            }

            if trimmedLine.hasPrefix("{"), trimmedLine.hasSuffix("}"), trimmedLine.count >= 2 {
                let inside = trimmedLine.dropFirst().dropLast().trimmingCharacters(in: .whitespacesAndNewlines)
                if !inside.isEmpty { return .funFact(String(inside)) }
            }

            if trimmedLine.hasPrefix("||"), trimmedLine.hasSuffix("||"), trimmedLine.count >= 4 {
                let inside = trimmedLine.dropFirst(2).dropLast(2).trimmingCharacters(in: .whitespacesAndNewlines)
                if !inside.isEmpty { return .highlight(String(inside)) }
            }

            return nil
        }

        func looksLikeStandaloneMarkerLine(_ line: String) -> Bool {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return parseStandaloneMarker(from: trimmed) != nil
        }

        let lines = input.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        for index in lines.indices {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.isEmpty {
                flushParagraph()
                continue
            }

            if let kind = parseStandaloneMarker(from: trimmed) {
                let hasPrevText = !paragraphLines.isEmpty
                let nextLine = (index + 1 < lines.count) ? lines[index + 1] : nil
                let nextTrimmed = nextLine?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let hasNextText = !nextTrimmed.isEmpty && !looksLikeStandaloneMarkerLine(nextLine ?? "")

                if hasPrevText && hasNextText {
                    pendingBlocks.append(kind)
                } else {
                    flushParagraph()
                    blocks.append(LessonContentBlock(id: UUID(), kind: kind))
                }
                continue
            }

            paragraphLines.append(line)
        }

        flushParagraph()
        return blocks
    }
}

struct ImageCredit: Equatable, Sendable {
    let originalName: String
    let author: String
    let license: String?
    let source: String?
}

final class ImageCreditsStore: ObservableObject {
    static let shared = ImageCreditsStore()

    @Published private(set) var creditsByKey: [String: ImageCredit] = [:]

    private init() {
        Task { @MainActor in
            creditsByKey = (try? Self.loadAllCredits()) ?? [:]
        }
    }

    func credit(for imageToken: String) -> ImageCredit? {
        for key in Self.fileKeyVariants(imageToken) {
            if let direct = creditsByKey[key] { return direct }
        }
        let normalizedToken = Self.fileKey(Self.cleanToken(imageToken))
        if normalizedToken.count >= 6 {
            var best: (key: String, credit: ImageCredit)? = nil
            for (key, credit) in creditsByKey {
                let nk = Self.fileKey(Self.cleanToken(key))
                if nk.contains(normalizedToken) || normalizedToken.contains(nk) {
                    if best == nil || nk.count < best!.key.count {
                        best = (nk, credit)
                    }
                }
            }
            if let best { return best.credit }
        }
        return nil
    }

    private static func loadAllCredits() throws -> [String: ImageCredit] {
        guard let illustrationsURL = Bundle.main.url(forResource: "Illustrations", withExtension: nil, subdirectory: "data") else {
            return [:]
        }

        var files: [URL] = []
        if let e = FileManager.default.enumerator(at: illustrationsURL, includingPropertiesForKeys: nil) {
            for case let url as URL in e {
                if url.pathExtension.lowercased() == "xlsx" && url.lastPathComponent.lowercased().contains("credits") {
                    files.append(url)
                }
            }
        }

        var merged: [String: ImageCredit] = [:]
        for url in files {
            let rows =
                (try? readRows(fileURL: url, preferredSheetNames: ["Crédits", "Credits", "Crédit", "Credit", "Sheet1"])) ??
                []
            for row in rows {
                let token =
                    normalized(row["image"]) ??
                    normalized(row["nom du fichier"]) ??
                    normalized(row["nom de l image"]) ??
                    normalized(row["nom dans le cours"]) ??
                    normalized(row["cours"]) ??
                    normalized(row["nom original"]) ??
                    normalized(row["nom"])

                guard let token, !token.isEmpty else { continue }

                let originalName =
                    normalized(row["nom original"]) ??
                    normalized(row["nom du fichier"]) ??
                    normalized(row["nom de l image"]) ??
                    token

                let author =
                    normalized(row["auteur"]) ??
                    normalized(row["credit"]) ??
                    normalized(row["credit copyright"]) ??
                    normalized(row["copyright"])

                guard !originalName.isEmpty else { continue }

                let license =
                    normalized(row["licence"]) ??
                    normalized(row["license"])

                let source =
                    normalized(row["source"]) ??
                    normalized(row["lien"]) ??
                    normalized(row["url"])

                let authorValue = author ?? ""
                if authorValue.isEmpty, (license ?? "").isEmpty, (source ?? "").isEmpty { continue }

                let credit = ImageCredit(
                    originalName: htmlUnescape(originalName),
                    author: htmlUnescape(authorValue),
                    license: license.map(htmlUnescape),
                    source: source.map(htmlUnescape)
                )

                for key in fileKeyVariants(token) + fileKeyVariants(originalName) {
                    merged[key] = credit
                }
            }
        }

        return merged
    }

    private static func readRows(fileURL: URL, preferredSheetNames: [String]) throws -> [[String: String]] {
        guard let file = XLSXFile(filepath: fileURL.path) else { return [] }
        let sharedStrings = try file.parseSharedStrings()
        guard let workbook = try file.parseWorkbooks().first else { return [] }
        let pathsAndNames = try file.parseWorksheetPathsAndNames(workbook: workbook)

        let normalizedPreferred = preferredSheetNames.map { headerKey($0) }
        let pathFromPreferred = pathsAndNames.first(where: { item in
            let nameKey = headerKey(item.name ?? "")
            return normalizedPreferred.contains(nameKey)
        })?.path

        let worksheetPath = pathFromPreferred ?? pathsAndNames.first?.path
        guard let worksheetPath else { return [] }

        return try readRows(file: file, sharedStrings: sharedStrings, worksheetPath: worksheetPath)
    }

    private static func readRows(fileURL: URL, sheetName: String) throws -> [[String: String]] {
        guard let file = XLSXFile(filepath: fileURL.path) else { return [] }
        let sharedStrings = try file.parseSharedStrings()
        guard let workbook = try file.parseWorkbooks().first else { return [] }
        let pathsAndNames = try file.parseWorksheetPathsAndNames(workbook: workbook)
        let worksheetPath = pathsAndNames.first(where: { ($0.name ?? "") == sheetName })?.path ?? pathsAndNames.first?.path
        guard let worksheetPath else { return [] }
        return try readRows(file: file, sharedStrings: sharedStrings, worksheetPath: worksheetPath)
    }

    private static func readRows(file: XLSXFile, sharedStrings: SharedStrings?, worksheetPath: String) throws -> [[String: String]] {
        let worksheet = try file.parseWorksheet(at: worksheetPath)
        let rows = worksheet.data?.rows ?? []
        guard let headerRow = rows.first else { return [] }

        let headerByColumn = Dictionary(uniqueKeysWithValues: headerRow.cells.compactMap { cell -> (String, String)? in
            let column = cell.reference.column.description
            guard let header = stringValue(cell: cell, sharedStrings: sharedStrings) else { return nil }
            let key = headerKey(header)
            guard !key.isEmpty else { return nil }
            return (column, key)
        })

        if headerByColumn.isEmpty { return [] }

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

    private static func stringValue(cell: Cell, sharedStrings: SharedStrings?) -> String? {
        if let sharedStrings, let value = cell.stringValue(sharedStrings) {
            return value
        }
        if let value = cell.value {
            return value
        }
        return nil
    }

    private static func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let replaced = value.replacingOccurrences(of: "\\n", with: "\n")
        let trimmed = replaced.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func headerKey(_ raw: String) -> String {
        let folded = raw
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

    private static func fileKeyVariants(_ raw: String) -> [String] {
        let trimmed = cleanToken(raw)
        if trimmed.isEmpty { return [] }

        let base = trimmed.components(separatedBy: ".").dropLast().joined(separator: ".")
        let normalizedTrimmed = fileKey(trimmed)
        let normalizedBase = base.isEmpty ? "" : fileKey(base)

        var keys: [String] = []
        keys.append(trimmed)
        if !base.isEmpty { keys.append(base) }
        keys.append(trimmed.lowercased())
        if !base.isEmpty { keys.append(base.lowercased()) }
        if !normalizedTrimmed.isEmpty { keys.append(normalizedTrimmed) }
        if !normalizedBase.isEmpty { keys.append(normalizedBase) }
        return Array(Set(keys))
    }

    private static func fileKey(_ raw: String) -> String {
        let folded = raw
            .replacingOccurrences(of: "\\n", with: " ")
            .replacingOccurrences(of: "_", with: " ")
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

    private static func cleanToken(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return trimmed }

        let noQuotes = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "\"“”'’"))
        let standardizedSlashes = noQuotes.replacingOccurrences(of: "\\", with: "/")
        if standardizedSlashes.contains("/") {
            return standardizedSlashes.split(separator: "/").last.map(String.init) ?? standardizedSlashes
        }
        return standardizedSlashes
    }

    private static func htmlUnescape(_ raw: String) -> String {
        var s = raw
        let replacements: [(String, String)] = [
            ("&amp;", "&"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&apos;", "'"),
            ("&lt;", "<"),
            ("&gt;", ">"),
        ]
        for (from, to) in replacements {
            s = s.replacingOccurrences(of: from, with: to, options: [.caseInsensitive], range: nil)
        }
        return s
    }
}

final class IllustrationFileIndex {
    static let shared = IllustrationFileIndex()

    private var byFilename: [String: URL] = [:]
    private var byBasename: [String: URL] = [:]
    private var byLowerFilename: [String: URL] = [:]
    private var byNormalizedFilename: [String: URL] = [:]
    private var byNormalizedBasename: [String: URL] = [:]

    private init() {
        if let illustrationsURL = Bundle.main.url(forResource: "Illustrations", withExtension: nil, subdirectory: "data") {
            let exts = Set(["jpg", "jpeg", "png", "webp", "gif"])
            if let e = FileManager.default.enumerator(at: illustrationsURL, includingPropertiesForKeys: nil) {
                for case let url as URL in e {
                    let ext = url.pathExtension.lowercased()
                    if !exts.contains(ext) { continue }
                    let filename = url.lastPathComponent
                    byFilename[filename] = url
                    byLowerFilename[filename.lowercased()] = url
                    let base = url.deletingPathExtension().lastPathComponent
                    if byBasename[base] == nil {
                        byBasename[base] = url
                    }
                    let nFile = Self.fileKey(filename)
                    if !nFile.isEmpty, byNormalizedFilename[nFile] == nil {
                        byNormalizedFilename[nFile] = url
                    }
                    let nBase = Self.fileKey(base)
                    if !nBase.isEmpty, byNormalizedBasename[nBase] == nil {
                        byNormalizedBasename[nBase] = url
                    }
                }
            }
        }
    }

    func url(for token: String) -> URL? {
        let cleaned = Self.cleanToken(token)
        if let exact = byFilename[cleaned] { return exact }
        if let byLower = byLowerFilename[cleaned.lowercased()] { return byLower }

        let base = cleaned.components(separatedBy: ".").dropLast().joined(separator: ".")
        if !base.isEmpty, let byBase = byBasename[base] { return byBase }
        if let byBase = byBasename[cleaned] { return byBase }

        let nToken = Self.fileKey(cleaned)
        if !nToken.isEmpty, let byN = byNormalizedFilename[nToken] { return byN }
        if !nToken.isEmpty, let byN = byNormalizedBasename[nToken] { return byN }
        if !base.isEmpty {
            let nBase = Self.fileKey(base)
            if !nBase.isEmpty, let byN = byNormalizedBasename[nBase] { return byN }
        }

        if let fuzzy = Self.findByContains(normalizedToken: nToken, in: byNormalizedFilename) { return fuzzy }
        if let fuzzy = Self.findByContains(normalizedToken: nToken, in: byNormalizedBasename) { return fuzzy }
        return nil
    }

    private static func fileKey(_ raw: String) -> String {
        let folded = raw
            .replacingOccurrences(of: "\\n", with: " ")
            .replacingOccurrences(of: "_", with: " ")
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

    private static func cleanToken(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return trimmed }

        let noQuotes = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "\"“”'’"))
        let standardizedSlashes = noQuotes.replacingOccurrences(of: "\\", with: "/")
        if standardizedSlashes.contains("/") {
            return standardizedSlashes.split(separator: "/").last.map(String.init) ?? standardizedSlashes
        }
        return standardizedSlashes
    }

    private static func findByContains(normalizedToken: String, in dict: [String: URL]) -> URL? {
        if normalizedToken.isEmpty { return nil }
        if normalizedToken.count < 6 { return nil }

        var best: (key: String, url: URL)? = nil
        for (key, url) in dict {
            if key.contains(normalizedToken) || normalizedToken.contains(key) {
                if best == nil || key.count < best!.key.count {
                    best = (key, url)
                }
            }
        }
        return best?.url
    }
}
