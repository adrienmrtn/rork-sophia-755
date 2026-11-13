import StoreKit
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
    @State private var showFeatureRequest: Bool = false
    @State private var showShare: Bool = false
    /// Page ambassadeur du site, ouverte dans Safari intégré depuis la bannière.
    @State private var creatorsPage: CreatorsPage? = nil
    @State private var showAudioDownloads: Bool = false
    /// La page « Invite un ami » (parrainage), poussée depuis la ligne de la section Compte.
    @State private var showInvite: Bool = false
    @State private var hapticTrigger: Int = 0
    @State private var reminderHour: Int = DailyCourseReminder.storedHour
    /// Écran de test des notifications, ouvert depuis la section développeur (Debug).
    @State private var showDebugNotifications: Bool = false
    /// Set only by the developer section, which is itself behind `#if DEBUG`.
    @State private var debugPaywall: SophiaPaywallContext? = nil
    /// Variante du paywall cours que le raccourci développeur montre ; elle alterne à chaque
    /// ouverture (la première est `bonhomme`).
    @State private var debugCourseVariant: CoursePaywallVariant = .reviews
    /// Idem pour le paywall de réduction (la première ouverture montre `percent`).
    @State private var debugDiscountVariant: DiscountPaywallVariant = .graduate
    /// Le @ du lecteur, pour la carte d'identité en tête.
    @Bindable private var social = SocialService.shared

    private static let destructive = DS.danger
    /// Bleu nuit de la carte Premium (maquette).
    private static let premiumNavy = Color(red: 0.102, green: 0.227, blue: 0.420)
    /// Crème et encre de l'illustration « ambassadeur » (papier découpé du site).
    private static let posterCream = Color(red: 0.984, green: 0.937, blue: 0.788)
    private static let posterInk = Color(red: 0.086, green: 0.149, blue: 0.239)

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
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            titleBar
                            identityCard
                                .dsStagger(0, step: 0.04)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                        preferenceSections
                        membershipSections
                        supportSections

                        Text(languageManager.text("settings.footer"))
                            .font(DS.sans(.footnote))
                            .foregroundStyle(DS.inkSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 32)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
            .navigationDestination(isPresented: $showInvite) {
                // L'offre, ou la seule saisie du code d'un ami tant qu'elle n'est pas ouverte.
                InviteFriendView(
                    progressManager: progressManager,
                    showsOffer: InviteFriend.showsOffer(progressManager: progressManager, isPremium: store.isPremium)
                )
                .toolbar(.hidden, for: .navigationBar)
            }
            // Où en est le parrainage (récompense, code d'un ami encore accepté) pour la ligne.
            .task(id: auth.isSignedIn) { await ReferralService.shared.sync() }
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
            .sheet(isPresented: $showFeatureRequest) { FeedbackView(isPremium: store.isPremium, initialCategory: .feature) }
            .sheet(isPresented: $showShare) { ShareSophiaSheet().sophiaSheetChrome() }
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

    // MARK: - Groupes de sections

    /// Compte, langue, mode de lecture, progression, rappel.
    @ViewBuilder
    private var preferenceSections: some View {
        accountSection
            .dsStagger(1, step: 0.04)

        section(languageManager.text("language.section")) {
            HStack {
                Spacer(minLength: 0)
                LanguagePickerControl()
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
        }
        .dsStagger(2, step: 0.04)

        readingSection
            .dsStagger(3, step: 0.04)

        progressionSection
            .dsStagger(4, step: 0.04)

        // Pendant l'essai gratuit, aucune notification : pas de réglage non plus.
        if !store.isInFreeTrial {
            reminderSection
                .dsStagger(5, step: 0.04)
        }
    }

    /// Premium ou abonnement, audio, données, bannière ambassadeur.
    @ViewBuilder
    private var membershipSections: some View {
        if !store.isPremium {
            premiumSection
                .dsStagger(6, step: 0.04)
        } else {
            subscriptionSection
                .dsStagger(6, step: 0.04)
        }

        if store.isPremium || !CourseAudioDownloads.shared.downloaded.isEmpty {
            audioSection
                .dsStagger(7, step: 0.04)
        }

        dataSection
            .dsStagger(8, step: 0.04)

        ambassadorBanner
            .padding(.horizontal, 20)
            .dsStagger(9, step: 0.04)
    }

    /// Aide, légal, à propos, et la section développeur en Debug.
    @ViewBuilder
    private var supportSections: some View {
        helpSection
            .dsStagger(10, step: 0.04)

        legalSection
            .dsStagger(10, step: 0.04)

        aboutSection
            .dsStagger(10, step: 0.04)

        #if DEBUG
        developerSection
        #endif
    }

    // MARK: - Title

    /// Le titre centré, la croix à droite (et son pendant vide à gauche, pour le centrage).
    private var titleBar: some View {
        HStack(spacing: 10) {
            Color.clear.frame(width: 44, height: 44)
            Spacer(minLength: 0)
            Text(languageManager.text("settings.title"))
                .font(DS.sans(.callout, .heavy))
                .foregroundStyle(DS.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            if let onDismiss {
                ProfileRoundButton(
                    systemImage: "xmark",
                    accessibilityLabel: languageManager.text("common.close"),
                    action: onDismiss
                )
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - Carte d'identité

    /// « @pseudo · membre depuis … » : seulement ce que l'app connaît déjà, rien sinon.
    private var identityDetail: String? {
        var parts: [String] = []
        if auth.isSignedIn, let handle = social.myHandle, !handle.isEmpty {
            parts.append("@\(handle)")
        }
        if let since = ProfileIdentity.memberSince(progressManager: progressManager, language: languageManager.current) {
            parts.append(String(format: languageManager.text("profile.member.since"), since))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// La carte d'identité du lecteur : avatar, titre de rang, @ et ancienneté. Elle ouvre le compte.
    private var identityCard: some View {
        let rankTitle: String = ProfileIdentity.rankTitle(languageManager: languageManager)
        let initialSource: String = social.myHandle ?? rankTitle
        return Button {
            hapticTrigger += 1
            showAccount = true
        } label: {
            HStack(spacing: 14) {
                AvatarCircle(
                    avatarId: progressManager.avatarId,
                    initial: String(initialSource.prefix(1)).uppercased(),
                    size: 56
                )
                VStack(alignment: .leading, spacing: 3) {
                    Text(rankTitle)
                        .font(DS.title(.headline, .semibold))
                        .foregroundStyle(DS.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let identityDetail {
                        Text(identityDetail)
                            .font(DS.sans(.footnote))
                            .foregroundStyle(DS.inkSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 4)
                rowChevron
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .dsCard(padding: 0)
            .contentShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        }
        .buttonStyle(PressableStyle(haptic: false))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Sections

    /// Pas à pas ou par pages : le même choix que dans l'en-tête du lecteur.
    private var readingSection: some View {
        section(languageManager.text("course.readingMode")) {
            ReadingModePickerControl()
                .padding(.horizontal, 20)
        }
    }

    private var accountSection: some View {
        section(languageManager.text("account.title")) {
            groupedCard {
                if auth.isSignedIn {
                    actionRow(
                        icon: "person",
                        title: auth.currentUser?.email ?? languageManager.text("account.signedIn.title"),
                        subtitle: languageManager.text("account.manage.subtitle")
                    ) {
                        hapticTrigger += 1
                        showAccount = true
                    }
                } else {
                    actionRow(
                        icon: "person",
                        title: languageManager.text("account.create.title"),
                        subtitle: languageManager.text("account.create.subtitle")
                    ) {
                        hapticTrigger += 1
                        showAccount = true
                    }
                }
                inviteRow
            }
        }
    }

    /// Le parrainage (docs/parrainage.md), qui a quitté le profil : « Inviter un ami » une fois
    /// le premier cours terminé ; avant cela, un compte tout neuf n'a que « Tu as le code d'un
    /// ami ? » ; sinon aucune ligne.
    @ViewBuilder
    private var inviteRow: some View {
        let entry: InviteFriend.SettingsEntry? = InviteFriend.settingsEntry(
            progressManager: progressManager,
            isPremium: store.isPremium,
            isSignedIn: auth.isSignedIn
        )
        if let entry {
            rowDivider
            switch entry {
            case .offer:
                actionRow(
                    icon: "gift",
                    title: languageManager.text("invite.cta"),
                    subtitle: ReferralService.shared.rewarded
                        ? String(format: languageManager.text("invite.status.earned"), progressManager.referralCreditsRemaining)
                        : languageManager.text("invite.card.subtitle")
                ) {
                    hapticTrigger += 1
                    showInvite = true
                }
            case .friendCode:
                actionRow(
                    icon: "gift",
                    title: languageManager.text("invite.enter.title")
                ) {
                    hapticTrigger += 1
                    showInvite = true
                }
            }
        }
    }

    private var progressionSection: some View {
        section(languageManager.text("settings.section.progress")) {
            groupedCard {
                statRow(
                    icon: "book",
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
                HStack(spacing: 12) {
                    rowIcon("bell")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(languageManager.text("settings.reminder.title"))
                            .font(DS.sans(.subheadline, .bold))
                            .foregroundStyle(DS.ink)
                        Text(languageManager.text("settings.reminder.subtitle"))
                            .font(DS.sans(.footnote))
                            .foregroundStyle(DS.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    reminderHourMenu
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .onChange(of: reminderHour) { _, hour in
            Haptics.select()
            DailyCourseReminder.storedHour = hour
            DailyCourseReminder.refresh()
        }
    }

    /// L'heure choisie sur une pastille bleu pâle ; la toucher ouvre le menu des heures.
    private var reminderHourMenu: some View {
        Menu {
            Picker(languageManager.text("settings.reminder.title"), selection: $reminderHour) {
                ForEach(5...23, id: \.self) { hour in
                    Text(OnboardingV2ReadingTime.label(hour: hour)).tag(hour)
                }
            }
        } label: {
            Text(OnboardingV2ReadingTime.label(hour: reminderHour))
                .font(DS.sans(.subheadline, .heavy))
                .foregroundStyle(DS.ink)
                .monospacedDigit()
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(DS.accentTint))
                .contentTransition(.numericText())
                .animation(DS.Motion.snappy, value: reminderHour)
        }
        .accessibilityLabel(Text(languageManager.text("settings.reminder.title")))
        .accessibilityValue(Text(OnboardingV2ReadingTime.label(hour: reminderHour)))
    }

    private var premiumSection: some View {
        section(languageManager.text("settings.section.premium")) {
            Button {
                hapticTrigger += 1
                onShowPaywall?()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DS.warm)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(languageManager.text("settings.premium.title"))
                            .font(DS.sans(.callout, .heavy))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                        Text(languageManager.text("settings.premium.subtitle"))
                            .font(DS.sans(.footnote))
                            .foregroundStyle(.white.opacity(0.82))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.forward")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Self.premiumNavy, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                .padding(.horizontal, 20)
            }
            .buttonStyle(PressableStyle(haptic: false))
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
                    icon: "arrow.down.to.line",
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
                    icon: "square.and.arrow.up",
                    title: languageManager.text("share.card.title"),
                    subtitle: languageManager.text("share.card.subtitle")
                ) {
                    hapticTrigger += 1
                    showShare = true
                }
                rowDivider
                actionRow(
                    icon: "pencil",
                    title: languageManager.text("settings.feedback.title"),
                    subtitle: languageManager.text("settings.feedback.subtitle")
                ) {
                    hapticTrigger += 1
                    showFeedback = true
                }
                rowDivider
                actionRow(
                    icon: "star",
                    title: languageManager.text("settings.featureRequest.title"),
                    subtitle: languageManager.text("settings.featureRequest.subtitle")
                ) {
                    hapticTrigger += 1
                    showFeatureRequest = true
                }
            }
        }
    }

    private var legalSection: some View {
        section(languageManager.text("settings.section.legal")) {
            groupedCard {
                actionRow(title: languageManager.text("settings.terms.title")) {
                    hapticTrigger += 1
                    showTerms = true
                }
                rowDivider
                actionRow(title: languageManager.text("settings.privacy.title")) {
                    hapticTrigger += 1
                    showPrivacy = true
                }
                if !store.isPremium {
                    rowDivider
                    actionRow(title: languageManager.text("settings.restore.title")) {
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
                rowDivider
                // Relit le catalogue en ligne sans attendre le rafraîchissement automatique.
                actionRow(
                    title: languageManager.text("settings.debug.catalogRefresh")
                ) {
                    hapticTrigger += 1
                    Task { await CatalogStore.shared.refresh(language: languageManager.current, force: true) }
                }
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
                    icon: "externaldrive.badge.icloud",
                    title: languageManager.text("settings.debug.catalog"),
                    subtitle: CatalogStore.shared.debugSummary(language: languageManager.current)
                ) {
                    hapticTrigger += 1
                    Task { await CatalogStore.shared.refresh(language: languageManager.current, force: true) }
                }
                rowDivider
                actionRow(
                    icon: "flame.fill",
                    title: languageManager.text("settings.debug.discountPaywall")
                ) {
                    hapticTrigger += 1
                    // Une ouverture sur deux pour chaque variante du test A/B, pour voir les deux.
                    debugDiscountVariant = debugDiscountVariant == .percent ? .graduate : .percent
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
                    // Une ouverture sur deux pour chaque variante du test A/B, pour voir les deux.
                    debugCourseVariant = debugCourseVariant == .bonhomme ? .reviews : .bonhomme
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
                onDismissed: { debugPaywall = nil },
                forcedVariant: debugCourseVariant
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
                onDismissed: { debugPaywall = nil },
                forcedVariant: debugDiscountVariant
            )
        }
    }
    #endif

    // MARK: - Ambassador banner

    /// Ouvre directement le Hub des créateurs dans la langue de l'app
    /// (`vik-studios-creators.com/<langue>`) : plus d'UGC, plus de choix de rôle ni de
    /// formulaire dans l'app.
    private func openAmbassadorPage() {
        guard let url = AppConfig.creatorHubURL(language: languageManager.current) else { return }
        creatorsPage = CreatorsPage(url: url)
    }

    /// Bannière « Deviens ambassadeur » dans le style papier du site : l'illustration à gauche,
    /// la promesse en une ligne, et la sortie vers le site.
    private var ambassadorBanner: some View {
        Button {
            hapticTrigger += 1
            openAmbassadorPage()
        } label: {
            ambassadorText
                .padding(14)
                .padding(.leading, 110)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(alignment: .leading) {
                    Color.clear
                        .frame(width: 110)
                        .frame(maxHeight: .infinity)
                        .overlay {
                            Image("ambassador_poster")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                        .clipped()
                        .accessibilityHidden(true)
                }
                .background(Self.posterCream)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        }
        .buttonStyle(PressableStyle(haptic: false))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isLink)
    }

    private var ambassadorText: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(languageManager.text("settings.ambassador.banner.title"))
                .font(DS.sans(.callout, .heavy))
                .foregroundStyle(Self.posterInk)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Text(languageManager.text("settings.ambassador.banner.subtitle"))
                .font(DS.sans(.footnote))
                .foregroundStyle(Self.posterInk)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Text(languageManager.text("settings.ambassador.cta"))
                    .font(DS.sans(.footnote, .bold))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous).fill(Self.posterInk))
            .padding(.top, 2)
        }
    }

    // MARK: - Building blocks

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ProfileGroupLabel(text: title)
                .padding(.horizontal, 20)
            content()
        }
    }

    @ViewBuilder
    private func groupedCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .dsCard(padding: 0)
        .padding(.horizontal, 20)
    }

    private var rowDivider: some View {
        ProfileRowDivider()
            .padding(.horizontal, 16)
    }

    /// Pictogramme de rangée : au trait, bleu (rouge pour une action destructrice), sans fond.
    private func rowIcon(_ name: String, tint: Color = DS.accent) -> some View {
        Image(systemName: name)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 24)
            .accessibilityHidden(true)
    }

    private var rowChevron: some View {
        Image(systemName: "chevron.forward")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(DS.inkSecondary)
            .accessibilityHidden(true)
    }

    private func statRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            rowIcon(icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(DS.sans(.footnote))
                    .foregroundStyle(DS.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    /// Une rangée d'action : pression douce, pictogramme facultatif, chevron (sauf action destructrice).
    private func actionRow(
        icon: String? = nil,
        title: String,
        subtitle: String? = nil,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon {
                    rowIcon(icon, tint: destructive ? Self.destructive : DS.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(destructive ? Self.destructive : DS.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle {
                        Text(subtitle)
                            .font(DS.sans(.footnote))
                            .foregroundStyle(DS.inkSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                if !destructive {
                    rowChevron
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        // La vibration vient de `hapticTrigger`, posé par chaque action.
        .buttonStyle(ProfileRowPressStyle(haptic: false))
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(DS.ink)
            Spacer(minLength: 8)
            Text(value)
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

/// Page créateurs à ouvrir dans Safari intégré.
struct CreatorsPage: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
