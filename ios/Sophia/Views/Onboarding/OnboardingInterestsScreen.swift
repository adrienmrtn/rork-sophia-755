import SwiftUI

struct OnboardingInterestsScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = false

    private let interests: [(label: String, icon: String, imageId: String, color: Color)] = [
        ("Histoire", "building.columns", "course_12_la_strategie_de_napoleon_a_ulm_1805", Color(red: 1.0, green: 0.86, blue: 0.62)),
        ("Sciences", "atom", "course_67_qu_est_ce_qu_un_trou_noir", Color(red: 0.70, green: 0.95, blue: 0.80)),
        ("Littérature", "book.closed", "course_97_le_mythe_de_sisyphe_camus", Color(red: 1.0, green: 0.78, blue: 0.78)),
        ("Art", "paintpalette", "course_150_la_nuit_etoilee_van_gogh", Color(red: 0.66, green: 0.92, blue: 0.96)),
        ("Mythologie", "bolt.fill", "course_162_promethee_le_voleur_de_feu", Color(red: 0.82, green: 0.78, blue: 1.0)),
        ("Monde actuel", "globe.europe.africa", "course_204_le_concept_de_monde_multipolaire", Color(red: 0.74, green: 0.90, blue: 1.0)),
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                OnboardingHeader(
                    title: "Quels sujets\nt'intéressent ?",
                    subtitle: "Sélectionne au moins un sujet.",
                    appeared: appeared
                )

                Spacer().frame(height: 24)

                ScrollView {
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
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)

                OnboardingPrimaryButton(title: "Suivant", isEnabled: viewModel.canProceed, action: onNext)
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
                Color(red: 0.96, green: 0.93, blue: 0.88)
                    .frame(height: 100)
                    .overlay {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        } else {
                            color
                        }
                    }
                    .overlay {
                        if isSelected {
                            ZStack {
                                Color.black.opacity(0.35)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 28, weight: .heavy))
                                    .foregroundStyle(.white)
                                    .padding(10)
                                    .background(Circle().fill(BrutalPalette.ink))
                                    .overlay { Circle().strokeBorder(.white, lineWidth: 2) }
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .clipShape(.rect(cornerRadii: .init(topLeading: 14, topTrailing: 14)))
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(BrutalPalette.ink).frame(height: 2.5)
                    }

                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                    Text(label)
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color)
                .clipShape(.rect(cornerRadii: .init(bottomLeading: 14, bottomTrailing: 14)))
            }
        }
        .buttonStyle(BrutalCardSelectableStyle())
        .onAppear {
            image = CourseImageMap.loadImage(for: imageId)
        }
    }
}

private struct BrutalCardSelectableStyle: ButtonStyle {
    var depth: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(BrutalPalette.ink)
                .offset(y: depth)

            configuration.label
                .clipShape(.rect(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
                }
                .offset(y: pressed ? depth : 0)
        }
        .padding(.bottom, depth)
        .animation(.spring(response: 0.18, dampingFraction: 0.7), value: pressed)
    }
}
