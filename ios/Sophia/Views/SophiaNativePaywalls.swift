import SwiftUI
import RevenueCat

// MARK: - Shared legal row (restore · terms · privacy)

/// Compact legal / restore row shared by the native in-app paywalls, styled with the
/// app design system (`DS`) rather than the onboarding palette.
private struct PaywallLegalRow: View {
    @Environment(LanguageManager.self) private var languageManager
    var onRestore: () -> Void
    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        HStack(spacing: 6) {
            Button(languageManager.text("paywall.restore"), action: onRestore)
            Text("·").foregroundStyle(DS.inkTertiary)
            Button(languageManager.text("settings.terms.title")) { showTerms = true }
            Text("·").foregroundStyle(DS.inkTertiary)
            Button(languageManager.text("settings.privacy.title")) { showPrivacy = true }
        }
        .font(DS.sans(.caption2, .medium))
        .foregroundStyle(DS.inkTertiary)
        .sheet(isPresented: $showTerms) { TermsView() }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
    }
}

// MARK: - Live countdown helpers

private enum PaywallCountdown {
    /// Formats a positive seconds count as HH:MM:SS (or MM:SS below one hour).
    static func format(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, sec)
        }
        return String(format: "%02d:%02d", m, sec)
    }
}

// MARK: - Standard paywall (quizz + debloquer_cours)

