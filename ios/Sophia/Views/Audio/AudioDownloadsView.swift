import SwiftUI

/// Settings › Audio downloads: what is on the phone, how much room it takes, and a way to
/// get the room back.
struct AudioDownloadsView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDeleteAll = false

    private var downloads: CourseAudioDownloads { .shared }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label(languageManager.text("audio.downloads.used"), systemImage: "internaldrive")
                            .font(DS.sans(.body, .medium))
                            .foregroundStyle(DS.ink)
                        Spacer()
                        Text(AudioFormat.bytes(downloads.totalBytes, locale: languageManager.locale))
                            .font(DS.sans(.body, .semibold))
                            .foregroundStyle(DS.inkSecondary)
                            .monospacedDigit()
                    }
                } footer: {
                    Text(languageManager.text("audio.downloads.footer"))
                }
                .listRowBackground(DS.surface)

                Section {
                    if downloads.items.isEmpty {
                        Text(languageManager.text("audio.downloads.empty"))
                            .font(DS.sans(.subheadline))
                            .foregroundStyle(DS.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        ForEach(downloads.items) { item in
                            row(item)
                        }
                        .onDelete { offsets in
                            let items = downloads.items
                            for index in offsets where items.indices.contains(index) {
                                let key = items[index].key
                                downloads.delete(courseId: key.courseId, language: key.language)
                            }
                        }
                    }
                }
                .listRowBackground(DS.surface)

                if !downloads.items.isEmpty {
                    Section {
                        Button(role: .destructive) {
                            confirmDeleteAll = true
                        } label: {
                            Label(languageManager.text("audio.downloads.deleteAll"), systemImage: "trash")
                        }
                    }
                    .listRowBackground(DS.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(DS.canvas)
            .navigationTitle(languageManager.text("audio.downloads.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(languageManager.text("common.close")) { dismiss() }
                }
            }
            .confirmationDialog(
                languageManager.text("audio.downloads.deleteAll.confirm"),
                isPresented: $confirmDeleteAll,
                titleVisibility: .visible
            ) {
                Button(languageManager.text("audio.downloads.deleteAll"), role: .destructive) {
                    downloads.deleteAll()
                }
            }
        }
    }

    private func row(_ item: CourseAudioDownloads.Item) -> some View {
        let course = ContentCatalog.course(withId: item.key.courseId)
        return HStack(spacing: 12) {
            AudioCoverView(courseId: item.key.courseId, subject: course?.subject, cornerRadius: 8)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(course?.title ?? item.key.courseId)
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(2)
                Text("\(item.key.language.flag) \(item.key.language.displayName) · \(AudioFormat.bytes(item.bytes, locale: languageManager.locale))")
                    .font(DS.sans(.caption, .medium))
                    .foregroundStyle(DS.inkSecondary)
            }
        }
    }
}
