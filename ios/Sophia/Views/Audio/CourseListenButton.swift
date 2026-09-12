import SwiftUI

/// Headphones button that starts the narration of the course it sits on.
///
/// Audio is entered from a course, not from a separate library: the thing you
/// want to hear is the course already in front of you. Once playback starts,
/// the only chrome is iOS's own Now Playing — lock screen, Control Center,
/// Dynamic Island — which survives leaving the app. There is deliberately no
/// in-app playback bar: it covered content and swallowed taps.
struct CourseListenButton: View {
    @Environment(LanguageManager.self) private var languageManager

    let course: Course
    let progressManager: ProgressManager
    let isPremium: Bool
    var onLocked: () -> Void

    @State private var catalog = CourseAudioCatalog.shared
    @State private var audio = AudioPlayerService.shared
    @State private var showPlayer = false

    /// The narration language for this course: the app's own when it exists,
    /// otherwise whichever language has one (French, for now).
    private var language: AppLanguage? {
        let available = catalog.languages(forCourse: course.id)
        return available.contains(languageManager.current) ? languageManager.current : available.first
    }

    private var isCurrent: Bool { audio.current?.courseId == course.id }

    var body: some View {
        if let language {
            Button {
                guard canListen else { return onLocked() }
                if isCurrent {
                    showPlayer = true
                } else {
                    progressManager.claimDailyFreeCourseIfNeeded(course.id)
                    audio.play(course: course, language: language)
                    showPlayer = true
                }
            } label: {
                Image(systemName: isCurrent && audio.isPlaying ? "waveform" : "headphones")
                    .font(.jakarta(size: 15, weight: .medium))
                    .foregroundStyle(isCurrent ? DS.accent : DS.inkSecondary)
                    .frame(width: 40, height: 40)
                    .background(DS.surface, in: Circle())
                    .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
            }
            .accessibilityLabel(languageManager.text("audio.listen"))
            .sheet(isPresented: $showPlayer) {
                AudioPlayerSheet().sophiaColorScheme()
            }
        }
    }

    private var canListen: Bool {
        FreemiumGate.canListen(
            isPremium: isPremium,
            isDailyFreeCourse: progressManager.isDailyFreeCourse(course.id),
            hasClaimedDailyFreeCourse: progressManager.hasClaimedDailyFreeCourse
        )
    }
}
