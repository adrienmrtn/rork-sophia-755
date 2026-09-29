import SwiftUI

/// The bar above the tab bar while a narration is loaded, like Apple Music and Podcasts.
/// A tap opens the full player; play/pause and close act in place.
struct AudioMiniPlayer: View {
    @Environment(LanguageManager.self) private var languageManager
    let onOpen: () -> Void

    private var player: CourseAudioPlayer { .shared }

    var body: some View {
        Group {
            if let item = player.current {
                bar(item)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: player.current?.id)
    }

    private func bar(_ item: AudioQueueItem) -> some View {
        let course = ContentCatalog.course(withId: item.courseId)
        return HStack(spacing: 12) {
            AudioCoverView(courseId: item.courseId, subject: course?.subject, cornerRadius: 8)
                .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text(course?.title ?? "Sophia")
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                Text(detail(item))
                    .font(DS.sans(.caption, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                player.togglePlayPause()
            } label: {
                Group {
                    if player.isBuffering && player.isPlaying {
                        ProgressView()
                    } else {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .foregroundStyle(DS.ink)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(languageManager.text(player.isPlaying ? "audio.pause" : "audio.play")))

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                player.stop()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(width: 32, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(languageManager.text("audio.close")))
        }
        .padding(.leading, 8)
        .padding(.trailing, 6)
        .padding(.vertical, 7)
        .background(DS.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
        .overlay(alignment: .bottom) {
            // Position, as a hairline along the bottom edge.
            GeometryReader { geo in
                Capsule()
                    .fill(DS.accent)
                    .frame(width: geo.size.width * player.progress, height: 2)
            }
            .frame(height: 2)
            .padding(.horizontal, 14)
        }
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
        .dsSoftShadow()
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(Text(languageManager.text("audio.nowPlaying")))
    }

    /// "FR · -12:03", or just the language before the duration is known.
    private func detail(_ item: AudioQueueItem) -> String {
        let language = "\(item.language.flag) \(item.language.shortCode)"
        guard player.duration > 0 else { return language }
        return "\(language) · -\(AudioFormat.time(player.duration - player.currentTime))"
    }
}

extension View {
    /// Pins the mini-player above the tab bar. Applied to each tab's root, so it sits
    /// right on top of the bar whatever its height, and scroll views end above it.
    func audioMiniPlayerInset(onOpen: @escaping () -> Void) -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            AudioMiniPlayer(onOpen: onOpen)
        }
    }
}
