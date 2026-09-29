import Foundation
import SwiftUI

/// Formatting shared by the audio screens.
enum AudioFormat {
    /// "4:07", "1:02:45".
    static func time(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }
        let total = max(0, Int(seconds.rounded(.down)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    /// "1×", "1,25×" — decimal separator of the app language.
    static func speed(_ rate: Double, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return (formatter.string(from: NSNumber(value: rate)) ?? String(rate)) + "×"
    }

    /// "12,4 Mo".
    static func bytes(_ count: Int64, locale: Locale) -> String {
        count.formatted(.byteCount(style: .file).locale(locale))
    }
}

/// The audio actions of a course: listen, play next, add to the queue, download.
///
/// Used as the content of a card's context menu (long press) and of the headphones menu
/// on the home card. Every action goes through the player's premium gate, so a free user
/// sees the same menu with a lock and lands on the audio paywall.
struct CourseAudioMenuItems: View {
    @Environment(LanguageManager.self) private var languageManager
    let courseId: String
    let source: String

    private var player: CourseAudioPlayer { .shared }
    private var catalog: CourseAudioCatalog { .shared }
    private var downloads: CourseAudioDownloads { .shared }

    var body: some View {
        if let language = catalog.defaultLanguage(for: courseId) {
            Button {
                player.requestPlay(courseId: courseId, source: source)
            } label: {
                Label(
                    languageManager.text(player.isPlayingCourse(courseId) ? "audio.nowPlaying" : "audio.listen"),
                    systemImage: player.isPremium ? "headphones" : "lock.fill"
                )
            }

            if player.hasItem, !player.isCurrent(courseId) {
                if player.isQueued(courseId) {
                    Button(role: .destructive) {
                        player.removeFromQueue(courseId: courseId)
                    } label: {
                        Label(languageManager.text("audio.removeFromQueue"), systemImage: "minus.circle")
                    }
                } else {
                    Button {
                        player.requestEnqueue(courseId: courseId, next: true, source: source)
                    } label: {
                        Label(languageManager.text("audio.playNext"), systemImage: "text.line.first.and.arrowtriangle.forward")
                    }
                    Button {
                        player.requestEnqueue(courseId: courseId, next: false, source: source)
                    } label: {
                        Label(languageManager.text("audio.addToQueue"), systemImage: "text.badge.plus")
                    }
                }
            }

            switch downloads.state(courseId: courseId, language: language) {
            case .none:
                Button {
                    player.requestDownload(courseId: courseId, language: language, source: source)
                } label: {
                    Label(
                        "\(languageManager.text("audio.download")) · \(language.shortCode)",
                        systemImage: player.isPremium ? "arrow.down.circle" : "lock.fill"
                    )
                }
            case .downloading:
                Button {
                    downloads.cancel(courseId: courseId, language: language)
                } label: {
                    Label(languageManager.text("audio.downloading"), systemImage: "xmark.circle")
                }
            case .downloaded:
                Button(role: .destructive) {
                    downloads.delete(courseId: courseId, language: language)
                } label: {
                    Label(languageManager.text("audio.deleteDownload"), systemImage: "trash")
                }
            }
        }
    }
}

private struct CourseAudioContextMenu: ViewModifier {
    let courseId: String
    let source: String
    let enabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        // No narration, no menu at all: an empty context menu would still lift the card.
        if enabled, CourseAudioCatalog.shared.hasAudio(courseId) {
            content.contextMenu {
                CourseAudioMenuItems(courseId: courseId, source: source)
            }
        } else {
            content
        }
    }
}

extension View {
    /// Long press on a course card: the audio menu, when the course is narrated.
    func courseAudioContextMenu(courseId: String, source: String, enabled: Bool = true) -> some View {
        modifier(CourseAudioContextMenu(courseId: courseId, source: source, enabled: enabled))
    }
}

/// Headphones button laid over a course cover. A tap plays; a long press opens the full
/// audio menu (queue, download). Absent when the course has no narration.
struct CourseAudioCardButton: View {
    @Environment(LanguageManager.self) private var languageManager
    let courseId: String
    let source: String
    var size: CGFloat = 38

    @State private var showChoice = false

    private var player: CourseAudioPlayer { .shared }

    var body: some View {
        if CourseAudioCatalog.shared.hasAudio(courseId) {
            Menu {
                CourseAudioMenuItems(courseId: courseId, source: source)
            } label: {
                icon
            } primaryAction: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if player.isPlayingCourse(courseId) {
                    player.pause()
                } else if player.isPremium, player.hasItem, !player.isCurrent(courseId) {
                    // Something else is loaded: ask rather than cut it off.
                    showChoice = true
                } else {
                    player.requestPlay(courseId: courseId, source: source)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(languageManager.text("audio.listen")))
            .audioPlayChoiceDialog(isPresented: $showChoice, courseId: courseId, source: source) {
                player.requestPlay(courseId: courseId, source: source)
            }
        }
    }

    private var icon: some View {
        Image(systemName: player.isPlayingCourse(courseId) ? "waveform" : "headphones")
            .font(.jakarta(size: size * 0.4, weight: .semibold))
            .foregroundStyle(player.isCurrent(courseId) ? DS.accent : DS.inkSecondary)
            .symbolEffect(.variableColor.iterative, isActive: player.isPlayingCourse(courseId))
            .frame(width: size, height: size)
            .background(.ultraThinMaterial, in: Circle())
            .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
    }
}
