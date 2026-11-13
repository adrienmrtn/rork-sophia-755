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
                    Text("·").foregroundStyle(DSLegacy.inkTertiary)
                    Button(languageManager.text("settings.privacy.title")) { showPrivacy = true }
                }
            }
        }
        .font(DSLegacy.sans(.caption2, .medium))
        .foregroundStyle(DSLegacy.inkTertiary)
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.85)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showTerms) { TermsView() }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
    }

    @ViewBuilder
    private var legalButtons: some View {
        Button(languageManager.text("paywall.restore"), action: onRestore)
        Text("·").foregroundStyle(DSLegacy.inkTertiary)
        Button(languageManager.text("settings.terms.title")) { showTerms = true }
        Text("·").foregroundStyle(DSLegacy.inkTertiary)
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
                        .strokeBorder(DS.hairline, lineWidth: 1.5)
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
                .font(DS.title(.title, .medium))
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
            .overlay { Capsule().strokeBorder(DS.hairline, lineWidth: 1.5) }
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
                        .font(DS.sans(.subheadline, .regular))
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

            OnboardingV2LegalRow(onRestore: restore)
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
                .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1.5) }
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
            DSLegacy.canvas.ignoresSafeArea()

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
            .frame(maxWidth: OV2Legacy.readableWidth)
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
            .foregroundStyle(DSLegacy.accent)
            .frame(width: 92, height: 92)
            .background(DSLegacy.accentTint, in: Circle())
    }

    // MARK: Headline

    private var headline: some View {
        VStack(spacing: 10) {
            Text(languageManager.text("paywall.training.title"))
                .font(DSLegacy.title(.title, .heavy))
                .foregroundStyle(DSLegacy.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(languageManager.text("paywall.training.subtitle"))
                .font(DSLegacy.sans(.subheadline))
                .foregroundStyle(DSLegacy.inkSecondary)
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
                tint: DSLegacy.success
            )
            statCard(
                value: languageManager.text("paywall.training.stat2.value"),
                label: languageManager.text("paywall.training.stat2.label"),
                tint: DSLegacy.danger
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
                .font(DSLegacy.sans(.caption, .medium))
                .foregroundStyle(DSLegacy.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .background(DSLegacy.surface)
        .clipShape(.rect(cornerRadius: DSLegacy.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DSLegacy.Radius.card, style: .continuous)
                .strokeBorder(DSLegacy.hairline, lineWidth: 1)
        }
    }

    // MARK: How it works

    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(languageManager.text("paywall.training.how.title"))
                .font(DSLegacy.sans(.caption2, .semibold))
                .foregroundStyle(DSLegacy.inkTertiary)
                .tracking(1.2)

            howStep(1, languageManager.text("paywall.training.how.step1"))
            howStep(2, languageManager.text("paywall.training.how.step2"))
            howStep(3, languageManager.text("paywall.training.how.step3"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(DSLegacy.surface)
        .clipShape(.rect(cornerRadius: DSLegacy.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DSLegacy.Radius.card, style: .continuous)
                .strokeBorder(DSLegacy.hairline, lineWidth: 1)
        }
    }

    private func howStep(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(DSLegacy.sans(.subheadline, .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(DSLegacy.accent, in: Circle())
            Text(text)
                .font(DSLegacy.sans(.subheadline, .medium))
                .foregroundStyle(DSLegacy.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Footnote

    private var footnote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.jakarta(size: 13, weight: .semibold))
                .foregroundStyle(DSLegacy.accentSoft)
            Text(languageManager.text("paywall.training.footnote"))
                .font(DSLegacy.sans(.caption, .medium))
                .foregroundStyle(DSLegacy.inkTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Text(priceLine)
                .font(DSLegacy.sans(.footnote, .medium))
                .foregroundStyle(DSLegacy.inkTertiary)
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
            .buttonStyle(DSLegacyPrimaryButtonStyle())
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
                .foregroundStyle(DSLegacy.inkSecondary)
                .frame(width: 40, height: 40)
                .background(DSLegacy.surface, in: Circle())
                .overlay { Circle().strokeBorder(DSLegacy.hairline, lineWidth: 1) }
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
/// of a course. Design « Elevate arrondi » : sans quiz / avec les quiz en en-tête, une question
/// d'exemple déjà répondue, « Ta mémoire, ça s'entraîne », puis le choix de formule. Prix,
/// essai et achat viennent de l'offre que RevenueCat sert (voir `ElevatePaywallScreen`), avec
/// `quizz` en repli.
struct SophiaQuizPaywall: View {
    @Environment(LanguageManager.self) private var languageManager

    let store: StoreViewModel
    /// Off for the developer shortcut in Settings, as on the discount paywall: the RevenueCat
    /// impression would otherwise count a paywall opened only to look at it.
    var tracksAnalytics: Bool = true
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    var onDismissed: (() -> Void)? = nil

    private let context = SophiaPaywallContext.quizz

    var body: some View {
        ElevatePaywallScreen(
            store: store,
            offeringIdentifier: context.rawValue,
            paywallId: "native_quiz",
            tracksAnalytics: tracksAnalytics,
            // La croix n'apparaît qu'au bout de 4 s, le temps de voir la valeur.
            closeDelay: 4,
            layout: .bonhomme,
            onPurchased: onPurchased,
            onRestored: onRestored,
            onClose: { onDismissed?() }
        ) {
            ElevateBeforeAfterHero(
                beforeImage: "pw_quiz_before",
                afterImage: "pw_quiz_after",
                beforeLabel: languageManager.text("paywall.quiz.chart.without"),
                afterLabel: languageManager.text("paywall.quiz.chart.with")
            )
            ElevatePaywallTitle(text: languageManager.text("paywall.elevate.quiz.title"))
                .dsStagger(0)
            ElevatePaywallSubtitle(text: languageManager.text("paywall.elevate.quiz.subtitle"))
                .dsStagger(1)
            ElevateSampleQuizCard()
                .dsStagger(2)
            training
                .dsStagger(3)
        }
    }

    /// L'illustration, « Ta mémoire, ça s'entraîne », puis les trois raisons.
    private var training: some View {
        VStack(spacing: 16) {
            Image("pw_quiz_training")
                .resizable()
                .aspectRatio(800.0 / 600.0, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                .accessibilityHidden(true)

            ElevateSectionTitle(text: languageManager.text("paywall.elevate.quiz.benefits.title"))
                .padding(.top, 4)
                .padding(.horizontal, 4)

            VStack(spacing: 16) {
                ElevateInfoRow(
                    systemImage: "list.bullet.rectangle",
                    title: languageManager.text("paywall.elevate.quiz.benefit1.title"),
                    detail: languageManager.text("paywall.elevate.quiz.benefit1.body")
                )
                ElevateInfoRow(
                    systemImage: "clock.arrow.circlepath",
                    title: languageManager.text("paywall.elevate.quiz.benefit2.title"),
                    detail: languageManager.text("paywall.elevate.quiz.benefit2.body")
                )
                ElevateInfoRow(
                    systemImage: "lightbulb",
                    title: languageManager.text("paywall.elevate.quiz.benefit3.title"),
                    detail: languageManager.text("paywall.elevate.quiz.benefit3.body")
                )
            }
            .padding(.horizontal, 6)
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
    }
}

// MARK: - Course unlock paywall (debloquer_cours offering)

/// Native paywall for the `debloquer_cours` context (le cours gratuit du jour est déjà lu).
/// Deux habillages « Elevate arrondi », départagés par un test A/B piloté depuis Supabase
/// (`PaywallExperiment`, clé `course_paywall_ab`) :
/// - `bonhomme` : avant / avec Sophia, les avantages, « Écrits par des experts », les avis ;
/// - `reviews` : « Toute la bibliothèque », des cours en éventail, les avantages, les experts,
///   les avis, des cartes de formule compactes.
/// La variante part avec l'impression et les événements d'achat (`variant`, `experiment`), et
/// l'identifiant de paywall devient `native_course_unlock_<variante>`. Cette vue ne se ferme
/// jamais d'elle-même : le présentateur empile le paywall comparatif (voir `CourseView`).
struct SophiaCourseUnlockPaywall: View {
    @Environment(LanguageManager.self) private var languageManager

    let store: StoreViewModel
    /// Le cours qu'on voulait lire : il prend le centre de l'éventail de la variante `reviews`.
    var course: Course? = nil
    /// Gardé pour les appelants ; le compte à rebours n'est plus affiché par ce design.
    var secondsUntilReset: Int? = nil
    /// Off for the developer shortcut in Settings, as on the discount paywall: the RevenueCat
    /// impression would otherwise count a paywall opened only to look at it.
    var tracksAnalytics: Bool = true
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    var onDismissed: (() -> Void)? = nil
    /// Impose une variante au lieu du tirage de l'installation (raccourci développeur).
    var forcedVariant: CoursePaywallVariant? = nil

    /// La variante de l'installation, figée à l'ouverture : un réglage qui arrive du réseau
    /// pendant que le paywall est à l'écran ne le change pas sous les yeux du lecteur.
    @State private var drawnVariant: CoursePaywallVariant = PaywallExperiment.courseVariant

    private let context = SophiaPaywallContext.debloquerCours

    private var variant: CoursePaywallVariant { forcedVariant ?? drawnVariant }

    var body: some View {
        let shown: CoursePaywallVariant = variant
        let layout: ElevatePaywallLayout = shown == .reviews ? .reviews : .bonhomme
        return ElevatePaywallScreen(
            store: store,
            offeringIdentifier: context.rawValue,
            paywallId: shown.paywallId,
            analyticsProps: PaywallExperiment.courseAnalyticsProps(shown),
            tracksAnalytics: tracksAnalytics,
            // La croix n'apparaît qu'au bout de 2 s, le temps de voir la valeur.
            closeDelay: 2,
            layout: layout,
            onPurchased: onPurchased,
            onRestored: onRestored,
            onClose: { onDismissed?() }
        ) {
            variantContent(shown)
        }
    }

    @ViewBuilder
    private func variantContent(_ shown: CoursePaywallVariant) -> some View {
        switch shown {
        case .bonhomme:
            ElevateBeforeAfterHero(
                beforeImage: "pw_course_before",
                afterImage: "pw_course_after",
                beforeLabel: languageManager.text("paywall.elevate.common.before"),
                afterLabel: languageManager.text("paywall.elevate.common.with"),
                afterLabelHasLogo: true
            )
            ElevatePaywallTitle(text: languageManager.text("paywall.elevate.course.title"))
                .dsStagger(0)
            ElevateFeatureList()
                .dsStagger(1)
            ElevateExpertsCard()
                .padding(.top, 26)
                .dsStagger(2)
            ElevateReviewsBlock()
                .dsStagger(3)
        case .reviews:
            ElevateLibraryTitle()
                .dsStagger(0)
            ElevateCourseFan(course: course)
                .dsStagger(1)
            ElevateFeatureList()
                .dsStagger(2)
            ElevateExpertsCard()
                .padding(.top, 32)
                .dsStagger(3)
            ElevateReviewsBlock()
                .dsStagger(4)
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
                colors: [DSLegacy.accent, DSLegacy.accentSoft],
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
            .frame(maxWidth: OV2Legacy.readableWidth)
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
                .font(DSLegacy.sans(.caption, .bold))
                .textCase(.uppercase)
                .tracking(0.5)
            Text(text)
                .font(DSLegacy.sans(.headline, .heavy))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(DSLegacy.danger, in: Capsule())
        .overlay { Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1) }
        .scaleEffect(pulse ? 1.04 : 1.0)
        .shadow(color: DSLegacy.danger.opacity(0.5), radius: pulse ? 16 : 8, y: 4)
    }

    // MARK: Discount badge

    @ViewBuilder
    private var discountBadge: some View {
        if let badge = prices.discountBadge {
            Text(badge)
                .font(DSLegacy.title(.largeTitle, .heavy))
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
                .font(DSLegacy.title(.title, .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(languageManager.text("paywall.discount.subtitle"))
                .font(DSLegacy.sans(.subheadline, .medium))
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
                        .font(DSLegacy.sans(.title3, .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .strikethrough()
                }
                Text(prices.promoPerMonth)
                    .font(DSLegacy.title(.largeTitle, .heavy))
                    .foregroundStyle(.white)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Text(languageManager.text("paywall.discount.perMonth"))
                .font(DSLegacy.sans(.footnote, .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)

            Text(prices.billedYearlyNote)
                .font(DSLegacy.sans(.caption, .medium))
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
                        ProgressView().tint(DSLegacy.accent)
                    } else {
                        Image(systemName: "bolt.fill")
                            .font(.jakarta(size: 15, weight: .bold))
                        Text(languageManager.text("paywall.discount.cta"))
                    }
                }
            }
            .buttonStyle(DSLegacyPrimaryButtonStyle(fill: .white, foreground: DSLegacy.accent))
            .disabled(purchasing)
            .padding(.horizontal, 24)

            Text(languageManager.text("paywall.discount.noTrial"))
                .font(DSLegacy.sans(.caption2, .medium))
                .foregroundStyle(.white.opacity(0.7))

            legalRow.padding(.bottom, 14)
        }
    }

    private var legalRow: some View {
        HStack(spacing: 6) {
            Button(languageManager.text("paywall.restore"), action: restore)
        }
        .font(DSLegacy.sans(.caption2, .medium))
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
