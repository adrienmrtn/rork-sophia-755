import SwiftUI
import UIKit

/// Animates XP text + tier progress bar, including a clean level-up sequence
/// (fill to 100% → pause → reset → fill in new tier).
enum XPProgressAnimator {
    typealias Tier = (level: Int, lower: Int, upper: Int)

    static var tiers: [Tier] { ProgressManager.subjectXPTiers }

    static func tier(for xp: Int) -> Tier {
        tiers.last(where: { xp >= $0.lower }) ?? tiers[0]
    }

    static func barFraction(for xp: Int) -> CGFloat {
        let t = tier(for: xp)
        if t.level == 5 { return 1.0 }
        let span = max(1, t.upper - t.lower)
        return CGFloat(min(1.0, max(0.0, Double(xp - t.lower) / Double(span))))
    }

    static func animate(
        from startXP: Int,
        to endXP: Int,
        setXP: @escaping (Int) -> Void,
        setLevel: @escaping (Int) -> Void,
        setBarFill: @escaping (CGFloat, Bool) -> Void,
        haptic: @escaping () -> Void,
        completion: @escaping () -> Void
    ) {
        let startTier = tier(for: startXP)
        let endTier = tier(for: endXP)

        setXP(startXP)
        setLevel(startTier.level)
        setBarFill(barFraction(for: startXP), false)

        if startTier.level == endTier.level {
            runSegment(
                xpFrom: startXP,
                xpTo: endXP,
                fillFrom: barFraction(for: startXP),
                fillTo: barFraction(for: endXP),
                duration: 2.0,
                steps: 40,
                setXP: setXP,
                setBarFill: setBarFill,
                haptic: haptic
            ) {
                setXP(endXP)
                setBarFill(barFraction(for: endXP), false)
                completion()
            }
            return
        }

        // Phase 1 — decelerate into tier cap, brief hold, instant reset, then fill new tier
        let capXP = max(startXP, startTier.upper - 1)
        let fillToFullDuration = (startTier.level == 1 && endTier.level == 2) ? 2.35 : 1.5
        runSegment(
            xpFrom: startXP,
            xpTo: capXP,
            fillFrom: barFraction(for: startXP),
            fillTo: 1.0,
            duration: fillToFullDuration,
            steps: 36,
            decelerate: true,
            setXP: setXP,
            setBarFill: setBarFill,
            haptic: haptic
        ) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                setBarFill(0, false)
                setLevel(endTier.level)
                setXP(endTier.lower)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                    runSegment(
                        xpFrom: endTier.lower,
                        xpTo: endXP,
                        fillFrom: 0,
                        fillTo: barFraction(for: endXP),
                        duration: 1.2,
                        steps: 32,
                        decelerate: false,
                        setXP: setXP,
                        setBarFill: setBarFill,
                        haptic: haptic
                    ) {
                        setXP(endXP)
                        setBarFill(barFraction(for: endXP), false)
                        completion()
                    }
                }
            }
        }
    }

    private static func runSegment(
        xpFrom: Int,
        xpTo: Int,
        fillFrom: CGFloat,
        fillTo: CGFloat,
        duration: Double,
        steps: Int,
        decelerate: Bool = false,
        setXP: @escaping (Int) -> Void,
        setBarFill: @escaping (CGFloat, Bool) -> Void,
        haptic: @escaping () -> Void,
        completion: @escaping () -> Void
    ) {
        let barAnimation: Animation = decelerate
            ? .timingCurve(0.12, 0.92, 0.18, 1.0, duration: duration)
            : .easeOut(duration: duration)

        withAnimation(barAnimation) {
            setBarFill(fillTo, true)
        }

        let interval = duration / Double(steps)
        var lastHapticBucket = -1

        for step in 0...steps {
            let delay = interval * Double(step)
            let progress = Double(step) / Double(steps)
            let eased = 1 - pow(1 - progress, 2.8)
            let xpValue = xpFrom + Int(eased * Double(xpTo - xpFrom))

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                setXP(xpValue)
                let bucket = Int(progress * 18)
                if bucket != lastHapticBucket {
                    lastHapticBucket = bucket
                    haptic()
                    if bucket % 4 == 0 {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.65)
                    }
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) {
            completion()
        }
    }

    static func progressionHaptic(intensity: CGFloat = 0.55) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: intensity)
    }
}
