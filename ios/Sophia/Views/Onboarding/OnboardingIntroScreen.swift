import SwiftUI
import AVKit

struct OnboardingIntroScreen: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var titleOffset: CGFloat = 40
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    Group {
                        if let player {
                            VideoPlayer(player: player)
                                .disabled(true)
                                .aspectRatio(9/16, contentMode: .fill)
                        } else {
                            BrutalPalette.pink
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.height * 0.62)
                    .clipped()
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(BrutalPalette.ink)
                            .frame(height: 3)
                    }
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.98)

                    LinearGradient(
                        colors: [
                            .clear,
                            .clear,
                            BrutalPalette.cream.opacity(0.4),
                            BrutalPalette.cream.opacity(0.9),
                            BrutalPalette.cream
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 180)
                    .allowsHitTesting(false)
                }

                VStack(spacing: 16) {
                    BrutalPill(
                        text: "Sophia",
                        icon: "sparkles",
                        background: BrutalPalette.pink,
                        foreground: BrutalPalette.ink
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                    Text("Deviens cultivé\nen 10 minutes\npar jour")
                        .font(.system(.title, design: .rounded, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : titleOffset)
                }
                .padding(.top, 8)
                .offset(y: -40)

                Spacer()

                OnboardingPrimaryButton(title: "Commencer", action: onNext)
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
