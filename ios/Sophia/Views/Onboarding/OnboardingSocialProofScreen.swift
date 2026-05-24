import SwiftUI
import StoreKit

struct OnboardingSocialProofScreen: View {
    let onNext: () -> Void
    @State private var appeared: Bool = true
    @State private var percentValue: Int = 0
    @State private var showReviews: Bool = false

    private let reviews: [(name: String, text: String, stars: Int, photoFile: String, accent: Color)] = [
        ("Lucas M.", "Je me sentais nul en culture G, maintenant j'ai toujours un truc intéressant à raconter.", 5, "lucas_m_profile", Color(red: 0.66, green: 0.92, blue: 0.96)),
        ("Camille R.", "10 min par jour et j'ai l'impression d'apprendre plus qu'en cours.", 5, "camille_r_profile", Color(red: 0.70, green: 0.95, blue: 0.80)),
        ("Thomas D.", "J'adore le format. C'est clair, rapide et on retient vraiment.", 5, "thomas_d_profile", Color(red: 1.0, green: 0.86, blue: 0.62)),
    ]

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 50)

                VStack(spacing: 18) {
                    BrutalPill(text: "Avis vérifiés", icon: "star.fill", background: BrutalPalette.pink, foreground: BrutalPalette.ink)
                        .opacity(appeared ? 1 : 0)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(percentValue)")
                            .font(.system(size: 80, weight: .heavy, design: .rounded))
                            .foregroundStyle(BrutalPalette.ink)
                            .contentTransition(.numericText(countsDown: false))
                        Text("%")
                            .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                    }
                    .opacity(appeared ? 1 : 0)

                    Text("des utilisateurs se sentent\nplus intéressants et à l'aise\nen société grâce à Sophia.")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(BrutalPalette.ink.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 28)

                if showReviews {
                    VStack(spacing: 12) {
                        ForEach(Array(reviews.enumerated()), id: \.offset) { i, review in
                            ReviewCard(
                                name: review.name,
                                text: review.text,
                                stars: review.stars,
                                photoFile: review.photoFile,
                                accent: review.accent
                            )
                            .opacity(showReviews ? 1 : 0)
                            .offset(y: showReviews ? 0 : 15)
                            .animation(.spring(response: 0.5).delay(Double(i) * 0.12), value: showReviews)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                OnboardingPrimaryButton(title: "Continuer", action: onNext)
                    .opacity(showReviews ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.2)) {
                appeared = true
            }
            animatePercent()
        }
    }

    private func animatePercent() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        let steps = 30
        let interval = 1.2 / Double(steps)

        for step in 0...steps {
            let delay = 0.4 + interval * Double(step)
            let progress = Double(step) / Double(steps)
            let eased = 1 - pow(1 - progress, 3)
            let value = Int(eased * 94)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.snappy(duration: 0.08)) {
                    percentValue = value
                }
                if step % 4 == 0 {
                    generator.impactOccurred(intensity: 0.3 + 0.7 * progress)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.5)) {
                showReviews = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: scene)
                }
            }
        }
    }
}

private struct ReviewCard: View {
    let name: String
    let text: String
    let stars: Int
    let photoFile: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProfilePhotoView(fileName: photoFile, fallbackLetter: String(name.prefix(1)), accent: accent)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(name)
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                    Spacer()
                    HStack(spacing: 2) {
                        ForEach(0..<stars, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(BrutalPalette.ink)
                        }
                    }
                }
                Text(text)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(BrutalPalette.cream, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
        }
        .shadow(color: BrutalPalette.ink.opacity(0.16), radius: 0, x: 0, y: 3)
    }
}

private struct ProfilePhotoView: View {
    let fileName: String
    let fallbackLetter: String
    let accent: Color
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Circle()
                .fill(BrutalPalette.ink)
                .offset(y: 2)
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        accent
                        Text(fallbackLetter)
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                    }
                }
            }
            .clipShape(Circle())
            .overlay { Circle().strokeBorder(BrutalPalette.ink, lineWidth: 2) }
        }
        .onAppear { loadPhoto() }
    }

    private func loadPhoto() {
        if let path = Bundle.main.path(forResource: fileName, ofType: "png", inDirectory: "Resources") {
            image = UIImage(contentsOfFile: path)
        } else if let path = Bundle.main.path(forResource: fileName, ofType: "png") {
            image = UIImage(contentsOfFile: path)
        }
    }
}
