import SwiftUI
import AVKit

struct OnboardingIntroScreen: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var titleOffset: CGFloat = 40
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
                            .frame(height: UIScreen.main.bounds.height * 0.72)
                            .clipped()
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.95)

                        LinearGradient(
                            colors: [
                                .clear,
                                .clear,
                                .clear,
                                SophiaTheme.background.opacity(0.5),
                                SophiaTheme.background.opacity(0.85),
                                SophiaTheme.background
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 220)
                        .allowsHitTesting(false)
                    }
                } else {
                    Spacer()
                        .frame(height: UIScreen.main.bounds.height * 0.72)
                }

                VStack(spacing: 14) {
                    Image("logo_white")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 34)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    Text("Deviens vraiment cultivé\nen seulement 10 minutes\npar jour")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : titleOffset)
                }
                .offset(y: -50)

                Spacer()

                Button(action: {
                    let g = UIImpactFeedbackGenerator(style: .medium)
                    g.impactOccurred()
                    onNext()
                }) {
                    HStack(spacing: 10) {
                        Text("Commencer")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(SophiaTheme.emerald, in: .rect(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
            }
        }
        .onAppear {
            setupPlayer()
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.3)) {
                appeared = true
                titleOffset = 0
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
