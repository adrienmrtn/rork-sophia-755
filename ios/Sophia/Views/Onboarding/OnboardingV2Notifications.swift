import SwiftUI
import UIKit

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
    /// Garde-fou contre un double `onNext()` : le garde-temps ci-dessous et la réponse du
    /// système peuvent arriver tous les deux.
    @State private var moved = false
    @State private var revealed = 0
    /// La vraie notification : la question du jour en titre, son accroche en texte.
    @State private var previewTitle: String?
    @State private var previewHook: String?

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

                Spacer().frame(height: 14)

                // L'argument chiffré, le nombre en rose comme sur les pages de présentation.
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(OV2.pink)
                    OV2Markup.highlighted(languageManager.text("onboardingV2.notifications.boost"))
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(OV2.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(OV2.pink.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 24)
                .ov2Reveal(delay: 0.2)

                Spacer().frame(height: 24)

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

                // Jamais désactivé : c'est la sortie de secours si l'alerte système
                // n'apparaît jamais (iOS la met en file d'attente derrière une autre alerte
                // — celle d'ATT au lancement — et une alerte jamais montrée ne rappelle
                // jamais). Les deux boutons grisés faisaient de cette page un cul-de-sac.
                Button(action: skip) {
                    Text(languageManager.text("onboardingV2.notifications.skip"))
                        .font(DS.sans(.footnote, .semibold))
                        .foregroundStyle(OV2.inkTertiary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                }
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
                Text(previewTitle ?? languageManager.text("notification.courseNudge.title"))
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
        previewHook ?? languageManager.text("notification.courseNudge.bodyFallback")
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
        guard !asked, !moved else { return }
        asked = true
        Task { @MainActor in
            await NotificationPermission.request()
            // Granted: the daily reminder goes on the calendar at the hour just chosen.
            DailyCourseReminder.scheduleIfAllowed()
            leave()
        }
        // Garde-temps : iOS met son alerte en file d'attente derrière une autre alerte
        // système (celle d'ATT est demandée au lancement), et une alerte jamais présentée ne
        // rappelle jamais — l'attente serait éternelle. L'autorisation n'est qu'un bonus :
        // la suite de l'onboarding ne doit pas en dépendre.
        //
        // On ne débloque que si la scène est **active** : une alerte système à l'écran rend
        // l'app inactive, donc « active » signifie qu'aucune alerte n'est affichée et qu'il
        // n'y a donc plus rien à attendre. Les 8 s initiales laissent largement le temps à
        // l'alerte d'arriver avant d'en conclure qu'elle ne viendra pas.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            for _ in 0..<20 {
                guard asked, !moved else { return }
                if UIApplication.shared.applicationState == .active { break }
                try? await Task.sleep(nanoseconds: 1_500_000_000)
            }
            leave()
        }
    }

    private func skip() {
        guard !moved else { return }
        asked = true
        leave()
    }

    private func leave() {
        guard !moved else { return }
        moved = true
        onNext()
    }

    private func runAnimation() {
        // Today's question of the day, so the preview reads as the notification this user
        // would actually get.
        let language = languageManager.current
        if let id = DailyQuestion.todayCourseId(language: language, isCompleted: { _ in false }),
           let course = ContentCatalog.course(withId: id, language: language) {
            previewTitle = course.title
            previewHook = CourseContentStore.content(courseId: id, language: language)?
                .hero?.hook?
                .withoutInlineMarkup
        }

        for i in 0..<notificationBullets.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(i) * 0.16) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { revealed = i + 1 }
            }
        }
    }
}
