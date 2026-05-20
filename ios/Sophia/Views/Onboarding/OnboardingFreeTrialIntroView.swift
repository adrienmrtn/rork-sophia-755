import SwiftUI
import AVKit

struct OnboardingFreeTrialIntroView: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var giftBounce: Int = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if let player {
                    ZStack(alignment: .bottom) {
                        VideoPlayer(player: player)
                            .disabled(true)
                            .aspectRatio(9/16, contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: UIScreen.main.bounds.height * 0.55)
                            .clipped()
                            .opacity(appeared ? 1 : 0)

                        LinearGradient(
                            colors: [
                                .clear,
                                .clear,
                                SophiaTheme.background.opacity(0.6),
                                SophiaTheme.background.opacity(0.9),
                                SophiaTheme.background
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 200)
                        .allowsHitTesting(false)
                    }
                } else {
                    Spacer()
                        .frame(height: UIScreen.main.bounds.height * 0.55)
                }

                VStack(spacing: 16) {
                    Image("logo_white")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 30)
                        .opacity(appeared ? 1 : 0)

                    Text("Vos 3 premiers jours sont offerts")
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(SophiaTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    HStack(spacing: 16) {
                        TrialFeaturePill(icon: "book.fill", text: "Cours illimités")
                        TrialFeaturePill(icon: "checkmark.circle.fill", text: "Tous les quiz")
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                }
                .offset(y: -30)

                Spacer()

                OnboardingButton(title: "Continuer", action: onNext)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
            }

            GeometryReader { geo in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.black.opacity(0.06), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 120, height: geo.size.height * 2)
                    .rotationEffect(.degrees(15))
                    .offset(x: shimmerOffset)
                    .allowsHitTesting(false)
            }
            .clipped()
        }
        .onAppear {
            setupPlayer()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                giftBounce += 1
                let g = UINotificationFeedbackGenerator()
                g.notificationOccurred(.success)
            }
            withAnimation(.easeInOut(duration: 2.5).delay(0.8)) {
                shimmerOffset = UIScreen.main.bounds.width + 200
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
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

private struct TrialFeaturePill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SophiaTheme.emerald)
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.8))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.06), in: .capsule)
    }
}
