import SwiftUI

struct OnboardingFinalScreen: View {
    let onComplete: () -> Void
    @State private var appeared: Bool = false
    @State private var confettiTrigger: Int = 0
    @State private var particles: [OnboardingConfetti] = []

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            ForEach(particles) { p in
                Rectangle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size * 1.4)
                    .overlay { Rectangle().strokeBorder(BrutalPalette.ink, lineWidth: 1.5) }
                    .rotationEffect(.degrees(p.rotation))
                    .position(p.position)
                    .opacity(p.opacity)
            }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    ZStack {
                        Circle()
                            .fill(BrutalPalette.ink)
                            .frame(width: 140, height: 140)
                            .offset(y: 6)

                        Circle()
                            .fill(Color(red: 0.70, green: 0.95, blue: 0.80))
                            .frame(width: 130, height: 130)
                            .overlay { Circle().strokeBorder(BrutalPalette.ink, lineWidth: 3) }

                        Image(systemName: "checkmark")
                            .font(.system(size: 56, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                            .symbolEffect(.bounce, value: confettiTrigger)
                    }
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.3)

                    VStack(spacing: 12) {
                        Text("Profil prêt !")
                            .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                            .opacity(appeared ? 1 : 0)

                        Text("Bienvenue dans Sophia.\nCommence à apprendre dès maintenant.")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                    }
                }

                Spacer()

                OnboardingPrimaryButton(title: "Commencer à apprendre", action: onComplete)
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
        let colors: [Color] = [
            BrutalPalette.pink,
            Color(red: 0.70, green: 0.95, blue: 0.80),
            Color(red: 1.0, green: 0.86, blue: 0.62),
            Color(red: 0.66, green: 0.92, blue: 0.96),
            Color(red: 0.82, green: 0.78, blue: 1.0),
        ]
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        for i in 0..<40 {
            let p = OnboardingConfetti(
                id: i,
                color: colors[i % colors.count],
                size: CGFloat.random(in: 8...14),
                position: CGPoint(x: screenWidth / 2, y: screenHeight * 0.4),
                rotation: Double.random(in: -30...30),
                opacity: 1.0
            )
            particles.append(p)

            let targetX = CGFloat.random(in: 20...(screenWidth - 20))
            let targetY = CGFloat.random(in: 50...(screenHeight - 100))
            let delay = Double(i) * 0.02
            let endRotation = Double.random(in: -180...180)

            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(delay)) {
                if let idx = particles.firstIndex(where: { $0.id == i }) {
                    particles[idx].position = CGPoint(x: targetX, y: targetY)
                    particles[idx].rotation = endRotation
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
    var rotation: Double
    var opacity: Double
}