/// Minimalist, single-offer native paywall used for the `quizz` and `debloquer_cours`
/// contexts. Shows one annual plan (39,99 €/an, 3-day free trial) with the price kept small
/// and a prominent "Débloquer gratuitement" CTA.
///
/// For `debloquer_cours` it additionally frames the moment: the free user has used up their
/// one free course of the day, with a live countdown to the next local midnight and (when
/// available) the thumbnail of the course they were reading.
struct SophiaStandardPaywall: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    let context: SophiaPaywallContext
    let store: StoreViewModel
    var course: Course? = nil
    /// Seconds until the daily free course resets (local midnight). Only used for
    /// `debloquer_cours`; pass `nil` to hide the countdown.
    var secondsUntilReset: Int? = nil
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    var onDismissed: (() -> Void)? = nil

    @State private var purchasing = false
    @State private var appeared = false
    @State private var presentedAt: Date?
    @State private var didTrackDismiss = false
    @State private var courseThumb: UIImage?

    private var isCourseUnlock: Bool { context == .debloquerCours }

    private var prices: StoreViewModel.PaywallPriceDisplay {
        store.paywallPriceDisplay(language: languageManager.current)
    }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    closeButton
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer(minLength: 8)

                VStack(spacing: 20) {
                    hero
                    headline.padding(.horizontal, 28)
                    if isCourseUnlock, let secondsUntilReset {
                        resetCountdown(seconds: secondsUntilReset)
                    }
                    benefits.padding(.horizontal, 28)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

                Spacer(minLength: 8)

                bottomBar
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }
        }
        .onAppear {
            presentedAt = Date()
            didTrackDismiss = false
            AnalyticsService.trackPaywallViewed(context: context.rawValue, triggerCourseId: course?.id)
            if let course { courseThumb = CourseImageMap.loadImage(for: course.id) }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
        }
        .task {
            if store.offerings == nil { await store.fetchOfferings() }
        }
        .onDisappear { trackDismissIfNeeded() }
    }

    // MARK: Hero

    @ViewBuilder
    private var hero: some View {
        if isCourseUnlock, let courseThumb {
            Image(uiImage: courseThumb)
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipShape(.rect(cornerRadius: DS.Radius.control))
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                        .strokeBorder(DS.hairline, lineWidth: 1)
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "lock.fill")
                        .font(.jakarta(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(DS.accent, in: Circle())
                        .overlay { Circle().strokeBorder(.white, lineWidth: 2) }
                        .offset(x: 8, y: 8)
                }
                .dsSoftShadow()
        } else {
            Image(systemName: isCourseUnlock ? "book.closed.fill" : "checklist")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(DS.accent)
                .frame(width: 92, height: 92)
                .background(DS.accentTint, in: Circle())
        }
    }

    // MARK: Headline

    private var headline: some View {
        VStack(spacing: 10) {
            Text(titleText)
                .font(DS.title(.title, .heavy))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitleText)
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var titleText: String {
        if isCourseUnlock {
            return languageManager.text("paywall.course.title")
        }
        return languageManager.text("paywall.quiz.title")
    }

    private var subtitleText: String {
        if isCourseUnlock {
            if let course {
                return String(format: languageManager.text("paywall.course.subtitle.named"), course.title)
            }
            return languageManager.text("paywall.course.subtitle")
        }
        return languageManager.text("paywall.quiz.subtitle")
    }

    // MARK: Reset countdown ("reviens demain")

    private func resetCountdown(seconds: Int) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            // Recompute a decreasing value locally so the label ticks live without touching
            // the model each second. Anchored to the seconds passed in at present time.
            let elapsed = Int(timeline.date.timeIntervalSince(presentedAt ?? timeline.date))
            let remaining = max(0, seconds - elapsed)
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.jakarta(size: 13, weight: .bold))
                VStack(alignment: .leading, spacing: 1) {
                    Text(languageManager.text("paywall.course.comeBack"))
                        .font(DS.sans(.caption2, .semibold))
                        .foregroundStyle(DS.inkSecondary)
                    Text(PaywallCountdown.format(remaining))
                        .font(DS.sans(.headline, .bold))
                        .monospacedDigit()
                        .foregroundStyle(DS.ink)
                        .contentTransition(.numericText(countsDown: true))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DS.surface, in: Capsule())
            .overlay { Capsule().strokeBorder(DS.hairline, lineWidth: 1) }
        }
    }

    // MARK: Benefits

    private var benefits: some View {
        VStack(spacing: 10) {
            ForEach(benefitKeys, id: \.self) { key in
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.jakarta(size: 16, weight: .semibold))
                        .foregroundStyle(DS.success)
                    Text(languageManager.text(key))
                        .font(DS.sans(.subheadline, .medium))
                        .foregroundStyle(DS.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var benefitKeys: [String] {
        [
            "paywall.benefit.unlimited",
            "paywall.benefit.quiz",
            "paywall.benefit.allSubjects",
        ]
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Text(priceLine)
                .font(DS.sans(.footnote, .medium))
                .foregroundStyle(DS.inkTertiary)
                .multilineTextAlignment(.center)

            Button(action: purchase) {
                HStack(spacing: 8) {
                    if purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "lock.open.fill")
                            .font(.jakarta(size: 15, weight: .bold))
                        Text(languageManager.text("paywall.cta.unlockFree"))
                    }
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .disabled(purchasing)
            .padding(.horizontal, 24)

            PaywallLegalRow(onRestore: restore)
                .padding(.bottom, 14)
        }
    }

    /// e.g. "Essai gratuit de 3 jours, puis 39,99 €/an (3,33 €/mois)."
    private var priceLine: String {
        String(
            format: languageManager.text("paywall.price.trialThenYearly"),
            prices.yearlyPrice, prices.yearlyPerMonth
        )
    }

    private var closeButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            trackDismissIfNeeded()
            dismiss()
            onDismissed?()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.inkSecondary)
                .frame(width: 40, height: 40)
                .background(DS.surface, in: Circle())
                .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
        }
    }

    // MARK: Actions

    private func purchase() {
        guard !purchasing else { return }
        guard let package = store.annualPackage(forOfferingIdentifier: context.rawValue) else {
            Task { await store.fetchOfferings() }
            return
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        purchasing = true
        Task {
            let ok = await store.purchase(package: package)
            purchasing = false
            if ok {
                AnalyticsService.trackPurchaseCompleted(
                    context: context.rawValue,
                    offeringId: store.offering(identifier: context.rawValue)?.identifier,
                    packageId: package.identifier
                )
                onPurchased()
            }
        }
    }

    private func restore() {
        Task {
            await store.restore()
            if store.isPremium { onRestored() }
        }
    }

    private func trackDismissIfNeeded() {
        guard !didTrackDismiss else { return }
        didTrackDismiss = true
        let duration = Int(Date().timeIntervalSince(presentedAt ?? Date()))
        AnalyticsService.trackPaywallDismissed(context: context.rawValue, durationSeconds: max(0, duration))
    }
}

