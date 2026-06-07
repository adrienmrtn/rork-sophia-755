import SwiftUI
import AVKit

struct OnboardingFreeTrialIntroView: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void
    @State private var appeared: Bool = true
    @State private var pillsAppeared: Bool = false
    @State private var buttonAppeared: Bool = false
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer().frame(height: 8)

                // Brutal pill badge
                BrutalPill(text: languageManager.text("onboarding.trial.badge"), icon: "gift.fill", background: BrutalPalette.pink, foreground: BrutalPalette.ink)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -10)

                // Title
                Text(languageManager.text("onboarding.trial.title"))
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)

                // Video inside brutal card
                videoCard
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.94)

                // Brutal feature pills
                HStack(spacing: 10) {
                    BrutalFeaturePill(icon: "book.fill", text: languageManager.text("onboarding.trial.unlimitedCourses"), tint: OnboardingPastels.at(1))
                    BrutalFeaturePill(icon: "checkmark.circle.fill", text: languageManager.text("onboarding.trial.allQuizzes"), tint: OnboardingPastels.at(3))
                }
                .padding(.horizontal, 24)
                .opacity(pillsAppeared ? 1 : 0)
                .offset(y: pillsAppeared ? 0 : 14)

                Spacer()

                OnboardingPrimaryButton(title: languageManager.text("common.continue"), action: onNext)
                    .opacity(buttonAppeared ? 1 : 0)
                    .offset(y: buttonAppeared ? 0 : 24)
            }
        }
        .onAppear {
            setupPlayer()
            withAnimation(.spring(response: 0.65, dampingFraction: 0.78).delay(0.15)) {
                appeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.55)) {
                pillsAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8)) {
                buttonAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                let g = UINotificationFeedbackGenerator()
                g.notificationOccurred(.success)
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    @ViewBuilder
    private var videoCard: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(BrutalPalette.ink)
                .offset(y: 5)

            Group {
                if let player {
                    VideoPlayer(player: player)
                        .disabled(true)
                        .aspectRatio(9/16, contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(BrutalPalette.pink.opacity(0.35))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.height * 0.42)
            .clipShape(.rect(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(BrutalPalette.ink, lineWidth: 3)
            }
        }
        .padding(.bottom, 5)
    }

    private func setupPlayer() {
        let urls = [
            Bundle.main.url(forResource: "onboarding_video", withExtension: "mp4", subdirectory: "Resources"),
            Bundle.main.url(forResource: "onboarding_video", withExtension: "mp4"),
        ]
        guard let url = urls.compactMap({ $0 }).first else { return }
        let p = AVPlayer(url: url)
        p.isMuted = true
        p.play()
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: p.currentItem, queue: .main) { _ in
            p.seek(to: .zero)
            p.play()
        }
        player = p
    }
}

private struct BrutalFeaturePill: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
            Text(text)
                .font(.system(.footnote, design: .rounded, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            ZStack(alignment: .top) {
                Capsule()
                    .fill(BrutalPalette.ink)
                    .offset(y: 3)
                Capsule()
                    .fill(tint)
                    .overlay {
                        Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2)
                    }
            }
        )
        .padding(.bottom, 3)
    }
}
