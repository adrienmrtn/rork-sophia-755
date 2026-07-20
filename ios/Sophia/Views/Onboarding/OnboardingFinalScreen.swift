import SwiftUI

struct OnboardingFinalScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onComplete: () -> Void
    @State private var appeared: Bool = true
    @State private var confettiTrigger: Int = 0
    @State private var particles: [OnboardingConfetti] = []

    private static let allInterests: [(subject: Subject, icon: String, color: Color)] = [
        (.histoire, "building.columns", Color(red: 1.0, green: 0.86, blue: 0.62)),
        (.sciences, "atom", Color(red: 0.70, green: 0.95, blue: 0.80)),
        (.litterature, "book.closed", Color(red: 1.0, green: 0.78, blue: 0.78)),
        (.art, "paintpalette", Color(red: 0.66, green: 0.92, blue: 0.96)),
        (.mythologie, "bolt.fill", Color(red: 0.82, green: 0.78, blue: 1.0)),
        (.comprendreLeMonde, "globe.europe.africa", Color(red: 0.74, green: 0.90, blue: 1.0)),
    ]

    private var selectedInterests: [(label: String, icon: String, color: Color)] {
        let saved = OnboardingViewModel.loadPersistedInterests()
        return Self.allInterests
            .filter { saved.contains($0.subject.storageKey) }
            .map { (
                label: $0.subject.localizedShortName(language: languageManager.current),
                icon: $0.icon,
                color: $0.color
            ) }
    }

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
                            .font(.jakarta(size: 56, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                            .symbolEffect(.bounce, value: confettiTrigger)
                    }
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.3)

                    VStack(spacing: 12) {
                        Text(languageManager.text("onboarding.final.title"))
                            .font(.jakarta(.largeTitle, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                            .opacity(appeared ? 1 : 0)

                        Text(languageManager.text("onboarding.final.subtitle"))
                            .font(.jakarta(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                    }

                    if !selectedInterests.isEmpty {
                        VStack(spacing: 10) {
                            Text(languageManager.text("onboarding.final.subjects"))
                                .font(.jakarta(size: 11, weight: .heavy, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(BrutalPalette.ink.opacity(0.5))

                            HStack(spacing: 8) {
                                ForEach(Array(selectedInterests.enumerated()), id: \.offset) { idx, interest in
                                    HStack(spacing: 6) {
                                        Image(systemName: interest.icon)
                                            .font(.jakarta(size: 12, weight: .heavy))
                                            .foregroundStyle(BrutalPalette.ink)
                                        Text(interest.label)
                                            .font(.jakarta(size: 13, weight: .heavy, design: .rounded))
                                            .foregroundStyle(BrutalPalette.ink)
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(interest.color)
                                    .clipShape(.rect(cornerRadius: 10))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(BrutalPalette.ink, lineWidth: 2)
                                    }
                                    .shadow(color: BrutalPalette.ink.opacity(0.18), radius: 0, x: 0, y: 2)
                                    .opacity(appeared ? 1 : 0)
                                    .scaleEffect(appeared ? 1 : 0.6)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.6 + Double(idx) * 0.1), value: appeared)
                                }
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                    }
                }

                Spacer()

                OnboardingPrimaryButton(title: languageManager.text("common.startLearning"), action: onComplete)
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
