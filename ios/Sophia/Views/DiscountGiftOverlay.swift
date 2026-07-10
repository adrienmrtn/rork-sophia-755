import SwiftUI

/// Surprise-gift overlay that floats above the app (the Home stays visible behind a
/// soft dim). The user taps the gift a few times to pop it open, then the discount
/// paywall is revealed. Designed to feel tactile and rewarding.
struct DiscountGiftOverlay: View {
    @Environment(LanguageManager.self) private var languageManager
    let onOpened: () -> Void

    /// Number of taps required to fully open the gift.
    private let tapsToOpen = 3

    @State private var taps = 0
    @State private var appeared = false
    @State private var shake = false
    @State private var lidLifted = false
    @State private var opened = false
    @State private var burst = false
    @State private var sparkles: [Sparkle] = []
    @State private var wobble = false
    @State private var backdropIn = false

    private let ink = BrutalPalette.ink
    private let pink = BrutalPalette.pink
    private let gold = BrutalPalette.yellow

    private var progress: CGFloat {
        CGFloat(min(taps, tapsToOpen)) / CGFloat(tapsToOpen)
    }

    var body: some View {
        ZStack {
            // Soft dim — the app remains visible behind it.
            Color.black.opacity(backdropIn ? 0.42 : 0)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { tapGift() }

            VStack(spacing: 30) {
                Spacer()

                VStack(spacing: 10) {
                    Text(languageManager.text("discount.gift.title"))
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(promptText)
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .contentTransition(.opacity)
                        .id(promptText)
                }
                .opacity(appeared && !opened ? 1 : 0)
                .offset(y: appeared ? 0 : 14)

                giftStack
                    .frame(width: 220, height: 240)

                progressPips
                    .opacity(appeared && !opened ? 1 : 0)

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { backdropIn = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.62).delay(0.08)) {
                appeared = true
            }
            startIdleWobble()
        }
    }

    private var promptText: String {
        let remaining = max(0, tapsToOpen - taps)
        if opened { return "" }
        if taps == 0 { return languageManager.text("discount.gift.tapToOpen") }
        if remaining <= 1 { return languageManager.text("discount.gift.almost") }
        return languageManager.text("discount.gift.keepTapping")
    }

    // MARK: - Gift

    private var giftStack: some View {
        ZStack {
            // Glow behind the gift, grows with each tap.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [gold.opacity(0.55), pink.opacity(0.2), .clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: 150
                    )
                )
                .frame(width: 260, height: 260)
                .scaleEffect((appeared ? 1 : 0.4) * (1 + progress * 0.35) * (burst ? 1.5 : 1))
                .opacity(appeared ? (0.6 + Double(progress) * 0.4) : 0)
                .animation(.easeOut(duration: 0.5), value: progress)
                .animation(.easeOut(duration: 0.6), value: burst)

            // Burst rays on open.
            if opened {
                ForEach(0..<12, id: \.self) { i in
                    Capsule()
                        .fill(i.isMultiple(of: 2) ? gold : pink)
                        .frame(width: 6, height: burst ? 60 : 8)
                        .offset(y: burst ? -120 : -60)
                        .rotationEffect(.degrees(Double(i) / 12 * 360))
                        .opacity(burst ? 0 : 1)
                        .animation(.easeOut(duration: 0.7).delay(0.05), value: burst)
                }
            }

