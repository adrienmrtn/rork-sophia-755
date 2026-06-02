import SwiftUI

/// `true` when this screen is the stable front layer (slide transition finished).
private struct OnboardingSlideSettledKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    var onboardingSlideSettled: Bool {
        get { self[OnboardingSlideSettledKey.self] }
        set { self[OnboardingSlideSettledKey.self] = newValue }
    }
}

/// Runs `action` once when the horizontal slide transition completes for this screen.
struct OnboardingAfterSlideTransition: ViewModifier {
    @Environment(\.onboardingSlideSettled) private var slideSettled
    let delay: TimeInterval
    let action: () -> Void
    @State private var didRun: Bool = false

    func body(content: Content) -> some View {
        content
            .onChange(of: slideSettled) { _, settled in
                guard settled, !didRun else { return }
                scheduleAction()
            }
            .onAppear {
                if slideSettled, !didRun {
                    scheduleAction()
                }
            }
    }

    private func scheduleAction() {
        didRun = true
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            action()
        }
    }
}

extension View {
    func onOnboardingSlideSettled(delay: TimeInterval = 0.15, perform action: @escaping () -> Void) -> some View {
        modifier(OnboardingAfterSlideTransition(delay: delay, action: action))
    }

    /// Full-bleed background — extends into safe areas (wrapper also sets per-slide color).
    func onboardingFullBleedBackground(_ color: Color) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(color.ignoresSafeArea())
    }
}
