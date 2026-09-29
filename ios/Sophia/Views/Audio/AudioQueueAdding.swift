import SwiftUI

// Adding to the queue without the long press: suggestions under the player, a browser of
// every narrated course, and a choice when another course is already playing.

/// Which courses to offer next under the player.
enum AudioSuggestions {
    /// The rest of the current course's collection first (in reading order, starting after
    /// it), then the same subject, then the rest of the catalogue. Only narrated courses,
    /// never the one playing or one already queued; unfinished courses before finished ones.
    static func courses(after courseId: String, limit: Int = 6) -> [Course] {
        let player = CourseAudioPlayer.shared
        let catalog = CourseAudioCatalog.shared
        let excluded = Set(player.queue.map(\.courseId)).union([courseId])
        let narrated = ContentCatalog.activeCourses.filter {
            !excluded.contains($0.id) && catalog.hasAudio($0.id)
        }
        guard !narrated.isEmpty else { return [] }

        var ordered: [Course] = []
        var seen: Set<String> = []
        func add(_ courses: [Course]) {
            for course in courses where seen.insert(course.id).inserted {
                ordered.append(course)
            }
        }

        let byId = Dictionary(narrated.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for collection in ContentCatalog.activeCollections {
            guard let index = collection.courseIds.firstIndex(of: courseId) else { continue }
            let after = collection.courseIds[(index + 1)...] + collection.courseIds[..<index]
            add(after.compactMap { byId[$0] })
        }
        if let subject = ContentCatalog.course(withId: courseId)?.subject {
            add(narrated.filter { $0.subject == subject })
        }
        add(narrated)

        let isCompleted = player.isCourseCompleted ?? { _ in false }
        let fresh = ordered.filter { !isCompleted($0.id) }
        let done = ordered.filter { isCompleted($0.id) }
        return Array((fresh + done).prefix(limit))
    }
}

/// A narrated course with its queue button: ＋ adds it at the end, ✓ once queued (a tap
/// takes it out again), the waveform while it plays. Long press: play next.
struct AudioAddRow: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    let source: String

    @State private var addedTrigger = 0

    private var player: CourseAudioPlayer { .shared }

    var body: some View {
        HStack(spacing: 12) {
            AudioCoverView(courseId: course.id, subject: course.subject, cornerRadius: 8)
                .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(course.title)
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(detail)
                    .font(DS.sans(.caption, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            queueButton
        }
        .contentShape(Rectangle())
        .contextMenu {
            if !player.isCurrent(course.id) {
                Button {
                    player.requestEnqueue(courseId: course.id, next: true, source: source)
                } label: {
                    Label(languageManager.text("audio.playNext"), systemImage: "text.line.first.and.arrowtriangle.forward")
                }
                Button {
                    player.requestPlay(courseId: course.id, source: source)
                } label: {
                    Label(languageManager.text("audio.playNow"), systemImage: "play.fill")
                }
            }
        }
        .sensoryFeedback(.success, trigger: addedTrigger)
    }

    private var detail: String {
        let flags = CourseAudioCatalog.shared.languages(for: course.id).map(\.flag).joined(separator: " ")
        return "\(course.subject.localizedShortName(language: languageManager.current)) · \(flags)"
    }

    @ViewBuilder
    private var queueButton: some View {
        if player.isCurrent(course.id) {
            Image(systemName: "waveform")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DS.accent)
                .symbolEffect(.variableColor.iterative, isActive: player.isPlaying)
                .frame(width: 40, height: 40)
        } else {
            let queued = player.isQueued(course.id)
            Button {
                if queued {
                    player.removeFromQueue(courseId: course.id)
                } else if player.requestEnqueue(courseId: course.id, next: false, source: source) {
                    addedTrigger += 1
                }
            } label: {
                Image(systemName: queued ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(queued ? DS.success : DS.accent)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(languageManager.text(queued ? "audio.removeFromQueue" : "audio.addToQueue")))
        }
    }
}

/// Under the full player: a few courses to queue in one tap, and the way to all of them.
struct AudioSuggestionsSection: View {
    @Environment(LanguageManager.self) private var languageManager
    let courseId: String
    let onBrowse: () -> Void

    var body: some View {
        let suggestions = AudioSuggestions.courses(after: courseId)
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.text("audio.suggestions.title"))
                .font(DS.title(.headline, .semibold))
                .foregroundStyle(DS.ink)

            if !suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, course in
                        if index > 0 {
                            Rectangle().fill(DS.hairline).frame(height: 1).padding(.leading, 58)
                        }
                        AudioAddRow(course: course, source: "player_suggestions")
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(DS.surface)
                .clipShape(.rect(cornerRadius: DS.Radius.control))
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                        .strokeBorder(DS.hairline, lineWidth: 1)
                }
            }

