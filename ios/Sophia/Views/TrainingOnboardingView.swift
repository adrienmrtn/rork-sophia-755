import SwiftUI

/// Mini-onboarding « Entraînement », déclenché par le bouton « Découvrir » de l'onglet
/// Révision. Trois écrans au style « Elevate arrondi » de l'onboarding principal (mêmes
/// briques : en-tête à flèche retour et barre de progression, titres à passage fort, cartes
/// bordées, bouton plein), puis, sans rupture, le paywall de fin d'onboarding (identique à
/// celui de l'OB classique).
///
/// - Écran 1 : bienvenue, l'illustration ronde et la phrase qui passe en gras mot après mot.
///   Pas de CTA : on tape pour passer à la suite.
/// - Écran 2 : l'active recall, illustré par un graphe de rétention (Sophia tient, la relecture
///   décroche) et une statistique. CTA « Comment ça marche ».
/// - Écran 3 : l'algorithme de révision continue. CTA « Continuer ».
/// - Puis : le paywall annuel de fin d'onboarding (`OnboardingV2PaywallAnnual`), puis son
///   paywall comparatif, exactement comme à la fin de l'onboarding classique.
///
/// Une fois parcouru une première fois (`TutorialFlags.trainingOnboarding`), l'appelant fait
/// démarrer ce flux directement sur le paywall (le bouton « Découvrir » devient « Débloquer »).
struct TrainingOnboardingView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    let store: StoreViewModel
    /// Si vrai, on saute les 3 écrans d'onboarding et on ouvre directement le paywall.
    var startAtPaywall: Bool = false
    /// Appelé quand l'utilisateur atteint la fin des 3 écrans (à marquer comme « vu »).
    var onCompletedOnboarding: () -> Void = {}
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    var onClose: () -> Void = {}

    private enum Step: Hashable { case welcome, recall, algorithm, paywallAnnual, paywallComparison }

    private let steps: [Step] = [.welcome, .recall, .algorithm, .paywallAnnual, .paywallComparison]

    @State private var stepIndex: Int = 0
    /// Sens de la dernière navigation : la transition glisse dans l'autre sens au retour.
    @State private var slidesForward = true

    private var current: Step {
        steps.indices.contains(stepIndex) ? steps[stepIndex] : .paywallAnnual
    }

    private var isPaywall: Bool { current == .paywallAnnual || current == .paywallComparison }

    /// Nombre d'écrans de présentation, ceux que la barre de progression compte.
    private var introCount: Int { steps.filter { $0 == .welcome || $0 == .recall || $0 == .algorithm }.count }

    private var progressValue: Double {
        guard introCount > 0 else { return 1 }
        return Double(min(stepIndex + 1, introCount)) / Double(introCount)
    }

    var body: some View {
        ZStack {
            OV2.bg.ignoresSafeArea()

            page(for: current)
                .id(current)
                .transition(.ov2Slide(
                    forward: slidesForward,
                    mirrored: layoutDirection == .rightToLeft,
                    distance: reduceMotion ? 0 : 64
                ))
        }
        // L'en-tête de l'onboarding principal ; les paywalls gardent leur propre haut d'écran.
        .safeAreaInset(edge: .top, spacing: 0) {
            if !isPaywall {
                OnboardingV2Header(
                    backLabel: languageManager.text("training.backToTraining"),
                    onBack: goBack
                ) {
                    DSProgressBar(value: progressValue)
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.light)
        // Glissement posé, sans rebond.
        .animation(.easeOut(duration: 0.38), value: stepIndex)
        .onAppear {
            if startAtPaywall, let idx = steps.firstIndex(of: .paywallAnnual) {
                stepIndex = idx
            }
        }
    }

    @ViewBuilder
    private func page(for step: Step) -> some View {
        switch step {
        case .welcome:
            WelcomeReadingPage(onContinue: advance)
        case .recall:
            ActiveRecallPage(onNext: advance)
        case .algorithm:
            AlgorithmPage(onNext: advance)
        case .paywallAnnual:
            OnboardingV2PaywallAnnual(
                store: store,
                onSubscribed: onPurchased,
                onClose: goToStep(.paywallComparison)
            )
        case .paywallComparison:
            OnboardingV2PaywallComparison(
                store: store,
                onSubscribed: onPurchased,
                onClose: onClose
            )
        }
    }

    private func advance() {
        let next = stepIndex + 1
        guard steps.indices.contains(next) else { onClose(); return }
        if steps[next] == .paywallAnnual {
            onCompletedOnboarding()
        }
        // Le bouton a déjà vibré : pas de seconde vibration au changement d'écran.
        if !OV2HapticGate.justConfirmed {
            OnboardingHaptics.selection()
        }
        move(to: next, forward: true)
    }

    /// La flèche de l'en-tête : l'écran précédent, ou la sortie depuis le premier.
    private func goBack() {
        guard stepIndex > 0 else { onClose(); return }
        OnboardingHaptics.selection()
        move(to: stepIndex - 1, forward: false)
    }

    private func goToStep(_ step: Step) -> () -> Void {
        { if let idx = steps.firstIndex(of: step) { move(to: idx, forward: true) } }
    }

    /// Change d'écran. La transition d'un écran qui sort est celle qu'il portait à son dernier
    /// rendu : quand le sens change, il est posé d'abord, et l'index au tour de boucle suivant
    /// (comme dans `OnboardingV2View`).
    private func move(to index: Int, forward: Bool) {
        if slidesForward == forward {
            stepIndex = index
        } else {
            slidesForward = forward
            DispatchQueue.main.async {
                stepIndex = index
            }
        }
    }
}

// MARK: - Briques de la page

/// Le titre `titleKey` avec son passage fort entouré de `**` (rendu en gras bleu par
/// `OV2CoreHighlightTitle`). Le passage vient de la table `trainingOnboarding`, langue par
/// langue ; s'il manque ou ne figure plus dans le titre, le titre revient tel quel.
private enum TrainingOnboardingText {
    static func marked(_ titleKey: String, highlightKey: String, language: AppLanguage) -> String {
        let title: String = AppLocalizable.string(titleKey, language: language)
        guard !title.contains("**"),
              let passage = AppLocalizableAdditions.trainingOnboarding[highlightKey]?[language.rawValue],
              !passage.isEmpty,
              let range = title.range(of: passage)
        else { return title }
        return title.replacingCharacters(in: range, with: "**" + passage + "**")
    }
}

/// Apparition d'un bloc une fois l'écran arrivé : fondu et légère montée, en ease-out, sans
/// rebond. `index` décale les blocs l'un après l'autre.
private struct TrainingReveal: ViewModifier {
    let index: Int
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 12)
            .onAppear {
                guard !shown else { return }
                withAnimation(.easeOut(duration: 0.45).delay(0.12 + Double(index) * 0.09)) {
                    shown = true
                }
            }
    }
}

