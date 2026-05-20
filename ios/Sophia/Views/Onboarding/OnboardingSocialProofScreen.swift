import SwiftUI
import StoreKit

struct OnboardingSocialProofScreen: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var percentValue: Int = 0
    @State private var showReviews: Bool = false

    private let reviews: [(name: String, text: String, stars: Int, photoFile: String)] = [
        ("Lucas M.", "Je me sentais nul en culture G, maintenant j'ai toujours un truc intéressant à raconter.", 5, "lucas_m_profile"),
        ("Camille R.", "10 min par jour et j'ai l'impression d'apprendre plus qu'en cours.", 5, "camille_r_profile"),
        ("Thomas D.", "J'adore le format. C'est clair, rapide et on retient vraiment.", 5, "thomas_d_profile"),
    ]

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(percentValue)")
                                .font(.system(size: 72, weight: .heavy, design: .rounded))
                                .foregroundStyle(SophiaTheme.emerald)
                                .contentTransition(.numericText(countsDown: false))
                            Text("%")
                                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                                .foregroundStyle(SophiaTheme.emerald)
                        }

                        Text("des utilisateurs affirment que Sophia\nles a rendus plus intéressants\net à l'aise en société.")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(appeared ? 1 : 0)

                    if showReviews {
                        VStack(spacing: 12) {
                            ForEach(Array(reviews.enumerated()), id: \.offset) { i, review in
                                HStack(alignment: .top, spacing: 12) {
                                    ProfilePhotoView(fileName: review.photoFile, fallbackLetter: String(review.name.prefix(1)))
                                        .frame(width: 40, height: 40)

                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 4) {
                                            Text(review.name)
                                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                                .foregroundStyle(.white)
                                            Spacer()
                                            HStack(spacing: 2) {
                                                ForEach(0..<review.stars, id: \.self) { _ in
                                                    Image(systemName: "star.fill")
                                                        .font(.caption2)
                                                        .foregroundStyle(SophiaTheme.streakOrange)
                                                }
                                            }
                                        }
                                        Text(review.text)
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.6))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .padding(14)
                                .background(.white.opacity(0.05), in: .rect(cornerRadius: 14))
                                .opacity(showReviews ? 1 : 0)
                                .offset(y: showReviews ? 0 : 15)
                                .animation(.spring(response: 0.5).delay(Double(i) * 0.12), value: showReviews)
                            }
                        }
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                    }
                }

                Spacer()

                OnboardingButton(title: "Continuer", action: onNext)
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
            let heavy = UIImpactFeedbackGenerator(style: .medium)
            heavy.impactOccurred()
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

private struct ProfilePhotoView: View {
    let fileName: String
    let fallbackLetter: String
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(SophiaTheme.accent.opacity(0.2))
                    Text(fallbackLetter)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(SophiaTheme.accent)
                }
            }
        }
        .onAppear {
            loadPhoto()
        }
    }

    private func loadPhoto() {
        if let path = Bundle.main.path(forResource: fileName, ofType: "png", inDirectory: "Resources") {
            image = UIImage(contentsOfFile: path)
        } else if let path = Bundle.main.path(forResource: fileName, ofType: "png") {
            image = UIImage(contentsOfFile: path)
        }
    }
}
