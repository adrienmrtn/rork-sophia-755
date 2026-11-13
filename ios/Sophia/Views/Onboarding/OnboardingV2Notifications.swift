import SwiftUI
import UIKit

/// Asks for notification authorization right after the profile reveal, while the user is still
/// being told what Sophia will do for them — same place as the Android page.
///
/// The page is Sophia's sentence and a faithful replica of the iOS permission alert, nothing
/// else. « Autoriser », or a tap anywhere else on the replica, opens the real system alert;
/// « Refuser » moves on without asking, so the one prompt iOS ever shows is not spent on a no.
/// Either way the flow continues to the same next step.
struct OnboardingV2Notifications: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var asked = false
    /// Garde-fou contre un double `onNext()` : le garde-temps ci-dessous et la réponse du
    /// système peuvent arriver tous les deux.
    @State private var moved = false

    /// Les mesures de l'alerte d'iOS : 270 pt de large, coins de 14 pt, boutons de 44 pt.
    private static let alertWidth: CGFloat = 270
    private static let alertCorner: CGFloat = 14
    private static let alertButtonHeight: CGFloat = 44
    /// Le filet entre le texte et les boutons, et entre les deux boutons.
    private static let alertSeparator = Color(red: 0.235, green: 0.235, blue: 0.263).opacity(0.36)
    /// Le bleu des boutons d'une alerte système.
    private static let alertTint = Color(red: 0, green: 0.478, blue: 1)

    var body: some View {
        OV2ScrollableContent {
            VStack(spacing: 0) {
                bubbleRow
                    .padding(.top, 14)
                    .dsStagger(0)

                systemAlert
                    .padding(.top, 44)
                    .dsStagger(1)
            }
            .padding(.horizontal, OV2End.side)
            .padding(.bottom, 16)
        } footer: {
            EmptyView()
        }
        .ov2Background()
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

            VStack(alignment: .leading, spacing: 0) {
                DSHighlightTitle(
                    text: languageManager.text("onboardingV2.notifications.bubble"),
                    style: .title3,
                    alignment: .leading
                )
                .accessibilityAddTraits(.isHeader)
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

    // MARK: - Réplique de l'alerte système

    /// L'alerte d'autorisation d'iOS, telle que le système la dessine : titre gras centré,
    /// texte, puis deux boutons côte à côte séparés par des filets, « Refuser » à gauche et
    /// « Autoriser » en gras à droite. Toucher « Autoriser » ou le reste de la carte ouvre la
    /// vraie alerte ; « Refuser » passe à la suite.
    private var systemAlert: some View {
        VStack(spacing: 0) {
            VStack(spacing: 3) {
                Text(languageManager.text("onboardingV2.notifications.alert.title.ios"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(languageManager.text("onboardingV2.notifications.alert.body.ios"))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.black)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(EdgeInsets(top: 19, leading: 16, bottom: 19, trailing: 16))
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture(perform: ask)

            Rectangle()
                .fill(Self.alertSeparator)
                .frame(height: 0.5)

            HStack(spacing: 0) {
                alertButton(
                    languageManager.text("onboardingV2.notifications.alert.deny.ios"),
                    weight: .regular,
                    action: skip
                )
                Rectangle()
                    .fill(Self.alertSeparator)
                    .frame(width: 0.5, height: Self.alertButtonHeight)
                alertButton(
                    languageManager.text("onboardingV2.notifications.alert.allow"),
                    weight: .semibold,
                    action: ask
                )
            }
        }
        .frame(width: Self.alertWidth)
        .background(
            RoundedRectangle(cornerRadius: Self.alertCorner, style: .continuous)
                .fill(.regularMaterial)
        )
        .background(
            RoundedRectangle(cornerRadius: Self.alertCorner, style: .continuous)
                .fill(Color.white.opacity(0.82))
        )
        .clipShape(RoundedRectangle(cornerRadius: Self.alertCorner, style: .continuous))
        .shadow(color: Color.black.opacity(0.16), radius: 28, x: 0, y: 12)
        .frame(maxWidth: .infinity)
        .opacity(asked ? 0.6 : 1)
        .animation(DSCalmMotion.state, value: asked)
    }

    private func alertButton(_ title: String, weight: Font.Weight, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: weight))
                .foregroundStyle(Self.alertTint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity)
                .frame(height: Self.alertButtonHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
}