            Button(action: onBrowse) {
                HStack(spacing: 8) {
                    Image(systemName: "square.grid.2x2")
                    Text(languageManager.text("audio.browse"))
                }
            }
            .buttonStyle(DSSecondaryButtonStyle())
        }
    }
}

/// Every narrated course, searchable and filtered by subject, each with its ＋.
struct AudioBrowseView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var subject: Subject?

    private var courses: [Course] {
        let catalog = CourseAudioCatalog.shared
        return ContentCatalog.activeCourses.filter { course in
            guard catalog.hasAudio(course.id) else { return false }
            if let subject, course.subject != subject { return false }
            guard !searchText.isEmpty else { return true }
            return course.title.localizedStandardContains(searchText)
                || course.subcategory.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    subjectFilter
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    if courses.isEmpty {
                        Text(languageManager.text("audio.browse.empty"))
                            .font(DS.sans(.subheadline))
                            .foregroundStyle(DS.inkSecondary)
                    } else {
                        ForEach(courses) { course in
                            AudioAddRow(course: course, source: "audio_browse")
                        }
                    }
                }
                .listRowBackground(DS.surface)
            }
            .scrollContentBackground(.hidden)
            .background(DS.canvas)
            .searchable(text: $searchText, prompt: Text(languageManager.text("audio.browse.search")))
            .navigationTitle(languageManager.text("audio.browse.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(languageManager.text("common.close")) { dismiss() }
                }
            }
        }
    }

    private var subjectFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: languageManager.text("audio.browse.all"), selected: subject == nil) {
                    subject = nil
                }
                ForEach(Subject.allCases, id: \.self) { item in
                    chip(title: item.localizedShortName(language: languageManager.current), selected: subject == item) {
                        subject = item
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    private func chip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(selected ? Color.white : DS.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? DS.accent : DS.surface, in: Capsule())
                .overlay { Capsule().strokeBorder(DS.hairline, lineWidth: selected ? 0 : 1) }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Choice when another course is playing

private struct AudioPlayChoiceDialog: ViewModifier {
    @Environment(LanguageManager.self) private var languageManager
    @Binding var isPresented: Bool
    let courseId: String
    let source: String
    let onPlayNow: () -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            languageManager.text("audio.choice.title"),
            isPresented: $isPresented,
            titleVisibility: .visible
        ) {
            Button(languageManager.text("audio.playNow"), action: onPlayNow)
            Button(languageManager.text("audio.playNext")) {
                if CourseAudioPlayer.shared.requestEnqueue(courseId: courseId, next: true, source: source) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
            Button(languageManager.text("audio.addToQueue")) {
                if CourseAudioPlayer.shared.requestEnqueue(courseId: courseId, next: false, source: source) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
            Button(languageManager.text("audio.cancel"), role: .cancel) {}
        }
    }
}

extension View {
    /// "Écouter maintenant / Lire ensuite / Ajouter à la file", asked when the listener
    /// starts a course while another one is loaded, rather than cutting it off.
    func audioPlayChoiceDialog(
        isPresented: Binding<Bool>,
        courseId: String,
        source: String,
        onPlayNow: @escaping () -> Void
    ) -> some View {
        modifier(AudioPlayChoiceDialog(isPresented: isPresented, courseId: courseId, source: source, onPlayNow: onPlayNow))
    }
}
