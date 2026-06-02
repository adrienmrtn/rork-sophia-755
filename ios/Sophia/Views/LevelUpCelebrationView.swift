import SwiftUI

struct LevelUpCelebrationView: View {
    let subject: Subject
    let previousLevel: Int
    let newLevel: Int
    let onContinue: () -> Void

    @State private var appeared: Bool = false
    @State private var badgeScale: CGFloat = 0.4
    @State private var levelScale: CGFloat = 0.5
    @State private var showNewLevel: Bool = false
    @State private var confettiTrigger: Int = 0

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream
    private let pink = BrutalPalette.pink
    private let yellow = Color(red: 1.0, green: 0.84, blue: 0.35)

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            ConfettiView(trigger: confettiTrigger)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                SubjectBadgeView(subject: subject, emojiSize: 56, cornerRadius: 22)
                    .frame(width: 120, height: 120)
                    .scaleEffect(badgeScale)
                    .opacity(appeared ? 1 : 0)

                Spacer(minLength: 28)

                Text("Niveau supérieur !")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                Text(subject.shortName)
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.55))
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)

                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text("NIV. \(previousLevel)")
                        .font(.system(.title, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink.opacity(showNewLevel ? 0.35 : 1))
                        .scaleEffect(showNewLevel ? 0.85 : 1)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(pink)
                        .opacity(showNewLevel ? 1 : 0.3)

                    Text("NIV. \(newLevel)")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundStyle(ink)
                        .scaleEffect(levelScale)
                        .opacity(showNewLevel ? 1 : 0)
                }
                .padding(.top, 24)

                Spacer(minLength: 32)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onContinue()
                } label: {
                    Text("Continuer")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(DuolingoButtonStyle(fill: yellow, shimmer: nil))
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(showNewLevel ? 1 : 0)
                .offset(y: showNewLevel ? 0 : 20)
            }
        }
        .onAppear { runSequence() }
    }

    private func runSequence() {
        withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
            appeared = true
            badgeScale = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            confettiTrigger += 1
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                showNewLevel = true
                levelScale = 1.0
            }
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
        }
    }
}
