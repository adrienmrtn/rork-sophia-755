import SwiftUI

// MARK: - Time formatting helper

enum OnboardingScreenTimeFormat {
    /// « 3h30 » / « 3h » / « 45 min » selon la valeur.
    static func label(minutes: Int, language: AppLanguage) -> String {
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m == 0 ? "\(h)h" : String(format: "%dh%02d", h, m)
        }
        return String(format: AppLocalizable.string("onboardingV2.screenTime.minutes", language: language), minutes)
    }
}

// MARK: - Page 1/4 — Slider temps d'écran

/// « Combien de temps passes-tu par jour sur ton téléphone ? »
/// Slider de 30 min à 10 h par blocs de 30 min ; le grand chiffre roule en slide-up.
///
/// Style « Elevate arrondi » : titre centré, illustration ronde quand la hauteur le permet,
/// le temps en très grand et en bleu, le curseur et ses bornes, puis le CTA épinglé.
struct OnboardingV2PhoneTime: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var minutes: Double = 180
    @State private var lastStep: Int = 6

    private let range: ClosedRange<Double> = 30...600
    private let step: Double = 30

    private var timeLabel: String {
        OnboardingScreenTimeFormat.label(minutes: Int(minutes), language: languageManager.current)
    }

    var body: some View {
        // Big number, slider and labels: at a large text size on a short phone the CTA below
        // them went off screen. Scrolls instead, with the button pinned.
        OV2CorePage { height in
            pageBody(height: height)
        } footer: {
            OnboardingV2Button(title: languageManager.text("common.continue")) {
                vm.phoneDailyMinutes = Int(minutes)
                onNext()
            }
        }
        .ov2Background()
        .onAppear {
            minutes = Double(vm.phoneDailyMinutes)
            lastStep = Int(minutes / step)
        }
    }

    private func pageBody(height: CGFloat) -> some View {
        let art: CGFloat = OV2CoreMetrics.artSize(base: 116, available: height, reserved: 360)
        return VStack(spacing: 0) {
            OV2CoreQuestionTitle(title: languageManager.text("onboardingV2.phoneTime.title"))
                .padding(.top, OV2CoreMetrics.topInset)
                .dsStagger(0)

            if art > 0 {
                OV2CoreIllustration(art: .phone, size: art)
                    .padding(.top, 22)
                    .dsPopIn(delay: 0.12)
            }

            Spacer(minLength: 24)

            Text(timeLabel)
                .font(.jakarta(size: 84, weight: .heavy))
                .foregroundStyle(OV2.accent)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText(value: minutes))
                .animation(DS.Motion.snappy, value: minutes)
                .padding(.horizontal, OV2CoreMetrics.sideInset)
                .dsStagger(1)

            sliderBlock
                .padding(.horizontal, 32)
                .padding(.top, 28)
                .dsStagger(2)

            Spacer(minLength: 24)
        }
        // Le bloc chiffre + curseur se centre dans la hauteur qui reste sous l'illustration.
        .frame(minHeight: height)
    }

    private var sliderBlock: some View {
        VStack(spacing: 8) {
            Slider(value: $minutes, in: range, step: step)
                .tint(OV2.accent)
                .accessibilityLabel(Text(languageManager.text("onboardingV2.phoneTime.title")))
                .accessibilityValue(Text(timeLabel))
                .onChange(of: minutes) { _, newValue in
                    let s = Int(newValue / step)
                    if s != lastStep {
                        lastStep = s
                        vm.phoneDailyMinutes = Int(newValue)
                        OnboardingHaptics.selection()
                    }
                }

            HStack {
                Text(OnboardingScreenTimeFormat.label(minutes: Int(range.lowerBound), language: languageManager.current))
                Spacer()
                Text(OnboardingScreenTimeFormat.label(minutes: Int(range.upperBound), language: languageManager.current))
            }
            .font(DS.sans(.footnote, .semibold))
            .foregroundStyle(OV2.inkSecondary)
        }
    }
}

// MARK: - Page 2/4 — Ta vie en années (80 carrés)

