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
}

// MARK: - Page 2/4 — Ta vie en années (80 carrés)

/// 80 carrés = 80 années de vie. Les carrés se remplissent lentement en rouge selon le
/// temps d'écran quotidien (part de vie passée sur le téléphone).
struct OnboardingV2YearsGrid: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    /// Nombre de carrés gris révélés (phase 1 : ouverture douce de la grille).
    @State private var revealed: Int = 0
    /// Nombre de carrés rouges remplis (phase 3 : années perdues).
    @State private var filled: Int = 0
    @State private var showTitle = false
    @State private var showCaption = false
    @State private var showButton = false
    @State private var animTask: Task<Void, Never>?

    private let totalYears = 80
    private let columns = 10

    private var redYears: Int {
        max(1, min(totalYears, Int(vm.phoneYearsOverLife.rounded())))
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 84)

            Text(languageManager.text("onboardingV2.yearsGrid.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 14)

            Spacer()

            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(0..<totalYears, id: \.self) { i in
                    let isRevealed = i < revealed
                    let isRed = i < filled
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(isRed ? OV2.danger : OV2.hairline.opacity(0.7))
                        .aspectRatio(1, contentMode: .fit)
                        .scaleEffect(isRevealed ? (isRed ? 1 : 0.9) : 0.3)
                        .opacity(isRevealed ? 1 : 0)
                }
            }
            .padding(.horizontal, 36)

            Spacer().frame(height: 28)

            Text(String(
                format: languageManager.text("onboardingV2.yearsGrid.caption"),
                redYears
            ))
            .font(DS.sans(.subheadline, .bold))
            .foregroundStyle(OV2.danger)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 36)
            .opacity(showCaption ? 1 : 0)
            .offset(y: showCaption ? 0 : 12)

            Spacer()

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
                .opacity(showButton ? 1 : 0)
                .allowsHitTesting(showButton)
        }
        .ov2Background()
        .onAppear { runSequence() }
        .onDisappear { animTask?.cancel() }
    }

    /// Enchaînement scénarisé : (1) ouverture des 80 carrés gris, (2) apparition douce du
    /// titre, (3) remplissage progressif des carrés rouges + texte rouge, (4) bouton.
    private func runSequence() {
        guard animTask == nil else { return }
        animTask = Task { @MainActor in
            // Phase 1 — ouverture lente et douce des carrés gris.
            try? await Task.sleep(nanoseconds: 350_000_000)
            for i in 1...totalYears {
                if Task.isCancelled { return }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) { revealed = i }
                if i % 8 == 0 { OnboardingHaptics.selection() }
                try? await Task.sleep(nanoseconds: 24_000_000)
            }

            // Phase 2 — « Voici ta vie en années » apparaît doucement.
            try? await Task.sleep(nanoseconds: 550_000_000)
            if Task.isCancelled { return }
            withAnimation(.easeOut(duration: 0.9)) { showTitle = true }

            // Phase 3 — remplissage lent des années perdues (rouge).
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            let target = redYears
            for i in 1...target {
                if Task.isCancelled { return }
                withAnimation(.easeInOut(duration: 0.4)) { filled = i }
                OnboardingHaptics.counterTick(progress: Double(i) / Double(target))
                try? await Task.sleep(nanoseconds: 150_000_000)
            }
            OnboardingHaptics.counterComplete()

            // Phase 4 — texte rouge puis bouton.
            try? await Task.sleep(nanoseconds: 350_000_000)
            if Task.isCancelled { return }
            withAnimation(.easeOut(duration: 0.7)) { showCaption = true }
            try? await Task.sleep(nanoseconds: 600_000_000)
            if Task.isCancelled { return }
            withAnimation(.easeOut(duration: 0.5)) { showButton = true }
        }
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

    private func animate() {
        guard animTask == nil else { return }
        animTask = Task { @MainActor in
            let count = words.count
            guard count > 0 else { showHint = true; return }

            // Gras progressif, mot par mot.
            try? await Task.sleep(nanoseconds: 500_000_000)
            for i in 1...count {
                if Task.isCancelled { return }
                withAnimation(.easeOut(duration: 0.3)) { boldCount = i }
                OnboardingHaptics.selection()
                try? await Task.sleep(nanoseconds: 320_000_000)
            }

            if Task.isCancelled { return }
            withAnimation(.easeIn(duration: 0.5)) { showHint = true }

            // Bascule du dernier mot : culture → art → philosophie…
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
