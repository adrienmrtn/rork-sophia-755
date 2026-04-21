import SwiftUI

struct OnboardingInterestsScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = false

    private let interests: [(label: String, icon: String, imageId: String, color: Color)] = [
        ("Histoire", "building.columns", "course_12_la_strategie_de_napoleon_a_ulm_1805", Color(red: 0.96, green: 0.62, blue: 0.04)),
        ("Sciences", "atom", "course_67_qu_est_ce_qu_un_trou_noir", Color(red: 0.20, green: 0.83, blue: 0.60)),
        ("Littérature", "book.closed", "course_97_le_mythe_de_sisyphe_camus", Color(red: 0.93, green: 0.35, blue: 0.45)),
        ("Art", "paintpalette", "course_150_la_nuit_etoilee_van_gogh", Color(red: 0.85, green: 0.55, blue: 0.95)),
        ("Mythologie", "bolt.fill", "course_162_promethee_le_voleur_de_feu", Color(red: 0.56, green: 0.40, blue: 0.92)),
        ("Monde actuel", "globe.europe.africa", "course_204_le_concept_de_monde_multipolaire", Color(red: 0.25, green: 0.72, blue: 0.85)),
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Image(systemName: "heart.text.clipboard.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(SophiaTheme.emerald)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.5)

                    Text("Quels sujets t'intéressent ?")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)

                    Text("Sélectionne au moins un sujet")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .opacity(appeared ? 1 : 0)
                }
                .padding(.top, 60)
                .padding(.bottom, 28)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Array(interests.enumerated()), id: \.offset) { i, interest in
                        let isSelected = viewModel.interests.contains(interest.label)
                        InterestCard(
                            label: interest.label,
                            icon: interest.icon,
                            imageId: interest.imageId,
                            color: interest.color,
                            isSelected: isSelected
                        ) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.toggleInterest(interest.label)
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.5).delay(Double(i) * 0.06), value: appeared)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                OnboardingButton(title: "Suivant", isEnabled: viewModel.canProceed, action: onNext)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .sensoryFeedback(.selection, trigger: viewModel.interests.count)
        .onAppear {
            let ids = interests.map(\.imageId)
            CourseImageMap.preloadImages(for: ids)
            withAnimation(.spring(response: 0.6).delay(0.1)) {
                appeared = true
            }
        }
    }
}

private struct InterestCard: View {
    let label: String
    let icon: String
    let imageId: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    @State private var image: UIImage?

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Color(.secondarySystemBackground)
                    .frame(height: 100)
                    .overlay {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        } else {
                            LinearGradient(
                                colors: [color.opacity(0.4), color.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                    .overlay {
                        if isSelected {
                            Color.black.opacity(0.3)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .clipShape(.rect(cornerRadii: .init(topLeading: 14, topTrailing: 14)))

                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(color)
                    Text(label)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(SophiaTheme.cardBackground)
                .clipShape(.rect(cornerRadii: .init(bottomLeading: 14, bottomTrailing: 14)))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? color.opacity(0.7) : .clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .onAppear {
            image = CourseImageMap.loadImage(for: imageId)
        }
    }
}
