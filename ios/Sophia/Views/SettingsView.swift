import SwiftUI

struct SettingsView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    let store: StoreViewModel
    var onShowPaywall: (() -> Void)? = nil
    var onResetOnboarding: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil
    @State private var showResetAlert: Bool = false
    @State private var showResetOnboardingAlert: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPrivacy: Bool = false
    @State private var hapticTrigger: Int = 0

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "66"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                cream.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title + optional close
                        HStack {
                            Text(languageManager.text("settings.title"))
                                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                                .foregroundStyle(ink)
                            Spacer()
                            if let onDismiss {
                                Button(action: onDismiss) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 15, weight: .heavy))
                                        .foregroundStyle(ink)
                                        .frame(width: 38, height: 38)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                        sectionHeader(languageManager.text("language.section"))
                        HStack {
                            Spacer()
                            LanguagePickerControl()
                        }
                        .padding(.horizontal, 20)

                        // Progression
                        sectionHeader(languageManager.text("settings.section.progress"))
                        VStack(spacing: 0) {
                            statRow(
                                icon: "trophy.fill",
                                iconBg: BrutalPalette.pastel(for: .histoire),
                                title: String(format: languageManager.text("settings.courses.completed"), progressManager.completedCount),
                                subtitle: String(format: languageManager.text("settings.courses.available"), ContentCatalog.activeCourses.count)
                            )
                            if progressManager.streak > 0 {
                                divider
                                statRow(
                                    icon: "flame.fill",
                                    iconBg: BrutalPalette.pink,
                                    title: String(format: languageManager.text("settings.streak.title"), progressManager.streak),
                                    subtitle: languageManager.text("settings.streak.subtitle")
                                )
                            }
                        }
                        .brutalCard()
                        .padding(.horizontal, 20)

                        // Premium
                        if !store.isPremium {
                            sectionHeader(languageManager.text("settings.section.premium"))
                            Button {
                                hapticTrigger += 1
                                onShowPaywall?()
                            } label: {
                                HStack(spacing: 14) {
                                    iconBadge(name: "crown.fill", bg: Color(red: 1.0, green: 0.86, blue: 0.4))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(languageManager.text("settings.premium.title"))
                                            .font(.system(.headline, design: .rounded, weight: .heavy))
                                            .foregroundStyle(ink)
                                        Text(languageManager.text("settings.premium.subtitle"))
                                            .font(.system(.caption, design: .rounded, weight: .semibold))
                                            .foregroundStyle(ink.opacity(0.55))
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .heavy))
                                        .foregroundStyle(ink)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(BrutalCardButtonStyle(depth: 2))
                            .brutalCard()
                            .padding(.horizontal, 20)
                        }

                        // Data
                        sectionHeader(languageManager.text("settings.section.data"))
                        VStack(spacing: 0) {
                            actionRow(
                                icon: "arrow.counterclockwise",
                                iconBg: Color(red: 1.0, green: 0.78, blue: 0.78),
                                title: languageManager.text("settings.reset.title"),
                                destructive: true
                            ) {
                                hapticTrigger += 1
                                showResetAlert = true
                            }
                        }
                        .brutalCard()
                        .padding(.horizontal, 20)

                        // Legal
                        sectionHeader(languageManager.text("settings.section.legal"))
                        VStack(spacing: 0) {
                            actionRow(
                                icon: "doc.text.fill",
                                iconBg: BrutalPalette.pastel(for: .art),
                                title: languageManager.text("settings.terms.title")
                            ) {
                                hapticTrigger += 1
                                showTerms = true
                            }
                            divider
                            actionRow(
                                icon: "hand.raised.fill",
                                iconBg: BrutalPalette.pastel(for: .mythologie),
                                title: languageManager.text("settings.privacy.title")
                            ) {
                                hapticTrigger += 1
                                showPrivacy = true
                            }
                            if !store.isPremium {
                                divider
                                actionRow(
                                    icon: "arrow.clockwise",
                                    iconBg: BrutalPalette.pastel(for: .sciences),
                                    title: languageManager.text("settings.restore.title")
                                ) {
                                    hapticTrigger += 1
                                    Task { await store.restore() }
                                }
                            }
                        }
                        .brutalCard()
                        .padding(.horizontal, 20)

                        // About
                        sectionHeader(languageManager.text("settings.section.about"))
                        VStack(spacing: 0) {
                            infoRow(label: languageManager.text("settings.about.version"), value: appVersionString)
                            divider
                            infoRow(label: languageManager.text("settings.about.courses"), value: "\(ContentCatalog.activeCourses.count)")
                        }
                        .brutalCard()
                        .padding(.horizontal, 20)

                        #if DEBUG
                        sectionHeader(languageManager.text("settings.section.developer"))
                        VStack(spacing: 0) {
                            if onResetOnboarding != nil {
                                actionRow(
                                    icon: "arrow.triangle.2.circlepath",
                                    iconBg: Color(red: 1.0, green: 0.78, blue: 0.78),
                                    title: languageManager.text("settings.debug.resetOnboarding")
                                ) {
                                    hapticTrigger += 1
                                    showResetOnboardingAlert = true
                                }
                                divider
                            }
                            actionRow(
                                icon: "calendar.badge.minus",
                                iconBg: Color(red: 1.0, green: 0.86, blue: 0.55),
                                title: languageManager.text("settings.debug.resetDaily"),
                                subtitle: progressManager.hasCompletedCourseToday
                                    ? languageManager.text("settings.debug.daily.done")
                                    : languageManager.text("settings.debug.daily.pending")
                            ) {
                                hapticTrigger += 1
                                progressManager.resetDailyCourseFlag()
                            }
                        }
                        .brutalCard()
                        .padding(.horizontal, 20)
                        #endif

                        Text(languageManager.text("settings.footer"))
                            .font(.system(.caption, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink.opacity(0.4))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
            .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
            .alert(languageManager.text("settings.reset.alert.title"), isPresented: $showResetAlert) {
                Button(languageManager.text("settings.reset.alert.cancel"), role: .cancel) { }
                Button(languageManager.text("settings.reset.alert.confirm"), role: .destructive) {
                    progressManager.resetProgress()
                }
            } message: {
                Text(languageManager.text("settings.reset.alert.message"))
            }
            .alert(languageManager.text("settings.onboarding.alert.title"), isPresented: $showResetOnboardingAlert) {
                Button(languageManager.text("settings.reset.alert.cancel"), role: .cancel) { }
                Button(languageManager.text("settings.onboarding.alert.confirm"), role: .destructive) {
                    onResetOnboarding?()
                }
            } message: {
                Text(languageManager.text("settings.onboarding.alert.message"))
            }
            .sheet(isPresented: $showTerms) {
                TermsView()
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacyPolicyView()
            }
        }
    }

    // MARK: - Building blocks

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(.caption, design: .rounded, weight: .heavy))
            .foregroundStyle(ink.opacity(0.55))
            .tracking(1.2)
            .padding(.horizontal, 28)
    }

    private var divider: some View {
        Rectangle()
            .fill(ink)
            .frame(height: 2)
    }

    private func iconBadge(name: String, bg: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(bg)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(ink, lineWidth: 2)
                }
            Image(systemName: name)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(ink)
        }
        .frame(width: 40, height: 40)
    }

    private func statRow(icon: String, iconBg: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            iconBadge(name: icon, bg: iconBg)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                Text(subtitle)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.55))
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private func actionRow(
        icon: String,
        iconBg: Color,
        title: String,
        subtitle: String? = nil,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconBadge(name: icon, bg: iconBg)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(destructive ? Color(red: 0.85, green: 0.1, blue: 0.2) : ink)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(ink.opacity(0.5))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(ink)
            Spacer()
            Text(value)
                .font(.system(.body, design: .rounded, weight: .heavy))
                .foregroundStyle(ink.opacity(0.55))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }
}

// brutalCard() modifier is shared from ProfileView.swift
