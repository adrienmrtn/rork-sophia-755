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
struct OnboardingV2PhoneTime: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var minutes: Double = 180
    @State private var lastStep: Int = 6

    private let range: ClosedRange<Double> = 30...600
    private let step: Double = 30

    var body: some View {
        // Big number, slider and labels: at a large text size on a short phone the CTA below
        // them went off screen. Scrolls instead, with the button pinned.
        OV2ScrollableContent {
            pageBody
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

    /// Page content, unchanged; the container above is what keeps the CTA on screen.
    private var pageBody: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 84)

            Text(languageManager.text("onboardingV2.phoneTime.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .ov2Reveal(delay: 0.1)

            Spacer()

            Text(OnboardingScreenTimeFormat.label(minutes: Int(minutes), language: languageManager.current))
                .font(.system(size: 68, weight: .heavy, design: .rounded))
                .foregroundStyle(OV2.accent)
                .monospacedDigit()
                .contentTransition(.numericText(value: minutes))
                .animation(.spring(response: 0.35, dampingFraction: 0.82), value: minutes)

            Spacer().frame(height: 32)

            VStack(spacing: 8) {
                Slider(value: $minutes, in: range, step: step)
                    .tint(OV2.accent)
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
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(OV2.inkTertiary)
            }
            .padding(.horizontal, 36)
            .ov2Reveal(delay: 0.3)

            Spacer()
        }
    }
}

// MARK: - Page 2/4 — Ta vie en années (80 carrés)

