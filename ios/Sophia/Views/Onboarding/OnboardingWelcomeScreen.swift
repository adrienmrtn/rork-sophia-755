import SwiftUI

struct OnboardingWelcomeScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void
    @State private var titleAppeared: Bool = false
    @State private var pillAppeared: Bool = false
    @State private var ctaAppeared: Bool = false
    @State private var subjectIndex: Int = 0
    @State private var pillOpacity: Double = 1
    @State private var pillOffset: CGFloat = 0
    @State private var rotationTimer: Timer?

    private let subjects: [(storageKey: String, colorIndex: Int)] = [
        ("art", 3),
        ("histoire", 0),
        ("sciences", 1),
        ("litterature", 2),
        ("mythologie", 4),
        ("comprendreLeMonde", 5),
    ]

    var body: some View {
        ZStack {
            BrutalPalette.cream

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    Text(languageManager.text("onboarding.welcome.title"))
                        .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    rotatingSubjectPill
                }
                .padding(.horizontal, 28)
                .opacity(titleAppeared ? 1 : 0)
                .offset(y: titleAppeared ? 0 : 20)

                Spacer()

                OnboardingPrimaryButton(title: languageManager.text("common.continue"), action: handleNext)
                    .opacity(ctaAppeared ? 1 : 0)
                    .offset(y: ctaAppeared ? 0 : 24)
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BrutalPalette.cream)
        .onOnboardingSlideSettled {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) {
                titleAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.2)) {
                pillAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.38)) {
                ctaAppeared = true
            }
            startSubjectRotation()
        }
        .onDisappear {
            rotationTimer?.invalidate()
            rotationTimer = nil
        }
    }

    private var rotatingSubjectPill: some View {
        let subject = subjects[subjectIndex]
        return Text(languageManager.text("onboarding.welcome.rotating.\(subject.storageKey)"))
            .font(.system(.title2, design: .rounded, weight: .heavy))
            .foregroundStyle(BrutalPalette.ink)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(OnboardingPastels.at(subject.colorIndex), in: .capsule)
            .overlay {
                Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
            }
            .opacity(pillOpacity * (pillAppeared ? 1 : 0))
            .offset(y: pillOffset)
    }

    private func startSubjectRotation() {
        rotationTimer?.invalidate()
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            cycleSubject()
        }
    }

    private func cycleSubject() {
        withAnimation(.easeOut(duration: 0.2)) {
            pillOpacity = 0
            pillOffset = -8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            subjectIndex = (subjectIndex + 1) % subjects.count
            pillOffset = 8
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
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