// MARK: - Training paywall (quizz offering)

/// Dedicated native paywall for the `quizz` context, opened from the training tab's
/// "Débloquer" CTA. Rather than a generic feature list, it *sells the training method*:
/// it explains what training is, shows spaced-repetition statistics, and frames spaced
/// repetition as the most proven way to anchor lasting knowledge. Purchases still attribute
/// to the `quizz` RevenueCat offering (single annual plan, 3-day trial).
struct SophiaTrainingPaywall: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    let store: StoreViewModel
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    var onDismissed: (() -> Void)? = nil

    @State private var purchasing = false
    @State private var appeared = false
    @State private var presentedAt: Date?
    @State private var didTrackDismiss = false

    private let context = SophiaPaywallContext.entrainement

    private var prices: StoreViewModel.PaywallPriceDisplay {
        store.paywallPriceDisplay(language: languageManager.current)
    }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    closeButton
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 22) {
                        hero
                        headline.padding(.horizontal, 28)
                        stats.padding(.horizontal, 24)
                        howItWorks.padding(.horizontal, 24)
                        footnote.padding(.horizontal, 32)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                }
                .scrollIndicators(.hidden)

                bottomBar
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }
        }
        .onAppear {
            presentedAt = Date()
            didTrackDismiss = false
            AnalyticsService.trackPaywallViewed(context: context.rawValue)
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
        }
        .task {
            if store.offerings == nil { await store.fetchOfferings() }
        }
        .onDisappear { trackDismissIfNeeded() }
    }

    // MARK: Hero

    private var hero: some View {
        Image(systemName: "arrow.triangle.2.circlepath")
            .font(.system(size: 42, weight: .semibold))
            .foregroundStyle(DS.accent)
            .frame(width: 92, height: 92)
            .background(DS.accentTint, in: Circle())
    }

    // MARK: Headline

    private var headline: some View {
        VStack(spacing: 10) {
            Text(languageManager.text("paywall.training.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(languageManager.text("paywall.training.subtitle"))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Stats

    private var stats: some View {
        HStack(spacing: 12) {
            statCard(
                value: languageManager.text("paywall.training.stat1.value"),
                label: languageManager.text("paywall.training.stat1.label"),
                tint: DS.success
            )
            statCard(
                value: languageManager.text("paywall.training.stat2.value"),
                label: languageManager.text("paywall.training.stat2.label"),
                tint: DS.danger
            )
        }
    }

    private func statCard(value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.jakarta(size: 30, weight: .bold))
                .foregroundStyle(tint)
                .monospacedDigit()
            Text(label)
                .font(DS.sans(.caption, .medium))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
    }

    // MARK: How it works

    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(languageManager.text("paywall.training.how.title"))
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(DS.inkTertiary)
                .tracking(1.2)

            howStep(1, languageManager.text("paywall.training.how.step1"))
            howStep(2, languageManager.text("paywall.training.how.step2"))
            howStep(3, languageManager.text("paywall.training.how.step3"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
    }

    private func howStep(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(DS.accent, in: Circle())
            Text(text)
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Footnote

    private var footnote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.jakarta(size: 13, weight: .semibold))
                .foregroundStyle(DS.accentSoft)
            Text(languageManager.text("paywall.training.footnote"))
                .font(DS.sans(.caption, .medium))
                .foregroundStyle(DS.inkTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Text(priceLine)
                .font(DS.sans(.footnote, .medium))
                .foregroundStyle(DS.inkTertiary)
                .multilineTextAlignment(.center)

            Button(action: purchase) {
                HStack(spacing: 8) {
                    if purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "lock.open.fill")
                            .font(.jakarta(size: 15, weight: .bold))
                        Text(languageManager.text("paywall.cta.unlockFree"))
                    }
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .disabled(purchasing)
            .padding(.horizontal, 24)

            PaywallLegalRow(onRestore: restore)
                .padding(.bottom, 14)
        }
    }

    /// e.g. "Essai gratuit de 3 jours, puis 39,99 €/an (3,33 €/mois)."
    private var priceLine: String {
        String(
            format: languageManager.text("paywall.price.trialThenYearly"),
            prices.yearlyPrice, prices.yearlyPerMonth
        )
    }

    private var closeButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            trackDismissIfNeeded()
            dismiss()
            onDismissed?()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.inkSecondary)
                .frame(width: 40, height: 40)
                .background(DS.surface, in: Circle())
                .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
        }
    }

    // MARK: Actions

    private func purchase() {
        guard !purchasing else { return }
        guard let package = store.annualPackage(forOfferingIdentifier: context.offeringIdentifier) else {
            Task { await store.fetchOfferings() }
            return
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        purchasing = true
        Task {
            let ok = await store.purchase(package: package)
            purchasing = false
            if ok {
                AnalyticsService.trackPurchaseCompleted(
                    context: context.rawValue,
                    offeringId: store.offering(identifier: context.offeringIdentifier)?.identifier,
                    packageId: package.identifier
                )
                onPurchased()
            }
        }
    }

    private func restore() {
        Task {
            await store.restore()
            if store.isPremium { onRestored() }
        }
    }

    private func trackDismissIfNeeded() {
        guard !didTrackDismiss else { return }
        didTrackDismiss = true
        let duration = Int(Date().timeIntervalSince(presentedAt ?? Date()))
        AnalyticsService.trackPaywallDismissed(context: context.rawValue, durationSeconds: max(0, duration))
    }
}

