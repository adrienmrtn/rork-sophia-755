import SwiftUI

/// Mini-onboarding « Entraînement », déclenché par le bouton « Découvrir » de l'onglet
/// Révision. Trois écrans très satisfaisants (même direction artistique que l'OB principal),
/// puis — sans rupture — le paywall entraînement, présenté comme la simple **suite** de cet
/// onboarding.
///
/// - Écran 1 : bienvenue dans l'entraînement.
/// - Écran 2 : les stats (révélées progressivement).
/// - Écran 3 : comment ça marche (répétition espacée : J+1 / J+3 / J+7 …).
/// - Puis : `SophiaTrainingPaywall`, dans le même plein écran.
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

    private enum Step: Hashable { case welcome, stats, how, paywall }

    private let steps: [Step] = [.welcome, .stats, .how, .paywall]

    @State private var stepIndex: Int = 0

    private var current: Step {
        steps.indices.contains(stepIndex) ? steps[stepIndex] : .paywall
    }

    private var dotTotal: Int { steps.filter { $0 != .paywall }.count }

    var body: some View {
        ZStack {
            OV2.bg.ignoresSafeArea()

            page(for: current)
                .id(current)
                .transition(.ov2)
        }
        .overlay(alignment: .top) {
            if current != .paywall {
                OnboardingV2ProgressDots(current: stepIndex, total: dotTotal)
                    .padding(.top, 14)
                    .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.light)
        .animation(.spring(response: 0.6, dampingFraction: 0.9), value: stepIndex)
        .onAppear {
            if startAtPaywall, let idx = steps.firstIndex(of: .paywall) {
                stepIndex = idx
            }
        }
    }

    @ViewBuilder
    private func page(for step: Step) -> some View {
        switch step {
        case .welcome:
            welcomePage
        case .stats:
            statsPage
        case .how:
            howPage
        case .paywall:
            SophiaTrainingPaywall(
                store: store,
                onPurchased: onPurchased,
                onRestored: onRestored,
                onDismissed: onClose
            )
        }
    }

    private func advance() {
        let next = stepIndex + 1
        guard steps.indices.contains(next) else { onClose(); return }
        if steps[next] == .paywall {
            onCompletedOnboarding()
        }
        OnboardingHaptics.selection()
        stepIndex = next
    }

    // MARK: - Écran 1 — Bienvenue

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            TrainingOBHeroIcon(systemName: "arrow.triangle.2.circlepath")

            Spacer().frame(height: 34)

            Text(languageManager.text("training.ob.welcome.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .ov2Reveal(delay: 0.15)

            Spacer().frame(height: 14)

            Text(languageManager.text("training.ob.welcome.subtitle"))
                .font(DS.sans(.body, .medium))
                .foregroundStyle(OV2.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 34)
                .ov2Reveal(delay: 0.3)

            Spacer()

            OnboardingV2Button(title: languageManager.text("common.continue"), action: advance)
        }
        .ov2Background()
    }

    // MARK: - Écran 2 — Les stats (révélées progressivement)

    private var statsPage: some View {
        StatsRevealPage(onNext: advance)
    }

    // MARK: - Écran 3 — Comment ça marche

    private var howPage: some View {
        HowItWorksRevealPage(onNext: advance)
    }
}

// MARK: - Hero icon partagé

private struct TrainingOBHeroIcon: View {
    let systemName: String
    @State private var appeared = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(OV2.accentSoft.opacity(0.10))
                .frame(width: 200, height: 200)
                .scaleEffect(pulse ? 1.06 : 0.9)
                .blur(radius: 22)
            Circle()
                .fill(OV2.accent.opacity(0.10))
                .frame(width: 116, height: 116)
            Image(systemName: systemName)
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(OV2.accent)
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.1)) { appeared = true }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

// MARK: - Écran 2 : stats

private struct StatsRevealPage: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var revealed = 0

    private var stats: [(value: String, label: String)] {
        [
            (languageManager.text("training.ob.stat1.value"), languageManager.text("training.ob.stat1.label")),
            (languageManager.text("training.ob.stat2.value"), languageManager.text("training.ob.stat2.label")),
            (languageManager.text("training.ob.stat3.value"), languageManager.text("training.ob.stat3.label")),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 96)

            Text(languageManager.text("training.ob.stats.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .ov2Reveal(delay: 0.1)

            Spacer()

            VStack(spacing: 16) {
                ForEach(Array(stats.enumerated()), id: \.offset) { i, stat in
                    statRow(value: stat.value, label: stat.label)
                        .opacity(i < revealed ? 1 : 0)
                        .offset(y: i < revealed ? 0 : 24)
                        .scaleEffect(i < revealed ? 1 : 0.92)
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            for i in 0..<stats.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 + Double(i) * 0.55) {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) { revealed = i + 1 }
                    OnboardingHaptics.selection()
                }
            }
        }
    }

    private func statRow(value: String, label: String) -> some View {
        HStack(spacing: 18) {
            Text(value)
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(OV2.accent)
                .frame(minWidth: 92, alignment: .leading)
            Text(label)
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OV2.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(OV2.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
    }
}

// MARK: - Écran 3 : comment ça marche (répétition espacée)

private struct HowItWorksRevealPage: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var revealed = 0

    /// Intervalles réels de répétition espacée (jours) — source de vérité côté progression.
    private var intervals: [Int] { ProgressManager.trainingIntervalDays }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 96)

            VStack(spacing: 12) {
                Text(languageManager.text("training.ob.how.title"))
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                Text(languageManager.text("training.ob.how.subtitle"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(OV2.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 30)
            .ov2Reveal(delay: 0.1)

            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(intervals.enumerated()), id: \.offset) { i, day in
                    timelineRow(index: i, day: day, isLast: i == intervals.count - 1)
                        .opacity(i < revealed ? 1 : 0)
                        .offset(x: i < revealed ? 0 : -18)
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            OnboardingV2Button(title: languageManager.text("training.ob.cta.last"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            for i in 0..<intervals.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(i) * 0.32) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { revealed = i + 1 }
                    OnboardingHaptics.selection()
                }
            }
        }
    }

    private func timelineRow(index: Int, day: Int, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(OV2.accent.opacity(0.12)).frame(width: 40, height: 40)
                    Text("J+\(day)")
                        .font(DS.sans(.caption2, .bold))
                        .foregroundStyle(OV2.accent)
                }
                if !isLast {
                    Rectangle()
                        .fill(OV2.accent.opacity(0.18))
                        .frame(width: 2, height: 28)
                }
            }
            Text(String(format: languageManager.text("training.ob.how.interval"), day))
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(OV2.ink)
                .padding(.top, 9)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}