/// 80 carrés = 80 années de vie. Ils se colorent lentement, un tiers après l'autre : le
/// sommeil en vert, le travail en marron, puis le temps libre qui reste. Ensuite, dans ce temps
/// libre, carré après carré, en rouge, les années passées sur le téléphone (d'après le temps
/// d'écran quotidien déclaré) ; la conclusion — le nombre en grand et sa phrase — n'arrive
/// qu'à la toute fin.
///
/// La séquence dure environ 14 secondes et rien n'annonce le nombre avant : le titre est
/// neutre (« Voici ta vie en années »), la ligne « téléphone » de la légende compte en même
/// temps que les carrés. Le bouton « Continuer » reste utilisable du début à la fin.
struct OnboardingV2YearsGrid: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    /// Nombre de carrés gris révélés (phase 1 : ouverture de la grille).
    @State private var revealed: Int = 0
    /// Carrés colorés de chaque tiers, dans l'ordre où ils se remplissent.
    @State private var sleepFilled: Int = 0
    @State private var workFilled: Int = 0
    @State private var freeFilled: Int = 0
    /// Carrés rouges dans le temps libre (années passées sur le téléphone).
    @State private var screenFilled: Int = 0
    /// La conclusion (nombre en grand + phrase), dernière à arriver.
    @State private var showConclusion = false
    /// `true` une fois la séquence jouée jusqu'au bout : inutile de la rejouer si la page
    /// réapparaît (rotation, retour d'arrière-plan).
    @State private var sequenceDone = false
    @State private var animTask: Task<Void, Never>?

    private let totalYears = 80
    private let columns = 10
    /// Un tiers de la vie à dormir, un tiers à travailler ; le reste est du temps libre.
    private let sleepYears = 27
    private let workYears = 27

    private static let sleepColor = Color(red: 0.30, green: 0.62, blue: 0.42)
    private static let workColor = Color(red: 0.55, green: 0.38, blue: 0.24)
    private static let freeColor = Color(red: 0.72, green: 0.82, blue: 0.95)
    /// Rouge des années passées sur le téléphone.
    private static let phoneColor = Color(red: 0.784, green: 0.251, blue: 0.184)
    private static let gridSpacing: CGFloat = 7

    private var freeYears: Int {
        totalYears - sleepYears - workYears
    }

    /// Années de temps libre passées sur le téléphone : le temps d'écran quotidien rapporté à
    /// 80 ans, borné au temps libre (au-delà, tout le temps libre y passe).
    private var screenYears: Int {
        max(1, min(freeYears, Int(vm.phoneYearsOverLife.rounded())))
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Self.gridSpacing), count: columns)
    }

    var body: some View {
        // The 80-square grid is the tallest block in the flow. On an iPad in landscape it
        // grew until the button sat hundreds of points below the fold, and on a short
        // phone at a large text size the caption pushed it off the bottom. Scrolls, with
        // the button pinned; `ov2Background` caps the width on a tablet.
        OV2CorePage { height in
            pageBody
                .frame(minHeight: height, alignment: .top)
        } footer: {
            // Toujours là, toujours actif : on peut passer sans attendre la fin.
            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear { startSequence() }
        .onDisappear { animTask?.cancel() }
    }

    /// Page content; the container above is what keeps the CTA on screen.
    private var pageBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.top, 16)

            Spacer(minLength: 20)

            grid

            legend
                .padding(.top, 20)

            conclusion
                .padding(.top, 20)

            Spacer(minLength: 16)
        }
        .padding(.horizontal, OV2CoreMetrics.sideInset)
    }

    // MARK: - En-tête

    /// « Voici **ta vie en années** » et « Une case, une année. » : visibles dès l'ouverture,
    /// sans rien dire du résultat.
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            OV2CoreHighlightTitle(
                text: OV2CoreText.marked(
                    "onboardingV2.yearsGrid.title",
                    highlightKey: "elevateOnboardingCore.yearsGrid.titleHighlight",
                    language: languageManager.current
                ),
                size: 25
            )
            Text(OV2CoreText.string("elevateOnboardingCore.yearsGrid.subtitle", language: languageManager.current))
                .font(DS.sans(.subheadline, .regular))
                .foregroundStyle(OV2.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .dsStagger(0)
    }

    // MARK: - Grille

    private var grid: some View {
        LazyVGrid(columns: gridColumns, spacing: Self.gridSpacing) {
            ForEach(0..<totalYears, id: \.self) { i in
                let isRevealed: Bool = i < revealed
                let filled: Bool = isFilled(i)
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(squareColor(i))
                    .aspectRatio(1, contentMode: .fit)
                    .scaleEffect(isRevealed ? (filled ? 1 : 0.88) : 0.3)
                    .opacity(isRevealed ? 1 : 0)
            }
        }
        .accessibilityHidden(true)
    }

    /// Le carré `i` dans l'ordre de la grille : sommeil, travail, puis temps libre (où les
    /// premiers carrés deviennent rouges).
    private func squareColor(_ i: Int) -> Color {
        if i < sleepYears {
            return i < sleepFilled ? Self.sleepColor : OV2.hairline
        }
        let work = i - sleepYears
        if work < workYears {
            return work < workFilled ? Self.workColor : OV2.hairline
        }
        let free = i - sleepYears - workYears
        if free < screenFilled { return Self.phoneColor }
        return free < freeFilled ? Self.freeColor : OV2.hairline
    }

    private func isFilled(_ i: Int) -> Bool {
        if i < sleepYears { return i < sleepFilled }
        let work = i - sleepYears
        if work < workYears { return work < workFilled }
        let free = i - sleepYears - workYears
        return free < freeFilled || free < screenFilled
    }

    // MARK: - Légende

    /// Une ligne par couleur, sur deux colonnes ; chacune apparaît quand sa couleur commence
    /// à se poser. La ligne « téléphone » compte avec les carrés rouges.
    private var legend: some View {
        let legendColumns: [GridItem] = [
            GridItem(.flexible(), spacing: 16, alignment: .leading),
            GridItem(.flexible(), spacing: 16, alignment: .leading),
        ]
        return LazyVGrid(columns: legendColumns, alignment: .leading, spacing: 12) {
            legendRow(color: Self.sleepColor, key: "onboardingV2.yearsGrid.sleep", years: sleepYears, shown: sleepFilled > 0)
            legendRow(color: Self.workColor, key: "onboardingV2.yearsGrid.work", years: workYears, shown: workFilled > 0)
            legendRow(color: Self.freeColor, key: "onboardingV2.yearsGrid.free", years: freeYears, shown: freeFilled > 0)
            legendRow(color: Self.phoneColor, key: "onboardingV2.yearsGrid.screen", years: max(screenFilled, 1), shown: screenFilled > 0)
        }
    }

    private func legendRow(color: Color, key: String, years: Int, shown: Bool) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(languageManager.text(key))
                .font(DS.sans(.footnote, .regular))
                .foregroundStyle(OV2.inkSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 4)
            Text(AppLocalizable.yearsString(years, language: languageManager.current))
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(OV2.ink)
                .monospacedDigit()
                .lineLimit(1)
                .contentTransition(.numericText(value: Double(years)))
        }
        .opacity(shown ? 1 : 0)
        .offset(y: shown || reduceMotion ? 0 : 10)
        .animation(DS.Motion.reveal, value: shown)
        .accessibilityElement(children: .combine)
        .accessibilityHidden(!shown)
    }

    // MARK: - Conclusion

    /// Le nombre en grand, puis la phrase : c'est ce que la page veut faire retenir. Sa place
    /// est réservée dès le début pour que rien ne saute quand elle arrive.
    private var conclusion: some View {
        HStack(alignment: .center, spacing: 14) {
            Text(AppLocalizable.yearsString(screenYears, language: languageManager.current))
                .font(.jakarta(size: 36, weight: .heavy))
                .foregroundStyle(DS.danger)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()

            Text(String(
                format: languageManager.text("onboardingV2.yearsGrid.captionFree"),
                freeYears, screenYears
            ))
            .font(DS.sans(.subheadline, .semibold))
            .foregroundStyle(DS.danger)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .fill(DS.dangerTint)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.danger.opacity(0.28), lineWidth: 1.5)
        )
        .opacity(showConclusion ? 1 : 0)
        .offset(y: showConclusion || reduceMotion ? 0 : 14)
        .scaleEffect(showConclusion || reduceMotion ? 1 : 0.96)
        .accessibilityElement(children: .combine)
        .accessibilityHidden(!showConclusion)
    }

    // MARK: - Séquence

    /// Démarre (ou reprend) l'enchaînement.
    ///
    /// La séquence est annulée par `onDisappear` (rotation, redimensionnement de fenêtre sur
    /// iPad, retour depuis l'arrière-plan) : elle reprend ici là où elle s'était arrêtée. Elle
    /// ne conditionne plus la sortie de la page — le bouton est là dès l'ouverture —, ce qui
    /// écarte pour de bon le blocage signalé par l'App Store (Guideline 2.1(a), « indefinite
    /// loading during onboarding », iPad Air M3 / iPadOS 26.6.2).
    ///
    /// Avec « Réduire les animations », la page s'affiche directement dans son état final.
    private func startSequence() {
        guard !sequenceDone else { return }
        animTask?.cancel()
        if reduceMotion {
            showFinalState()
            return
        }
        animTask = Task { @MainActor in
            let finished = await playSequence()
            if finished { sequenceDone = true }
        }
    }

    private func showFinalState() {
        revealed = totalYears
        sleepFilled = sleepYears
        workFilled = workYears
        freeFilled = freeYears
        screenFilled = screenYears
        showConclusion = true
        sequenceDone = true
    }

    /// Enchaînement lent et séquentiel, environ 14 s : (1) ouverture des 80 carrés gris,
    /// (2) le sommeil en vert, (3) le travail en marron, (4) le temps libre en bleu pâle —
    /// chacun avec sa ligne de légende et un temps de lecture —, (5) carré après carré, en
    /// rouge, les années de temps libre passées sur le téléphone, (6) la conclusion.
    /// Reprend à l'état courant, donc rejouable sans repartir de zéro. Retourne `false` si
    /// elle a été annulée en cours de route.
    private func playSequence() async -> Bool {
        // Phase 1 — ouverture des carrés gris (≈ 0,3 → 1,2 s).
        if revealed < totalYears {
            guard await pause(0.3) else { return false }
            for i in (revealed + 1)...totalYears {
                if Task.isCancelled { return false }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) { revealed = i }
                if i % 10 == 0 { OnboardingHaptics.selection() }
                try? await Task.sleep(nanoseconds: 11_000_000)
            }
            guard await pause(0.8) else { return false }
        }

        // Phase 2 — le sommeil (≈ 2,0 → 3,4 s), puis le temps de le lire.
        if sleepFilled < sleepYears {
            let done = await fill(to: sleepYears, from: sleepFilled, interval: 50_000_000) { sleepFilled = $0 }
            guard done else { return false }
            guard await pause(1.25) else { return false }
        }

        // Phase 3 — le travail (≈ 4,6 → 6,0 s).
        if workFilled < workYears {
            let done = await fill(to: workYears, from: workFilled, interval: 50_000_000) { workFilled = $0 }
            guard done else { return false }
            guard await pause(1.25) else { return false }
        }

        // Phase 4 — le temps libre (≈ 7,2 → 8,5 s).
        if freeFilled < freeYears {
            let done = await fill(to: freeYears, from: freeFilled, interval: 50_000_000) { freeFilled = $0 }
            guard done else { return false }
            guard await pause(1.5) else { return false }
        }

        // Phase 5 — les années de temps libre passées sur le téléphone, une par une
        // (≈ 10 → 13 s, quel que soit leur nombre).
        let target = screenYears
        if screenFilled < target {
            let perSquare: Double = min(0.45, max(0.12, 3.0 / Double(target)))
            for i in (screenFilled + 1)...target {
                if Task.isCancelled { return false }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { screenFilled = i }
                OnboardingHaptics.counterTick(progress: Double(i) / Double(target))
                guard await pause(perSquare) else { return false }
            }
            OnboardingHaptics.counterComplete()
        }

        // Phase 6 — la conclusion, en dernier (≈ 13,6 s).
        if !showConclusion {
            guard await pause(0.6) else { return false }
            withAnimation(DS.Motion.pop) { showConclusion = true }
        }
        return await pause(0.8)
    }

    /// Attend `seconds` ; retourne `false` si la tâche a été annulée entre-temps.
    private func pause(_ seconds: Double) async -> Bool {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        return !Task.isCancelled
    }

    /// Colore les carrés `from + 1` à `to` l'un après l'autre, `interval` entre deux.
    /// Retourne `false` si la tâche a été annulée.
    private func fill(to count: Int, from current: Int, interval: UInt64, apply: (Int) -> Void) async -> Bool {
        guard current < count else { return true }
        for i in (current + 1)...count {
            if Task.isCancelled { return false }
            withAnimation(.easeOut(duration: 0.4)) { apply(i) }
            if i % 9 == 0 { OnboardingHaptics.selection() }
            try? await Task.sleep(nanoseconds: interval)
        }
        return true
    }
}

