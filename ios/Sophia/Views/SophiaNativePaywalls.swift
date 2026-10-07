import SwiftUI
import RevenueCat

// MARK: - Shared legal row (restore · terms · privacy)

/// Compact legal / restore row shared by the native in-app paywalls, styled with the
/// app design system (`DS`) rather than the onboarding palette. Internal rather than
/// private so the paywalls that live in their own file (`SophiaAudioPaywall`) share it.
struct PaywallLegalRow: View {
    @Environment(LanguageManager.self) private var languageManager
    var onRestore: () -> Void
    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        // Long DE/PT legal labels overflow one line on SE-class widths — fall back to wrap.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) { legalButtons }
            VStack(spacing: 4) {
                Button(languageManager.text("paywall.restore"), action: onRestore)
                HStack(spacing: 6) {
                    Button(languageManager.text("settings.terms.title")) { showTerms = true }
                    Text("·").foregroundStyle(DS.inkTertiary)
                    Button(languageManager.text("settings.privacy.title")) { showPrivacy = true }
                }
            }
        }
        .font(DS.sans(.caption2, .medium))
        .foregroundStyle(DS.inkTertiary)
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.85)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showTerms) { TermsView() }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
    }

    @ViewBuilder
    private var legalButtons: some View {
        Button(languageManager.text("paywall.restore"), action: onRestore)
        Text("·").foregroundStyle(DS.inkTertiary)
        Button(languageManager.text("settings.terms.title")) { showTerms = true }
        Text("·").foregroundStyle(DS.inkTertiary)
        Button(languageManager.text("settings.privacy.title")) { showPrivacy = true }
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

// MARK: - Price footnote (quizz + debloquer_cours + blocker)

/// The price above the CTA of the quiz, course-unlock and blocker paywalls: one small grey
/// line, "Essai gratuit de 3 jours, puis 39,99 € / an". The button underneath says what
/// today costs; this says what the store charges once the trial is over.
struct PaywallPriceFootnote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DS.sans(.footnote, .medium))
            .foregroundStyle(DS.inkTertiary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
    }
}

// MARK: - « Tu débloques aussi » (quizz, debloquer_cours, blocker)

/// Un atout PRO : un emoji et un libellé.
struct PaywallUnlockItem: Identifiable {
    let emoji: String
    let key: String
    var id: String { key }

    static let audio = PaywallUnlockItem(emoji: "🎧", key: "paywall.unlock.audio")
    static let unlimited = PaywallUnlockItem(emoji: "📚", key: "paywall.unlock.unlimited")
    static let quiz = PaywallUnlockItem(emoji: "🧠", key: "paywall.unlock.quiz")
    static let antiScroll = PaywallUnlockItem(emoji: "📵", key: "paywall.unlock.antiScroll")
}

