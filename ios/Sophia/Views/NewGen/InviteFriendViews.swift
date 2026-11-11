import SwiftUI

/// Quand montrer le parrainage (docs/parrainage.md) : jamais avant le premier cours terminé,
/// jamais à un abonné Premium (les cours gratuits ne lui apportent rien).
enum InviteFriend {
    /// La carte du fil d'accueil : tant que la récompense n'est pas gagnée.
    static func showsFeedCard(progressManager: ProgressManager, isPremium: Bool) -> Bool {
        !isPremium && progressManager.completedCount >= 1 && !ReferralService.shared.rewarded
    }

    /// La carte du profil : comme le fil, puis tant qu'il reste des cours gratuits à utiliser.
    static func showsProfileCard(progressManager: ProgressManager, isPremium: Bool) -> Bool {
        guard !isPremium, progressManager.completedCount >= 1 else { return false }
        return !ReferralService.shared.rewarded || progressManager.referralCreditsRemaining > 0
    }
}

// MARK: - Carte du fil

/// « Invite un ami et gagne 3 cours gratuits », glissée dans le fil d'accueil : l'illustration
/// papier, la promesse, et le bouton qui ouvre la page d'invitation.
struct InviteFriendFeedCard: View {
    @Environment(LanguageManager.self) private var languageManager
    /// Dans le fil paginé, la carte remplit sa page.
    var fillsPage = false
    let onInvite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(minHeight: 140, idealHeight: 200, maxHeight: fillsPage ? 340 : 200)
                .layoutPriority(fillsPage ? 1 : 0)
                .overlay {
                    Image("invite_poster")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityHidden(true)

            Text(languageManager.text("invite.card.title"))
                .font(DS.title(.title2, .heavy))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(languageManager.text("invite.card.body"))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if fillsPage { Spacer(minLength: 0) }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onInvite()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(languageManager.text("invite.cta"))
                        .font(DS.sans(.subheadline, .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DS.accent))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxHeight: fillsPage ? .infinity : nil, alignment: .top)
        .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
        .dsSoftShadow()
    }
}

// MARK: - Page d'invitation

