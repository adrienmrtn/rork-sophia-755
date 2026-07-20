import SwiftUI

/// Flash-discount pull tab that pokes in from the right edge of the screen while the
/// 60-minute offer is active. Bobs and glows to draw attention; tapping opens the paywall.
struct DiscountSideTab: View {
    @Environment(LanguageManager.self) private var languageManager
    let discountManager: DiscountOfferManager
    let onTap: () -> Void

    @State private var appeared = false
    @State private var bob = false
    @State private var glow = false
    @State private var pressed = false

    private let ink = Color.black
    private let pink = Color(red: 1.0, green: 0.553, blue: 0.706)
    private let gold = Color(red: 1.0, green: 0.84, blue: 0.35)

    private let corner: CGFloat = 20

    var body: some View {
        // Observe the per-second tick so the countdown refreshes live.
        _ = discountManager.tick
        return HStack(spacing: 0) {
            Spacer(minLength: 0)
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { pressed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = false }
                    onTap()
                }
            } label: {
                content
            }
            .buttonStyle(.plain)
            .offset(x: appeared ? (bob ? 0 : 8) : 120)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .offset(y: -30)
        .allowsHitTesting(true)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.2)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                bob = true
            }
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }

    private var content: some View {
        VStack(spacing: 5) {
            Image(systemName: "bolt.fill")
                .font(.jakarta(size: 20, weight: .black))
                .foregroundStyle(gold)
                .shadow(color: .black.opacity(0.25), radius: 1, y: 1)

            Text(languageManager.text("discount.sideTab.label"))
                .font(.jakarta(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .tracking(0.6)

            Text(discountManager.formattedRemaining)
                .font(.jakarta(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(width: 74)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: corner,
                bottomLeadingRadius: corner,
                style: .continuous
            )
            .fill(pink)
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: corner,
                bottomLeadingRadius: corner,
                style: .continuous
            )
            .strokeBorder(ink, lineWidth: 3)
        )
        .overlay(alignment: .leading) {
            // Little grip dots hinting it's pull-able.
            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle().fill(ink.opacity(0.35)).frame(width: 4, height: 4)
                }
            }
            .padding(.leading, 6)
        }
        .background(alignment: .center) {
            // Glow halo behind the tab.
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(gold.opacity(glow ? 0.5 : 0.25))
                .blur(radius: 14)
                .scaleEffect(glow ? 1.15 : 0.95)
        }
        .scaleEffect(pressed ? 0.92 : 1)
    }
}
