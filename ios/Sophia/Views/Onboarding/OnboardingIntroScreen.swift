import SwiftUI
import AVKit

struct OnboardingIntroScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void
    @State private var appeared: Bool = true
    @State private var titleOffset: CGFloat = 40
    @State private var player: AVPlayer?
    @State private var buttonShimmer: CGFloat = -100
    @State private var tapCount: Int = 0
    @State private var shimmerActive: Bool = true

    private let videoHeightRatio: CGFloat = 0.62
    private let videoCropOffset: CGFloat = 36

    var body: some View {
        ZStack(alignment: .topTrailing) {
            BrutalPalette.cream

            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    let videoHeight = UIScreen.main.bounds.height * videoHeightRatio

                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: videoHeight)
                        .overlay {
                            Group {
                                if let player {
                                    VideoPlayer(player: player)
                                        .disabled(true)
                                        .aspectRatio(9 / 16, contentMode: .fill)
                                } else {
                                    BrutalPalette.pink
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: videoHeight + videoCropOffset)
                            .offset(y: videoCropOffset)
                        }
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

                Text(languageManager.text("onboarding.intro.title"))
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .offset(y: -28)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : titleOffset)

                Spacer()

                Button {
                    tapCount += 1
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onNext()
                } label: {
                    HStack(spacing: 10) {
                        Text(languageManager.text("onboarding.intro.cta"))
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.heavy))
                    }
                    .foregroundStyle(BrutalPalette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
                .buttonStyle(DuolingoButtonStyle(fill: BrutalPalette.pink, shimmer: buttonShimmer))
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .sensoryFeedback(.impact(weight: .medium), trigger: tapCount)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
            }

            LanguagePickerControl(compact: true)
                .padding(.top, 12)
                .padding(.trailing, 20)
                .opacity(appeared ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BrutalPalette.cream)
        .onAppear {
            setupPlayer()
            shimmerActive = true
            ShimmerAnimation.runLoop(offset: $buttonShimmer) { shimmerActive }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.3)) {
                appeared = true
                titleOffset = 0
            }
        }
        .onDisappear {
            shimmerActive = false
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
