import SwiftUI
import RevenueCat
import Combine

struct OnboardingSpecialOfferView: View {
    let store: StoreViewModel
    let onSubscribed: () -> Void
    let onSkip: () -> Void
    @State private var appeared: Bool = false
    @State private var pulsing: Bool = false
    @State private var countdownMinutes: Int = 14
    @State private var countdownSeconds: Int = 59
    @State private var discountScale: CGFloat = 0.3
    @State private var glowOpacity: Double = 0.3

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    SophiaTheme.background, SophiaTheme.background, SophiaTheme.background,
                    SophiaTheme.accent.opacity(0.08), SophiaTheme.streakOrange.opacity(0.06), SophiaTheme.accent.opacity(0.08),
                    SophiaTheme.background, SophiaTheme.background, SophiaTheme.background
                ]
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        triggerHaptic(.light)
                        onSkip()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.08), in: .circle)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        VStack(spacing: 12) {
                            Text("Votre offre unique")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 15)

                            Text("-70% POUR TOUJOURS")
                                .font(.system(.title, design: .rounded, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [SophiaTheme.streakOrange, .yellow],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .scaleEffect(discountScale)
                                .shadow(color: SophiaTheme.streakOrange.opacity(glowOpacity), radius: 20)
                        }
                        .padding(.top, 16)

                        VStack(spacing: 8) {
                            Text("1,67 \u{20AC}")
                                .font(.system(size: 52, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            + Text(" /mois")
                                .font(.system(.title3, design: .rounded, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))

                            HStack(spacing: 8) {
                                Text("factur\u{00E9}")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.5))
                                Text("69,99 \u{20AC}")
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.35))
                                    .strikethrough(color: .white.opacity(0.35))
                                Text("19,99 \u{20AC}/an")
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.04), in: .rect(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [SophiaTheme.streakOrange.opacity(0.5), .yellow.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                        HStack(spacing: 10) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(SophiaTheme.streakOrange)
                            Text("Expire dans")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(String(format: "%02d", countdownMinutes)):\(String(format: "%02d", countdownSeconds))")
                                .font(.system(.title3, design: .monospaced, weight: .bold))
                                .foregroundStyle(SophiaTheme.streakOrange)
                                .contentTransition(.numericText())
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            SophiaTheme.streakOrange.opacity(0.08),
                            in: .rect(cornerRadius: 14)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(SophiaTheme.streakOrange.opacity(0.2), lineWidth: 1)
                        )
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(pulsing ? 1.02 : 1.0)

                        VStack(spacing: 8) {
                            SpecialOfferFeature(text: "240 cours de culture g\u{00E9}n\u{00E9}rale")
                            SpecialOfferFeature(text: "Quiz interactifs illimit\u{00E9}s")
                            SpecialOfferFeature(text: "Nouveau contenu chaque semaine")
                        }
                        .padding(.horizontal, 28)
                        .opacity(appeared ? 1 : 0)
                    }
                }

                VStack(spacing: 12) {
                    Button {
                        triggerHaptic(.medium)
                        Task {
                            guard let pkg = store.promoPackage else { return }
                            let success = await store.purchase(package: pkg)
                            if success { onSubscribed() }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "bolt.fill")
                                .font(.subheadline.weight(.bold))
                            Text("D\u{00E9}bloquer mon acc\u{00E8}s -70%")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [SophiaTheme.streakOrange, SophiaTheme.streakOrange.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: .rect(cornerRadius: 16)
                        )
                        .shadow(color: SophiaTheme.streakOrange.opacity(0.4), radius: 16, y: 6)
                    }
                    .disabled(store.isPurchasing)
                    .opacity(store.isPurchasing ? 0.6 : 1)
                    .padding(.horizontal, 24)

                    Button {
                        Task { await store.restore() }
                    } label: {
                        Text("Restaurer les achats")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
                .padding(.bottom, 40)
            }

            if store.isPurchasing {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.linear(duration: 0.3)) {
                if countdownSeconds > 0 {
                    countdownSeconds -= 1
                } else if countdownMinutes > 0 {
                    countdownMinutes -= 1
                    countdownSeconds = 59
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.1)) {
                appeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.3)) {
                discountScale = 1.0
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulsing = true
                glowOpacity = 0.6
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let g = UINotificationFeedbackGenerator()
                g.notificationOccurred(.warning)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                let g = UIImpactFeedbackGenerator(style: .heavy)
                g.impactOccurred()
            }
        }
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let g = UIImpactFeedbackGenerator(style: style)
        g.prepare()
        g.impactOccurred()
    }
}

private struct SpecialOfferFeature: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(SophiaTheme.emerald)
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
        }
    }
}
