import SwiftUI

/// Central lock shown on progressively-blurred lesson pages for free users.
/// A single animated padlock — no CTA copy — that wiggles and pulses to invite a tap.
/// Tapping it opens the paywall.
struct CourseLessonLockOverlay: View {
    let onUnlock: () -> Void

    @State private var appeared = false
    @State private var pulse = false
    @State private var wiggle = false
    @State private var ringPhase = false
    @State private var pressed = false

    private let ink = Color.black
    private let pink = Color(red: 1.0, green: 0.553, blue: 0.706)
    private let gold = Color(red: 1.0, green: 0.84, blue: 0.35)

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = false }
                onUnlock()
            }
        } label: {
            ZStack {
                // Attention rings expanding outward.
                ForEach(0..<2, id: \.self) { i in
                    Circle()
                        .stroke(pink.opacity(0.5), lineWidth: 3)
                        .frame(width: 96, height: 96)
                        .scaleEffect(ringPhase ? 1.9 : 1.0)
                        .opacity(ringPhase ? 0 : 0.7)
                        .animation(
                            .easeOut(duration: 1.8)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.9),
                            value: ringPhase
                        )
                }

                // Soft glow.
                Circle()
                    .fill(gold.opacity(pulse ? 0.4 : 0.2))
                    .frame(width: 120, height: 120)
                    .blur(radius: 16)
                    .scaleEffect(pulse ? 1.1 : 0.9)

                // Padlock medallion.
                ZStack {
                    Circle()
                        .fill(pink)
                        .frame(width: 92, height: 92)
                        .overlay { Circle().strokeBorder(ink, lineWidth: 3.5) }
                        .background(alignment: .center) {
                            Circle().fill(ink).frame(width: 92, height: 92).offset(y: 6)
                        }

                    Image(systemName: "lock.fill")
                        .font(.jakarta(size: 38, weight: .heavy))
                        .foregroundStyle(ink)
                        .scaleEffect(pulse ? 1.06 : 1.0)
                }
                .rotationEffect(.degrees(wiggle ? 5 : -5))
                .scaleEffect(pressed ? 0.88 : (appeared ? 1 : 0.4))
            }
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appeared = true }
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) { pulse = true }
            ringPhase = true
            startWiggleLoop()
        }
    }

    /// Periodic playful wiggle to draw the eye without being constant.
    private func startWiggleLoop() {
        func tick() {
            withAnimation(.easeInOut(duration: 0.1).repeatCount(5, autoreverses: true)) {
                wiggle.toggle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                tick()
            }
        }
        tick()
    }
}
