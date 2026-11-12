import SwiftUI

/// Page objectifs — sélection **multiple**, puis CTA « Continuer ».
///
/// Style « Elevate arrondi » : titre centré, sous-titre gris, illustration ronde (le trophée)
/// quand la hauteur le permet, puis une carte d'option par objectif. Une carte choisie se
/// teinte en bleu ; il n'y a ni pastille ni case, le sous-titre dit qu'on peut en prendre
/// plusieurs.
struct OnboardingV2Objective: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    var body: some View {
        OV2CorePage { height in
            pageBody(height: height)
        } footer: {
            OnboardingV2Button(
                title: languageManager.text("common.continue"),
                enabled: !vm.objectiveKeys.isEmpty,
                action: onNext
            )
        }
        .ov2Background()
    }

    private func pageBody(height: CGFloat) -> some View {
        let art: CGFloat = OV2CoreMetrics.artSize(base: 116, available: height, reserved: 464)
        return VStack(spacing: 0) {
            OV2CoreQuestionTitle(
                title: languageManager.text("onboardingV2.objective.title"),
                subtitle: languageManager.text("onboardingV2.objective.subtitle")
            )
            .padding(.top, OV2CoreMetrics.topInset)
            .dsStagger(0)

            if art > 0 {
                OV2CoreIllustration(art: .trophy, size: art)
                    .padding(.top, 22)
                    .dsPopIn(delay: 0.12)
            }

            rows
                .padding(.horizontal, OV2CoreMetrics.sideInset)
                .padding(.top, 24)
                .padding(.bottom, 16)
        }
    }

    private var rows: some View {
        VStack(spacing: 9) {
            ForEach(Array(OnboardingV2ViewModel.objectiveKeys.enumerated()), id: \.element) { index, key in
                OV2CoreOptionRow(
                    label: OnboardingV2ViewModel.objectiveLabel(key, language: languageManager.current),
                    isSelected: vm.isSelected(key),
                    minHeight: 56,
                    action: {
                        withAnimation(DS.Motion.snappy) {
                            vm.toggleObjective(key)
                        }
                    }
                )
                .dsStagger(index, base: 0.18)
            }
        }
    }
}
