import SwiftUI

struct OnboardingObjectivesScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = false

    private let objectives: [(icon: String, label: String, detail: String)] = [
        ("sparkles", "Être plus curieux", "Découvre des anecdotes surprenantes sur chaque sujet"),
        ("lightbulb.fill", "Apprendre de nouvelles choses", "Un nouveau sujet maîtrisé chaque jour"),
        ("star.fill", "Impressionner tes proches", "Brille en conversation — des faits que personne ne connaît"),
        ("bubble.left.and.bubble.right.fill", "Renforcer ton aisance en société", "Les clés culturelles pour parler de tout"),
        ("arrow.down.circle.fill", "Réduire ton temps à scroller", "10 min utiles au lieu de 30 min vides"),
    ]

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Image(systemName: "target")
                            .font(.system(size: 40))
                            .foregroundStyle(SophiaTheme.accent)
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.6)

                        Text("Quel est ton objectif\navec Sophia ?")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)

                        Text("Sélectionne un ou plusieurs objectifs")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                            .opacity(appeared ? 1 : 0)
                    }

                    VStack(spacing: 10) {
                        ForEach(Array(objectives.enumerated()), id: \.offset) { i, obj in
                            let isSelected = viewModel.objectives.contains(obj.label)
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.toggleObjective(obj.label)
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: obj.icon)
                                        .font(.title3)
                                        .foregroundStyle(isSelected ? SophiaTheme.emerald : .white.opacity(0.4))
                                        .frame(width: 28, alignment: .center)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(obj.label)
                                            .font(.system(.body, design: .rounded, weight: .medium))
                                            .foregroundStyle(.white)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)

                                        Text(obj.detail)
                                            .font(.system(.caption, design: .rounded, weight: .medium))
                                            .foregroundStyle(.white.opacity(0.55))
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    ZStack {
                                        Circle()
                                            .strokeBorder(.white.opacity(0.2), lineWidth: 2)
                                            .frame(width: 24, height: 24)
                                        if isSelected {
                                            Circle()
                                                .fill(SophiaTheme.emerald)
                                                .frame(width: 24, height: 24)
                                                .overlay {
                                                    Image(systemName: "checkmark")
                                                        .font(.caption.weight(.bold))
                                                        .foregroundStyle(.white)
                                                }
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                    .frame(width: 24)
                                }
                                .padding(14)
                                .background(
                                    isSelected ? SophiaTheme.emerald.opacity(0.1) : .white.opacity(0.04),
                                    in: .rect(cornerRadius: 14)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(isSelected ? SophiaTheme.emerald.opacity(0.4) : .clear, lineWidth: 1.5)
                                )
                            }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)
                            .animation(.spring(response: 0.5).delay(Double(i) * 0.06), value: appeared)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                OnboardingButton(title: "Suivant", isEnabled: viewModel.canProceed, action: onNext)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .sensoryFeedback(.selection, trigger: viewModel.objectives.count)
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) {
                appeared = true
            }
        }
    }
}
