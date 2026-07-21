import SwiftUI

/// Central lock shown on progressively-blurred lesson pages for free users.
/// A single calm padlock medallion — no CTA copy — aligned on the current design system
/// (`DS.*`): white surface, accent lock, hairline border, soft shadow and a gentle pulse
/// with soft attention rings. Tapping it opens the paywall.
struct CourseLessonLockOverlay: View {
    let onUnlock: () -> Void

    @State private var appeared = false
    @State private var pulse = false
    @State private var ringPhase = false
    @State private var pressed = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.22, dampingFraction: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { pressed = false }
                onUnlock()
            }
        } label: {
            ZStack {
                // Soft attention rings expanding outward.
                ForEach(0..<2, id: \.self) { i in
                    Circle()
                        .stroke(DS.accent.opacity(0.22), lineWidth: 2)
                        .frame(width: 92, height: 92)
                        .scaleEffect(ringPhase ? 1.8 : 1.0)
                        .opacity(ringPhase ? 0 : 0.6)
                        .animation(
                            .easeOut(duration: 2.2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 1.1),
                            value: ringPhase
                        )
                }

                // Calm accent halo.
                Circle()
                    .fill(DS.accent.opacity(pulse ? 0.14 : 0.07))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                    .scaleEffect(pulse ? 1.08 : 0.94)

                // Padlock medallion (design-system aligned).
                ZStack {
                    Circle()
                        .fill(DS.surface)
                        .frame(width: 88, height: 88)
                        .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
                        .dsSoftShadow()

                    Circle()
                        .fill(DS.accentTint)
                        .frame(width: 62, height: 62)

                    Image(systemName: "lock.fill")
                        .font(.jakarta(size: 29, weight: .semibold))
                        .foregroundStyle(DS.accent)
                        .scaleEffect(pulse ? 1.04 : 1.0)
                }
                .scaleEffect(pressed ? 0.9 : (appeared ? 1 : 0.5))
            }
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) { appeared = true }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { pulse = true }
            ringPhase = true
        }
    }
}
