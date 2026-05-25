import SwiftUI
import Combine

struct OnboardingWelcomeScreen: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var subjectIndex: Int = 0
    @State private var pillOpacity: Double = 1
    @State private var pillOffset: CGFloat = 0

    private let subjects: [String] = [
        "l'art",
        "l'histoire",
        "les sciences",
        "la littérature",
        "la mythologie",
        "le monde actuel"
    ]

    private let subjectColors: [Color] = [
        Color(red: 0.66, green: 0.92, blue: 0.96), // art - cyan
        Color(red: 1.0, green: 0.86, blue: 0.62),  // histoire - peach
        Color(red: 0.70, green: 0.95, blue: 0.80), // sciences - mint
        Color(red: 1.0, green: 0.78, blue: 0.78),  // littérature - soft red
        Color(red: 0.82, green: 0.78, blue: 1.0),  // mythologie - lavender
        Color(red: 0.74, green: 0.90, blue: 1.0),  // monde actuel - sky
    ]

    private let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Card
                VStack(spacing: 28) {
                    Text("Sophia est ton partenaire\npour maîtriser")
                        .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    // Animated pill with subject color
                    Text(subjects[subjectIndex])
                        .font(.system(.title, design: .rounded, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(subjectColors[subjectIndex], in: .capsule)
                        .overlay {
                            Capsule()
                                .strokeBorder(BrutalPalette.ink, lineWidth: 2)
                        }
                        .opacity(pillOpacity)
                        .offset(y: pillOffset)
                        .animation(.easeInOut(duration: 0.35), value: pillOpacity)
                        .animation(.easeInOut(duration: 0.35), value: pillOffset)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 36)
                .background(.white)
                .clipShape(.rect(cornerRadius: 24))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
                }
                .shadow(color: BrutalPalette.ink.opacity(0.16), radius: 0, x: 0, y: 4)
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)

                Spacer()

                OnboardingPrimaryButton(title: "Suivant \u{2192}", action: handleNext)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                appeared = true
            }
        }
        .onReceive(timer) { _ in
            cycleSubject()
        }
    }

    private let haptic = UIImpactFeedbackGenerator(style: .light)

    private func cycleSubject() {
        // Fade out + slight slide up
        withAnimation(.easeInOut(duration: 0.2)) {
            pillOpacity = 0
            pillOffset = -12
        }

        // Change subject, fade in + slide down from above
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            subjectIndex = (subjectIndex + 1) % subjects.count
            pillOffset = 12
            haptic.impactOccurred()

            withAnimation(.easeInOut(duration: 0.28)) {
                pillOpacity = 1
                pillOffset = 0
            }
        }
    }

    private func handleNext() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onNext()
    }
}
