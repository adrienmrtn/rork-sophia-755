import AVKit
import SwiftUI

/// Full-screen player, opened from the mini-player or from the headphones of a course.
///
/// Cover, position, ±15 s, speed slider (0.5× to 2×), narration language, download for
/// offline, AirPlay, and the queue. Everything it shows lives in `CourseAudioPlayer`, so
/// the lock screen and this sheet never disagree.
struct AudioPlayerView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    @State private var scrubbing = false
    @State private var scrubValue: Double = 0
    @State private var speedValue: Double = CourseAudioPlayer.shared.rate
    @State private var showQueue = false
    @State private var playTrigger = 0

    private var player: CourseAudioPlayer { .shared }
    private var catalog: CourseAudioCatalog { .shared }
    private var downloads: CourseAudioDownloads { .shared }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            if let item = player.current {
                content(item)
            }
        }
        .onChange(of: player.hasItem) { _, hasItem in
            // End of the queue, or closed from the lock screen: nothing left to show.
            if !hasItem { dismiss() }
        }
        .onChange(of: player.rate) { _, rate in
            // Changed from the lock screen or AirPods while the sheet is open.
            if abs(rate - speedValue) > 0.001 { speedValue = rate }
        }
        .sheet(isPresented: $showQueue) {
            AudioQueueView()
                .presentationDetents([.medium, .large])
                .sophiaSheetChrome()
        }
        .presentationDragIndicator(.visible)
        .sensoryFeedback(.impact(weight: .medium), trigger: playTrigger)
    }

    private func content(_ item: AudioQueueItem) -> some View {
        let course = ContentCatalog.course(withId: item.courseId)
        return VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 14)

            ScrollView {
                VStack(spacing: 26) {
                    AudioCoverView(courseId: item.courseId, subject: course?.subject, cornerRadius: DS.Radius.card)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 320)
                        .scaleEffect(player.isPlaying ? 1 : 0.9)
                        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: player.isPlaying)
                        .dsSoftShadow()
                        .padding(.horizontal, 36)
                        .padding(.top, 12)

                    titleBlock(item: item, course: course)
                        .padding(.horizontal, 28)

                    scrubber
                        .padding(.horizontal, 28)

                    if player.failedToLoad {
                        errorBanner
                            .padding(.horizontal, 28)
                    }

                    transport

                    speedCard
                        .padding(.horizontal, 24)

                    actionRow(item: item)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: OV2.readableWidth)
    }

    // MARK: Top

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(width: 40, height: 40)
                    .background(DS.surface, in: Circle())
                    .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
            }
            .accessibilityLabel(Text(languageManager.text("common.close")))

            Spacer()

            Text(languageManager.text("audio.nowPlaying").uppercased())
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(DS.inkTertiary)
                .tracking(1.2)

            Spacer()

            AirPlayButton()
                .frame(width: 40, height: 40)
                .background(DS.surface, in: Circle())
                .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
        }
    }

    private func titleBlock(item: AudioQueueItem, course: Course?) -> some View {
        VStack(spacing: 6) {
            Text(course?.title ?? "Sophia")
                .font(DS.title(.title3, .bold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle(item: item, course: course))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }

    private func subtitle(item: AudioQueueItem, course: Course?) -> String {
        var parts: [String] = []
        if let author = AuthorStore.author(forCourseId: item.courseId) { parts.append(author.name) }
        if let course { parts.append(course.subject.localizedShortName(language: languageManager.current)) }
        parts.append("\(item.language.flag) \(item.language.shortCode)")
        return parts.joined(separator: " · ")
    }

    // MARK: Scrubber

    private var scrubber: some View {
        let upper = max(player.duration, 1)
        let shown = scrubbing ? scrubValue : player.currentTime
        return VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { player.duration > 0 ? min(shown, upper) : 0 },
                    set: { scrubValue = $0 }
                ),
                in: 0...upper,
                onEditingChanged: { editing in
                    if editing {
                        scrubValue = player.currentTime
                        scrubbing = true
                    } else {
                        player.seek(to: scrubValue)
                        scrubbing = false
                    }
                }
            )
            .tint(DS.accent)
            .disabled(player.duration <= 0)

            HStack {
                Text(AudioFormat.time(shown))
                Spacer()
                if player.isBuffering {
                    ProgressView().controlSize(.mini)
                }
                Spacer()
                Text(player.duration > 0 ? "-" + AudioFormat.time(player.duration - shown) : "--:--")
            }
            .font(DS.sans(.caption, .medium))
            .foregroundStyle(DS.inkTertiary)
            .monospacedDigit()
        }
    }

    private var errorBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(DS.danger)
            Text(languageManager.text("audio.error"))
                .font(DS.sans(.footnote, .medium))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button(languageManager.text("audio.retry")) {
                player.resume()
            }
            .font(DS.sans(.footnote, .semibold))
            .foregroundStyle(DS.accentSoft)
        }
        .padding(12)
        .background(DS.dangerTint, in: RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))
    }

    // MARK: Transport

    private var transport: some View {
        HStack(spacing: 34) {
            transportButton(
                systemImage: "gobackward.15",
                size: 28,
                label: "audio.skipBack"
            ) {
                player.skip(by: -CourseAudioPlayer.skipInterval)
            }

            Button {
                playTrigger += 1
                player.togglePlayPause()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 78, height: 78)
                    .background(DS.accent, in: Circle())
            }
            .buttonStyle(SoftPressButtonStyle())
            .accessibilityLabel(Text(languageManager.text(player.isPlaying ? "audio.pause" : "audio.play")))

            transportButton(
                systemImage: "goforward.15",
                size: 28,
                label: "audio.skipForward"
            ) {
                player.skip(by: CourseAudioPlayer.skipInterval)
            }
        }
        .overlay(alignment: .trailing) {
            // Next narration, only when there is one.
            if !player.queue.isEmpty {
                transportButton(systemImage: "forward.end.fill", size: 20, label: "audio.next") {
                    player.skipToNext()
                }
                .offset(x: 64)
            }
        }
    }

    private func transportButton(
        systemImage: String,
        size: CGFloat,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(DS.ink)
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(languageManager.text(label)))
    }

    // MARK: Speed

    private var speedCard: some View {
        VStack(spacing: 10) {
            HStack {
                Label(languageManager.text("audio.speed"), systemImage: "speedometer")
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                Spacer()
                Text(AudioFormat.speed(speedValue, locale: languageManager.locale))
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(DS.accentSoft)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                if abs(speedValue - 1) > 0.001 {
                    Button("1×") {
                        withAnimation(.snappy) { speedValue = 1 }
                        commitSpeed()
                    }
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(DS.inkSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DS.accentTint, in: Capsule())
                }
            }

            Slider(
                value: $speedValue,
                in: CourseAudioPlayer.speedRange,
                step: CourseAudioPlayer.speedStep,
                label: { Text(languageManager.text("audio.speed")) },
                minimumValueLabel: {
                    Text(AudioFormat.speed(CourseAudioPlayer.speedRange.lowerBound, locale: languageManager.locale))
                },
                maximumValueLabel: {
                    Text(AudioFormat.speed(CourseAudioPlayer.speedRange.upperBound, locale: languageManager.locale))
                },
                onEditingChanged: { editing in
                    if !editing { commitSpeed() }
                }
            )
            .font(DS.sans(.caption2, .medium))
            .foregroundStyle(DS.inkTertiary)
            .tint(DS.accent)
            .onChange(of: speedValue) { _, value in
                // Live, so the listener hears the speed while dragging.
                player.setRate(value)
            }
        }
        .padding(16)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.control))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
    }

    private func commitSpeed() {
        player.setRate(speedValue)
        AnalyticsService.trackAudioSpeedChanged(rate: player.rate)
    }

    // MARK: Language · download · queue

    private func actionRow(item: AudioQueueItem) -> some View {
        HStack(spacing: 10) {
            languageMenu(item: item)
            downloadControl(item: item)
            queueButton
        }
    }

    private func languageMenu(item: AudioQueueItem) -> some View {
        Menu {
            ForEach(catalog.languages(for: item.courseId)) { language in
                Button {
                    player.switchLanguage(to: language)
                } label: {
                    if language == item.language {
                        Label("\(language.flag) \(language.displayName)", systemImage: "checkmark")
                    } else {
                        Text("\(language.flag) \(language.displayName)")
                    }
                }
            }
        } label: {
            actionTile(
                title: languageManager.text("audio.language"),
                value: "\(item.language.flag) \(item.language.shortCode)"
            ) {
                Image(systemName: "globe")
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func downloadControl(item: AudioQueueItem) -> some View {
        switch downloads.state(courseId: item.courseId, language: item.language) {
        case .none:
            Button {
                player.requestDownload(courseId: item.courseId, language: item.language, source: "player")
            } label: {
                actionTile(title: languageManager.text("audio.download"), value: item.language.shortCode) {
                    Image(systemName: "arrow.down.circle")
                }
            }
            .buttonStyle(.plain)
        case .downloading(let fraction):
            Button {
                downloads.cancel(courseId: item.courseId, language: item.language)
            } label: {
                actionTile(
                    title: languageManager.text("audio.downloading"),
                    value: "\(Int((fraction * 100).rounded())) %"
                ) {
                    ProgressRing(fraction: fraction)
                        .frame(width: 18, height: 18)
                }
            }
            .buttonStyle(.plain)
        case .downloaded:
            Menu {
                Button(role: .destructive) {
                    downloads.delete(courseId: item.courseId, language: item.language)
                } label: {
                    Label(languageManager.text("audio.deleteDownload"), systemImage: "trash")
                }
            } label: {
                actionTile(title: languageManager.text("audio.downloaded"), value: item.language.shortCode) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DS.success)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var queueButton: some View {
        Button {
            showQueue = true
        } label: {
            actionTile(
                title: languageManager.text("audio.upNext"),
                value: "\(player.queue.count)"
            ) {
                Image(systemName: "list.bullet")
            }
        }
        .buttonStyle(.plain)
    }

    private func actionTile<Icon: View>(
        title: String,
        value: String,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        VStack(spacing: 6) {
            icon()
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DS.accentSoft)
                .frame(height: 22)
            Text(value)
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(DS.ink)
                .monospacedDigit()
                .lineLimit(1)
            Text(title)
                .font(DS.sans(.caption2, .medium))
                .foregroundStyle(DS.inkTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.control))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Queue

/// Now playing, then what comes next: reorder by dragging, swipe to remove, tap to play.
struct AudioQueueView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    private var player: CourseAudioPlayer { .shared }

    var body: some View {
        NavigationStack {
            List {
                if let current = player.current {
                    Section(languageManager.text("audio.nowPlaying")) {
                        AudioQueueRow(item: current, isCurrent: true)
                    }
                }

                Section(languageManager.text("audio.upNext")) {
                    if player.queue.isEmpty {
                        Text(languageManager.text("audio.queue.empty"))
                            .font(DS.sans(.subheadline))
                            .foregroundStyle(DS.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        ForEach(player.queue) { item in
                            Button {
                                player.playFromQueue(item)
                            } label: {
                                AudioQueueRow(item: item, isCurrent: false)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { player.removeFromQueue(atOffsets: $0) }
                        .onMove { player.moveQueue(fromOffsets: $0, toOffset: $1) }
                    }
                }
                .listRowBackground(DS.surface)
            }
            .scrollContentBackground(.hidden)
            .background(DS.canvas)
            .navigationTitle(languageManager.text("audio.queue.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(languageManager.text("common.close")) { dismiss() }
                }
                if !player.queue.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Button(languageManager.text("audio.queue.clear"), role: .destructive) {
                            player.clearQueue()
                        }
                    }
                }
            }
        }
    }
}

private struct AudioQueueRow: View {
    @Environment(LanguageManager.self) private var languageManager
    let item: AudioQueueItem
    let isCurrent: Bool

    var body: some View {
        let course = ContentCatalog.course(withId: item.courseId)
        HStack(spacing: 12) {
            AudioCoverView(courseId: item.courseId, subject: course?.subject, cornerRadius: 8)
                .frame(width: 46, height: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text(course?.title ?? item.courseId)
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(2)
                Text("\(item.language.flag) \(item.language.displayName)")
                    .font(DS.sans(.caption, .medium))
                    .foregroundStyle(DS.inkSecondary)
            }
            Spacer(minLength: 0)
            if isCurrent {
                Image(systemName: "waveform")
                    .foregroundStyle(DS.accent)
                    .symbolEffect(.variableColor.iterative, isActive: CourseAudioPlayer.shared.isPlaying)
            } else if CourseAudioDownloads.shared.isDownloaded(courseId: item.courseId, language: item.language) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(DS.inkTertiary)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Shared pieces

/// The bundled course cover, or the subject icon on a tint when the course has none.
struct AudioCoverView: View {
    let courseId: String
    let subject: Subject?
    var cornerRadius: CGFloat = 12

    var body: some View {
        DS.surfaceMuted
            .overlay {
                if let image = CourseImageMap.loadImage(for: courseId) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: subject?.icon ?? "headphones")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(DS.accentSoft.opacity(0.6))
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(DS.hairline, lineWidth: 1)
            }
    }
}

/// Download progress as a thin ring.
struct ProgressRing: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Circle().stroke(DS.hairline, lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: max(0.03, fraction))
                .stroke(DS.accentSoft, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: fraction)
        }
    }
}

/// The system AirPlay / Bluetooth route picker.
struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.tintColor = DS.uiInkSecondary
        view.activeTintColor = DS.uiAccent
        view.prioritizesVideoDevices = false
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
