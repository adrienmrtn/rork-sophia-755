import SwiftUI

struct OnboardingFinalScreen: View {
    let onComplete: () -> Void
    @State private var appeared: Bool = false
    @State private var confettiTrigger: Int = 0
    @State private var particles: [OnboardingConfetti] = []

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .position(p.position)
                    .opacity(p.opacity)
            }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    ZStack {
                        Circle()
                            .fill(SophiaTheme.emerald.opacity(0.12))
                            .frame(width: 120, height: 120)

                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(SophiaTheme.emerald)
                            .symbolEffect(.bounce, value: confettiTrigger)
                    }
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.3)

                    VStack(spacing: 14) {
                        Text("Votre profil est configuré")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(SophiaTheme.textPrimary)
                            .opacity(appeared ? 1 : 0)

                        Text("Bienvenue dans Sophia.")
                            .font(.system(.title3, design: .rounded, weight: .medium))
                            .foregroundStyle(SophiaTheme.emerald)
                            .opacity(appeared ? 1 : 0)

                        Text("Commence à apprendre dès maintenant.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                    }
                }

                Spacer()

                OnboardingButton(title: "Commencer à apprendre", action: onComplete)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
            }
        }
        .sensoryFeedback(.success, trigger: confettiTrigger)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.3)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                confettiTrigger += 1
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                spawnConfetti()
            }
        }
    }

    private func spawnConfetti() {
        let colors: [Color] = [SophiaTheme.emerald, SophiaTheme.accent, SophiaTheme.streakOrange, .white, SophiaTheme.errorRed]
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        for i in 0..<40 {
            let p = OnboardingConfetti(
                id: i,
                color: colors[i % colors.count],
                size: CGFloat.random(in: 4...10),
                position: CGPoint(x: screenWidth / 2, y: screenHeight * 0.4),
                opacity: 1.0
            )
            particles.append(p)

            let targetX = CGFloat.random(in: 20...(screenWidth - 20))
            let targetY = CGFloat.random(in: 50...(screenHeight - 100))
            let delay = Double(i) * 0.02

            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(delay)) {
                if let idx = particles.firstIndex(where: { $0.id == i }) {
                    particles[idx].position = CGPoint(x: targetX, y: targetY)
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 + delay) {
                withAnimation(.easeOut(duration: 0.8)) {
                    if let idx = particles.firstIndex(where: { $0.id == i }) {
                        particles[idx].opacity = 0
                    }
                }
            }
        }
    }
}

struct OnboardingConfetti: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}
