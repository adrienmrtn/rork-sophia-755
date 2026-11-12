import SwiftUI
import UIKit

private let notificationBullets: [(emoji: String, key: String)] = [
    ("📚", "onboardingV2.notifications.bullet1"),
    ("⏰", "onboardingV2.notifications.bullet2"),
    ("🔕", "onboardingV2.notifications.bullet3"),
]

/// Asks for notification authorization right after the profile reveal, while the user is still
/// being told what Sophia will do for them — same place as the Android page. Sophia says why
/// in a speech bubble, a preview of the system dialog shows where to tap, and the preview card
/// shows the notification copy, so the system prompt arrives with its reason already on screen.
///
/// iOS only ever shows that prompt once, so it is fired from the CTA rather than on appear:
/// the user reads the reason first, then decides. A refusal changes nothing else — the flow
/// continues to the same next step.
struct OnboardingV2Notifications: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection
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
    /// La flèche sous « Autoriser » monte et descend doucement.
    @State private var arrowUp = false

    /// Gris de la boîte de dialogue système, telle qu'iOS la dessine.
    private static let dialogFill = Color(red: 0.957, green: 0.961, blue: 0.969)
    private static let dialogEdge = Color(red: 0.882, green: 0.894, blue: 0.914)

    var body: some View {
        OV2ScrollableContent {
            VStack(spacing: 0) {
                bubbleRow
                    .padding(.top, 14)
                    .dsStagger(0)

                boostRow
                    .padding(.top, 10)
                    .padding(.leading, 52)
                    .dsStagger(1)

                dialogPreview
                    .padding(.top, 26)
                    .dsStagger(2)

                previewCard
                    .padding(.top, 22)
                    .dsStagger(3)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(notificationBullets.enumerated()), id: \.offset) { i, bullet in
                        bulletRow(bullet, visible: i < revealed)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 18)
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, OV2End.side)
            .padding(.bottom, 16)
        } footer: {
            VStack(spacing: 0) {
                OnboardingV2Button(
                    title: languageManager.text("onboardingV2.notifications.cta"),
                    enabled: !asked,
                    bottomPadding: 6,
                    action: ask
                )

                // Jamais désactivé : c'est la sortie de secours si l'alerte système
                // n'apparaît jamais (iOS la met en file d'attente derrière une autre alerte
                // — celle d'ATT au lancement — et une alerte jamais montrée ne rappelle
                // jamais). Les deux boutons grisés faisaient de cette page un cul-de-sac.
                Button(action: skip) {
                    Text(languageManager.text("onboardingV2.notifications.skip"))
                        .font(DS.sans(.footnote, .semibold))
                        .foregroundStyle(DS.inkSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.pressable)
                .padding(.bottom, 10)
            }
        }
        .ov2Background()
        .onAppear(perform: runAnimation)
    }

    // MARK: - Bulle de Sophia

    private var bubbleShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 4,
            bottomLeadingRadius: DS.Radius.card,
            bottomTrailingRadius: DS.Radius.card,
            topTrailingRadius: DS.Radius.card,
            style: .continuous
        )
    }

    /// Le logo de Sophia et sa bulle : la raison de la demande, dite à la première personne.
    private var bubbleRow: some View {
        HStack(alignment: .top, spacing: 12) {
            sophiaMark
                .frame(width: 40, height: 40)
                .padding(.top, 6)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                DSHighlightTitle(
                    text: languageManager.text("onboardingV2.notifications.bubble"),
                    style: .title3,
                    alignment: .leading
                )
                .accessibilityAddTraits(.isHeader)

                Text(languageManager.text("onboardingV2.notifications.bubbleNote"))
                    .font(DS.sans(.footnote, .regular))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(bubbleShape.fill(DS.surface))
            .overlay(bubbleShape.stroke(DS.hairline, lineWidth: 1.5))
            .background(bubbleShape.fill(DS.hairline).offset(y: 1.5))
        }
    }

    @ViewBuilder
    private var sophiaMark: some View {
        if UIImage(named: "SplashLogo") != nil {
            Image("SplashLogo")
                .resizable()
                .scaledToFit()
        } else {
            ZStack {
                Circle().fill(DS.accent)
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    /// L'argument chiffré, le nombre en gras bleu, sous la bulle comme une seconde réplique.
    private var boostRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(DS.accent)
            OV2Markup.highlighted(languageManager.text("onboardingV2.notifications.boost"), color: DS.accent)
                .font(DS.sans(.footnote, .semibold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous).fill(DS.accentTint))
    }

    // MARK: - Aperçu de la boîte de dialogue système

    /// Une image de la demande d'iOS, avec une flèche sous « Autoriser » : ce qu'il faudra
    /// toucher une fois le bouton du bas pressé. Purement illustratif, rien n'y est cliquable.
    private var dialogPreview: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                Text(languageManager.text("onboardingV2.notifications.dialog.title"))
                    .font(DS.sans(.callout, .bold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(languageManager.text("onboardingV2.notifications.dialog.body"))
                    .font(DS.sans(.footnote, .regular))
                    .foregroundStyle(DS.inkSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    dialogButton(
                        languageManager.text("onboardingV2.notifications.dialog.deny"),
                        fill: Self.dialogEdge,
                        foreground: DS.ink
                    )
                    dialogButton(
                        languageManager.text("onboardingV2.notifications.dialog.allow"),
                        fill: DS.accent,
                        foreground: .white
                    )
                }
                .padding(.top, 8)
            }
            .padding(EdgeInsets(top: 20, leading: 18, bottom: 16, trailing: 18))
            .frame(maxWidth: 286)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Self.dialogFill))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Self.dialogEdge, lineWidth: 1.5)
            )

            Image(systemName: "arrow.up")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(DS.accent)
                // Sous « Autoriser » : la colonne de droite, ou de gauche en écriture droite-à-gauche.
                .offset(x: layoutDirection == .rightToLeft ? -69 : 69, y: arrowUp ? -5 : 3)
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private func dialogButton(_ title: String, fill: Color, foreground: Color) -> some View {
        Text(title)
            .font(DS.sans(.subheadline, .semibold))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(Capsule(style: .continuous).fill(fill))
    }

    // MARK: - Aperçu de la notification

    /// Mock of the system banner, so the value of saying yes is visible before the prompt.
    private var previewCard: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(DS.accentTint)
                    .frame(width: 38, height: 38)
                Image(systemName: "bell.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.accent)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: "Sophia")
                    .font(DS.sans(.caption, .bold))
                    .tracking(0.6)
                    .foregroundStyle(DS.accent)
                Text(previewTitle ?? languageManager.text("notification.courseNudge.title"))
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.leading)
                Text(previewBody)
                    .font(DS.sans(.caption, .regular))
                    .foregroundStyle(DS.inkSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .ov2EndCard()
        .accessibilityElement(children: .combine)
    }

    private var previewBody: String {
        previewHook ?? languageManager.text("notification.courseNudge.bodyFallback")
    }

    private func bulletRow(_ bullet: (emoji: String, key: String), visible: Bool) -> some View {
        HStack(spacing: 12) {
            Text(bullet.emoji).font(.system(size: 17))
            Text(languageManager.text(bullet.key))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(visible ? 1 : 0)
        .offset(x: visible || reduceMotion ? 0 : -10)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45 + Double(i) * 0.12) {
                withAnimation(DS.Motion.reveal) { revealed = i + 1 }
            }
        }

        if !reduceMotion, !arrowUp {
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true).delay(0.6)) {
                arrowUp = true
            }
        }
    }
}