// MARK: - Page 3/4 — « Transforme ce temps en culture »

/// Moment doux : la phrase « Avec Sophia, transforme ce temps en culture » se met en gras
/// progressivement (mot par mot). Chaque mot occupe un emplacement de largeur fixe (largeur
/// « gras ») pour éviter tout décalage du texte quand le gras arrive. Une fois le gras au bout,
/// le dernier mot bascule (par le haut) entre « culture », « art », « philosophie »… en bleu.
/// Pas de CTA : on tape n'importe où pour continuer.
///
/// Style « Elevate arrondi » : une illustration ronde au-dessus de la phrase, en très grand et
/// centrée ; l'invitation à toucher l'écran en bas.
struct OnboardingV2Transform: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var boldCount = 0
    @State private var showHint = false
    @State private var advanced = false
    @State private var swapping = false
    @State private var swapIndex = 0
    @State private var animTask: Task<Void, Never>?

    private var words: [String] {
        TextSegmentation.animationWords(languageManager.text("onboardingV2.transform.text"), keepLastWhole: true)
    }

    private var swapWords: [String] {
        languageManager.text("onboardingV2.transform.words")
            .split(whereSeparator: { $0 == "," || $0 == "、" })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        GeometryReader { geo in
            let style: Font.TextStyle = OV2CoreMetrics.sentenceStyle(
                words: words + swapWords,
                width: geo.size.width - OV2CoreMetrics.sideInset * 2
            )
            ZStack {
                VStack(spacing: 26) {
                    OV2CoreIllustration(art: .nightBook, size: 150)
                        .dsPopIn(delay: 0.1)

                    OV2FlowLayout(spacing: languageManager.current == .japanese ? 0 : 8, lineSpacing: 6) {
                        ForEach(Array(words.enumerated()), id: \.offset) { i, word in
                            if i == words.count - 1 {
                                swapCell(fallback: word, style: style)
                            } else {
                                wordCell(word, bold: i < boldCount, style: style)
                            }
                        }
                    }
                }
                .padding(.horizontal, OV2CoreMetrics.sideInset)

                VStack {
                    Spacer()
                    OV2CoreTapHint(text: languageManager.text("onboardingV2.transform.tapHint"), visible: showHint)
                        .padding(.bottom, 28)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ov2Background()
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .onAppear { animate() }
        .onDisappear { animTask?.cancel() }
    }

    // MARK: - Cellules de mots (largeur fixe = largeur « gras »)

    private func wordCell(_ word: String, bold: Bool, style: Font.TextStyle) -> some View {
        ZStack {
            // Sizer invisible en gras : réserve toujours la largeur maximale du mot.
            Text(word).font(DS.title(style, .heavy)).opacity(0)
            Text(word)
                .font(DS.title(style, bold ? .heavy : .regular))
                .foregroundStyle(bold ? OV2.ink : OV2.inkTertiary)
                .animation(.easeOut(duration: 0.3), value: bold)
        }
        .fixedSize()
    }

    @ViewBuilder
    private func swapCell(fallback: String, style: Font.TextStyle) -> some View {
        let lastRevealed = boldCount >= words.count
        let text = swapping && !swapWords.isEmpty
            ? swapWords[swapIndex % swapWords.count]
            : (swapWords.first ?? fallback)
        // Le mot qui bascule est toujours en bleu d'accent, dès que le gras l'atteint.
        let color: Color = (swapping || lastRevealed) ? OV2.accent : OV2.inkTertiary

        ZStack {
            // Sizer : empile tous les mots possibles (gras) pour figer la largeur du slot.
            ForEach(swapWords.isEmpty ? [fallback] : swapWords, id: \.self) { w in
                Text(w).font(DS.title(style, .heavy)).opacity(0)
            }
            Text(text)
                .font(DS.title(style, (swapping || lastRevealed) ? .heavy : .regular))
                .foregroundStyle(color)
                .id(swapping ? swapIndex : -1)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
        }
        .fixedSize()
        .clipped()
    }

    // MARK: - Animation

    /// Cette page n'a pas de bouton : la seule indication qu'il faut taper est `showHint`,
    /// révélée à la fin de l'animation. Annulée en cours (rotation / redimensionnement de
    /// fenêtre sur iPad, retour d'arrière-plan), l'ancienne version laissait une phrase à
    /// moitié en gras, sans indice et sans issue visible — et `guard animTask == nil`
    /// interdisait tout redémarrage. L'animation reprend maintenant où elle en était, et
    /// l'indice s'affiche quoi qu'il arrive.
    private func animate() {
        animTask?.cancel()
        animTask = Task { @MainActor in
            await playAnimation()
            // Terminée ou interrompue, l'utilisateur sait toujours qu'il peut avancer.
            withAnimation(.easeIn(duration: 0.5)) { showHint = true }
            await playWordSwap()
        }
    }

    private func playAnimation() async {
        let count = words.count
        guard count > 0 else { return }

        // Gras progressif, mot par mot, repris à l'état courant.
        guard boldCount < count else { return }
        if boldCount == 0 {
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        for i in (boldCount + 1)...count {
            if Task.isCancelled { return }
            withAnimation(.easeOut(duration: 0.3)) { boldCount = i }
            OnboardingHaptics.selection()
            try? await Task.sleep(nanoseconds: 320_000_000)
        }
    }

    /// Bascule du dernier mot : culture → art → philosophie…
    private func playWordSwap() async {
        guard swapWords.count > 1 else { return }
        try? await Task.sleep(nanoseconds: 750_000_000)
        if Task.isCancelled { return }
        swapping = true
        while !Task.isCancelled {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.74)) {
                swapIndex += 1
            }
            OnboardingHaptics.selection()
            try? await Task.sleep(nanoseconds: 1_150_000_000)
        }
    }

    private func advance() {
        guard !advanced else { return }
        advanced = true
        animTask?.cancel()
        onNext()
    }
}

// MARK: - Flow layout (retour à la ligne, centré)

/// Layout de type « flow » : place les vues les unes après les autres et passe à la ligne quand
/// la largeur est dépassée, chaque ligne étant centrée. Utilisé pour aligner proprement des mots
/// dont la largeur est figée, sans le décalage d'un `Text` concaténé qui se remet en page.
struct OV2FlowLayout: Layout {
    var spacing: CGFloat = 7
    var lineSpacing: CGFloat = 10

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        let rows = layoutRows(maxWidth: maxWidth, subviews: subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: min(maxWidth, width), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let rows = layoutRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX + (bounds.width - row.width) / 2
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private func layoutRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let projected = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if !current.indices.isEmpty && projected > maxWidth {
                rows.append(current)
                current = Row(indices: [index], width: size.width, height: size.height)
            } else {
                current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
                current.height = max(current.height, size.height)
                current.indices.append(index)
            }
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
