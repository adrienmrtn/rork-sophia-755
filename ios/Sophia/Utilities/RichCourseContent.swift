import Combine
import CoreXLSX
import SwiftUI
import ZIPFoundation

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

extension ImageCredit {
    var displayCopyrightLine: String {
        let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLicense = license?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedSource = source?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if trimmedAuthor.isEmpty {
            if !trimmedLicense.isEmpty, !trimmedSource.isEmpty {
                if trimmedLicense.localizedCaseInsensitiveContains(trimmedSource) { return trimmedLicense }
                if trimmedSource.localizedCaseInsensitiveContains(trimmedLicense) { return trimmedSource }
                return trimmedLicense + " — " + trimmedSource
            }
            if !trimmedLicense.isEmpty { return trimmedLicense }
            return trimmedSource
        }

        let authorPart = trimmedAuthor.hasPrefix("©") ? trimmedAuthor : "© \(trimmedAuthor)"

        var parts: [String] = [authorPart]
        if !trimmedLicense.isEmpty { parts.append(trimmedLicense) }
        if !trimmedSource.isEmpty {
            let existing = parts.joined(separator: " — ")
            if !existing.localizedCaseInsensitiveContains(trimmedSource) {
                parts.append(trimmedSource)
            }
        }
        return parts.joined(separator: " — ")
    }
}

@MainActor
final class ImageCreditsStore: ObservableObject {
    static let shared = ImageCreditsStore()

    @Published private(set) var creditsByKey: [String: ImageCredit] = [:]
    private var loadedCreditDirectories: Set<String> = []