/// 80 carrés = 80 années de vie. Ils se colorent par tiers : le sommeil en vert, le travail
/// en marron, puis le temps libre qui reste. Ensuite tout s'efface sauf le temps libre, et
/// dedans, carré après carré, en rouge, les années passées sur le téléphone (d'après le temps
/// d'écran quotidien déclaré) ; le nombre s'affiche en grand, puis la phrase.
struct OnboardingV2YearsGrid: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    /// Nombre de carrés gris révélés (phase 1 : ouverture de la grille).
    @State private var revealed: Int = 0
    /// Carrés colorés de chaque tiers, dans l'ordre où ils se remplissent.
    @State private var sleepFilled: Int = 0
    @State private var workFilled: Int = 0
    @State private var freeFilled: Int = 0
    /// Carrés rouges dans le temps libre (phase finale : années passées sur le téléphone).
    @State private var screenFilled: Int = 0
    /// `true` quand le sommeil et le travail s'effacent pour ne laisser que le temps libre.
    @State private var focusPhone = false
    @State private var showTitle = false
    @State private var showNumber = false
    @State private var showCaption = false
    @State private var showButton = false
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

    private var freeYears: Int {
        totalYears - sleepYears - workYears
    }

    /// Années de temps libre passées sur le téléphone : le temps d'écran quotidien rapporté à
    /// 80 ans, borné au temps libre (au-delà, tout le temps libre y passe).
    private var screenYears: Int {
        max(1, min(freeYears, Int(vm.phoneYearsOverLife.rounded())))
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
    }

    var body: some View {
        // The 80-square grid is the tallest block in the flow. On an iPad in landscape it
        // grew until the button sat hundreds of points below the fold, and on a short
        // phone at a large text size the caption pushed it off the bottom. Scrolls, with
        // the button pinned; `ov2Background` caps the width on a tablet.
        OV2ScrollableContent {
            pageBody
        } footer: {
            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
                .opacity(showButton ? 1 : 0)
                .allowsHitTesting(showButton)
        }
        .ov2Background()
        .onAppear { startSequence() }
        .onDisappear { animTask?.cancel() }
    }

    /// Page content; the container above is what keeps the CTA on screen.
    private var pageBody: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 64)

            Text(languageManager.text("onboardingV2.yearsGrid.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 14)

            Spacer().frame(height: 26)

            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(0..<totalYears, id: \.self) { i in
                    let isRevealed = i < revealed
                    let filled = isFilled(i)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(squareColor(i))
                        .aspectRatio(1, contentMode: .fit)
                        .scaleEffect(isRevealed ? (filled ? 1 : 0.9) : 0.3)
                        .opacity(isRevealed ? squareOpacity(i) : 0)
                }
            }
            .padding(.horizontal, 36)

            Spacer().frame(height: 20)

            legend
                .padding(.horizontal, 28)

            Spacer().frame(height: 18)

            // Le nombre en grand, puis la phrase : c'est ce que la page veut faire retenir.
            Text(AppLocalizable.yearsString(screenYears, language: languageManager.current))
                .font(.jakarta(size: 44, weight: .heavy))
                .foregroundStyle(OV2.danger)
                .monospacedDigit()
                .scaleEffect(showNumber ? 1 : 0.6)
                .opacity(showNumber ? 1 : 0)

            Text(String(
                format: languageManager.text("onboardingV2.yearsGrid.captionFree"),
                freeYears, screenYears
            ))
            .font(DS.sans(.body, .bold))
            .foregroundStyle(OV2.danger)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 32)
            .padding(.top, 8)
            .opacity(showCaption ? 1 : 0)
            .offset(y: showCaption ? 0 : 12)

            // Le pendant du `Spacer(minLength: 64)` du haut : les deux ensemble recentrent
            // le contenu quand il tient, et se réduisent dès que ça défile.
            Spacer(minLength: 48)
        }
    }

    // MARK: - Couleurs des carrés

    /// Le carré `i` dans l'ordre de la grille : sommeil, travail, puis temps libre (où les
    /// premiers carrés deviennent rouges).
    private func squareColor(_ i: Int) -> Color {
        if i < sleepYears {
            return i < sleepFilled ? Self.sleepColor : OV2.hairline.opacity(0.7)
        }
        let work = i - sleepYears
        if work < workYears {
            return work < workFilled ? Self.workColor : OV2.hairline.opacity(0.7)
        }
        let free = i - sleepYears - workYears
        if free < screenFilled { return OV2.danger }
        return free < freeFilled ? Self.freeColor : OV2.hairline.opacity(0.7)
    }

    private func isFilled(_ i: Int) -> Bool {
        if i < sleepYears { return i < sleepFilled }
        let work = i - sleepYears
        if work < workYears { return work < workFilled }
        let free = i - sleepYears - workYears
        return free < freeFilled || free < screenFilled
    }

    /// Le sommeil et le travail s'effacent quand le temps libre devient le sujet.
    private func squareOpacity(_ i: Int) -> Double {
        (focusPhone && i < sleepYears + workYears) ? 0.3 : 1
    }

    // MARK: - Légende

    /// Une pastille par tiers, qui apparaît quand son tiers commence à se colorer.
    private var legend: some View {
        OV2FlowLayout(spacing: 8, lineSpacing: 8) {
            legendChip(color: Self.sleepColor, textColor: Self.sleepColor, key: "onboardingV2.yearsGrid.sleep", years: sleepYears, shown: sleepFilled > 0, dimmed: focusPhone)
            legendChip(color: Self.workColor, textColor: Self.workColor, key: "onboardingV2.yearsGrid.work", years: workYears, shown: workFilled > 0, dimmed: focusPhone)
            legendChip(color: Self.freeColor, textColor: OV2.accentSoft, key: "onboardingV2.yearsGrid.free", years: freeYears, shown: freeFilled > 0, dimmed: false)
            legendChip(color: OV2.danger, textColor: OV2.danger, key: "onboardingV2.yearsGrid.screen", years: screenYears, shown: screenFilled > 0, dimmed: false)
        }
    }

    private func legendChip(color: Color, textColor: Color, key: String, years: Int, shown: Bool, dimmed: Bool) -> some View {
        HStack(spacing: 7) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(languageManager.text(key))
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(OV2.ink)
            Text(AppLocalizable.yearsString(years, language: languageManager.current))
                .font(DS.sans(.caption, .bold))
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(OV2.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(OV2.hairline, lineWidth: 1))
        .opacity(shown ? (dimmed ? 0.45 : 1) : 0)
        .scaleEffect(shown ? 1 : 0.85)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: shown)
        .animation(.easeInOut(duration: 0.5), value: dimmed)
    }

    // MARK: - Séquence

    /// Démarre (ou reprend) l'enchaînement, et garantit que le CTA finit toujours par
    /// apparaître.
    ///
    /// La séquence était annulée par `onDisappear`, et `guard animTask == nil` empêchait
    /// ensuite tout redémarrage : une seule interruption (rotation, redimensionnement de
    /// fenêtre sur iPad, retour depuis l'arrière-plan) laissait la grille figée **sans
    /// bouton**, donc un onboarding sans issue. C'est le blocage signalé par l'App Store
    /// (Guideline 2.1(a), « indefinite loading during onboarding », iPad Air M3 / iPadOS 26.6.2).
    ///
    /// Désormais : la séquence reprend là où elle s'était arrêtée, et qu'elle aille au bout
    /// ou qu'elle soit interrompue, le bouton est révélé dans tous les cas.
    private func startSequence() {
        guard !sequenceDone else { return }
        animTask?.cancel()
        animTask = Task { @MainActor in
            let finished = await playSequence()
            if finished { sequenceDone = true }
            // Terminée ou interrompue, la page offre toujours une sortie.
            withAnimation(.easeOut(duration: 0.5)) { showButton = true }
        }
    }

    /// Enchaînement scénarisé, posé : (1) ouverture des 80 carrés gris, (2) titre, (3) sommeil
    /// en vert, travail en marron, temps libre en bleu pâle, chacun avec sa pastille,
    /// (4) le sommeil et le travail s'effacent, (5) carré après carré, en rouge, les années de
    /// temps libre passées sur le téléphone, (6) le nombre en grand, la phrase, le bouton.
    /// Reprend à l'état courant, donc rejouable sans repartir de zéro. Retourne `false` si
    /// elle a été annulée en cours de route.
    private func playSequence() async -> Bool {
        // Phase 1 — ouverture des carrés gris.
        if revealed < totalYears {
            try? await Task.sleep(nanoseconds: 300_000_000)
            for i in (revealed + 1)...totalYears {
                if Task.isCancelled { return false }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) { revealed = i }
                if i % 10 == 0 { OnboardingHaptics.selection() }
                try? await Task.sleep(nanoseconds: 10_000_000)
            }
        }

        // Phase 2 — « Voici ta vie en années ».
        if !showTitle {
            try? await Task.sleep(nanoseconds: 400_000_000)
            if Task.isCancelled { return false }
            withAnimation(.easeOut(duration: 0.7)) { showTitle = true }
            try? await Task.sleep(nanoseconds: 700_000_000)
        }

        // Phase 3 — les trois tiers, chacun le temps d'être lu.
        let sleepDone = await fill(to: sleepYears, from: sleepFilled, interval: 30_000_000) { sleepFilled = $0 }
        guard sleepDone else { return false }
        try? await Task.sleep(nanoseconds: 550_000_000)
        let workDone = await fill(to: workYears, from: workFilled, interval: 30_000_000) { workFilled = $0 }
        guard workDone else { return false }
        try? await Task.sleep(nanoseconds: 550_000_000)
        let freeDone = await fill(to: freeYears, from: freeFilled, interval: 30_000_000) { freeFilled = $0 }
        guard freeDone else { return false }
        try? await Task.sleep(nanoseconds: 700_000_000)

        // Phase 4 — le sommeil et le travail s'effacent : il ne reste que le temps libre.
        if !focusPhone {
            if Task.isCancelled { return false }
            withAnimation(.easeInOut(duration: 0.6)) { focusPhone = true }
            try? await Task.sleep(nanoseconds: 700_000_000)
        }

        // Phase 5 — les années de temps libre passées sur le téléphone, une par une.
        let target = screenYears
        if screenFilled < target {
            for i in (screenFilled + 1)...target {
                if Task.isCancelled { return false }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { screenFilled = i }
                OnboardingHaptics.counterTick(progress: Double(i) / Double(target))
                try? await Task.sleep(nanoseconds: 140_000_000)
            }
            OnboardingHaptics.counterComplete()
        }

        // Phase 6 — le nombre en grand, puis la phrase, puis le bouton (révélé par l'appelant).
        if !showNumber {
            try? await Task.sleep(nanoseconds: 250_000_000)
            if Task.isCancelled { return false }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { showNumber = true }
            try? await Task.sleep(nanoseconds: 450_000_000)
        }
        if !showCaption {
            if Task.isCancelled { return false }
            withAnimation(.easeOut(duration: 0.6)) { showCaption = true }
        }
        try? await Task.sleep(nanoseconds: 600_000_000)
        return !Task.isCancelled
    }

    /// Colore les carrés `from + 1` à `to` l'un après l'autre, `interval` entre deux.
    /// Retourne `false` si la tâche a été annulée.
    private func fill(to count: Int, from current: Int, interval: UInt64, apply: (Int) -> Void) async -> Bool {
        guard current < count else { return true }
        for i in (current + 1)...count {
            if Task.isCancelled { return false }
            withAnimation(.easeOut(duration: 0.25)) { apply(i) }
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
/// le dernier mot bascule (par le haut) entre « culture », « art », « philosophie »… en couleur.
/// Pas de CTA : on tape n'importe où pour continuer.
struct OnboardingV2Transform: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var boldCount = 0
    @State private var showHint = false
    @State private var advanced = false
    @State private var swapping = false
    @State private var swapIndex = 0
    @State private var animTask: Task<Void, Never>?

    /// Couleurs successives du mot qui bascule (la première reste l'accent, en continuité
    /// avec le dernier mot mis en gras).
    private let swapColors: [Color] = [
        OV2.accent,
        OV2.danger,
        OV2.warm,
        OV2.success,
        Color(red: 0.48, green: 0.36, blue: 0.82),
    ]

    private var words: [String] {
        languageManager.text("onboardingV2.transform.text")
            .split(separator: " ")
            .map(String.init)
    }

    private var swapWords: [String] {
        languageManager.text("onboardingV2.transform.words")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        ZStack {
            OV2.bg.ignoresSafeArea()

            OV2FlowLayout(spacing: 7, lineSpacing: 10) {
                ForEach(Array(words.enumerated()), id: \.offset) { i, word in
                    if i == words.count - 1 {
                        swapCell(fallback: word)
                    } else {
                        wordCell(word, bold: i < boldCount)
                    }
                }
            }
            .padding(.horizontal, 28)

            VStack {
                Spacer()
                Text(languageManager.text("onboardingV2.transform.tapHint"))
                    .font(DS.sans(.footnote, .semibold))
                    .foregroundStyle(OV2.inkTertiary)
                    .opacity(showHint ? 1 : 0)
                    .padding(.bottom, 40)
            }
        }
        .ov2Background()
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .onAppear { animate() }
        .onDisappear { animTask?.cancel() }
    }

    // MARK: - Cellules de mots (largeur fixe = largeur « gras »)

    private func wordCell(_ word: String, bold: Bool) -> some View {
        ZStack {
            // Sizer invisible en gras : réserve toujours la largeur maximale du mot.
            Text(word).font(DS.title(.title, .heavy)).opacity(0)
            Text(word)
                .font(DS.title(.title, bold ? .heavy : .regular))
                .foregroundStyle(bold ? OV2.ink : OV2.inkTertiary)
                .animation(.easeOut(duration: 0.3), value: bold)
        }
        .fixedSize()
    }

    @ViewBuilder
    private func swapCell(fallback: String) -> some View {
        let lastRevealed = boldCount >= words.count
        let text = swapping && !swapWords.isEmpty
            ? swapWords[swapIndex % swapWords.count]
            : (swapWords.first ?? fallback)
        let color = swapping
            ? swapColors[swapIndex % swapColors.count]
            : (lastRevealed ? OV2.accent : OV2.inkTertiary)

        ZStack {
            // Sizer : empile tous les mots possibles (gras) pour figer la largeur du slot.
            ForEach(swapWords.isEmpty ? [fallback] : swapWords, id: \.self) { w in
                Text(w).font(DS.title(.title, .heavy)).opacity(0)
            }
            Text(text)
                .font(DS.title(.title, (swapping || lastRevealed) ? .heavy : .regular))
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
