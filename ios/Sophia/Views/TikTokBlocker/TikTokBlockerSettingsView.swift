import SwiftUI
import FamilyControls
import UserNotifications

/// Settings for the TikTok blocker. Pushed from `SettingsView`.
///
/// Turning it on walks through the three things the feature needs, in order, and stops at
/// the first one missing: Premium, Screen Time permission, then TikTok ticked in Apple's
/// picker. Turning it off never asks for anything: whoever set the lock can always lift
/// it, no subscription required.
struct TikTokBlockerSettingsView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    let store: StoreViewModel
    var onShowPaywall: (() -> Void)? = nil
    /// Presented as a cover from the profile rather than pushed: the back control is a
    /// close cross.
    var presentedAsCover: Bool = false

    @Bindable private var blocker = TikTokBlockerManager.shared
    @State private var showPicker = false
    @State private var notificationsAllowed = true
    /// iOS has never been asked: the prompt can still be shown from here. Once refused,
    /// only Settings can turn it back on.
    @State private var notificationsUndetermined = false
    @State private var hapticTrigger = 0
    @State private var toggleOn = TikTokBlockerManager.shared.isEnabled

    private var isPremium: Bool { store.isPremium }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    titleBar
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                    heroCard
                        .padding(.horizontal, 20)
                        .dsStagger(0)

                    toggleSection
                        .dsStagger(1)

                    if blocker.isEnabled || blocker.hasSelection {
                        appSection
                        statusSection
                    }

                    if blocker.authorization == .denied {
                        authDeniedCard
                            .padding(.horizontal, 20)
                    }

                    if blocker.isEnabled, !notificationsAllowed {
                        notificationsCard
                            .padding(.horizontal, 20)
                    }

                    howItWorksSection
                        .dsStagger(2)

                    if blocker.unlockCount > 0 {
                        Text(String(format: languageManager.text("tiktokBlocker.stats.unlocks"), blocker.unlockCount))
                            .font(DS.sans(.footnote))
                            .foregroundStyle(DS.inkSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }

                    Spacer(minLength: 32)
                }
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .familyActivityPicker(
            headerText: languageManager.text("tiktokBlocker.picker.header"),
            footerText: languageManager.text("tiktokBlocker.picker.footer"),
            isPresented: $showPicker,
            selection: $blocker.selection
        )
        .onChange(of: showPicker) { _, presented in
            // Picker closed with TikTok ticked: the switch that started all this can
            // finish its job.
            guard !presented else { return }
            if toggleOn, blocker.hasSelection, !blocker.isEnabled {
                blocker.setEnabled(true)
            } else if toggleOn, !blocker.hasSelection {
                toggleOn = false
            }
        }
        .onChange(of: blocker.isEnabled) { _, enabled in
            toggleOn = enabled
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            blocker.reconcileShield()
            Task { await refreshNotificationStatus() }
        }
        .task {
            blocker.reconcileShield()
            await refreshNotificationStatus()
        }
    }

    // MARK: - Title

    private var titleBar: some View {
        HStack(spacing: 12) {
            // La vibration vient du style du bouton rond.
            ProfileRoundButton(
                systemImage: presentedAsCover ? "xmark" : "chevron.backward",
                accessibilityLabel: languageManager.text(presentedAsCover ? "common.close" : "elevateProfile.back")
            ) {
                dismiss()
            }

            Text(languageManager.text("tiktokBlocker.settings.row.title"))
                .font(DS.title(.title2, .semibold))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(DS.accent, in: Circle())
                    .dsPopIn(delay: 0.15)
                Text(languageManager.text("tiktokBlocker.title"))
                    .font(DS.title(.title3, .semibold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(languageManager.text("tiktokBlocker.hero.body"))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsOptionCard(.selected)
    }

    // MARK: - Toggle

    private var toggleSection: some View {
        section(languageManager.text("tiktokBlocker.section")) {
            card {
                HStack(spacing: 12) {
                    iconBadge("hand.raised")
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(languageManager.text("tiktokBlocker.toggle.title"))
                                .font(DS.sans(.subheadline, .bold))
                                .foregroundStyle(DS.ink)
                            if !isPremium {
                                premiumPill
                            }
                        }
                        Text(toggleSubtitle)
                            .font(DS.sans(.footnote))
                            .foregroundStyle(DS.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Toggle("", isOn: Binding(
                        get: { toggleOn },
                        set: { handleToggle($0) }
                    ))
                    .labelsHidden()
                    .tint(DS.accent)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    private var toggleSubtitle: String {
        if !isPremium {
            return languageManager.text("tiktokBlocker.toggle.subtitle.premium")
        }
        if blocker.isEnabled {
            return languageManager.text("tiktokBlocker.toggle.subtitle.on")
        }
        return languageManager.text("tiktokBlocker.toggle.subtitle.off")
    }

    private var premiumPill: some View {
        Text(languageManager.text("tiktokBlocker.premium.badge").uppercasedInApp())
            .font(DS.sans(.caption2, .bold))
            .tracking(0.6)
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(DS.warm, in: Capsule())
    }

    /// The switch, step by step. Each missing piece is asked for and the switch waits for
    /// the answer; nothing is enabled until TikTok is actually ticked.
    private func handleToggle(_ on: Bool) {
        // Une bascule : le cran de sélection.
        Haptics.select()
        guard on else {
            toggleOn = false
            blocker.setEnabled(false)
            return
        }
        guard isPremium else {
            toggleOn = false
            onShowPaywall?()
            return
        }
        toggleOn = true
        Task {
            if blocker.authorization != .approved {
                let granted = await blocker.requestAuthorization()
                guard granted else {
                    toggleOn = false
                    return
                }
            }
            // The shield's "Open Sophia" button reaches the user through a notification:
            // ask now, while the switch is in hand, rather than warn afterwards.
            if await NotificationPermission.status() == .notDetermined {
                await NotificationPermission.request()
                await refreshNotificationStatus()
            }
            if blocker.hasSelection {
                blocker.setEnabled(true)
            } else {
                showPicker = true
            }
        }
    }

    // MARK: - Blocked app

    private var appSection: some View {
        section(languageManager.text("tiktokBlocker.app.title")) {
            card {
                HStack(spacing: 12) {
                    if blocker.hasSelection {
                        selectedAppIcons
                    } else {
                        iconBadge("app.dashed")
                        Text(languageManager.text("tiktokBlocker.app.none"))
                            .font(DS.sans(.footnote))
                            .foregroundStyle(DS.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Button {
                        hapticTrigger += 1
                        showPicker = true
                    } label: {
                        Text(languageManager.text(blocker.hasSelection ? "tiktokBlocker.app.change" : "tiktokBlocker.app.choose"))
                            .font(DS.sans(.footnote, .bold))
                            .foregroundStyle(DS.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(DS.accentTint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(PressableStyle(haptic: false))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    /// Icons and names of whatever was ticked, drawn by the system: we can show a token,
    /// never read it.
    private var selectedAppIcons: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(blocker.selection.applicationTokens), id: \.self) { token in
                Label(token)
                    .labelStyle(.titleAndIcon)
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
            }
            ForEach(Array(blocker.selection.categoryTokens), id: \.self) { token in
                Label(token)
                    .labelStyle(.titleAndIcon)
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
            }
            ForEach(Array(blocker.selection.webDomainTokens), id: \.self) { token in
                Label(token)
                    .labelStyle(.titleAndIcon)
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
            }
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        card {
            HStack(spacing: 12) {
                if blocker.isUnlockWindowOpen, let until = blocker.unlockedUntil {
                    iconBadge("lock.open.fill", tint: DS.success, bg: DS.successTint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(languageManager.text("tiktokBlocker.status.unlocked"))
                            .font(DS.sans(.subheadline, .bold))
                            .foregroundStyle(DS.ink)
                        HStack(spacing: 4) {
                            Text(languageManager.text("tiktokBlocker.status.unlocked.subtitle"))
                            Text(until, style: .timer)
                                .monospacedDigit()
                        }
                        .font(DS.sans(.footnote))
                        .foregroundStyle(DS.inkSecondary)
                    }
                    Spacer(minLength: 8)
                    Button {
                        hapticTrigger += 1
                        blocker.lockNow()
                    } label: {
                        Text(languageManager.text("tiktokBlocker.status.lockNow"))
                            .font(DS.sans(.footnote, .bold))
                            .foregroundStyle(DS.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(DS.accentTint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(PressableStyle(haptic: false))
                } else if blocker.isShieldActive {
                    iconBadge("lock.fill")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(languageManager.text("tiktokBlocker.status.locked"))
                            .font(DS.sans(.subheadline, .bold))
                            .foregroundStyle(DS.ink)
                        Text(languageManager.text("tiktokBlocker.status.locked.subtitle"))
                            .font(DS.sans(.footnote))
                            .foregroundStyle(DS.inkSecondary)
                    }
                    Spacer()
                } else {
                    iconBadge("moon.zzz", tint: DS.inkSecondary, bg: DS.surfaceMuted)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(languageManager.text("tiktokBlocker.status.idle"))
                            .font(DS.sans(.subheadline, .bold))
                            .foregroundStyle(DS.ink)
                        Text(languageManager.text("tiktokBlocker.status.idle.subtitle"))
                            .font(DS.sans(.footnote))
                            .foregroundStyle(DS.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Warnings

    private var authDeniedCard: some View {
        warningCard(
            icon: "exclamationmark.triangle.fill",
            title: languageManager.text("tiktokBlocker.auth.denied.title"),
            message: languageManager.text("tiktokBlocker.auth.denied.subtitle"),
            buttonTitle: languageManager.text("tiktokBlocker.notifications.open"),
            action: openSystemSettings
        )
    }

    private var notificationsCard: some View {
        warningCard(
            icon: "bell.badge",
            title: languageManager.text("tiktokBlocker.notifications.title"),
            message: languageManager.text("tiktokBlocker.notifications.subtitle"),
            buttonTitle: languageManager.text(notificationsUndetermined ? "tiktokBlocker.notifications.enable" : "tiktokBlocker.notifications.open"),
            action: {
                if notificationsUndetermined {
                    Task {
                        await NotificationPermission.request()
                        await refreshNotificationStatus()
                    }
                } else {
                    openSystemSettings()
                }
            }
        )
    }

    private func warningCard(icon: String, title: String, message: String, buttonTitle: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                iconBadge(icon, tint: DS.danger, bg: DS.dangerTint)
                Text(title)
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(message)
                .font(DS.sans(.footnote))
                .foregroundStyle(DS.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                hapticTrigger += 1
                action()
            } label: {
                Text(buttonTitle)
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(DS.accent)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle(haptic: false))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsOptionCard(.wrong)
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func refreshNotificationStatus() async {
        let status = await NotificationPermission.status()
        notificationsAllowed = status == .authorized || status == .provisional || status == .ephemeral
        notificationsUndetermined = status == .notDetermined
    }

    // MARK: - How it works

    private var howItWorksSection: some View {
        section(languageManager.text("tiktokBlocker.how.title")) {
            card {
                VStack(spacing: 0) {
                    step(1, languageManager.text("tiktokBlocker.how.step1"))
                    divider
                    step(2, languageManager.text("tiktokBlocker.how.step2"))
                    divider
                    step(3, languageManager.text("tiktokBlocker.how.step3"))
                }
            }
        }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(DS.sans(.footnote, .heavy))
                .foregroundStyle(DS.accent)
                .frame(width: 28, height: 28)
                .background(DS.accentTint, in: Circle())
                .dsPopIn(delay: 0.2 + Double(number) * 0.08)
            Text(text)
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.ink)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Building blocks (mirrors SettingsView's private helpers)

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ProfileGroupLabel(text: title)
                .padding(.horizontal, 20)
            content()
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .dsCard(padding: 0)
        .padding(.horizontal, 20)
    }

    private var divider: some View {
        ProfileRowDivider()
            .padding(.horizontal, 16)
    }

    /// Pictogramme de rangée, à la couleur de son état. `bg` n'est plus dessiné (pictogramme
    /// au trait, sans pastille) ; il reste pour les appels existants.
    private func iconBadge(_ name: String, tint: Color = DS.accent, bg: Color = DS.accentTint) -> some View {
        Image(systemName: name)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 24)
            .accessibilityHidden(true)
    }
}
