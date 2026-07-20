import SwiftUI

/// Page 6 — temps d'écran quotidien, slider satisfaisant (0…8 h par pas de 0,5).
struct OnboardingV2PhoneTime: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var hours: Double = 3.0

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 84)

            Text(languageManager.text("onboardingV2.phone.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .ov2Reveal(delay: 0.1)

            Spacer()

            VStack(spacing: 6) {
                Text(hoursLabel)
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(OV2.accent)
                    .contentTransition(.numericText())
                Text(languageManager.text("onboardingV2.phone.perDay"))
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(OV2.inkSecondary)
            }

            Image(systemName: "iphone.gen3")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(OV2.accentSoft.opacity(0.5))
                .padding(.vertical, 28)

            Slider(value: $hours, in: 0...8, step: 0.5)
                .tint(OV2.accent)
                .padding(.horizontal, 36)
                .onChange(of: hours) { _, newValue in
                    vm.phoneDailyHours = newValue
                    OnboardingHaptics.selection()
                }

            HStack {
                Text("0h").font(DS.sans(.caption, .medium)).foregroundStyle(OV2.inkTertiary)
                Spacer()
                Text("8h+").font(DS.sans(.caption, .medium)).foregroundStyle(OV2.inkTertiary)
            }
            .padding(.horizontal, 40)
            .padding(.top, 4)

            Spacer()

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            hours = vm.phoneDailyHours
        }
    }

    private var hoursLabel: String {
        let whole = Int(hours)
        let hasHalf = (hours - Double(whole)) >= 0.25
        return hasHalf ? "\(whole)h30" : "\(whole)h"
    }
}
