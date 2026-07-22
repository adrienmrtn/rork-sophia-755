import SwiftUI
import Supabase

struct SettingsView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AuthService.self) private var auth
    let progressManager: ProgressManager
    let store: StoreViewModel
    var onShowPaywall: (() -> Void)? = nil
    var onResetOnboarding: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil
    @State private var showAccount: Bool = false
    @State private var showResetAlert: Bool = false
    @State private var showResetOnboardingAlert: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPrivacy: Bool = false
    @State private var showFeedback: Bool = false
    @State private var showAmbassador: Bool = false
    @State private var hapticTrigger: Int = 0

    private static let destructive = Color(red: 0.80, green: 0.31, blue: 0.31)
    private static let destructiveTint = Color(red: 0.965, green: 0.925, blue: 0.925)

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "66"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.canvas.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        titleBar
                            .padding(.horizontal, 20)
                            .padding(.top, 4)

                        accountSection

                        section(languageManager.text("language.section")) {
                            HStack {
                                Spacer(minLength: 0)
                                LanguagePickerControl()
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 20)
                        }

                        progressionSection

                        if !store.isPremium {
                            premiumSection
                        }

                        dataSection

                        ambassadorBanner
                            .padding(.horizontal, 20)

                        helpSection

                        legalSection

                        aboutSection

                        #if DEBUG
                        developerSection
                        #endif

                        Text(languageManager.text("settings.footer"))
                            .font(DS.sans(.caption, .medium))
                            .foregroundStyle(DS.inkTertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                            .padding(.bottom, 32)
                    }
                }
                .scrollIndicators(.hidden)
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
            .sheet(isPresented: $showAccount) { AccountView() }
            .sheet(isPresented: $showTerms) { TermsView() }
            .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
            .sheet(isPresented: $showFeedback) { FeedbackView(isPremium: store.isPremium) }
            .sheet(isPresented: $showAmbassador) { AmbassadorView() }
        }
    }

    // MARK: - Title

    private var titleBar: some View {
        HStack {
            Text(languageManager.text("settings.title"))
                .font(DS.title(.largeTitle, .semibold))
                .foregroundStyle(DS.ink)
            Spacer()
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.jakarta(size: 15, weight: .medium))
                        .foregroundStyle(DS.inkSecondary)
                        .frame(width: 40, height: 40)
                        .background(DS.surface, in: Circle())
                        .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
                }
                .buttonStyle(SoftPressButtonStyle())
            }
        }
    }

    // MARK: - Sections

    private var accountSection: some View {
        section(languageManager.text("account.title")) {
            groupedCard {
                if auth.isSignedIn {
                    actionRow(
                        icon: "person.crop.circle.fill",
                        title: auth.currentUser?.email ?? languageManager.text("account.signedIn.title"),
                        subtitle: languageManager.text("account.manage.subtitle")
                    ) {
                        hapticTrigger += 1
                        showAccount = true
                    }
                } else {
                    actionRow(
                        icon: "person.crop.circle.badge.plus",
                        title: languageManager.text("account.create.title"),
                        subtitle: languageManager.text("account.create.subtitle")
                    ) {
                        hapticTrigger += 1
                        showAccount = true
                    }
                }
            }
        }
    }

    private var progressionSection: some View {
        section(languageManager.text("settings.section.progress")) {
            groupedCard {
                statRow(
                    icon: "checkmark.circle",
                    title: String(format: languageManager.text("settings.courses.completed"), progressManager.completedCount),
                    subtitle: String(format: languageManager.text("settings.courses.available"), ContentCatalog.activeCourses.count)
                )
                if progressManager.streak > 0 {
                    rowDivider
                    statRow(
                        icon: "flame",
                        title: String(format: languageManager.text("settings.streak.title"), progressManager.streak),
                        subtitle: languageManager.text("settings.streak.subtitle")
                    )
                }
            }
        }
    }

    private var premiumSection: some View {
        section(languageManager.text("settings.section.premium")) {
            Button {
                hapticTrigger += 1
                onShowPaywall?()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "crown.fill")
                        .font(.jakarta(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(.white.opacity(0.18), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(languageManager.text("settings.premium.title"))
                            .font(DS.title(.headline, .semibold))
                            .foregroundStyle(.white)
                        Text(languageManager.text("settings.premium.subtitle"))
                            .font(DS.sans(.caption, .medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.right")
                        .font(.jakarta(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DS.accent, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                .padding(.horizontal, 20)
            }
            .buttonStyle(SoftPressButtonStyle())
        }
    }

    private var dataSection: some View {
        section(languageManager.text("settings.section.data")) {
            groupedCard {
                actionRow(
                    icon: "arrow.counterclockwise",
                    title: languageManager.text("settings.reset.title"),
                    destructive: true
                ) {
                    hapticTrigger += 1
                    showResetAlert = true
                }
            }
        }
    }

    private var helpSection: some View {
        section(languageManager.text("settings.section.help")) {
            groupedCard {
                actionRow(
                    icon: "bubble.left.and.bubble.right",
                    title: languageManager.text("settings.feedback.title"),
                    subtitle: languageManager.text("settings.feedback.subtitle")
                ) {
                    hapticTrigger += 1
                    showFeedback = true
                }
            }
        }
    }

    private var legalSection: some View {
        section(languageManager.text("settings.section.legal")) {
            groupedCard {
                actionRow(icon: "doc.text", title: languageManager.text("settings.terms.title")) {
                    hapticTrigger += 1
                    showTerms = true
                }
                rowDivider
                actionRow(icon: "hand.raised", title: languageManager.text("settings.privacy.title")) {
                    hapticTrigger += 1
                    showPrivacy = true
                }
                if !store.isPremium {
                    rowDivider
                    actionRow(icon: "arrow.clockwise", title: languageManager.text("settings.restore.title")) {
                        hapticTrigger += 1
                        Task { await store.restore() }
                    }
                }
            }
        }
    }

    private var aboutSection: some View {
        section(languageManager.text("settings.section.about")) {
            groupedCard {
                infoRow(label: languageManager.text("settings.about.version"), value: appVersionString)
                rowDivider
                infoRow(label: languageManager.text("settings.about.courses"), value: "\(ContentCatalog.activeCourses.count)")
            }
        }
    }

    #if DEBUG
    private var developerSection: some View {
        section(languageManager.text("settings.section.developer")) {
            groupedCard {
                if onResetOnboarding != nil {
                    actionRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: languageManager.text("settings.debug.resetOnboarding"),
                        destructive: true
                    ) {
                        hapticTrigger += 1
                        showResetOnboardingAlert = true
                    }
                    rowDivider
                }
                actionRow(
                    icon: "calendar.badge.minus",
                    title: languageManager.text("settings.debug.resetDaily"),
                    subtitle: progressManager.hasClaimedDailyFreeCourse
                        ? languageManager.text("settings.debug.daily.done")
                        : languageManager.text("settings.debug.daily.pending")
                ) {
                    hapticTrigger += 1
                    progressManager.resetDailyCourseFlag()
                }
            }
        }
    }
    #endif

    // MARK: - Ambassador banner

    private var ambassadorBanner: some View {
        Button {
            hapticTrigger += 1
            showAmbassador = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.jakarta(size: 18, weight: .medium))
                    .foregroundStyle(DS.accentSoft)
                    .frame(width: 44, height: 44)
                    .background(DS.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(DS.hairline, lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(languageManager.text("settings.ambassador.banner.badge").uppercased())
                        .font(DS.sans(.caption2, .semibold))
                        .foregroundStyle(DS.accentSoft)
                        .tracking(1.0)
                    Text(languageManager.text("settings.ambassador.banner.title"))
                        .font(DS.title(.headline, .semibold))
                        .foregroundStyle(DS.ink)
                    Text(languageManager.text("settings.ambassador.banner.subtitle"))
                        .font(DS.sans(.caption, .medium))
                        .foregroundStyle(DS.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.jakarta(size: 13, weight: .semibold))
                    .foregroundStyle(DS.inkTertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.accentTint, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        }
        .buttonStyle(SoftPressButtonStyle())
    }

    // MARK: - Building blocks

    @ViewBuilder
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

    @ViewBuilder
    private func groupedCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .dsCard(padding: 0)
        .padding(.horizontal, 20)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(DS.hairline)
            .frame(height: 1)
            .padding(.leading, 66)
    }

    private func iconBadge(name: String, tint: Color = DS.accentSoft, bg: Color = DS.accentTint) -> some View {
        Image(systemName: name)
            .font(.jakarta(size: 16, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: 38, height: 38)
            .background(bg, in: Circle())
    }

    private func statRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            iconBadge(name: icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DS.title(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                Text(subtitle)
                    .font(DS.sans(.caption, .medium))
                    .foregroundStyle(DS.inkSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private func actionRow(
        icon: String,
        title: String,
        subtitle: String? = nil,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconBadge(
                    name: icon,
                    tint: destructive ? Self.destructive : DS.accentSoft,
                    bg: destructive ? Self.destructiveTint : DS.accentTint
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DS.sans(.body, .medium))
                        .foregroundStyle(destructive ? Self.destructive : DS.ink)
                    if let subtitle {
                        Text(subtitle)
                            .font(DS.sans(.caption, .medium))
                            .foregroundStyle(DS.inkSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.jakarta(size: 12, weight: .semibold))
                    .foregroundStyle(DS.inkTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(SoftPressButtonStyle())
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(DS.sans(.body, .medium))
                .foregroundStyle(DS.ink)
            Spacer()
            Text(value)
                .font(DS.sans(.body, .medium))
                .foregroundStyle(DS.inkSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }
}