            // Sparkles flying out.
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size, weight: .black))
                    .foregroundStyle(sparkle.color)
                    .offset(x: sparkle.x, y: sparkle.y)
                    .opacity(sparkle.opacity)
                    .rotationEffect(.degrees(sparkle.rotation))
            }

            // The gift box (base + lid).
            ZStack(alignment: .bottom) {
                giftBase
                    .scaleEffect(opened ? 1.04 : 1)

                giftLid
                    .offset(y: lidLifted ? -128 : -96)
                    .rotationEffect(.degrees(lidLifted ? -18 : 0), anchor: .bottomLeading)
                    .opacity(lidLifted && opened ? 0 : 1)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: lidLifted)
            }
            .scaleEffect(appeared ? (opened ? 1.06 : 1) : 0.3)
            .rotationEffect(.degrees(shake ? 4 : (wobble ? -3 : 0)))
            .offset(y: opened ? -8 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.45), value: shake)
            .animation(.easeInOut(duration: 1.4), value: wobble)
            .contentShape(Rectangle())
            .onTapGesture { tapGift() }
        }
    }

    private var giftBase: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(pink)
                .frame(width: 150, height: 118)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(ink, lineWidth: 3.5)
                }
                .overlay(alignment: .center) {
                    // Vertical ribbon.
                    Rectangle()
                        .fill(gold)
                        .frame(width: 26)
                        .overlay {
                            Rectangle().strokeBorder(ink, lineWidth: 3)
                                .frame(width: 26)
                        }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .background(alignment: .top) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ink)
                .frame(width: 150, height: 118)
                .offset(y: 5)
        }
    }

    private var giftLid: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(pink)
                .frame(width: 172, height: 44)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(ink, lineWidth: 3.5)
                }
                .overlay(alignment: .center) {
                    Rectangle()
                        .fill(gold)
                        .frame(width: 26)
                        .overlay { Rectangle().strokeBorder(ink, lineWidth: 3).frame(width: 26) }
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Bow on top of the lid.
            bow
                .offset(y: -30)
        }
    }

    private var bow: some View {
        HStack(spacing: -6) {
            Ellipse()
                .fill(gold)
                .frame(width: 30, height: 40)
                .rotationEffect(.degrees(-24))
                .overlay {
                    Ellipse().strokeBorder(ink, lineWidth: 3)
                        .frame(width: 30, height: 40)
                        .rotationEffect(.degrees(-24))
                }
            Circle()
                .fill(gold)
                .frame(width: 20, height: 20)
                .overlay { Circle().strokeBorder(ink, lineWidth: 3) }
                .zIndex(1)
            Ellipse()
                .fill(gold)
                .frame(width: 30, height: 40)
                .rotationEffect(.degrees(24))
                .overlay {
                    Ellipse().strokeBorder(ink, lineWidth: 3)
                        .frame(width: 30, height: 40)
                        .rotationEffect(.degrees(24))
                }
        }
    }

    private var progressPips: some View {
        HStack(spacing: 10) {
            ForEach(0..<tapsToOpen, id: \.self) { i in
                Capsule()
                    .fill(i < taps ? gold : Color.white.opacity(0.3))
                    .frame(width: i < taps ? 28 : 14, height: 8)
                    .overlay { Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 1) }
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: taps)
            }
        }
    }

    // MARK: - Interaction

    private func tapGift() {
        guard !opened else { return }
        taps += 1

        // Escalating haptics for a satisfying build-up.
        let intensity = 0.5 + progress * 0.5
        UIImpactFeedbackGenerator(style: taps >= tapsToOpen ? .heavy : .medium)
            .impactOccurred(intensity: intensity)

        // Shake / squash bounce on each tap.
        shake = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { shake = false }

        spawnTapSparkles()

        if taps >= tapsToOpen {
            openGift()
        }
    }

    private func openGift() {
        opened = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
            lidLifted = true
        }
        withAnimation(.easeOut(duration: 0.7)) {
            burst = true
        }
        spawnOpenSparkles()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            onOpened()
        }
    }

    private func startIdleWobble() {
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            wobble = true
        }
    }

    // MARK: - Sparkles

    private func spawnTapSparkles() {
        for _ in 0..<4 {
            addSparkle(spread: 90, upward: false)
        }
    }

    private func spawnOpenSparkles() {
        for _ in 0..<16 {
            addSparkle(spread: 150, upward: true)
        }
    }

    private func addSparkle(spread: CGFloat, upward: Bool) {
        let id = UUID()
        let startX = CGFloat.random(in: -30...30)
        let sparkle = Sparkle(
            id: id,
            x: startX,
            y: upward ? -40 : 0,
            size: CGFloat.random(in: 12...22),
            color: Bool.random() ? gold : pink,
            opacity: 1,
            rotation: Double.random(in: 0...360)
        )
        sparkles.append(sparkle)

        let dx = CGFloat.random(in: -spread...spread)
        let dy = upward ? CGFloat.random(in: -180 ... -60) : CGFloat.random(in: -90 ... -20)

        withAnimation(.easeOut(duration: 0.8)) {
            update(id) {
                $0.x += dx
                $0.y += dy
                $0.rotation += Double.random(in: -180...180)
            }
        }
        withAnimation(.easeIn(duration: 0.5).delay(0.35)) {
            update(id) { $0.opacity = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            sparkles.removeAll { $0.id == id }
        }
    }

    private func update(_ id: UUID, _ mutate: (inout Sparkle) -> Void) {
        guard let idx = sparkles.firstIndex(where: { $0.id == id }) else { return }
        mutate(&sparkles[idx])
    }

    private struct Sparkle: Identifiable {
        let id: UUID
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var color: Color
        var opacity: Double
        var rotation: Double
    }
}
