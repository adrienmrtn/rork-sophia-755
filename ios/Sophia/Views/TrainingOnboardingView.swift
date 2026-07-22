import SwiftUI

/// Mini-onboarding « Entraînement », déclenché par le bouton « Découvrir » de l'onglet
/// Révision. Trois écrans soignés (même direction artistique que l'OB principal), puis, sans
/// rupture, le paywall de fin d'onboarding (identique à celui de l'OB classique).
///
/// - Écran 1 : bienvenue, texte lent avec gras qui suit la lecture. Pas de CTA : on tape pour
///   passer à la suite.
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

    private var current: Step {
        steps.indices.contains(stepIndex) ? steps[stepIndex] : .paywallAnnual
    }

    private var isPaywall: Bool { current == .paywallAnnual || current == .paywallComparison }

    private var dotTotal: Int { steps.filter { $0 == .welcome || $0 == .recall || $0 == .algorithm }.count }

    var body: some View {
        ZStack {
            OV2.bg.ignoresSafeArea()

            page(for: current)
                .id(current)
                .transition(.ov2)
        }
        .overlay(alignment: .top) {
            if !isPaywall {
                OnboardingV2ProgressDots(current: stepIndex, total: dotTotal)
                    .padding(.top, 14)
                    .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.light)
        .animation(.spring(response: 0.6, dampingFraction: 0.9), value: stepIndex)
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
        OnboardingHaptics.selection()
        stepIndex = next
    }

    private func goToStep(_ step: Step) -> () -> Void {
        { if let idx = steps.firstIndex(of: step) { stepIndex = idx } }
    }
}

// MARK: - Écran 1 — Bienvenue (lecture lente, gras qui suit la lecture)

/// Un seul énoncé, révélé mot après mot : chaque mot passe d'un gris estompé à l'encre pleine,
/// au rythme d'une lecture calme. Pas de CTA : un appui n'importe où passe à la suite.
private struct WelcomeReadingPage: View {
    @Environment(LanguageManager.self) private var languageManager
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var readIndex = -1
    @State private var showHint = false
    @State private var leaving = false
    @State private var timer: Timer?

    private var words: [String] {
        languageManager.text("training.ob.welcome.line")
            .split(separator: " ")
            .map(String.init)
    }

    var body: some View {
        ZStack {
            OV2.bg.ignoresSafeArea()

            readingText
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.96)

            VStack {
                Spacer()
                Text(languageManager.text("explain.tapToClose"))
                    .font(DS.sans(.footnote, .semibold))
                    .foregroundStyle(OV2.inkTertiary)
                    .opacity(showHint ? 1 : 0)
                    .padding(.bottom, 46)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear { runReveal() }
        .onDisappear { timer?.invalidate() }
    }

    private var readingText: Text {
        let list = words
        return list.enumerated().reduce(Text("")) { acc, pair in
            let (i, word) = pair
            let isRead = i <= readIndex
            let suffix = i < list.count - 1 ? " " : ""
            let run = Text(word + suffix)
                .font(DS.title(.largeTitle, .heavy))
                .foregroundColor(isRead ? OV2.ink : OV2.inkTertiary.opacity(0.26))
            return acc + run
        }
    }

    private func runReveal() {
        withAnimation(.easeOut(duration: 0.7)) { appeared = true }
        // Révélation mot à mot, à un rythme de lecture posé.
        let count = words.count
        timer?.invalidate()
        var i = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.42, repeats: true) { t in
            guard i < count else {
                t.invalidate()
                withAnimation(.easeIn(duration: 0.7)) { showHint = true }
                return
            }
            withAnimation(.easeOut(duration: 0.45)) { readIndex = i }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
            i += 1
        }
        // Léger délai avant le premier mot pour laisser respirer l'entrée.
        timer?.fireDate = Date().addingTimeInterval(0.55)
    }

    private func finish() {
        guard !leaving else { return }
        leaving = true
        timer?.invalidate()
        onContinue()
    }
}

// MARK: - Écran 2 — Active recall (graphe de rétention + statistique)

