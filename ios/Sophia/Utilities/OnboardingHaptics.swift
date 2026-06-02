import UIKit

enum OnboardingHaptics {
    static func slideTransition() {
        impact(.rigid, intensity: 0.85)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            impact(.heavy, intensity: 1.0)
        }
    }

    static func selection() {
        impact(.soft, intensity: 0.65)
    }

    static func primaryCTA() {
        impact(.heavy, intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            impact(.rigid, intensity: 0.9)
        }
    }

    static func counterTick(progress: Double) {
        let milestones: [Double] = [0.25, 0.5, 0.75, 1.0]
        for m in milestones where abs(progress - m) < 0.025 {
            if m >= 1.0 {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                impact(.medium, intensity: 0.5 + m * 0.4)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    impact(.rigid, intensity: 0.7 + m * 0.2)
                }
            }
            return
        }
        if Int(progress * 42) % 4 == 0 {
            impact(.light, intensity: 0.35 + progress * 0.3)
        }
    }

    static func counterComplete() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            impact(.heavy, intensity: 1.0)
        }
    }

    static func loadingStepComplete(step: Int) {
        switch step {
        case 0: impact(.medium, intensity: 0.7)
        case 1:
            impact(.rigid, intensity: 0.85)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                impact(.heavy, intensity: 0.9)
            }
        default:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                impact(.heavy, intensity: 1.0)
            }
        }
    }

    static func planSelected() {
        impact(.rigid, intensity: 0.9)
    }

    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat) {
        let g = UIImpactFeedbackGenerator(style: style)
        g.impactOccurred(intensity: intensity)
    }
}
