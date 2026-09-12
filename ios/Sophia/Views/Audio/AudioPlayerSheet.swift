import SwiftUI

/// The full player: scrubber, transport, speed, audio language, offline copy
/// and the queue.
struct AudioPlayerSheet: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    @State private var audio = AudioPlayerService.shared
    @State private var downloads = AudioDownloadManager.shared
    @State private var catalog = CourseAudioCatalog.shared
    @State private var scrubbing: Double? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Space.l) {
                    if let track = audio.current {
                        artwork(for: track)
                        titles(for: track)
                        scrubber
                        transport
                        secondaryRow(for: track)
                    }
                    queueSection
                }
                .padding(DS.Space.l)
            }
            .background(DS.canvas)
            .navigationTitle(languageManager.text("audio.mode"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.text("audio.close")) { dismiss() }
                }
            }
        }
    }

    // MARK: - Now playing

    @ViewBuilder
    private func artwork(for track: AudioPlayerService.Track) -> some View {
        Group {
            if let image = CourseImageMap.loadImage(for: track.courseId) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                track.subject.color.opacity(0.18)
                    .overlay(
                        Image(systemName: "waveform")
                            .font(.system(size: 52, weight: .semibold))
                            .foregroundStyle(track.subject.color)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .clipShape(.rect(cornerRadius: DS.Radius.card))
    }

    private func titles(for track: AudioPlayerService.Track) -> some View {
        VStack(spacing: 4) {
            Text(track.title)
                .font(DS.sans(.title3, .bold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
            Text(track.subject.rawValue)
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.inkSecondary)
        }
    }

    private var scrubber: some View {
        VStack(spacing: 4) {
            Slider(
                value: Binding(
                    get: { scrubbing ?? audio.currentTime },
                    set: { scrubbing = $0 }
                ),
                in: 0...max(audio.duration, 1),
                onEditingChanged: { editing in
                    // Commit on release only: seeking on every pixel of the drag
                    // makes the player stutter and fights the time observer.
                    if !editing, let target = scrubbing {
                        audio.seek(to: target)
                        scrubbing = nil
                    }
                }
            )
            .tint(DS.accent)
            .disabled(audio.duration <= 0)

            HStack {
                Text(Self.clock(scrubbing ?? audio.currentTime))
                Spacer()
                Text(Self.clock(audio.duration))
            }
            .font(.jakarta(size: 12, weight: .medium))
            .foregroundStyle(DS.inkSecondary)
            .monospacedDigit()
        }
    }

    private var transport: some View {
        HStack(spacing: DS.Space.xl) {
            Button { audio.previous() } label: {
                Image(systemName: "backward.end.fill").font(.system(size: 20, weight: .semibold))
            }
            .disabled(!audio.hasPrevious && audio.currentTime <= 3)

            Button { audio.skipBackward() } label: {
                Image(systemName: "gobackward.15").font(.system(size: 26, weight: .medium))
            }

            Button { audio.toggle() } label: {
                ZStack {
                    Circle().fill(DS.accent).frame(width: 66, height: 66)
                    if audio.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .accessibilityLabel(languageManager.text(audio.isPlaying ? "audio.pause" : "audio.play"))

            Button { audio.skipForward() } label: {
                Image(systemName: "goforward.15").font(.system(size: 26, weight: .medium))
            }

            Button { audio.next() } label: {
                Image(systemName: "forward.end.fill").font(.system(size: 20, weight: .semibold))
            }
            .disabled(!audio.hasNext)
        }
        .foregroundStyle(DS.ink)
    }

    // MARK: - Speed, language, download

    private func secondaryRow(for track: AudioPlayerService.Track) -> some View {
        HStack(spacing: DS.Space.s) {
            Menu {
                ForEach(AudioPlayerService.rates, id: \.self) { value in
                    Button {
                        audio.setRate(value)
                    } label: {
                        if value == audio.rate {
                            Label(rateLabel(value), systemImage: "checkmark")
                        } else {
                            Text(rateLabel(value))
                        }
                    }
                }
            } label: {
                pill(icon: "speedometer", text: rateLabel(audio.rate))
            }

            languageMenu(for: track)

            downloadButton(for: track)
        }
    }

    @ViewBuilder
    private func languageMenu(for track: AudioPlayerService.Track) -> some View {
        let available = catalog.languages(forCourse: track.courseId)
        Menu {
            ForEach(available) { language in
                Button {
                    guard language != track.language,
                          let course = ContentCatalog.course(withId: track.courseId, language: language)
                    else { return }
                    audio.play(course: course, language: language)
                } label: {
                    if language == track.language {
                        Label("\(language.flag) \(language.displayName)", systemImage: "checkmark")
                    } else {
                        Text("\(language.flag) \(language.displayName)")
                    }
                }
            }
            if available.count <= 1 {
                Section { Text(languageManager.text("audio.only_french")) }
            }
        } label: {
            pill(icon: "globe", text: "\(track.language.flag) \(track.language.displayName)")
        }
    }

    @ViewBuilder
    private func downloadButton(for track: AudioPlayerService.Track) -> some View {
        switch downloads.state(courseId: track.courseId, language: track.language) {
        case .absent:
            Button {
                downloads.download(courseId: track.courseId, language: track.language)
            } label: {
                pill(icon: "arrow.down.circle", text: languageManager.text("audio.download"))
            }
        case .downloading(let fraction):
            pill(icon: "arrow.down.circle", text: "\(Int(fraction * 100)) %")
                .opacity(0.6)
        case .ready:
            Menu {
                Button(role: .destructive) {
                    downloads.remove(courseId: track.courseId, language: track.language)
                } label: {
                    Label(languageManager.text("audio.remove_download"), systemImage: "trash")
                }
            } label: {
                pill(icon: "checkmark.circle.fill", text: languageManager.text("audio.downloaded"))
            }
        }
    }

    private func pill(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold))
            Text(text).font(.jakarta(size: 12, weight: .semibold)).lineLimit(1)
        }
        .foregroundStyle(DS.ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(DS.surfaceMuted, in: .rect(cornerRadius: DS.Radius.small))
    }

    // MARK: - Queue

    private var queueSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            Text(languageManager.text("audio.queue"))
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(DS.ink)

            if audio.queue.count <= 1 {
                Text(languageManager.text("audio.queue_empty"))
                    .font(DS.sans(.footnote, .medium))
                    .foregroundStyle(DS.inkSecondary)
            } else {
                ForEach(Array(audio.queue.enumerated()), id: \.element.id) { position, track in
                    Button {
                        audio.jump(to: position)
                    } label: {
                        HStack(spacing: DS.Space.s) {
                            Image(systemName: position == audio.index ? "speaker.wave.2.fill" : "line.3.horizontal")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(position == audio.index ? DS.accent : DS.inkTertiary)
                                .frame(width: 18)
                            Text(track.title)
                                .font(DS.sans(.footnote, position == audio.index ? .semibold : .medium))
                                .foregroundStyle(position == audio.index ? DS.ink : DS.inkSecondary)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Space.m)
        .background(DS.surface, in: .rect(cornerRadius: DS.Radius.card))
    }

    // MARK: - Formatting

    private static func clock(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    /// « 1× », « 1,5× » — decimal separator follows the app's language, so a
    /// French reader does not get an English-looking "1.5".
    private func rateLabel(_ value: Float) -> String {
        let formatter = NumberFormatter()
        formatter.locale = languageManager.locale
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let text = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return text + "×"
    }
}
