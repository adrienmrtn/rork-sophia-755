import SwiftUI

/// Page 11 — « How your free trial works » (timeline). Inspiré du 1er screenshot, adapté à
/// un essai de **3 jours** (Aujourd'hui → J+2 rappel → J+3 fin).
struct OnboardingV2TrialSteps: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var revealed = 0

    private var endDateString: String {
        let date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        let f = DateFormatter()
        f.locale = Locale(identifier: languageManager.current.localeIdentifier)
        f.dateFormat = "d MMMM"
        return f.string(from: date)
    }

    private var steps: [(icon: String, title: String, detail: String, active: Bool, done: Bool)] {
        [
            ("checkmark", languageManager.text("onboardingV2.trial.step0.title"),
             languageManager.text("onboardingV2.trial.step0.detail"), false, true),
            ("lock.open.fill", languageManager.text("onboardingV2.trial.step1.title"),
             languageManager.text("onboardingV2.trial.step1.detail"), true, false),
            ("bell.fill", languageManager.text("onboardingV2.trial.step2.title"),
             languageManager.text("onboardingV2.trial.step2.detail"), false, false),
            ("star.fill", languageManager.text("onboardingV2.trial.step3.title"),
             String(format: languageManager.text("onboardingV2.trial.step3.detail"), endDateString), false, false),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 72)

            Text(languageManager.text("onboardingV2.trial.title"))
                .font(DS.title(.largeTitle, .heavy))
                .foregroundStyle(OV2.ink)
                .padding(.horizontal, 28)
                .ov2Reveal(delay: 0.05)

            Spacer().frame(height: 36)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 0) {
                            icon(step)
                            if i < steps.count - 1 {
                                Rectangle()
                                    .fill(OV2.accent.opacity(0.18))
                                    .frame(width: 3, height: 46)
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .font(DS.title(.headline, .bold))
                                .foregroundStyle(step.active ? OV2.accent : OV2.ink)
                            Text(step.detail)
                                .font(DS.sans(.subheadline, .medium))
                                .foregroundStyle(OV2.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.bottom, i < steps.count - 1 ? 14 : 0)
                        Spacer(minLength: 0)
                    }
                    .opacity(i < revealed ? 1 : 0)
                    .offset(x: i < revealed ? 0 : -12)
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            OnboardingV2Button(title: languageManager.text("onboardingV2.trial.cta"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            for i in 0..<steps.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + Double(i) * 0.18) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { revealed = i + 1 }
                    OnboardingHaptics.selection()
                }
            }
        }
    }

    private func icon(_ step: (icon: String, title: String, detail: String, active: Bool, done: Bool)) -> some View {
        let bg: Color = step.done ? OV2.accent : (step.active ? OV2.accent : OV2.inkTertiary.opacity(0.35))
        return ZStack {
            Circle().fill(bg).frame(width: 40, height: 40)
            Image(systemName: step.icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}