// MARK: - Discount paywall (offre_discount)

/// Ultra-aggressive native flash-sale paywall for the `offre_discount` context.
/// Single annual plan from the `special_promo` offering (19,99 €/an, **no free trial**),
/// a big struck-through regular price, a savings badge, and a prominent 1-hour countdown
/// driven by `DiscountOfferManager` for urgency.
struct SophiaDiscountPaywall: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    let store: StoreViewModel
    /// Drives the live 60-minute countdown. Optional so previews / fallbacks still render.
    var discountManager: DiscountOfferManager? = nil
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    var onDismissed: (() -> Void)? = nil

    @State private var purchasing = false
    @State private var appeared = false
    @State private var pulse = false
    @State private var presentedAt: Date?
    @State private var didTrackDismiss = false

    private let context = SophiaPaywallContext.offreDiscount

    private var prices: StoreViewModel.DiscountPriceDisplay {
        store.discountPriceDisplay(language: languageManager.current)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DS.accent, DS.accentSoft],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    closeButton
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer(minLength: 8)

                VStack(spacing: 18) {
                    countdownChip
                    discountBadge
                    headline.padding(.horizontal, 28)
                    priceBlock
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)

                Spacer(minLength: 8)

                bottomBar
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }
        }
        .onAppear {
            presentedAt = Date()
            didTrackDismiss = false
            AnalyticsService.trackPaywallViewed(context: context.rawValue)
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .task {
            if store.offerings == nil { await store.fetchOfferings() }
        }
        .onDisappear { trackDismissIfNeeded() }
    }

    // MARK: Countdown chip

    private var countdownChip: some View {
        if let discountManager {
            _ = discountManager.tick
            return AnyView(chip(text: discountManager.formattedRemaining))
        } else {
            return AnyView(
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    let elapsed = Int(timeline.date.timeIntervalSince(presentedAt ?? timeline.date))
                    chip(text: PaywallCountdown.format(max(0, 3600 - elapsed)))
                }
            )
        }
    }

    private func chip(text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.jakarta(size: 14, weight: .black))
            Text(languageManager.text("paywall.discount.endsIn"))
                .font(DS.sans(.caption, .bold))
                .textCase(.uppercase)
                .tracking(0.5)
            Text(text)
                .font(DS.sans(.headline, .heavy))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(DS.danger, in: Capsule())
        .overlay { Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1) }
        .scaleEffect(pulse ? 1.04 : 1.0)
        .shadow(color: DS.danger.opacity(0.5), radius: pulse ? 16 : 8, y: 4)
    }

    // MARK: Discount badge

    @ViewBuilder
    private var discountBadge: some View {
        if let badge = prices.discountBadge {
            Text(badge)
                .font(DS.title(.largeTitle, .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 8)
                .background(.white.opacity(0.16), in: Capsule())
                .overlay { Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 1.5) }
        }
    }

    // MARK: Headline

    private var headline: some View {
        VStack(spacing: 10) {
            Text(languageManager.text("paywall.discount.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(languageManager.text("paywall.discount.subtitle"))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Price block

    private var priceBlock: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                if let regular = prices.regularYearly {
                    Text(regular)
                        .font(DS.sans(.title3, .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .strikethrough()
                }
                Text(prices.promoYearly)
                    .font(DS.title(.largeTitle, .heavy))
                    .foregroundStyle(.white)
            }
            Text(languageManager.text("paywall.discount.perYear"))
                .font(DS.sans(.footnote, .semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Button(action: purchase) {
                HStack(spacing: 8) {
                    if purchasing {
                        ProgressView().tint(DS.accent)
                    } else {
                        Image(systemName: "bolt.fill")
                            .font(.jakarta(size: 15, weight: .bold))
                        Text(languageManager.text("paywall.discount.cta"))
                    }
                }
            }
            .buttonStyle(DSPrimaryButtonStyle(fill: .white, foreground: DS.accent))
            .disabled(purchasing)
            .padding(.horizontal, 24)

            Text(languageManager.text("paywall.discount.noTrial"))
                .font(DS.sans(.caption2, .medium))
                .foregroundStyle(.white.opacity(0.7))

            legalRow.padding(.bottom, 14)
        }
    }

    private var legalRow: some View {
        HStack(spacing: 6) {
            Button(languageManager.text("paywall.restore"), action: restore)
        }
        .font(DS.sans(.caption2, .medium))
        .foregroundStyle(.white.opacity(0.7))
    }

    private var closeButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            trackDismissIfNeeded()
            dismiss()
            onDismissed?()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.15), in: Circle())
        }
    }

    // MARK: Actions

    private func purchase() {
        guard !purchasing else { return }
        guard let package = store.promoPackage else {
            Task { await store.fetchOfferings() }
            return
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        purchasing = true
        Task {
            let ok = await store.purchase(package: package)
            purchasing = false
            if ok {
                AnalyticsService.trackPurchaseCompleted(
                    context: context.rawValue,
                    offeringId: store.offering(identifier: "special_promo")?.identifier,
                    packageId: package.identifier
                )
                onPurchased()
            }
        }
    }

    private func restore() {
        Task {
            await store.restore()
            if store.isPremium { onRestored() }
        }
    }

    private func trackDismissIfNeeded() {
        guard !didTrackDismiss else { return }
        didTrackDismiss = true
        let duration = Int(Date().timeIntervalSince(presentedAt ?? Date()))
        AnalyticsService.trackPaywallDismissed(context: context.rawValue, durationSeconds: max(0, duration))
    }
}
