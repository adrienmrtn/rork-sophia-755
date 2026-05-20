import SwiftUI
import AVKit

struct PrePaywallQuizView: View {
    let onContinue: () -> Void
    @EnvironmentObject private var paywall: PaywallCoordinator
    @State private var appeared: Bool = false
    @State private var shimmerOffset: CGFloat = -200
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    if let player {
                        VideoPlayer(player: player)
                            .disabled(true)
                            .aspectRatio(9/16, contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: UIScreen.main.bounds.height * 0.55)
                            .clipped()
                            .opacity(appeared ? 1 : 0)
                    } else {
                        Color.clear
                            .frame(height: UIScreen.main.bounds.height * 0.55)
                    }

                    LinearGradient(
                        colors: [
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

                    Image("logo_white")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 30)
                        .opacity(appeared ? 0.9 : 0)
                        .offset(y: -20)
                }

                Spacer()

                VStack(spacing: 12) {
                    Text("Les quiz sont réservés\naux membres Premium")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                    Text("Passe Premium pour tester tes\nconnaissances et progresser chaque jour")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                }

                Spacer()

                VStack(spacing: 10) {
                    Button {
                        triggerHaptic(.medium)
                        paywall.presentPrimary(onPurchasedOrRestored: {
                            onContinue()
                        })
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.open.fill")
                                .font(.subheadline.weight(.semibold))
                            Text("Continuer")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(SophiaTheme.emerald, in: .rect(cornerRadius: 16))
                        .shadow(color: SophiaTheme.emerald.opacity(0.3), radius: 12, y: 4)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            }

            GeometryReader { geo in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.05), .clear],
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
        .modifier(PaywallHost(paywall: paywall, isPremium: false))
        .onAppear {
            setupPlayer()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.15)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                let g = UINotificationFeedbackGenerator()
                g.notificationOccurred(.warning)
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

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let g = UIImpactFeedbackGenerator(style: style)
        g.prepare()
        g.impactOccurred()
    }

    private func setupPlayer() {
        let urls = [
            Bundle.main.url(forResource: "quiz_prepaywall_video", withExtension: "mp4", subdirectory: "Resources"),
            Bundle.main.url(forResource: "quiz_prepaywall_video", withExtension: "mp4"),
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
