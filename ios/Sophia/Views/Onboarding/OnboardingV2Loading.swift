import SwiftUI
import UIKit

/// Page 9 — « On prépare ton parcours de connaissances » : trois barres qui se remplissent
/// comme un vrai chargement (vite au début, de plus en plus lentement vers la fin, chacune à
/// son rythme), puis la preuve sociale : des utilisateurs en photo, la note 4,8 entre deux
/// lauriers, « 500 000 utilisateurs lisent des cours sur Sophia tous les mois », et le CTA
/// « voir mon profil ».
struct OnboardingV2Loading: View {
    @Environment(LanguageManager.self) private var languageManager
    var firstName: String = ""
    let onNext: () -> Void

    @State private var progress: [Double] = [0, 0, 0]
    @State private var completed: [Bool] = [false, false, false]
    @State private var allDone = false
    @State private var animTask: Task<Void, Never>?
    @State private var photos: [UIImage] = []

    /// Durée de chaque barre : trois chargements différents, comme trois vraies étapes.
    private static let durations: [Double] = [1.3, 2.2, 1.6]

    private var stepKeys: [String] {
        ["onboardingV2.loading.step1", "onboardingV2.loading.step2", "onboardingV2.loading.step3"]
    }

    var body: some View {
        // Trois barres, les photos, les lauriers et deux phrases : trop haut pour un petit
        // iPhone en grande taille de texte. Défile, avec le bouton épinglé.
        OV2ScrollableContent {
            VStack(spacing: 0) {
                Spacer().frame(height: 72)

                Text(OnboardingV2ViewModel.personalizedText("onboardingV2.loading.title", name: firstName, language: languageManager.current))
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .ov2Reveal(delay: 0.05)

                Spacer().frame(height: 32)

                VStack(spacing: 22) {
                    ForEach(0..<3, id: \.self) { i in
                        stepRow(i)
                    }
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 30)

                socialProof
                    .opacity(allDone ? 1 : 0.45)
                    .animation(.easeInOut(duration: 0.5), value: allDone)

                Spacer(minLength: 20)
            }
        } footer: {
            OnboardingV2Button(
                title: languageManager.text("onboardingV2.loading.cta"),
                enabled: allDone,
                action: onNext
            )
        }
        .ov2Background()
        .onAppear {
            if photos.isEmpty { photos = Array(OnboardingStudentPhotos.load().prefix(5)) }
            startLoading()
        }
        .onDisappear { animTask?.cancel() }
    }

    private func stepRow(_ i: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(completed[i] ? OV2.success : OV2.accent.opacity(0.12)).frame(width: 34, height: 34)
                if completed[i] {
                    Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    ProgressView().tint(OV2.accent)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(languageManager.text(stepKeys[i]))
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(OV2.ink)
                ProgressView(value: progress[i])
                    .tint(OV2.accent)
            }
        }
    }

    // MARK: - Preuve sociale

    /// Photos, lauriers « 4,8 · 500 000 utilisateurs », puis la phrase et l'invitation.
    private var socialProof: some View {
        VStack(spacing: 14) {
            if !photos.isEmpty {
                OnboardingV2PhotoRow(photos: photos, size: 38)
            }
            OnboardingV2LaurelBadge(size: 48) {
                OnboardingV2RatingStack(caption: languageManager.text("onboardingV2.loading.social.count"), compact: true)
            }
            VStack(spacing: 4) {
                Text(languageManager.text("onboardingV2.loading.social.body"))
                    .font(DS.sans(.body, .medium))
                    .foregroundStyle(OV2.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(languageManager.text("onboardingV2.loading.social.join"))
                    .font(DS.sans(.body, .bold))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Chargement

    /// Les trois étapes sont une mise en scène (aucun réseau, aucune dépendance) : le CTA
    /// doit donc **toujours** finir par s'activer. C'est la page que l'App Store décrirait
    /// comme « indefinite loading » si elle restait bloquée, alors elle reprend là où elle
    /// s'était arrêtée quand la page réapparaît, et l'interruption elle-même débloque le CTA.
    private func startLoading() {
        guard !allDone else { return }
        animTask?.cancel()
        animTask = Task { @MainActor in
            await playSteps()
            withAnimation(.easeInOut(duration: 0.3)) { allDone = true }
        }
    }

    /// Chaque barre part vite et ralentit en approchant du bout (courbe en exponentielle
    /// inversée), sur sa propre durée ; la suivante démarre quand la précédente est cochée.
    private func playSteps() async {
        for i in 0..<3 where !completed[i] {
            let remaining = Self.durations[i] * (1 - progress[i])
            withAnimation(.timingCurve(0.05, 0.75, 0.3, 1.0, duration: remaining)) { progress[i] = 1 }
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000) + 80_000_000)
            if Task.isCancelled { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { completed[i] = true }
            OnboardingHaptics.loadingStepComplete(step: i)
            try? await Task.sleep(nanoseconds: 180_000_000)
        }
    }
}
