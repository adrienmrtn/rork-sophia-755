import SwiftUI

private let notificationBullets: [(emoji: String, key: String)] = [
    ("📚", "onboardingV2.notifications.bullet1"),
    ("⏰", "onboardingV2.notifications.bullet2"),
    ("🔕", "onboardingV2.notifications.bullet3"),
]

/// Asks for notification authorization right after the profile reveal, while the user is still
/// being told what Sophia will do for them — same place as the Android page. The preview card
/// shows the notification copy, so the system prompt arrives with its reason already on screen.
///
/// iOS only ever shows that prompt once, so it is fired from the CTA rather than on appear:
/// the user reads the reason first, then decides. A refusal changes nothing else — the flow
/// continues to the same next step.
struct OnboardingV2Notifications: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var asked = false
    @State private var revealed = 0
    @State private var previewCourseTitle: String?

    var body: some View {
        OV2ScrollableContent {
            VStack(spacing: 0) {
                Spacer().frame(height: 76)

                Text(languageManager.text("onboardingV2.notifications.title"))
                    .font(DS.title(.largeTitle, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .ov2Reveal(delay: 0.06)

                Spacer().frame(height: 10)

                Text(languageManager.text("onboardingV2.notifications.subtitle"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(OV2.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 30)
                    .ov2Reveal(delay: 0.14)

                Spacer().frame(height: 30)

                previewCard
                    .padding(.horizontal, 24)
                    .ov2Reveal(delay: 0.26, yOffset: 24)

                Spacer().frame(height: 30)

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(notificationBullets.enumerated()), id: \.offset) { i, bullet in
                        bulletRow(bullet, visible: i < revealed)
                    }
                }
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer().frame(height: 20)
            }
        } footer: {
            VStack(spacing: 0) {
                OnboardingV2Button(
                    title: languageManager.text("onboardingV2.notifications.cta"),
                    enabled: !asked,
                    action: ask
                )

                Button(action: skip) {
                    Text(languageManager.text("onboardingV2.notifications.skip"))
                        .font(DS.sans(.footnote, .semibold))
                        .foregroundStyle(OV2.inkTertiary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                }
                .disabled(asked)
                .padding(.bottom, 14)
            }
        }
        .ov2Background()
        .onAppear(perform: runAnimation)
    }

    // MARK: - Aperçu de la notification

    /// Mock of the system banner, so the value of saying yes is visible before the prompt.
    private var previewCard: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(OV2.accent.opacity(0.12))
                    .frame(width: 38, height: 38)
                Text("🔔").font(.system(size: 19))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Sophia")
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(OV2.inkTertiary)
                Text(languageManager.text("notification.courseNudge.title"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(OV2.ink)
                Text(previewBody)
                    .font(DS.sans(.caption, .regular))
                    .foregroundStyle(OV2.inkSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(OV2.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(OV2.hairline, lineWidth: 1)
        )
    }

    private var previewBody: String {
        guard let title = previewCourseTitle else {
            return languageManager.text("notification.courseNudge.bodyFallback")
        }
        return String(format: languageManager.text("notification.courseNudge.body"), title)
    }

    private func bulletRow(_ bullet: (emoji: String, key: String), visible: Bool) -> some View {
        HStack(spacing: 13) {
            Text(bullet.emoji).font(.system(size: 19))
            Text(languageManager.text(bullet.key))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(OV2.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(visible ? 1 : 0)
        .offset(x: visible ? 0 : -10)
    }

    // MARK: - Actions

    private func ask() {
        guard !asked else { return }
        asked = true
        Task { @MainActor in
            await NotificationPermission.request()
            onNext()
        }
    }

    private func skip() {
        guard !asked else { return }
        asked = true
        onNext()
    }

    private func runAnimation() {
        // Feature one of the courses the profile page just promised, so the preview reads as
        // the notification this user would actually get.
        previewCourseTitle = vm.awaitingCourses(language: languageManager.current)
            .randomElement()?
            .title

        for i in 0..<notificationBullets.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(i) * 0.16) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { revealed = i + 1 }
            }
        }
    }
}
