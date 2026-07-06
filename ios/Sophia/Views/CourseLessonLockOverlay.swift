import SwiftUI

/// Central locker overlay shown on progressively-blurred lesson pages for free users.
struct CourseLessonLockOverlay: View {
    @Environment(LanguageManager.self) private var languageManager
    let onUnlock: () -> Void

    @State private var appeared = false
    @State private var pulse = false

    private let ink = Color.black
    private let pink = Color(red: 1.0, green: 0.553, blue: 0.706)

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(pink)
                    .frame(width: 76, height: 76)
                    .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                    .scaleEffect(pulse ? 1.06 : 1)

                Image(systemName: "lock.fill")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(ink)
            }

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onUnlock()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.subheadline.weight(.heavy))
                    Text(languageManager.text("course.unlock.free"))
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                }
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(DuolingoButtonStyle(fill: pink, shimmer: nil, depth: 4))
        }
        .padding(24)
        .frame(maxWidth: 300)
        .brutalOnboardingCard(depth: 5, corner: 24)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.94)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