private struct ActiveRecallPage: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 92)

            Text(languageManager.text("training.ob.recall.title"))
                .font(DS.title(.title2, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
                .ov2Reveal(delay: 0.1)

            Spacer(minLength: 24)

            RetentionGraph()
                .frame(height: 200)
                .padding(.horizontal, 24)
                .ov2Reveal(delay: 0.25)

            Spacer(minLength: 20)

            statLine
                .padding(.horizontal, 30)
                .ov2Reveal(delay: 0.4)

            Spacer(minLength: 24)

            OnboardingV2Button(title: languageManager.text("training.ob.recall.cta"), action: onNext)
        }
        .ov2Background()
    }

    private var statLine: some View {
        let prefix = Text(languageManager.text("training.ob.recall.stat.prefix") + " ")
            .font(DS.sans(.subheadline, .medium))
            .foregroundColor(OV2.inkSecondary)
        let highlight = Text(languageManager.text("training.ob.recall.stat.highlight"))
            .font(DS.sans(.subheadline, .heavy))
            .foregroundColor(OV2.accent)
        let suffix = Text(" " + languageManager.text("training.ob.recall.stat.suffix"))
            .font(DS.sans(.subheadline, .medium))
            .foregroundColor(OV2.inkSecondary)
        return (prefix + highlight + suffix)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Graphe de rétention animé : deux courbes partent ensemble au sommet, puis la grise
/// (relecture) décroche vite tandis que la dorée (Sophia) tient dans le temps.
private struct RetentionGraph: View {
    @Environment(LanguageManager.self) private var languageManager

    @State private var progress: CGFloat = 0
    @State private var showLegend = false

    private let gold = OV2.warm
    private var grey: Color { OV2.inkTertiary.opacity(0.55) }

    // Rétention (0 en bas, 1 en haut) en fonction du temps normalisé x ∈ [0, 1].
    private func sophia(_ x: CGFloat) -> CGFloat { 0.70 + 0.30 * exp(-0.45 * x * 3.0) }
    private func reread(_ x: CGFloat) -> CGFloat { 0.10 + 0.90 * exp(-3.1 * x) }

    var body: some View {
        VStack(spacing: 14) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    // Grille horizontale discrète.
                    ForEach(0..<4, id: \.self) { i in
                        let y = h * CGFloat(i) / 3.0
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: w, y: y))
                        }
                        .stroke(OV2.hairline.opacity(0.6), lineWidth: 1)
                    }

                    // Aire sous la courbe dorée.
                    curvePath(in: geo.size, curve: sophia, closed: true)
                        .fill(
                            LinearGradient(
                                colors: [gold.opacity(0.22), gold.opacity(0.0)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .mask(revealMask(width: w, height: h))

                    // Courbe grise (relecture) qui décroche.
                    curvePath(in: geo.size, curve: reread, closed: false)
                        .stroke(grey, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 6]))
                        .mask(revealMask(width: w, height: h))

                    // Courbe dorée (Sophia) qui tient.
                    curvePath(in: geo.size, curve: sophia, closed: false)
                        .stroke(gold, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        .mask(revealMask(width: w, height: h))

                    // Points en tête de courbe.
                    endpointDot(in: geo.size, curve: sophia, color: gold)
                    endpointDot(in: geo.size, curve: reread, color: grey)
                }
            }

            legend
                .opacity(showLegend ? 1 : 0)
        }
        .padding(16)
        .background(OV2.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(OV2.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).delay(0.35)) { progress = 1 }
            withAnimation(.easeIn(duration: 0.6).delay(1.9)) { showLegend = true }
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
            .frame(width: 9, height: 9)
            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
            .position(pt)
            .opacity(progress > 0.02 ? 1 : 0)
    }

    private var legend: some View {
        HStack(spacing: 18) {
            legendItem(color: gold, label: languageManager.text("training.ob.recall.legend.sophia"))
            legendItem(color: grey, label: languageManager.text("training.ob.recall.legend.reread"))
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 7) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(label)
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(OV2.inkSecondary)
        }
    }
}

// MARK: - Écran 3 — L'algorithme de révision continue

private struct AlgorithmPage: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 96)

            ZStack {
                Circle()
                    .fill(OV2.accent.opacity(0.10))
                    .frame(width: 132, height: 132)
                    .scaleEffect(pulse ? 1.05 : 0.92)
                    .blur(radius: 14)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(OV2.accent)
            }
            .ov2Reveal(delay: 0.05)

            Spacer().frame(height: 30)

            Text(languageManager.text("training.ob.algo.title"))
                .font(DS.title(.title2, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 30)
                .ov2Reveal(delay: 0.15)

            Spacer().frame(height: 14)

            Text(languageManager.text("training.ob.algo.body"))
                .font(DS.sans(.body, .medium))
                .foregroundStyle(OV2.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 34)
                .ov2Reveal(delay: 0.3)

            Spacer()

            highlightCard
                .padding(.horizontal, 28)
                .ov2Reveal(delay: 0.45)

            Spacer()

            OnboardingV2Button(title: languageManager.text("training.ob.cta.last"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    private var highlightCard: some View {
        HStack(spacing: 16) {
            Text(languageManager.text("training.ob.algo.highlight.value"))
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(OV2.accent)
                .fixedSize()
            Text(languageManager.text("training.ob.algo.highlight.label"))
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(OV2.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OV2.accent.opacity(0.07), in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(OV2.accent.opacity(0.18), lineWidth: 1))
    }
}