private extension View {
    func trainingReveal(_ index: Int) -> some View {
        modifier(TrainingReveal(index: index))
    }
}

/// Illustration ronde d'une page, sur le bleu pâle du style : l'affiche de l'Entraînement ou
/// un pictogramme.
private struct TrainingRoundArt: View {
    var imageName: String? = nil
    var systemImage: String? = nil
    var size: CGFloat = 160

    var body: some View {
        ZStack {
            Circle().fill(DS.accentTint)
            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(DS.accent)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Écran 1 — Bienvenue (la phrase passe en gras mot après mot)

/// Un seul énoncé, en très grand sous l'illustration ronde : chaque mot passe du gris léger au
/// gras, au rythme d'une lecture calme, comme l'écran « Personnalisons ton contenu » de
/// l'onboarding. Pas de CTA : un appui n'importe où passe à la suite.
private struct WelcomeReadingPage: View {
    @Environment(LanguageManager.self) private var languageManager
    let onContinue: () -> Void

    @State private var boldCount = 0
    @State private var showHint = false
    @State private var leaving = false
    @State private var animTask: Task<Void, Never>?

    private var words: [String] {
        TextSegmentation.animationWords(languageManager.text("training.ob.welcome.line"))
    }

    var body: some View {
        GeometryReader { geo in
            let style: Font.TextStyle = OV2CoreMetrics.sentenceStyle(
                words: words,
                width: geo.size.width - OV2CoreMetrics.sideInset * 2
            )
            // L'illustration rétrécit, puis s'efface, quand la phrase a besoin de la hauteur.
            let artSize: CGFloat = OV2CoreMetrics.artSize(base: 160, available: geo.size.height, reserved: 330)
            ZStack {
                VStack(spacing: 26) {
                    if artSize > 0 {
                        TrainingRoundArt(imageName: "training_poster", size: artSize)
                            .trainingReveal(0)
                    }

                    OV2FlowLayout(spacing: languageManager.current == .japanese ? 0 : 8, lineSpacing: 6) {
                        ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                            wordCell(word, bold: index < boldCount, style: style)
                        }
                    }
                }
                .padding(.horizontal, OV2CoreMetrics.sideInset)
                .padding(.bottom, 36)

                VStack {
                    Spacer()
                    OV2CoreTapHint(text: languageManager.text("explain.tapToClose"), visible: showHint)
                        .padding(.bottom, 28)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ov2Background()
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear { animate() }
        .onDisappear { animTask?.cancel() }
    }

    /// Chaque mot occupe sa largeur « gras » : la phrase ne bouge pas quand le gras arrive.
    private func wordCell(_ word: String, bold: Bool, style: Font.TextStyle) -> some View {
        ZStack {
            Text(word).font(DS.title(style, .heavy)).opacity(0)
            Text(word)
                .font(DS.title(style, bold ? .heavy : .regular))
                .foregroundStyle(bold ? OV2.ink : OV2.inkTertiary)
                .animation(.easeOut(duration: 0.3), value: bold)
        }
        .fixedSize()
    }

    /// Sans bouton, la seule indication qu'il faut toucher l'écran est `showHint` : elle
    /// s'affiche que l'animation soit allée au bout ou qu'elle ait été interrompue.
    private func animate() {
        guard !showHint else { return }
        animTask?.cancel()
        animTask = Task { @MainActor in
            await playAnimation()
            withAnimation(.easeOut(duration: 0.5)) { showHint = true }
        }
    }

    /// Gras progressif, mot par mot, repris à l'état courant.
    private func playAnimation() async {
        let count: Int = words.count
        guard count > 0, boldCount < count else { return }
        if boldCount == 0 {
            try? await Task.sleep(nanoseconds: 550_000_000)
        }
        for index in (boldCount + 1)...count {
            if Task.isCancelled { return }
            withAnimation(.easeOut(duration: 0.3)) { boldCount = index }
            OnboardingHaptics.selection()
            try? await Task.sleep(nanoseconds: 340_000_000)
        }
    }

    private func finish() {
        guard !leaving else { return }
        leaving = true
        animTask?.cancel()
        onContinue()
    }
}

// MARK: - Écran 2 — Active recall (graphe de rétention + statistique)

private struct ActiveRecallPage: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    var body: some View {
        OV2ScrollableContent {
            VStack(spacing: 0) {
                OV2CoreHighlightTitle(
                    text: TrainingOnboardingText.marked(
                        "training.ob.recall.title",
                        highlightKey: "training.ob.recall.titleHighlight",
                        language: languageManager.current
                    )
                )
                .padding(.top, OV2End.top)
                .trainingReveal(0)

                RetentionGraph()
                    .padding(.top, 24)
                    .trainingReveal(1)

                statCard
                    .padding(.top, 14)
                    .trainingReveal(2)
            }
            .padding(.horizontal, OV2End.side)
            .padding(.bottom, 16)
        } footer: {
            OnboardingV2Button(title: languageManager.text("training.ob.recall.cta"), action: onNext)
        }
        .ov2Background()
    }

    /// La statistique, dans une carte du style : le chiffre en gras bleu au fil de la phrase.
    private var statCard: some View {
        let prefix = Text(languageManager.text("training.ob.recall.stat.prefix") + " ")
        let highlight = Text(languageManager.text("training.ob.recall.stat.highlight"))
            .font(DS.sans(.subheadline, .bold))
            .foregroundColor(DS.accent)
        let suffix = Text(" " + languageManager.text("training.ob.recall.stat.suffix"))
        return (prefix + highlight + suffix)
            .font(DS.sans(.subheadline, .medium))
            .foregroundStyle(DS.inkSecondary)
            .lineSpacing(3)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .ov2EndCard()
    }
}

/// Graphe de rétention animé, dans les couleurs de la courbe « 90 jours » de l'onboarding :
/// deux courbes partent ensemble au sommet, puis la sombre (relecture) décroche vite tandis
/// que la bleue (Sophia) tient dans le temps.
private struct RetentionGraph: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var progress: CGFloat = 0
    @State private var showLegend = false

    /// Fond très légèrement bleuté de la carte du graphique (celui de `OnboardingV2Curve90`).
    private static let cardFill = Color(red: 0.969, green: 0.976, blue: 0.992)
    private static let axisColor = Color(red: 0.765, green: 0.796, blue: 0.847)

    private var sophiaColor: Color { DS.accent }
    private var rereadColor: Color { DS.ink }

    // Rétention (0 en bas, 1 en haut) en fonction du temps normalisé x ∈ [0, 1].
    private func sophia(_ x: CGFloat) -> CGFloat { 0.70 + 0.30 * exp(-0.45 * x * 3.0) }
    private func reread(_ x: CGFloat) -> CGFloat { 0.10 + 0.90 * exp(-3.1 * x) }

    var body: some View {
        VStack(spacing: 14) {
            GeometryReader { geo in
                let w: CGFloat = geo.size.width
                let h: CGFloat = geo.size.height
                ZStack {
                    // Grille horizontale discrète.
                    ForEach(0..<4, id: \.self) { i in
                        let y: CGFloat = h * CGFloat(i) / 3.0
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: w, y: y))
                        }
                        .stroke(Self.axisColor.opacity(i == 3 ? 1 : 0.45), lineWidth: i == 3 ? 1.5 : 1)
                    }

                    // Aire sous la courbe bleue.
                    curvePath(in: geo.size, curve: sophia, closed: true)
                        .fill(
                            LinearGradient(
                                colors: [sophiaColor.opacity(0.16), sophiaColor.opacity(0.0)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .mask(revealMask(width: w, height: h))

                    // Courbe sombre (relecture) qui décroche.
                    curvePath(in: geo.size, curve: reread, closed: false)
                        .stroke(rereadColor, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                        .mask(revealMask(width: w, height: h))

                    // Courbe bleue (Sophia) qui tient.
                    curvePath(in: geo.size, curve: sophia, closed: false)
                        .stroke(sophiaColor, style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round))
                        .mask(revealMask(width: w, height: h))

                    // Points en tête de courbe.
                    endpointDot(in: geo.size, curve: reread, color: rereadColor)
                    endpointDot(in: geo.size, curve: sophia, color: sophiaColor)
                }
            }
            .frame(height: 170)

            legend
                .opacity(showLegend ? 1 : 0)
        }
        .padding(EdgeInsets(top: 18, leading: 16, bottom: 14, trailing: 16))
        .ov2EndCard(fill: Self.cardFill)
        .onAppear {
            guard progress == 0 else { return }
            if reduceMotion {
                progress = 1
                showLegend = true
                return
            }
            withAnimation(.easeInOut(duration: 1.6).delay(0.4)) { progress = 1 }
            withAnimation(.easeOut(duration: 0.5).delay(1.9)) { showLegend = true }
        }
    }

    private func point(in size: CGSize, curve: (CGFloat) -> CGFloat, x: CGFloat) -> CGPoint {
        let padTop: CGFloat = 6
        let usableH = size.height - padTop
        let px = x * size.width
        let py = padTop + usableH * (1 - curve(x))
        return CGPoint(x: px, y: py)
    }

    private func curvePath(in size: CGSize, curve: @escaping (CGFloat) -> CGFloat, closed: Bool) -> Path {
        Path { p in
            let steps = 60
            var first = true
            for i in 0...steps {
                let x = CGFloat(i) / CGFloat(steps)
                let pt = point(in: size, curve: curve, x: x)
                if first { p.move(to: pt); first = false } else { p.addLine(to: pt) }
            }
            if closed {
                p.addLine(to: CGPoint(x: size.width, y: size.height))
                p.addLine(to: CGPoint(x: 0, y: size.height))
                p.closeSubpath()
            }
        }
    }

    /// Masque de révélation gauche→droite piloté par `progress`.
    private func revealMask(width: CGFloat, height: CGFloat) -> some View {
        Rectangle()
            .frame(width: max(0, width * progress), height: height)
            .frame(width: width, height: height, alignment: .leading)
    }

    private func endpointDot(in size: CGSize, curve: @escaping (CGFloat) -> CGFloat, color: Color) -> some View {
        let pt = point(in: size, curve: curve, x: progress)
        return Circle()
            .fill(color)
            .frame(width: 11, height: 11)
            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
            .position(pt)
            .opacity(progress > 0.02 ? 1 : 0)
    }

    private var legend: some View {
        HStack(spacing: 18) {
            legendItem(color: sophiaColor, label: languageManager.text("training.ob.recall.legend.sophia"))
            legendItem(color: rereadColor, label: languageManager.text("training.ob.recall.legend.reread"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 7) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(label)
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(DS.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }
}

// MARK: - Écran 3 — L'algorithme de révision continue

private struct AlgorithmPage: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    var body: some View {
        OV2ScrollableContent {
            VStack(spacing: 0) {
                OV2CoreHighlightTitle(
                    text: TrainingOnboardingText.marked(
                        "training.ob.algo.title",
                        highlightKey: "training.ob.algo.titleHighlight",
                        language: languageManager.current
                    )
                )
                .padding(.top, OV2End.top)
                .trainingReveal(0)

                Text(languageManager.text("training.ob.algo.body"))
                    .font(DS.sans(.callout))
                    .lineSpacing(4)
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
                    .trainingReveal(1)

                TrainingRoundArt(systemImage: "brain.head.profile", size: 128)
                    .padding(.top, 30)
                    .trainingReveal(2)

                highlightCard
                    .padding(.top, 30)
                    .trainingReveal(3)
            }
            .padding(.horizontal, OV2End.side)
            .padding(.bottom, 16)
        } footer: {
            OnboardingV2Button(title: languageManager.text("training.ob.cta.last"), action: onNext)
        }
        .ov2Background()
    }

    /// « 5 min/jour » : la carte teintée du style, le chiffre en bleu.
    private var highlightCard: some View {
        HStack(spacing: 16) {
            Text(languageManager.text("training.ob.algo.highlight.value"))
                .font(CourseType.font(26, .heavy, relativeTo: .title2))
                .foregroundStyle(DS.accent)
                .fixedSize()
            Text(languageManager.text("training.ob.algo.highlight.label"))
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ov2EndCard(fill: DS.accentTint, border: DS.accent)
    }
}