    private init() {
        Task { [weak self] in
            let credits = await Task.detached(priority: .utility) {
                (try? Self.loadAllCredits()) ?? [:]
            }.value
            self?.creditsByKey = credits
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

    func ensureCredit(for imageToken: String, near imageURL: URL?) async -> ImageCredit? {
        if let direct = credit(for: imageToken) { return direct }

        let candidateFiles: [URL] = await Task.detached(priority: .utility) {
            var urls: [URL] = []
            if let imageURL {
                var dir = imageURL.deletingLastPathComponent()
                for _ in 0 ..< 8 {
                    let filesInDir = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
                    for url in filesInDir {
                        if url.pathExtension.lowercased() != "xlsx" { continue }
                        let nameKey = url.lastPathComponent
                            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                            .lowercased()
                        if nameKey.contains("credit") {
                            urls.append(url)
                        }
                    }
                    let parent = dir.deletingLastPathComponent()
                    if parent.path == dir.path { break }
                    dir = parent
                }
            }
            if urls.isEmpty {
                urls = Self.discoverCreditFiles()
            }
            return Array(Set(urls)).sorted(by: { $0.path < $1.path })
        }.value

        let extra = await Task.detached(priority: .utility) {
            Self.loadCredits(from: candidateFiles)
        }.value

        if !extra.isEmpty {
            var merged = creditsByKey
            for (k, v) in extra {
                merged[k] = v
            }
            creditsByKey = merged
        }

        if let direct = credit(for: imageToken) { return direct }
        if let imageURL {
            if let byFilename = credit(for: imageURL.lastPathComponent) { return byFilename }
            let base = imageURL.deletingPathExtension().lastPathComponent
            if let byBase = credit(for: base) { return byBase }
        }
        return nil
    }

    func preloadCreditsIfNeeded(near imageURL: URL?) {
        guard let imageURL else { return }

        var candidateDir = imageURL.deletingLastPathComponent()
        for _ in 0 ..< 5 {
            let filesInDir = (try? FileManager.default.contentsOfDirectory(at: candidateDir, includingPropertiesForKeys: nil)) ?? []
            let creditFiles = filesInDir.filter { url in
                if url.pathExtension.lowercased() != "xlsx" { return false }
                return url.lastPathComponent
                    .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                    .lowercased()
                    .contains("credit")
            }

            if !creditFiles.isEmpty {
                let dirKey = candidateDir.path
                if loadedCreditDirectories.contains(dirKey) { return }
                loadedCreditDirectories.insert(dirKey)

                Task { [weak self] in
                    let extra = await Task.detached(priority: .utility) {
                        Self.loadCredits(from: creditFiles)
                    }.value
                    guard let self, !extra.isEmpty else { return }
                    var merged = self.creditsByKey
                    for (k, v) in extra where merged[k] == nil {
                        merged[k] = v
                    }
                    self.creditsByKey = merged
                }
                return
            }

            let parent = candidateDir.deletingLastPathComponent()
            if parent.path == candidateDir.path { return }
            candidateDir = parent
        }
    }

    private nonisolated static func loadAllCredits() throws -> [String: ImageCredit] {
        let files = discoverCreditFiles()

        return loadCredits(from: files)
    }

    private nonisolated static func loadCredits(from files: [URL]) -> [String: ImageCredit] {
        var merged: [String: ImageCredit] = [:]
        for url in files {
            let beforeCount = merged.count
            let rows =
                (try? readRows(fileURL: url, preferredSheetNames: ["Crédits", "Credits", "Crédit", "Credit", "Crédits illustration", "Credit illustration", "Sheet1"])) ??
                []
            applyCredits(from: rows, into: &merged)
            if merged.count == beforeCount {
                let fixed = readFixedCreditRowsViaZipFoundation(fileURL: url)
                applyCredits(from: fixed, into: &merged)
            }
        }
        return merged
    }

    private nonisolated static func applyCredits(from rows: [[String: String]], into merged: inout [String: ImageCredit]) {
        for row in rows {
            let tokenRaw =
                normalized(row["cours"]) ??
                normalized(row["requete image"]) ??
                normalized(row["requete"]) ??
                normalized(row["prompt"]) ??
                normalized(row["image"]) ??
                normalized(row["nom du fichier"]) ??
                normalized(row["nom de l image"]) ??
                normalized(row["nom dans le cours"]) ??
                normalized(row["nom original"]) ??
                normalized(row["nom"])

            guard let tokenRaw, !tokenRaw.isEmpty else { continue }
            let token = htmlUnescape(tokenRaw)

            let originalNameRaw =
                normalized(row["nom original"]) ??
                normalized(row["nom du fichier"]) ??
                normalized(row["nom de l image"]) ??
                tokenRaw
            let originalName = htmlUnescape(originalNameRaw)

            let authorRaw =
                normalized(row["auteur"]) ??
                normalized(row["photographe"]) ??
                normalized(row["artiste"]) ??
                normalized(row["illustrateur"]) ??
                normalized(row["credit"]) ??
                normalized(row["credit copyright"]) ??
                normalized(row["copyright"])

            guard !originalName.isEmpty else { continue }

            let licenseRaw =
                normalized(row["licence"]) ??
                normalized(row["license"])

            let sourceRaw =
                normalized(row["source"]) ??
                normalized(row["lien"]) ??
                normalized(row["url"])

            let authorValue = htmlUnescape(authorRaw ?? "")
            let license = licenseRaw.map(htmlUnescape)
            let source = sourceRaw.map(htmlUnescape)

            if authorValue.isEmpty, (license ?? "").isEmpty, (source ?? "").isEmpty { continue }

            let credit = ImageCredit(
                originalName: originalName,
                author: authorValue,
                license: license,
                source: source
            )

            for key in fileKeyVariants(token) + fileKeyVariants(originalName) {
                merged[key] = credit
            }
        }
    }

    private nonisolated static func discoverCreditFiles() -> [URL] {
        var urls: Set<URL> = []

        func isCreditFile(_ url: URL) -> Bool {
            if url.pathExtension.lowercased() != "xlsx" { return false }
            let nameKey = url.lastPathComponent
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                .lowercased()
            if !nameKey.contains("credit") { return false }
            return true
        }

        let knownCreditFiles: [(subdir: String, file: String)] = [
            ("data/Illustrations/Art", "credits-illustrations.xlsx"),
            ("data/Illustrations/histoire", "credits-illustrations-histoire.xlsx"),
            ("data/Illustrations/Littérature", "credits-illustrations-litterature.xlsx"),
            ("data/Illustrations/Litte\u{0301}rature", "credits-illustrations-litterature.xlsx"),
            ("data/Illustrations/monde actuel", "credits-illustrations-monde-actuel.xlsx"),
            ("data/Illustrations/monde%20actuel", "credits-illustrations-monde-actuel.xlsx"),
            ("data/Illustrations/mythologie", "credits-illustrations-mythologie.xlsx"),
            ("data/Illustrations/Mythologie", "credits-illustrations-mythologie.xlsx"),
            ("data/Illustrations/Science", "credits-illustrations-Science.xlsx"),
            ("data/Illustrations/science", "credits-illustrations-Science.xlsx"),
        ]
        for item in knownCreditFiles {
            let name = item.file.replacingOccurrences(of: ".xlsx", with: "")
            if let url = Bundle.main.url(forResource: name, withExtension: "xlsx", subdirectory: item.subdir) {
                urls.insert(url)
            }
        }

        let knownSubdirs = [
            "data/Illustrations",
            "data/illustrations",
            "data/Illustration",
            "data/illustration",
        ]
        for subdir in knownSubdirs {
            if let direct = Bundle.main.urls(forResourcesWithExtension: "xlsx", subdirectory: subdir) {
                for url in direct where isCreditFile(url) {
                    urls.insert(url)
                }
            }
        }

        if let fromData = Bundle.main.urls(forResourcesWithExtension: "xlsx", subdirectory: "data") {
            for url in fromData where isCreditFile(url) {
                urls.insert(url)
            }
        }

        let fallbackRoots: [URL] = [
            Bundle.main.url(forResource: "Illustrations", withExtension: nil, subdirectory: "data"),
            Bundle.main.bundleURL.appendingPathComponent("data/Illustrations", isDirectory: true),
            Bundle.main.bundleURL.appendingPathComponent("data/illustrations", isDirectory: true),
        ].compactMap { $0 }

        for root in fallbackRoots {
            if let e = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) {
                for case let url as URL in e where isCreditFile(url) {
                    urls.insert(url)
                }
            }
        }

        return urls.sorted(by: { $0.path < $1.path })
    }

    private nonisolated static func readRows(fileURL: URL, preferredSheetNames: [String]) throws -> [[String: String]] {
        guard let file = XLSXFile(filepath: fileURL.path) else { return [] }
        let sharedStrings = try? file.parseSharedStrings()
        guard let workbook = try file.parseWorkbooks().first else { return [] }
        let pathsAndNames = try file.parseWorksheetPathsAndNames(workbook: workbook)

        let normalizedPreferred = preferredSheetNames.map { headerKey($0) }
        let pathFromPreferred = pathsAndNames.first(where: { item in
            let nameKey = headerKey(item.name ?? "")
            return normalizedPreferred.contains(nameKey)
        })?.path

        let worksheetPath = pathFromPreferred ?? pathsAndNames.first?.path
        guard let worksheetPath else { return [] }

        let coreRows = try readRows(file: file, sharedStrings: sharedStrings, worksheetPath: worksheetPath)
        let zipRows = readRowsViaZipFoundation(fileURL: fileURL)
        if coreRows.isEmpty { return zipRows }
        if zipRows.isEmpty { return coreRows }
        return coreRows + zipRows
    }

    private nonisolated static func readRows(fileURL: URL, sheetName: String) throws -> [[String: String]] {
        guard let file = XLSXFile(filepath: fileURL.path) else { return [] }
        let sharedStrings = try? file.parseSharedStrings()
        guard let workbook = try file.parseWorkbooks().first else { return [] }
        let pathsAndNames = try file.parseWorksheetPathsAndNames(workbook: workbook)
        let worksheetPath = pathsAndNames.first(where: { ($0.name ?? "") == sheetName })?.path ?? pathsAndNames.first?.path
        guard let worksheetPath else { return [] }
        return try readRows(file: file, sharedStrings: sharedStrings, worksheetPath: worksheetPath)
    }

    private nonisolated static func readRows(file: XLSXFile, sharedStrings: SharedStrings?, worksheetPath: String) throws -> [[String: String]] {
        let worksheet = try file.parseWorksheet(at: worksheetPath)
        let rows = worksheet.data?.rows ?? []
        guard let headerRow = rows.first else { return [] }

        let headerByColumn = Dictionary(uniqueKeysWithValues: headerRow.cells.compactMap { cell -> (String, String)? in
            let column = cell.reference.column.description
            guard let header = stringValue(cell: cell, sharedStrings: sharedStrings) else { return nil }
            let key = ImageCreditsStore.headerKey(header)
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

    private nonisolated static func readRowsViaZipFoundation(fileURL: URL) -> [[String: String]] {
        guard let archive = Archive(url: fileURL, accessMode: .read) else { return [] }

        let sharedStrings = loadSharedStrings(archive: archive)
        guard let sheetPath = firstWorksheetPath(archive: archive) else { return [] }
        guard let rows = loadWorksheetRows(archive: archive, path: sheetPath, sharedStrings: sharedStrings) else { return [] }
        guard let header = rows.first(where: { !$0.isEmpty }) else { return [] }

        var headerByColumn: [String: String] = [:]
        for (column, value) in header {
            let key = headerKey(value)
            if !key.isEmpty {
                headerByColumn[column] = key
            }
        }
        if headerByColumn.isEmpty { return [] }

        var foundHeader = false
        var out: [[String: String]] = []
        for row in rows {
            if !foundHeader {
                if row == header { foundHeader = true }
                continue
            }
            var dict: [String: String] = [:]
            for (column, value) in row {
                guard let key = headerByColumn[column] else { continue }
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    dict[key] = trimmed
                }
            }
            if !dict.isEmpty {
                out.append(dict)
            }
        }
        return out
    }

    private nonisolated static func readFixedCreditRowsViaZipFoundation(fileURL: URL) -> [[String: String]] {
        guard let archive = Archive(url: fileURL, accessMode: .read) else { return [] }
        let sharedStrings = loadSharedStrings(archive: archive)
        guard let sheetPath = firstWorksheetPath(archive: archive) else { return [] }
        guard let rows = loadWorksheetRows(archive: archive, path: sheetPath, sharedStrings: sharedStrings) else { return [] }

        var out: [[String: String]] = []
        for row in rows {
            if let a = row["A"]?.trimmingCharacters(in: .whitespacesAndNewlines), !a.isEmpty, headerKey(a) == "cours" {
                continue
            }
            var dict: [String: String] = [:]
            if let v = row["A"] { dict["cours"] = v }
            if let v = row["B"] { dict["nom original"] = v }
            if let v = row["C"] { dict["auteur"] = v }
            if let v = row["D"] { dict["licence"] = v }
            if let v = row["E"] { dict["source"] = v }
            if dict.values.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                out.append(dict)
            }
        }
        return out
    }

    private nonisolated static func firstWorksheetPath(archive: Archive) -> String? {
        let candidates = archive.map(\.path)
        if candidates.contains("xl/worksheets/sheet1.xml") { return "xl/worksheets/sheet1.xml" }
        let worksheetPaths = candidates
            .filter { $0.hasPrefix("xl/worksheets/") && $0.hasSuffix(".xml") }
            .sorted()
        return worksheetPaths.first
    }

    private nonisolated static func loadSharedStrings(archive: Archive) -> [String] {
        guard archive["xl/sharedStrings.xml"] != nil else { return [] }
        guard let data = extractEntry(archive: archive, path: "xl/sharedStrings.xml") else { return [] }
        let parser = XMLParser(data: data)
        let delegate = SharedStringsXMLParser()
        parser.delegate = delegate
        _ = parser.parse()
        return delegate.strings
    }

    private nonisolated static func loadWorksheetRows(
        archive: Archive,
        path: String,
        sharedStrings: [String]
    ) -> [[String: String]]? {
        guard let data = extractEntry(archive: archive, path: path) else { return nil }
        let parser = XMLParser(data: data)
        let delegate = WorksheetXMLParser(sharedStrings: sharedStrings)
        parser.delegate = delegate
        _ = parser.parse()
        return delegate.rows
    }

    private nonisolated static func extractEntry(archive: Archive, path: String) -> Data? {
        guard let entry = archive[path] else { return nil }
        var data = Data()
        do {
            _ = try archive.extract(entry) { chunk in
                data.append(chunk)
            }
            return data
        } catch {
            return nil
        }
    }

    private final class SharedStringsXMLParser: NSObject, XMLParserDelegate {
        private(set) var strings: [String] = []
        private var currentParts: [String] = []
        private var currentText: String = ""
        private var inText = false

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
            if elementName == "si" {
                currentParts = []
            } else if elementName == "t" {
                inText = true
                currentText = ""
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            if inText {
                currentText += string
            }
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            if elementName == "t" {
                inText = false
                currentParts.append(currentText)
            } else if elementName == "si" {
                strings.append(currentParts.joined())
            }
        }
    }

    private final class WorksheetXMLParser: NSObject, XMLParserDelegate {
        private(set) var rows: [[String: String]] = []
        private let sharedStrings: [String]

        private var currentRow: [String: String] = [:]
        private var currentCellColumn: String = ""
        private var currentCellType: String = ""
        private var currentValueParts: [String] = []
        private var currentText: String = ""
        private var inValue = false
        private var inText = false

        init(sharedStrings: [String]) {
            self.sharedStrings = sharedStrings
        }

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
            if elementName == "row" {
                currentRow = [:]
            } else if elementName == "c" {
                currentCellColumn = columnLetters(from: attributeDict["r"] ?? "")
                currentCellType = attributeDict["t"] ?? ""
                currentValueParts = []
            } else if elementName == "v" {
                inValue = true
                currentText = ""
            } else if elementName == "t" {
                inText = true
                currentText = ""
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            if inValue || inText {
                currentText += string
            }
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            if elementName == "v" {
                inValue = false
                currentValueParts.append(currentText)
            } else if elementName == "t" {
                inText = false
                currentValueParts.append(currentText)
            } else if elementName == "c" {
                let joined = currentValueParts.joined()
                if !currentCellColumn.isEmpty {
                    let resolved = resolveCellText(raw: joined, type: currentCellType)
                    if let resolved {
                        currentRow[currentCellColumn] = resolved
                    }
                }
                currentCellColumn = ""
                currentCellType = ""
                currentValueParts = []
            } else if elementName == "row" {
                if !currentRow.isEmpty {
                    rows.append(currentRow)
                }
                currentRow = [:]
            }
        }

        private func resolveCellText(raw: String, type: String) -> String? {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            if type == "s" {
                if let idx = Int(trimmed), idx >= 0, idx < sharedStrings.count {
                    return sharedStrings[idx]
                }
                return nil
            }
            return trimmed
        }

        private func columnLetters(from reference: String) -> String {
            var out = ""
            for ch in reference {
                if ch.isASCII && ch.isLetter {
                    out.append(ch)
                } else if !out.isEmpty {
                    break
                }
            }
            return out
        }
    }

    fileprivate nonisolated static func stringValue(cell: Cell, sharedStrings: SharedStrings?) -> String? {
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

    private nonisolated static func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let replaced = value
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\\n", with: "\n")
        let trimmed = replaced.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    fileprivate nonisolated static func headerKey(_ raw: String) -> String {
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

    private nonisolated static func fileKeyVariants(_ raw: String) -> [String] {
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

    private nonisolated static func fileKey(_ raw: String) -> String {
        let folded = raw
            .replacingOccurrences(of: "\u{00A0}", with: " ")
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

    private nonisolated static func cleanToken(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return trimmed }

        let noQuotes = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "\"“”'’"))
        let standardizedSlashes = noQuotes.replacingOccurrences(of: "\\", with: "/")
        if standardizedSlashes.contains("/") {
            return standardizedSlashes.split(separator: "/").last.map(String.init) ?? standardizedSlashes
        }
        return standardizedSlashes
    }

    private nonisolated static func htmlUnescape(_ raw: String) -> String {
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

@MainActor
final class CourseIllustrationPromptIndex: ObservableObject {
    static let shared = CourseIllustrationPromptIndex()

    @Published private(set) var promptByCourseNumber: [Int: String] = [:]

    private init() {
        Task { [weak self] in
            let prompts = await Task.detached(priority: .utility) {
                (try? Self.loadPrompts()) ?? [:]
            }.value
            self?.promptByCourseNumber = prompts
        }
    }

    func prompt(forCourseId courseId: String) -> String? {
        guard let n = Self.courseNumber(from: courseId) else { return nil }
        return promptByCourseNumber[n]
    }

    private static func courseNumber(from courseId: String) -> Int? {
        guard courseId.hasPrefix("course_") else { return nil }
        let rest = courseId.dropFirst("course_".count)
        let digits = rest.prefix { $0.isNumber }
        return Int(digits)
    }

    private nonisolated static func loadPrompts() throws -> [Int: String] {
        guard let fileURL = discoverIllustrationsListFileURL() else { return [:] }

        guard let file = XLSXFile(filepath: fileURL.path) else { return [:] }
        let sharedStrings = try? file.parseSharedStrings()
        guard let workbook = try file.parseWorkbooks().first else { return [:] }
        let pathsAndNames = try file.parseWorksheetPathsAndNames(workbook: workbook)
        guard let worksheetPath = pathsAndNames.first?.path else { return [:] }

        let worksheet = try file.parseWorksheet(at: worksheetPath)
        let rows = worksheet.data?.rows ?? []
        guard let headerRow = rows.first else { return [:] }

        var headerByColumn: [String: String] = [:]
        for cell in headerRow.cells {
            let column = cell.reference.column.description
                guard let header = ImageCreditsStore.stringValue(cell: cell, sharedStrings: sharedStrings) else { continue }
                let key = ImageCreditsStore.headerKey(header)
            guard !key.isEmpty else { continue }
            headerByColumn[column] = key
        }
        if headerByColumn.isEmpty { return [:] }

        var bestByCourse: [Int: (isIntro: Bool, prompt: String)] = [:]

        for row in rows.dropFirst() {
            var dict: [String: String] = [:]
            for cell in row.cells {
                let column = cell.reference.column.description
                guard let key = headerByColumn[column] else { continue }
                guard let value = ImageCreditsStore.stringValue(cell: cell, sharedStrings: sharedStrings) else { continue }
                let trimmed = value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    dict[key] = trimmed
                }
            }

            guard
                let rawId = dict["id cours"] ?? dict["id"] ?? dict["cours"],
                let courseNumber = parseCourseNumber(rawId)
            else { continue }

            let prompt = (dict["requete image"] ?? dict["requete"] ?? dict["prompt"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if prompt.isEmpty { continue }

            let placementRaw = (dict["emplacement"] ?? "").folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            let isIntro = placementRaw.localizedCaseInsensitiveContains("intro")

            if let existing = bestByCourse[courseNumber] {
                if existing.isIntro { continue }
                if isIntro {
                    bestByCourse[courseNumber] = (true, prompt)
                }
            } else {
                bestByCourse[courseNumber] = (isIntro, prompt)
            }
        }

        var result: [Int: String] = [:]
        for (k, v) in bestByCourse {
            result[k] = v.prompt
        }
        return result
    }

    private nonisolated static func parseCourseNumber(_ raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let i = Int(trimmed) { return i }
        if let d = Double(trimmed) { return Int(d) }
        let digits = trimmed.filter { $0.isNumber }
        if let i = Int(digits), !digits.isEmpty { return i }
        return nil
    }

    private nonisolated static func discoverIllustrationsListFileURL() -> URL? {
        let candidates = Bundle.main.urls(forResourcesWithExtension: "xlsx", subdirectory: "data") ?? []
        for url in candidates {
            let key = url.lastPathComponent
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                .lowercased()
            if key.contains("liste") && key.contains("illustration") {
                return url
            }
        }
        return nil
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
