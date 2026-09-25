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

    @Bindable private var blocker = TikTokBlockerManager.shared
    @State private var showPicker = false
    @State private var notificationsAllowed = true
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

                    toggleSection

                    if blocker.isEnabled || blocker.hasSelection {
                        appSection
                        durationSection
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

                    if blocker.unlockCount > 0 {
                        Text(String(format: languageManager.text("tiktokBlocker.stats.unlocks"), blocker.unlockCount))
                            .font(DS.sans(.caption, .medium))
                            .foregroundStyle(DS.inkTertiary)
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
        HStack(spacing: 14) {
            Button {
                hapticTrigger += 1
                dismiss()
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.jakarta(size: 15, weight: .semibold))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(width: 40, height: 40)
                    .background(DS.surface, in: Circle())
                    .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
            }
            .buttonStyle(SoftPressButtonStyle())

            Text(languageManager.text("tiktokBlocker.settings.row.title"))
                .font(DS.title(.title2, .semibold))
                .foregroundStyle(DS.ink)
            Spacer()
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.jakarta(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.18), in: Circle())
                Text(languageManager.text("tiktokBlocker.title"))
                    .font(DS.title(.title3, .heavy))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(String(format: languageManager.text("tiktokBlocker.hero.body"), blocker.unlockMinutes))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.accent, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
    }

    // MARK: - Toggle

    private var toggleSection: some View {
        section(languageManager.text("tiktokBlocker.section")) {
            card {
                HStack(spacing: 14) {
                    iconBadge("hand.raised.fill")
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(languageManager.text("tiktokBlocker.toggle.title"))
                                .font(DS.sans(.body, .medium))
                                .foregroundStyle(DS.ink)
                            if !isPremium {
                                premiumPill
                            }
                        }
                        Text(toggleSubtitle)
                            .font(DS.sans(.caption, .medium))
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
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
    }

    private var toggleSubtitle: String {
        if !isPremium {
            return languageManager.text("tiktokBlocker.toggle.subtitle.premium")
        }
        if blocker.isEnabled {
            return String(format: languageManager.text("tiktokBlocker.toggle.subtitle.on"), blocker.unlockMinutes)
        }
        return languageManager.text("tiktokBlocker.toggle.subtitle.off")
    }

    private var premiumPill: some View {
        Text(languageManager.text("tiktokBlocker.premium.badge").uppercased())
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
        hapticTrigger += 1
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
                HStack(spacing: 14) {
                    if blocker.hasSelection {
                        selectedAppIcons
                    } else {
                        iconBadge("app.dashed")
                        Text(languageManager.text("tiktokBlocker.app.none"))
                            .font(DS.sans(.caption, .medium))
                            .foregroundStyle(DS.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Button {
                        hapticTrigger += 1
                        showPicker = true
                    } label: {
                        Text(languageManager.text(blocker.hasSelection ? "tiktokBlocker.app.change" : "tiktokBlocker.app.choose"))
                            .font(DS.sans(.subheadline, .semibold))
                            .foregroundStyle(DS.accentSoft)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(DS.accentTint, in: Capsule())
                    }
                    .buttonStyle(SoftPressButtonStyle())
                }
                .padding(.horizontal, 14)
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
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.ink)
            }
            ForEach(Array(blocker.selection.categoryTokens), id: \.self) { token in
                Label(token)
                    .labelStyle(.titleAndIcon)
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.ink)
            }
            ForEach(Array(blocker.selection.webDomainTokens), id: \.self) { token in
                Label(token)
                    .labelStyle(.titleAndIcon)
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.ink)
            }
        }
    }

    // MARK: - Duration

    private var durationSection: some View {
        section(languageManager.text("tiktokBlocker.duration.title")) {
            HStack(spacing: 8) {
                ForEach(TikTokBlockerShared.unlockOptions, id: \.self) { minutes in
                    let selected = blocker.unlockMinutes == minutes
                    Button {
                        hapticTrigger += 1
                        blocker.unlockMinutes = minutes
                    } label: {
                        Text(String(format: languageManager.text("tiktokBlocker.duration.minutes"), minutes))
                            .font(DS.sans(.subheadline, .semibold))
                            .foregroundStyle(selected ? .white : DS.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(selected ? DS.accent : DS.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(selected ? Color.clear : DS.hairline, lineWidth: 1)
                            )
                    }
                    .buttonStyle(SoftPressButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        card {
            HStack(spacing: 14) {
                if blocker.isUnlockWindowOpen, let until = blocker.unlockedUntil {
                    iconBadge("lock.open.fill", tint: DS.success, bg: DS.successTint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(languageManager.text("tiktokBlocker.status.unlocked"))
                            .font(DS.title(.subheadline, .semibold))
                            .foregroundStyle(DS.ink)
                        HStack(spacing: 4) {
                            Text(languageManager.text("tiktokBlocker.status.unlocked.subtitle"))
                            Text(until, style: .timer)
                                .monospacedDigit()
                        }
                        .font(DS.sans(.caption, .medium))
                        .foregroundStyle(DS.inkSecondary)
                    }
                    Spacer(minLength: 8)
                    Button {
                        hapticTrigger += 1
                        blocker.lockNow()
                    } label: {
                        Text(languageManager.text("tiktokBlocker.status.lockNow"))
                            .font(DS.sans(.caption, .semibold))
                            .foregroundStyle(DS.accentSoft)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(DS.accentTint, in: Capsule())
                    }
                    .buttonStyle(SoftPressButtonStyle())
                } else if blocker.isShieldActive {
                    iconBadge("lock.fill")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(languageManager.text("tiktokBlocker.status.locked"))
                            .font(DS.title(.subheadline, .semibold))
                            .foregroundStyle(DS.ink)
                        Text(languageManager.text("tiktokBlocker.status.locked.subtitle"))
                            .font(DS.sans(.caption, .medium))
                            .foregroundStyle(DS.inkSecondary)
                    }
                    Spacer()
                } else {
                    iconBadge("moon.zzz", tint: DS.inkTertiary, bg: DS.surfaceMuted)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(languageManager.text("tiktokBlocker.status.idle"))
                            .font(DS.title(.subheadline, .semibold))
                            .foregroundStyle(DS.ink)
                        Text(languageManager.text("tiktokBlocker.status.idle.subtitle"))
                            .font(DS.sans(.caption, .medium))
                            .foregroundStyle(DS.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 14)
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
            buttonTitle: languageManager.text("tiktokBlocker.notifications.open"),
            action: openSystemSettings
        )
    }

    private func warningCard(icon: String, title: String, message: String, buttonTitle: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                iconBadge(icon, tint: DS.danger, bg: DS.dangerTint)
                Text(title)
                    .font(DS.title(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
            }
            Text(message)
                .font(DS.sans(.caption, .medium))
                .foregroundStyle(DS.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                hapticTrigger += 1
                action()
            } label: {
                Text(buttonTitle)
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.accentSoft)
            }
            .buttonStyle(SoftPressButtonStyle())
        }
        .dsCard(padding: 16)
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func refreshNotificationStatus() async {
        let status = await NotificationPermission.status()
        notificationsAllowed = status == .authorized || status == .provisional || status == .ephemeral
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
                    step(3, String(format: languageManager.text("tiktokBlocker.how.step3"), blocker.unlockMinutes))
                }
            }
        }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(DS.accentSoft)
                .frame(width: 38, height: 38)
                .background(DS.accentTint, in: Circle())
            Text(text)
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Building blocks (mirrors SettingsView's private helpers)

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(DS.inkTertiary)
                .tracking(1.2)
                .padding(.horizontal, 24)
            content()
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .dsCard(padding: 0)
        .padding(.horizontal, 20)
    }

    private var divider: some View {
        Rectangle()
            .fill(DS.hairline)
            .frame(height: 1)
            .padding(.leading, 66)
    }

    private func iconBadge(_ name: String, tint: Color = DS.accentSoft, bg: Color = DS.accentTint) -> some View {
        Image(systemName: name)
            .font(.jakarta(size: 16, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: 38, height: 38)
            .background(bg, in: Circle())
    }
}
