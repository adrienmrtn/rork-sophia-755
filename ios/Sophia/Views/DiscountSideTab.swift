import SwiftUI

/// Flash-discount pull tab that pokes in from the right edge while the offer clock is live.
/// Redesigned in the app's calm design system (`DS`): a clean navy pill with a hairline
/// edge and a soft shadow, a small flame glyph and the live countdown. Gently bobs to draw
/// attention without the previous cartoon pink/gold look. Tapping opens the discount paywall.
struct DiscountSideTab: View {
    @Environment(LanguageManager.self) private var languageManager
    let discountManager: DiscountOfferManager
    let onTap: () -> Void

    @State private var appeared = false
    @State private var bob = false
    @State private var pressed = false

    private let corner: CGFloat = 18

    var body: some View {
        // Observe the per-second tick so the countdown refreshes live.
        _ = discountManager.tick
        return HStack(spacing: 0) {
            Spacer(minLength: 0)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { pressed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = false }
                    onTap()
                }
            } label: {
                content
            }
            .buttonStyle(.plain)
            .offset(x: appeared ? (bob ? 0 : 6) : 120)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .offset(y: -30)
        .allowsHitTesting(true)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.2)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                bob = true
            }
        }
    }

    private var content: some View {
        VStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .font(.jakarta(size: 17, weight: .bold))
                .foregroundStyle(.white)

            Text(languageManager.text("discount.sideTab.label"))
                .font(.jakarta(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .tracking(0.6)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: true, vertical: true)

            Text(discountManager.formattedRemaining)
                .font(.jakarta(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .fixedSize(horizontal: true, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        // Grow with DE/IT labels (ANGEBOT / OFFERTA) instead of clipping at FR-tuned 66pt.
        .frame(minWidth: 66)
        .fixedSize(horizontal: true, vertical: false)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: corner,
                bottomLeadingRadius: corner,
                style: .continuous
            )
            .fill(DS.accent)
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: corner,
                bottomLeadingRadius: corner,
                style: .continuous
            )
            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            // Little grip dots hinting it's pull-able.
            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle().fill(.white.opacity(0.4)).frame(width: 3, height: 3)
                }
            }
            .padding(.leading, 6)
        }
        .shadow(color: DS.accent.opacity(0.3), radius: 12, x: -2, y: 6)
        .scaleEffect(pressed ? 0.92 : 1)
    }
}
