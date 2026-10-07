import StoreKit
import SwiftUI
import Supabase

struct SettingsView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AppearanceManager.self) private var appearance
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
    @State private var showShare: Bool = false
    /// Choix du rôle (UGC ou slideshow) avant d'ouvrir la page créateurs du site.
    @State private var showCreatorChoice: Bool = false
    @State private var creatorsPage: CreatorsPage? = nil
    @State private var showAudioDownloads: Bool = false
    @State private var hapticTrigger: Int = 0
    @State private var reminderHour: Int = DailyCourseReminder.storedHour
    /// Écran de test des notifications, ouvert depuis la section développeur (Debug).
    @State private var showDebugNotifications: Bool = false
    /// Set only by the developer section, which is itself behind `#if DEBUG`.
    @State private var debugPaywall: SophiaPaywallContext? = nil

    private static let destructive = DS.danger
    private static let destructiveTint = DS.dangerTint

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

                        appearanceSection

                        progressionSection

                        // Pendant l'essai gratuit, aucune notification : pas de réglage non plus.
                        if !store.isInFreeTrial {
                            reminderSection
                        }

                        if !store.isPremium {
                            premiumSection
                        } else {
                            subscriptionSection
                        }

                        if store.isPremium || !CourseAudioDownloads.shared.downloaded.isEmpty {
                            audioSection
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
            .fullScreenCover(item: $debugPaywall) { context in
                #if DEBUG
                // Presented from here rather than routed through ContentView: the real
                // paywalls come with their own triggers, counters and analytics, and a
                // shortcut for looking at a screen has no business spending any of that.
                debugPaywallScreen(context)
                    .preferredColorScheme(.light)
                #endif
            }
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
            .sheet(isPresented: $showTerms) { TermsView().sophiaSheetChrome() }
            .sheet(isPresented: $showPrivacy) { PrivacyPolicyView().sophiaSheetChrome() }
            .sheet(isPresented: $showFeedback) { FeedbackView(isPremium: store.isPremium) }
            .sheet(isPresented: $showShare) { ShareSophiaSheet().sophiaSheetChrome() }
            .confirmationDialog(
                languageManager.text("settings.ambassador.banner.title"),
                isPresented: $showCreatorChoice,
                titleVisibility: .visible
            ) {
                Button(languageManager.text("ambassador.role.ugc.title")) { openCreatorsPage(role: "ugc") }
                Button(languageManager.text("ambassador.role.slideshow.title")) { openCreatorsPage(role: "slideshow") }
                Button(languageManager.text("settings.reset.alert.cancel"), role: .cancel) { }
            }
            .sheet(item: $creatorsPage) { page in
                InAppSafariView(url: page.url)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showAudioDownloads) { AudioDownloadsView().sophiaSheetChrome() }
            .sheet(isPresented: $showDebugNotifications) {
                #if DEBUG
                DebugNotificationsView()
                #endif
            }
        }
        .sophiaColorScheme()
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

    private var appearanceSection: some View {
        section(languageManager.text("settings.section.appearance")) {
            VStack(alignment: .leading, spacing: 10) {
                AppearancePickerControl()
                    .padding(.horizontal, 20)
                if appearance.preference == .system {
                    Text(languageManager.text("settings.appearance.hint"))
                        .font(DS.sans(.caption, .medium))
                        .foregroundStyle(DS.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                }
            }
        }
    }

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

    /// L'heure de la question du jour, choisie dans l'onboarding, modifiable ici.
    private var reminderSection: some View {
        section(languageManager.text("settings.section.reminder")) {
            groupedCard {
                HStack(spacing: 14) {
                    iconBadge(name: "bell")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(languageManager.text("settings.reminder.title"))
                            .font(DS.sans(.body, .medium))
                            .foregroundStyle(DS.ink)
                        Text(languageManager.text("settings.reminder.subtitle"))
                            .font(DS.sans(.caption, .medium))
                            .foregroundStyle(DS.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Picker(languageManager.text("settings.reminder.title"), selection: $reminderHour) {
                        ForEach(5...23, id: \.self) { hour in
                            Text(OnboardingV2ReadingTime.label(hour: hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .tint(DS.accentSoft)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .onChange(of: reminderHour) { _, hour in
            DailyCourseReminder.storedHour = hour
            DailyCourseReminder.refresh()
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
                    Image(systemName: "arrow.forward")
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

    /// One row that opens Apple's subscription settings, the only place a subscription
    /// can be changed or cancelled.
    private var subscriptionSection: some View {
        section(languageManager.text("settings.section.subscription")) {
            groupedCard {
                actionRow(
                    icon: "creditcard",
                    title: languageManager.text("settings.subscription.manage.title"),
                    subtitle: languageManager.text("settings.subscription.manage.subtitle")
                ) {
                    hapticTrigger += 1
                    Self.openSubscriptionSettings()
                }
            }
        }
    }

    /// Opens Apple's subscription settings.
    ///
    /// `AppStore.showManageSubscriptions(in:)` needs a window scene, and this is
    /// presented from a sheet, so the scene is fetched rather than passed down. If
    /// there is none to be found the App Store URL is the honest fallback — better
    /// than a button that does nothing when the reader has decided to leave.
    @MainActor
    private static func openSubscriptionSettings() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else {
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                UIApplication.shared.open(url)
            }
            return
        }
        Task {
            try? await AppStore.showManageSubscriptions(in: scene)
        }
    }

    private var audioSection: some View {
        section(languageManager.text("settings.section.audio")) {
            groupedCard {
                actionRow(
                    icon: "arrow.down.circle",
                    title: languageManager.text("audio.downloads.title"),
                    subtitle: String(
                        format: languageManager.text("audio.downloads.subtitle"),
                        AudioFormat.bytes(CourseAudioDownloads.shared.totalBytes, locale: languageManager.locale)
                    )
                ) {
                    hapticTrigger += 1
                    showAudioDownloads = true
                }
            }
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
                    icon: "paperplane",
                    title: languageManager.text("share.card.title"),
                    subtitle: languageManager.text("share.card.subtitle")
                ) {
                    hapticTrigger += 1
                    showShare = true
                }
                rowDivider
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
                    icon: "bell.badge",
                    title: languageManager.text("settings.debug.notifications")
                ) {
                    hapticTrigger += 1
                    showDebugNotifications = true
                }
                rowDivider
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
                rowDivider
                actionRow(
                    icon: "flame.fill",
                    title: languageManager.text("settings.debug.discountPaywall")
                ) {
                    hapticTrigger += 1
                    debugPaywall = .offreDiscount
                }
                rowDivider
                actionRow(
                    icon: "questionmark.circle.fill",
                    title: languageManager.text("settings.debug.quizPaywall")
                ) {
                    hapticTrigger += 1
                    debugPaywall = .quizz
                }
                rowDivider
                actionRow(
                    icon: "lock.fill",
                    title: languageManager.text("settings.debug.courseUnlockPaywall")
                ) {
                    hapticTrigger += 1
                    debugPaywall = .debloquerCours
                }
                rowDivider
                actionRow(
                    icon: "headphones",
                    title: languageManager.text("settings.debug.audioPaywall")
                ) {
                    hapticTrigger += 1
                    debugPaywall = .audio
                }
            }
        }
    }

    /// The paywalls the developer section opens, with tracking off: a paywall opened to look
    /// at it would otherwise count as a real RevenueCat impression.
    ///
    /// Closing one just closes it. The comparison paywall that `CourseView` stacks on top of
    /// the quiz and course-unlock paywalls belongs to the course, not to the screen being
    /// looked at.
    @ViewBuilder
    private func debugPaywallScreen(_ context: SophiaPaywallContext) -> some View {
        switch context {
        case .quizz:
            SophiaQuizPaywall(
                store: store,
                tracksAnalytics: false,
                onPurchased: { debugPaywall = nil },
                onRestored: { debugPaywall = nil },
                onDismissed: { debugPaywall = nil }
            )
        case .debloquerCours:
            // A real course, so the thumbnail shows, and the real countdown to midnight.
            SophiaCourseUnlockPaywall(
                store: store,
                course: ContentCatalog.activeCourses.first,
                secondsUntilReset: progressManager.secondsUntilDailyReset(),
                tracksAnalytics: false,
                onPurchased: { debugPaywall = nil },
                onRestored: { debugPaywall = nil },
                onDismissed: { debugPaywall = nil }
            )
        case .audio:
            SophiaAudioPaywall(
                store: store,
                course: ContentCatalog.activeCourses.first,
                tracksAnalytics: false,
                onPurchased: { debugPaywall = nil },
                onRestored: { debugPaywall = nil },
                onDismissed: { debugPaywall = nil }
            )
        default:
            // The discount paywall, the only other one the section opens. With no manager
            // it runs its own 60-minute clock, so it still looks like itself.
            SophiaDiscountPaywall(
                store: store,
                tracksAnalytics: false,
                onPurchased: { debugPaywall = nil },
                onRestored: { debugPaywall = nil },
                onDismissed: { debugPaywall = nil }
            )
        }
    }
    #endif

    // MARK: - Ambassador banner

    /// Page du site pour le rôle choisi, dans Safari intégré. Laisse le choix se refermer
    /// avant d'ouvrir la page, sinon les deux présentations se gênent.
    private func openCreatorsPage(role: String) {
        guard let url = AppConfig.creatorsURL(role: role, language: languageManager.current) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            creatorsPage = CreatorsPage(url: url)
        }
    }

    /// Demande le rôle (UGC ou slideshow), puis ouvre sa page sur le site. Le formulaire
    /// intégré n'est plus affiché.
    private var ambassadorBanner: some View {
        Button {
            hapticTrigger += 1
            showCreatorChoice = true
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
                    Text(languageManager.text("settings.ambassador.banner.badge").uppercasedInApp())
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

                Image(systemName: "chevron.forward")
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
            Text(title.uppercasedInApp())
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
                Image(systemName: "chevron.forward")
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

/// Page créateurs à ouvrir dans Safari intégré.
struct CreatorsPage: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
