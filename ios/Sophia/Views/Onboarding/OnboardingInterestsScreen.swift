import SwiftUI

struct OnboardingInterestsScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = true

    private let interests: [(subject: Subject, icon: String, imageId: String, color: Color)] = [
        (.histoire, "building.columns", "course_12_la_strategie_de_napoleon_a_ulm_1805", Color(red: 1.0, green: 0.86, blue: 0.62)),
        (.sciences, "atom", "course_67_qu_est_ce_qu_un_trou_noir", Color(red: 0.70, green: 0.95, blue: 0.80)),
        (.litterature, "book.closed", "course_97_le_mythe_de_sisyphe_camus", Color(red: 1.0, green: 0.78, blue: 0.78)),
        (.art, "paintpalette", "course_150_la_nuit_etoilee_van_gogh", Color(red: 0.66, green: 0.92, blue: 0.96)),
        (.mythologie, "bolt.fill", "course_162_promethee_le_voleur_de_feu", Color(red: 0.82, green: 0.78, blue: 1.0)),
        (.comprendreLeMonde, "globe.europe.africa", "course_204_le_concept_de_monde_multipolaire", Color(red: 0.74, green: 0.90, blue: 1.0)),
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 44)

                VStack(spacing: 8) {
                    Text(languageManager.text("onboarding.interests.title"))
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .lineSpacing(-2)
                        .foregroundStyle(BrutalPalette.ink)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)

                    Text(languageManager.text("onboarding.interests.subtitle"))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(BrutalPalette.ink.opacity(0.58))
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 18)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(interests.enumerated()), id: \.offset) { i, interest in
                            let key = interest.subject.storageKey
                            let isSelected = viewModel.interests.contains(key)
                            InterestCard(
                                label: interest.subject.localizedShortName(language: languageManager.current),
                                icon: interest.icon,
                                imageId: interest.imageId,
                                color: interest.color,
                                isSelected: isSelected
                            ) {
                                OnboardingHaptics.selection()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.toggleInterest(key)
                                }
                            }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                            .animation(.spring(response: 0.5).delay(Double(i) * 0.06), value: appeared)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 18)
                }
                .scrollIndicators(.hidden)

                OnboardingPrimaryButton(title: languageManager.text("common.continue"), isEnabled: viewModel.canProceed, action: onNext)
                    .opacity(appeared ? 1 : 0)
        }
        .onboardingFullBleedBackground(BrutalPalette.cream)
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
                    .frame(height: 88)
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
                .padding(.vertical, 10)
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
    var depth: CGFloat = 2

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        ZStack(alignment: .top) {
            configuration.label
                .clipShape(.rect(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
                }
                .shadow(color: BrutalPalette.ink.opacity(0.18), radius: 0, x: 0, y: pressed ? 1 : 3)
                .offset(y: pressed ? depth : 0)
        }
        .padding(.bottom, depth)
        .animation(.spring(response: 0.18, dampingFraction: 0.7), value: pressed)
    }
}
