import SwiftUI

/// Central locker overlay shown on blurred lesson pages for free users.
struct CourseLessonLockOverlay: View {
    @Environment(LanguageManager.self) private var languageManager
    let onUnlock: () -> Void

    @State private var appeared = false
    @State private var shimmerOffset: CGFloat = -200
    @State private var shimmerActive = false

    private let ink = Color.black
    private let emerald = Color(red: 0.18, green: 0.72, blue: 0.55)

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 72, height: 72)
                    .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                Image(systemName: "lock.fill")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(ink)
            }

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onUnlock()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.subheadline.weight(.semibold))
                    Text(languageManager.text("course.unlock.free"))
                        .font(.system(.headline, design: .rounded, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(emerald, in: .rect(cornerRadius: 16))
                .overlay {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.45), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 80, height: geo.size.height * 2)
                            .rotationEffect(.degrees(12))
                            .offset(x: shimmerOffset)
                            .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 16))
                }
                .shadow(color: emerald.opacity(0.35), radius: 12, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .frame(maxWidth: 300)
        .background(Color.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.5)
        }
        .shadow(color: ink.opacity(0.1), radius: 18, y: 8)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.94)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                appeared = true
            }
            shimmerActive = true
            ShimmerAnimation.runLoop(offset: $shimmerOffset) { shimmerActive }
        }
        .onDisappear {
            shimmerActive = false
        }
    }
}