/// La carte « Tu débloques aussi » des paywalls de fonctionnalité : un titre, puis une ligne
/// par atout avec son emoji et une coche, sur un fond teinté. Le même bloc partout, pour que
/// chaque paywall rappelle que PRO, c'est tout Sophia et pas une seule option.
struct PaywallUnlockList: View {
    @Environment(LanguageManager.self) private var languageManager
    let titleKey: String
    let items: [PaywallUnlockItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.text(titleKey).uppercasedInApp())
                .font(DS.sans(.caption, .heavy))
                .tracking(0.8)
                .foregroundStyle(DS.accentSoft)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Divider().overlay(DS.accentSoft.opacity(0.14)).padding(.leading, 44)
                    }
                    HStack(spacing: 12) {
                        Text(item.emoji)
                            .font(.system(size: 19))
                            .frame(width: 32, height: 32)
                            .background(DS.surface, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        Text(languageManager.text(item.key))
                            .font(DS.sans(.subheadline, .semibold))
                            .foregroundStyle(DS.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white, DS.accent)
                    }
                    .padding(.vertical, 9)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(colors: [DS.accentTint, DS.accentTint.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.accentSoft.opacity(0.18), lineWidth: 1)
        }
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
    @State private var courseThumb: UIImage?

    private var isCourseUnlock: Bool { context == .debloquerCours }

    private var prices: StoreViewModel.PaywallPriceDisplay {
        store.paywallPriceDisplay(language: languageManager.current)
    }

    /// The offering served here may come from a RevenueCat experiment without an intro offer.
    private var hasTrial: Bool {
        store.annualHasFreeTrial(forOfferingIdentifier: context.rawValue)
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
            // One column of copy, drawn for an iPhone. Stretched across an iPad in
            // landscape it stops looking like the design and pushes the CTA below the
            // fold — and Apple reviews on iPad. The background layer above stays
            // full-bleed, so gradient paywalls still reach the edges.
            .frame(maxWidth: OV2.readableWidth)
        }
        .onAppear {
            presentedAt = Date()
            store.trackPaywallImpression(paywallId: "native_standard", offeringIdentifier: context.rawValue)
            if let course { courseThumb = CourseImageMap.loadImage(for: course.id) }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
        }
        .task {
            if store.offerings == nil { await store.loadOfferingsWithRetry() }
        }
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
                        Image(systemName: hasTrial ? "lock.open.fill" : "sparkles")
                            .font(.jakarta(size: 15, weight: .bold))
                        Text(languageManager.text(hasTrial ? "paywall.cta.unlockFree" : "paywall.cta.subscribe"))
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

    /// e.g. "Essai gratuit de 3 jours, puis 39,99 €/an (3,33 €/mois)", or the no-trial
    /// wording when the served product has no introductory offer.
    private var priceLine: String {
        String(
            format: hasTrial
                ? languageManager.trialText("paywall.price.trialThenYearly", days: store.annualTrialDays)
                : languageManager.text("paywall.price.yearlyNoTrial"),
            prices.yearlyPrice
        )
    }

    private var closeButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
            Task { await store.loadOfferingsWithRetry() }
            return
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        purchasing = true
        Task {
            let ok = await store.purchase(package: package)
            purchasing = false
            if ok {
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

}

// MARK: - Training paywall (quizz offering)

/// Dedicated native paywall for the `quizz` context, opened from the training tab's
/// "Débloquer" CTA. Rather than a generic feature list, it *sells the training method*:
/// it explains what training is, shows spaced-repetition statistics, and frames spaced
/// repetition as the most proven way to anchor lasting knowledge. It sells the annual plan of
/// the offering RevenueCat currently serves (so price experiments apply here too), with the
/// `quizz` offering as fallback; the impression and the purchase report that same offering.
struct SophiaTrainingPaywall: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    let store: StoreViewModel
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    var onDismissed: (() -> Void)? = nil

    @State private var purchasing = false
    @State private var appeared = false

    private let context = SophiaPaywallContext.entrainement

    private var prices: StoreViewModel.PaywallPriceDisplay {
        store.paywallPriceDisplay(language: languageManager.current)
    }

    /// The offering served here may come from a RevenueCat experiment without an intro offer.
    private var hasTrial: Bool {
        store.annualHasFreeTrial(forOfferingIdentifier: context.offeringIdentifier)
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
            // One column of copy, drawn for an iPhone. Stretched across an iPad in
            // landscape it stops looking like the design and pushes the CTA below the
            // fold — and Apple reviews on iPad. The background layer above stays
            // full-bleed, so gradient paywalls still reach the edges.
            .frame(maxWidth: OV2.readableWidth)
        }
        .onAppear {
            store.trackPaywallImpression(paywallId: "native_training", offeringIdentifier: context.offeringIdentifier)
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
        }
        .task {
            if store.offerings == nil { await store.loadOfferingsWithRetry() }
        }
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
                        Image(systemName: hasTrial ? "lock.open.fill" : "sparkles")
                            .font(.jakarta(size: 15, weight: .bold))
                        Text(languageManager.text(hasTrial ? "paywall.cta.unlockFree" : "paywall.cta.subscribe"))
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

    /// e.g. "Essai gratuit de 3 jours, puis 39,99 €/an (3,33 €/mois)", or the no-trial
    /// wording when the served product has no introductory offer.
    private var priceLine: String {
        String(
            format: hasTrial
                ? languageManager.trialText("paywall.price.trialThenYearly", days: store.annualTrialDays)
                : languageManager.text("paywall.price.yearlyNoTrial"),
            prices.yearlyPrice
        )
    }

    private var closeButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
            Task { await store.loadOfferingsWithRetry() }
            return
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        purchasing = true
        Task {
            let ok = await store.purchase(package: package)
            purchasing = false
            if ok {
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

}

// MARK: - Quiz paywall (quizz offering)

/// Native paywall for the `quizz` context, opened when a free reader taps the quiz at the end
/// of a course. « N'oublie pas ce que tu viens d'apprendre » : the forgetting curve drawn
/// twice (with the quizzes it stays high and climbs back at every reminder; without them it
/// drops and never recovers), then what else PRO unlocks, the rating, and the CTA. It sells
/// the annual plan of the offering RevenueCat currently serves, with `quizz` as fallback.
struct SophiaQuizPaywall: View {
    @Environment(LanguageManager.self) private var languageManager

    let store: StoreViewModel
    /// Off for the developer shortcut in Settings, as on the discount paywall: the RevenueCat
    /// impression would otherwise count a paywall opened only to look at it.
    var tracksAnalytics: Bool = true
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    var onDismissed: (() -> Void)? = nil

    @State private var purchasing = false
    @State private var appeared = false
    @State private var showClose = false

    private let context = SophiaPaywallContext.quizz

    private var prices: StoreViewModel.PaywallPriceDisplay {
        store.paywallPriceDisplay(language: languageManager.current)
    }

    /// The offering served here may come from a RevenueCat experiment without an intro offer.
    private var hasTrial: Bool {
        store.annualHasFreeTrial(forOfferingIdentifier: context.rawValue)
    }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    closeButton
                        .opacity(showClose ? 1 : 0)
                        .allowsHitTesting(showClose)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 22) {
                        headline.padding(.horizontal, 28)
                        QuizRetentionChart().padding(.horizontal, 22)
                        PaywallUnlockList(titleKey: "paywall.unlock.also", items: [.audio, .antiScroll, .unlimited])
                            .padding(.horizontal, 22)
                        ratingFootnote
                    }
                    .padding(.top, 6)
                    .padding(.bottom, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                }
                .scrollIndicators(.hidden)

                bottomBar
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }
            // One column of copy, drawn for an iPhone. Stretched across an iPad in
            // landscape it stops looking like the design and pushes the CTA below the
            // fold — and Apple reviews on iPad. The background layer above stays
            // full-bleed, so gradient paywalls still reach the edges.
            .frame(maxWidth: OV2.readableWidth)
        }
        .onAppear {
            if tracksAnalytics {
                store.trackPaywallImpression(paywallId: "native_quiz", offeringIdentifier: context.rawValue)
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
            // La croix n'apparaît qu'au bout de 4 s, le temps de voir la valeur.
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation(.easeOut(duration: 0.4)) { showClose = true }
            }
        }
        .task {
            if store.offerings == nil { await store.loadOfferingsWithRetry() }
        }
    }

    // MARK: Rating (discreet, at the bottom)

    private var ratingFootnote: some View {
        HStack(spacing: 5) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(DS.warm)
                }
            }
            Text("\((4.8).formatted(.number.precision(.fractionLength(1)).locale(languageManager.locale))) · \(languageManager.text("paywall.quiz.rating"))")
                .font(DS.sans(.caption2, .medium))
                .foregroundStyle(DS.inkTertiary)
        }
    }

    // MARK: Headline

    private var headline: some View {
        VStack(spacing: 10) {
            Text(languageManager.text("paywall.quiz.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(languageManager.text("paywall.quiz.subtitle"))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            PaywallPriceFootnote(text: priceLine)

            Button(action: purchase) {
                HStack(spacing: 8) {
                    if purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.jakarta(size: 15, weight: .bold))
                        Text(ctaTitle)
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

    private var priceLine: String {
        String(
            format: hasTrial
                ? languageManager.trialText("paywall.price.trialThenYearly", days: store.annualTrialDays)
                : languageManager.text("paywall.price.yearlyNoTrial"),
            prices.yearlyPrice
        )
    }

    /// « Continuer pour 0,00 € » while the trial is served: what today costs, in the
    /// store's currency. Without a trial the button says what it does.
    private var ctaTitle: String {
        hasTrial
            ? String(format: languageManager.text("paywall.cta.continueFor"), store.zeroPriceString(language: languageManager.current))
            : languageManager.text("paywall.cta.subscribe")
    }

    private var closeButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
            Task { await store.loadOfferingsWithRetry() }
            return
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        purchasing = true
        Task {
            let ok = await store.purchase(package: package)
            purchasing = false
            if ok {
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

}

// MARK: - Courbe de rétention (paywall quiz)

/// Deux courbes dessinées à la main : en bleu, ce qu'on retient avec les quiz et
/// l'entraînement (haut, qui redescend un peu puis remonte à J3, J7, J15, J30) ; en gris,
/// sans quiz (qui chute et ne remonte jamais). Un dessin, pas une mesure : il illustre la
/// courbe de l'oubli et ce que les rappels en font.
private struct QuizRetentionChart: View {
    @Environment(LanguageManager.self) private var languageManager
    @State private var drawn: CGFloat = 0

    /// Points (x 0…1, y 0…1 où 1 = tout retenu) de la courbe « avec quiz » : des rappels à
    /// J3, J7, J15 et J30 qui remontent à chaque fois.
    private static let withQuiz: [CGPoint] = [
        CGPoint(x: 0.00, y: 1.00), CGPoint(x: 0.07, y: 0.78), CGPoint(x: 0.13, y: 0.96),
        CGPoint(x: 0.24, y: 0.76), CGPoint(x: 0.30, y: 0.97), CGPoint(x: 0.47, y: 0.80),
        CGPoint(x: 0.55, y: 0.98), CGPoint(x: 0.78, y: 0.86), CGPoint(x: 0.86, y: 1.00),
        CGPoint(x: 1.00, y: 0.97),
    ]
    /// Sans quiz : la chute, puis presque rien.
    private static let withoutQuiz: [CGPoint] = [
        CGPoint(x: 0.00, y: 1.00), CGPoint(x: 0.07, y: 0.50), CGPoint(x: 0.18, y: 0.28),
        CGPoint(x: 0.38, y: 0.16), CGPoint(x: 0.65, y: 0.10), CGPoint(x: 1.00, y: 0.06),
    ]
    /// Les repères de l'axe (J1, J3, J7, J15, J30) ; pour les quatre rappels, c'est aussi le
    /// sommet où la courbe bleue remonte.
    private static let dayMarks: [(day: Int, x: CGFloat)] = [(1, 0.0), (3, 0.13), (7, 0.30), (15, 0.55), (30, 0.86)]

    private static let plotHeight: CGFloat = 150
    private static let inset: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                legend(color: DS.accentSoft, key: "paywall.quiz.chart.with", strong: true)
                legend(color: DS.inkTertiary, key: "paywall.quiz.chart.without", strong: false)
                Spacer(minLength: 0)
            }

            HStack(alignment: .top, spacing: 6) {
                // Le libellé de l'axe vertical, couché le long du tracé.
                Text(languageManager.text("paywall.quiz.chart.axis"))
                    .font(DS.sans(.caption2, .semibold))
                    .foregroundStyle(DS.inkTertiary)
                    .lineLimit(1)
                    .fixedSize()
                    .rotationEffect(.degrees(-90))
                    .frame(width: 14, height: Self.plotHeight)

                VStack(spacing: 6) {
                    GeometryReader { geo in
                        plot(in: geo.size)
                    }
                    .frame(height: Self.plotHeight)

                    GeometryReader { geo in
                        ForEach(Array(Self.dayMarks.enumerated()), id: \.offset) { _, mark in
                            Text(String(format: languageManager.text("paywall.quiz.chart.day"), mark.day))
                                .font(DS.sans(.caption2, .bold))
                                .foregroundStyle(mark.day == 1 ? DS.inkTertiary : DS.accentSoft)
                                .fixedSize()
                                .position(x: Self.inset + (geo.size.width - 2 * Self.inset) * mark.x, y: 8)
                        }
                    }
                    .frame(height: 16)
                }
            }
        }
        .padding(18)
        .background(DS.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
        .dsSoftShadow()
        .accessibilityElement(children: .combine)
        .onAppear {
            withAnimation(.easeOut(duration: 1.8).delay(0.35)) { drawn = 1 }
        }
    }

    private func legend(color: Color, key: String, strong: Bool) -> some View {
        HStack(spacing: 6) {
            Capsule().fill(color).frame(width: 16, height: 4)
            Text(languageManager.text(key))
                .font(DS.sans(.caption, strong ? .bold : .medium))
                .foregroundStyle(strong ? DS.ink : DS.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func plot(in size: CGSize) -> some View {
        ZStack {
            // Trois lignes de grille, très légères.
            ForEach(1..<4, id: \.self) { i in
                Rectangle()
                    .fill(DS.hairline.opacity(0.8))
                    .frame(height: 1)
                    .position(x: size.width / 2, y: size.height * CGFloat(i) / 4)
            }

            // Sans quiz : la chute, en gris.
            Self.curve(Self.withoutQuiz, in: size)
                .trim(from: 0, to: drawn)
                .stroke(DS.inkTertiary.opacity(0.75), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

            // Avec les quiz : l'aire teintée, puis la ligne bleue.
            Self.area(Self.withQuiz, in: size)
                .fill(
                    LinearGradient(colors: [DS.accentSoft.opacity(0.22), DS.accentSoft.opacity(0.0)], startPoint: .top, endPoint: .bottom)
                )
                .opacity(Double(drawn))
            Self.curve(Self.withQuiz, in: size)
                .trim(from: 0, to: drawn)
                .stroke(DS.accentSoft, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))

            // Un point à chaque rappel : la courbe remonte.
            ForEach(Array(Self.dayMarks.dropFirst().enumerated()), id: \.offset) { _, mark in
                let peak = Self.withQuiz.first { abs($0.x - mark.x) < 0.001 } ?? CGPoint(x: mark.x, y: 1)
                Circle()
                    .fill(DS.surface)
                    .overlay(Circle().strokeBorder(DS.accentSoft, lineWidth: 2.5))
                    .frame(width: 11, height: 11)
                    .position(Self.point(peak, in: size))
                    .opacity(drawn >= mark.x ? 1 : 0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: drawn >= mark.x)
            }
        }
    }

    // MARK: Géométrie

    private static func point(_ p: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: inset + p.x * (size.width - 2 * inset),
            y: inset + (1 - p.y) * (size.height - 2 * inset)
        )
    }

    /// Une courbe lisse (Catmull-Rom → Bézier) par les points donnés.
    private static func curve(_ points: [CGPoint], in size: CGSize) -> Path {
        var path = Path()
        let pts = points.map { point($0, in: size) }
        guard let first = pts.first else { return path }
        path.move(to: first)
        for i in 0..<(pts.count - 1) {
            let p0 = i > 0 ? pts[i - 1] : pts[i]
            let p1 = pts[i]
            let p2 = pts[i + 1]
            let p3 = i + 2 < pts.count ? pts[i + 2] : p2
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        return path
    }

    /// La courbe fermée sur le bas du tracé, pour l'aire teintée.
    private static func area(_ points: [CGPoint], in size: CGSize) -> Path {
        var path = curve(points, in: size)
        guard let last = points.last, let first = points.first else { return path }
        path.addLine(to: CGPoint(x: point(last, in: size).x, y: size.height))
        path.addLine(to: CGPoint(x: point(first, in: size).x, y: size.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Course unlock paywall (debloquer_cours offering)

/// Native paywall for the `debloquer_cours` context ("Tu as déjà lu ton cours gratuit du
/// jour"). The course they were reading, locked; the live countdown to the next free course;
/// then « OU » and the other way out: Sophia PRO, built to maximise what you remember, with
/// what it unlocks. The close button appears only after 2s and this view never dismisses
/// itself — the presenter stacks the second-chance comparison paywall on top (see `CourseView`).
struct SophiaCourseUnlockPaywall: View {
    @Environment(LanguageManager.self) private var languageManager

    let store: StoreViewModel
    var course: Course? = nil
    var secondsUntilReset: Int? = nil
    /// Off for the developer shortcut in Settings, as on the discount paywall: the RevenueCat
    /// impression would otherwise count a paywall opened only to look at it.
    var tracksAnalytics: Bool = true
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    var onDismissed: (() -> Void)? = nil

    @State private var purchasing = false
    @State private var appeared = false
    @State private var showClose = false
    @State private var presentedAt: Date?
    @State private var courseThumb: UIImage?

    private let context = SophiaPaywallContext.debloquerCours

    private var prices: StoreViewModel.PaywallPriceDisplay {
        store.paywallPriceDisplay(language: languageManager.current)
    }

    /// The offering served here may come from a RevenueCat experiment without an intro offer.
    private var hasTrial: Bool {
        store.annualHasFreeTrial(forOfferingIdentifier: context.rawValue)
    }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    closeButton
                        .opacity(showClose ? 1 : 0)
                        .allowsHitTesting(showClose)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 20) {
                        hero
                        title.padding(.horizontal, 28)
                        if let secondsUntilReset {
                            resetCountdown(seconds: secondsUntilReset)
                        }
                        orDivider.padding(.horizontal, 40)
                        proPitch.padding(.horizontal, 28)
                        PaywallUnlockList(titleKey: "paywall.unlock.you", items: [.audio, .unlimited, .quiz, .antiScroll])
                            .padding(.horizontal, 22)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                }
                .scrollIndicators(.hidden)

                bottomBar
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }
            // One column of copy, drawn for an iPhone. Stretched across an iPad in
            // landscape it stops looking like the design and pushes the CTA below the
            // fold — and Apple reviews on iPad. The background layer above stays
            // full-bleed, so gradient paywalls still reach the edges.
            .frame(maxWidth: OV2.readableWidth)
        }
        .onAppear {
            presentedAt = Date()
            if tracksAnalytics {
                store.trackPaywallImpression(paywallId: "native_course_unlock", offeringIdentifier: context.rawValue)
            }
            if let course { courseThumb = CourseImageMap.loadImage(for: course.id) }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
            // La croix n'apparaît qu'au bout de 2 s, le temps de voir la valeur.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.4)) { showClose = true }
            }
        }
        .task {
            if store.offerings == nil { await store.loadOfferingsWithRetry() }
        }
    }

    // MARK: Hero

    @ViewBuilder
    private var hero: some View {
        if let courseThumb {
            Image(uiImage: courseThumb)
                .resizable()
                .scaledToFill()
                .frame(width: 92, height: 92)
                .clipShape(.rect(cornerRadius: DS.Radius.control))
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                        .strokeBorder(DS.hairline, lineWidth: 1)
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "lock.fill")
                        .font(.jakarta(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(DS.accent, in: Circle())
                        .overlay { Circle().strokeBorder(.white, lineWidth: 2) }
                        .offset(x: 8, y: 8)
                }
                .dsSoftShadow()
        } else {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(DS.accent)
                .frame(width: 88, height: 88)
                .background(DS.accentTint, in: Circle())
        }
    }

    // MARK: Title (subtitle removed per design)

    private var title: some View {
        Text(languageManager.text("paywall.course.title"))
            .font(DS.title(.title, .heavy))
            .foregroundStyle(DS.ink)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }

    // MARK: Reset countdown ("reviens demain") — centered and aligned in its block

    private func resetCountdown(seconds: Int) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let elapsed = Int(timeline.date.timeIntervalSince(presentedAt ?? timeline.date))
            let remaining = max(0, seconds - elapsed)
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.jakarta(size: 12, weight: .bold))
                    Text(languageManager.text("paywall.course.comeBack"))
                        .font(DS.sans(.caption, .semibold))
                }
                .foregroundStyle(DS.inkSecondary)

                Text(PaywallCountdown.format(remaining))
                    .font(DS.sans(.title2, .bold))
                    .monospacedDigit()
                    .foregroundStyle(DS.ink)
                    .contentTransition(.numericText(countsDown: true))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(DS.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .strokeBorder(DS.hairline, lineWidth: 1)
            }
            .padding(.horizontal, 22)
        }
    }

    // MARK: « OU » puis Sophia PRO

    /// Le trait d'union entre les deux issues : attendre demain, ou débloquer maintenant.
    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(DS.hairline).frame(height: 1)
            Text(languageManager.text("paywall.course.or"))
                .font(DS.sans(.caption, .heavy))
                .tracking(1.2)
                .foregroundStyle(DS.inkTertiary)
            Rectangle().fill(DS.hairline).frame(height: 1)
        }
    }

    /// « Débloque Sophia PRO, étudié pour maximiser ce que tu retiens. »
    private var proPitch: some View {
        Text(languageManager.text("paywall.course.proPitch"))
            .font(DS.title(.title3, .heavy))
            .foregroundStyle(DS.accent)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            PaywallPriceFootnote(text: priceLine)

            Button(action: purchase) {
                HStack(spacing: 8) {
                    if purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: hasTrial ? "lock.open.fill" : "sparkles")
                            .font(.jakarta(size: 15, weight: .bold))
                        Text(ctaTitle)
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

    private var priceLine: String {
        String(
            format: hasTrial
                ? languageManager.trialText("paywall.price.trialThenYearly", days: store.annualTrialDays)
                : languageManager.text("paywall.price.yearlyNoTrial"),
            prices.yearlyPrice
        )
    }

    /// « Continuer pour 0,00 € » while the trial is served: what today costs, in the
    /// store's currency. Without a trial the button says what it does.
    private var ctaTitle: String {
        hasTrial
            ? String(format: languageManager.text("paywall.cta.continueFor"), store.zeroPriceString(language: languageManager.current))
            : languageManager.text("paywall.cta.subscribe")
    }

    private var closeButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
            Task { await store.loadOfferingsWithRetry() }
            return
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        purchasing = true
        Task {
            let ok = await store.purchase(package: package)
            purchasing = false
            if ok {
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

}

// MARK: - Discount paywall (offre_discount)

/// Ultra-aggressive native flash-sale paywall for the `offre_discount` context.
/// Single annual plan from the `offre_discount` offering (19,99 €/an, **no free trial**),
/// a big struck-through regular price, a savings badge, and a prominent 1-hour countdown
/// driven by `DiscountOfferManager` for urgency.
struct SophiaDiscountPaywall: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    let store: StoreViewModel
    /// Drives the live 60-minute countdown. Optional so previews / fallbacks still render.
    var discountManager: DiscountOfferManager? = nil
    /// Off for the developer shortcut in Settings: the RevenueCat impression would otherwise
    /// count a paywall opened only to look at it.
    var tracksAnalytics: Bool = true
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    var onDismissed: (() -> Void)? = nil

    @State private var purchasing = false
    @State private var appeared = false
    @State private var pulse = false
    @State private var presentedAt: Date?

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
            // One column of copy, drawn for an iPhone. Stretched across an iPad in
            // landscape it stops looking like the design and pushes the CTA below the
            // fold — and Apple reviews on iPad. The background layer above stays
            // full-bleed, so gradient paywalls still reach the edges.
            .frame(maxWidth: OV2.readableWidth)
        }
        .onAppear {
            presentedAt = Date()
            if tracksAnalytics {
                store.trackPaywallImpression(paywallId: "native_discount", offering: store.promoOffering)
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .task {
            if store.offerings == nil { await store.loadOfferingsWithRetry() }
        }
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

    /// Prix mensuels, comme sur les paywalls de l'onboarding : l'offre se compare au plan
    /// annuel normal dans la même unité. Le montant réellement prélevé une fois par an
    /// reste juste en dessous, en petit (App Store 3.1.2).
    private var priceBlock: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                if let regular = prices.regularPerMonth {
                    Text(regular)
                        .font(DS.sans(.title3, .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .strikethrough()
                }
                Text(prices.promoPerMonth)
                    .font(DS.title(.largeTitle, .heavy))
                    .foregroundStyle(.white)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Text(languageManager.text("paywall.discount.perMonth"))
                .font(DS.sans(.footnote, .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)

            Text(prices.billedYearlyNote)
                .font(DS.sans(.caption, .medium))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
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
        // Le paquet promo `offre_discount` est prioritaire ; si l'offering promo n'est pas
        // configurée (paquet nil), on retombe sur le plan annuel standard pour que le bouton
        // « J'en profite maintenant » déclenche toujours l'achat au lieu de ne rien faire.
        guard let package = store.promoPackage ?? store.annualPackage else {
            Task { await store.loadOfferingsWithRetry() }
            return
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        purchasing = true
        Task {
            let ok = await store.purchase(package: package)
            purchasing = false
            if ok {
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

}