/// La page « Invite un ami » : l'illustration, les trois étapes, mon code à copier ou partager,
/// où j'en suis, et, pour un compte tout neuf, le champ où saisir le code d'un ami.
struct InviteFriendView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss
    let progressManager: ProgressManager

    @Bindable private var social = SocialService.shared
    @Bindable private var referral = ReferralService.shared
    @State private var showAccount = false
    @State private var copied = false
    @State private var enteredCode = ""
    @State private var claimMessage: String?
    @State private var claimSucceeded = false
    @State private var isClaiming = false

    private var language: AppLanguage { languageManager.current }
    private var handle: String? { auth.isSignedIn ? social.myHandle : nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    RoundIconButton(systemImage: "chevron.left", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
                    Spacer()
                }

                Color.clear
                    .frame(maxWidth: .infinity)
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .overlay {
                        Image("invite_poster")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                    .accessibilityHidden(true)

                Text(languageManager.text("invite.card.title"))
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)

                stepsCard
                codeCard
                statusLine

                if auth.isSignedIn, referral.canClaim {
                    enterCodeCard
                }
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(DS.canvas.ignoresSafeArea())
        .task(id: auth.isSignedIn) {
            guard auth.isSignedIn else { return }
            if social.myHandle == nil { await social.refreshMyHandle() }
            await referral.sync()
        }
        .sheet(isPresented: $showAccount) { AccountView() }
    }

    // MARK: Pièces

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            step(1, languageManager.text("invite.step1"))
            step(2, languageManager.text("invite.step2"))
            step(3, languageManager.text("invite.step3"))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(DS.sans(.footnote, .bold))
                .foregroundStyle(DS.accent)
                .frame(width: 28, height: 28)
                .background(Circle().fill(DS.accentTint))
            Text(text)
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.ink)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
    }

    /// Mon code et le bouton de partage ; sans compte, l'invitation à en créer un.
    @ViewBuilder
    private var codeCard: some View {
        if let handle {
            VStack(alignment: .leading, spacing: 12) {
                Text(languageManager.text("invite.code.label").uppercasedInApp())
                    .font(DS.sans(.caption, .bold))
                    .foregroundStyle(DS.inkSecondary)
                    .tracking(0.6)

                Button {
                    UIPasteboard.general.string = handle
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    withAnimation(.easeInOut(duration: 0.2)) { copied = true }
                    Task {
                        try? await Task.sleep(nanoseconds: 1_600_000_000)
                        withAnimation(.easeInOut(duration: 0.2)) { copied = false }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text("@\(handle)")
                            .font(DS.title(.title2, .heavy))
                            .foregroundStyle(DS.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Spacer(minLength: 8)
                        if copied {
                            Text(languageManager.text("invite.code.copied"))
                                .font(DS.sans(.footnote, .bold))
                                .foregroundStyle(DS.success)
                        }
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(copied ? DS.success : DS.accent)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(DS.warm, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                ShareLink(item: ReferralService.shareText(handle: handle, language: language)) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                        Text(languageManager.text("invite.cta"))
                            .font(DS.sans(.subheadline, .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DS.accent))
                }
                .simultaneousGesture(TapGesture().onEnded {
                    AnalyticsService.shared.log(.share, screen: "invite", props: ["channel": .string("sheet"), "target": .string("invite")])
                })
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.surface))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
            .dsSoftShadow()
        } else if auth.isSignedIn {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        } else {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showAccount = true
            } label: {
                Text(languageManager.text("invite.signin"))
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DS.accent))
            }
            .buttonStyle(.plain)
        }
    }

    /// Où j'en suis : personne encore, des cours gratuits à utiliser, ou tout est utilisé.
    @ViewBuilder
    private var statusLine: some View {
        if auth.isSignedIn {
            let remaining = progressManager.referralCreditsRemaining
            let text: String = {
                if !referral.rewarded { return languageManager.text("invite.status.waiting") }
                if remaining > 0 { return String(format: languageManager.text("invite.status.earned"), remaining) }
                return languageManager.text("invite.status.used")
            }()
            HStack(spacing: 10) {
                Image(systemName: referral.rewarded ? "gift.fill" : "hourglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(referral.rewarded ? DS.warm : DS.inkTertiary)
                Text(text)
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DS.accentTint))
        }
    }

    /// Un compte tout neuf peut saisir le code de l'ami qui l'a invité (le lien le fait sinon).
    private var enterCodeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.text("invite.enter.title"))
                .font(DS.title(.headline, .heavy))
                .foregroundStyle(DS.ink)

            HStack(spacing: 10) {
                TextField(languageManager.text("invite.enter.placeholder"), text: $enteredCode)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(DS.sans(.body, .medium))
                    .foregroundStyle(DS.ink)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(DS.canvas))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))

                Button {
                    submitCode()
                } label: {
                    Text(languageManager.text("invite.enter.cta"))
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(DS.accent))
                }
                .buttonStyle(.plain)
                .disabled(isClaiming || enteredCode.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(isClaiming ? 0.6 : 1)
            }

            if let claimMessage {
                Text(claimMessage)
                    .font(DS.sans(.footnote, .semibold))
                    .foregroundStyle(claimSucceeded ? DS.success : DS.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
    }

    private func submitCode() {
        let code = enteredCode
        isClaiming = true
        claimMessage = nil
        Task {
            let outcome = await referral.claim(code: code)
            isClaiming = false
            claimSucceeded = outcome == .ok || outcome == .alreadyClaimed
            switch outcome {
            case .ok, .alreadyClaimed:
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                claimMessage = languageManager.text("invite.enter.ok")
            case .unknownCode, .ownCode:
                claimMessage = languageManager.text("invite.enter.unknown")
            case .accountTooOld:
                claimMessage = languageManager.text("invite.enter.tooOld")
            case .notSignedIn, .failed:
                claimMessage = languageManager.text("invite.enter.error")
            }
        }
    }
}
