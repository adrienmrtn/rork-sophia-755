import SwiftUI

/// Surprise-gift overlay that floats above the app (the Home stays visible behind a
/// soft dim). The user taps the gift a few times to reveal it, then the discount
/// paywall is shown. Calm card-based reveal: a soft icon fills with each tap, no
/// bursts or sparkle showers.
struct DiscountGiftOverlay: View {
    @Environment(LanguageManager.self) private var languageManager
    let onOpened: () -> Void

    /// Number of taps required to fully open the gift.
    private let tapsToOpen = 3

    @State private var taps = 0
    @State private var appeared = false
    @State private var bounce = false
    @State private var opened = false
    @State private var backdropIn = false
    @State private var iconPulse = false

    private var progress: CGFloat {
        CGFloat(min(taps, tapsToOpen)) / CGFloat(tapsToOpen)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(backdropIn ? 0.45 : 0)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { tapGift() }

            card
                .padding(.horizontal, 32)
                .scaleEffect(appeared ? 1 : 0.9)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { backdropIn = true }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.05)) {
                appeared = true
            }
        }
    }

    private var card: some View {
        VStack(spacing: 22) {
            VStack(spacing: 8) {
                Text(languageManager.text("discount.gift.title"))
                    .font(DS.title(.title2, .semibold))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)

                Text(promptText)
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
                    .id(promptText)
            }
            .opacity(!opened ? 1 : 0)

            giftIcon
                .contentShape(Circle())
                .onTapGesture { tapGift() }

            progressPips
                .opacity(!opened ? 1 : 0)
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
        .dsSoftShadow()
    }

    private var promptText: String {
        let remaining = max(0, tapsToOpen - taps)
        if opened { return "" }
        if taps == 0 { return languageManager.text("discount.gift.tapToOpen") }
        if remaining <= 1 { return languageManager.text("discount.gift.almost") }
        return languageManager.text("discount.gift.keepTapping")
    }

    // MARK: - Gift icon

    private var giftIcon: some View {
        ZStack {
            Circle()
                .stroke(DS.hairline, lineWidth: 8)
                .frame(width: 128, height: 128)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(DS.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 128, height: 128)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)

            Circle()
                .fill(DS.accentTint)
                .frame(width: 100, height: 100)

            Image(systemName: opened ? "gift.fill" : "gift")
                .font(.jakarta(size: 42, weight: .regular))
                .foregroundStyle(DS.accent)
                .symbolEffect(.bounce, value: bounce)
                .scaleEffect(iconPulse ? 1.08 : 1.0)
        }
        .scaleEffect(bounce ? 1.08 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.45), value: bounce)
    }

    private var progressPips: some View {
        HStack(spacing: 8) {
            ForEach(0..<tapsToOpen, id: \.self) { i in
                Capsule()
                    .fill(i < taps ? DS.accent : DS.hairline)
                    .frame(width: i < taps ? 24 : 12, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: taps)
            }
        }
    }

    // MARK: - Interaction

    private func tapGift() {
        guard !opened else { return }
        taps += 1

        let intensity = 0.5 + progress * 0.5
        UIImpactFeedbackGenerator(style: taps >= tapsToOpen ? .heavy : .medium)
            .impactOccurred(intensity: intensity)

        bounce.toggle()

        if taps >= tapsToOpen {
            openGift()
        }
    }

    private func openGift() {
        opened = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        withAnimation(.easeInOut(duration: 0.9).repeatCount(2, autoreverses: true)) {
            iconPulse = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            onOpened()
        }
    }
}
