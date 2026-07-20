import SwiftUI

struct OnboardingPhoneTimeScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void

    @State private var appeared: Bool = true

    private let ink = BrutalPalette.ink

    private var wholeHours: Int { Int(viewModel.phoneDailyHours) }
    private var hasHalf: Bool { (viewModel.phoneDailyHours - Double(wholeHours)) >= 0.25 }

    private var hoursBinding: Binding<Double> {
        Binding(
            get: { viewModel.phoneDailyHours },
            set: { viewModel.setPhoneDailyHours($0) }
        )
    }

    private var intensity: (labelKey: String, color: Color) {
        switch OnboardingViewModel.phoneBucket(forHours: viewModel.phoneDailyHours) {
        case 0: return ("onboarding.phone.intensity.light", OnboardingPastels.at(1))
        case 1: return ("onboarding.phone.intensity.moderate", OnboardingPastels.at(0))
        case 2: return ("onboarding.phone.intensity.high", BrutalPalette.pink)
        default: return ("onboarding.phone.intensity.intense", Color(red: 1.0, green: 0.45, blue: 0.45))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)

            OnboardingHeader(
                title: languageManager.text("onboarding.phone.title"),
                subtitle: languageManager.text("onboarding.phone.subtitle"),
                appeared: appeared
            )

            Spacer()

            hoursDisplay
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.85)

            Spacer().frame(height: 40)

            VStack(spacing: 12) {
                SmoothHoursSlider(hours: hoursBinding) {
                    OnboardingHaptics.selection()
                }

                HStack {
                    ForEach([0, 2, 4, 6, 8], id: \.self) { tick in
                        Text("\(tick)h")
                            .font(.jakarta(.caption2, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink.opacity(0.4))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()

            OnboardingPrimaryButton(title: languageManager.text("common.continue"), isEnabled: viewModel.canProceed, action: onNext)
                .opacity(appeared ? 1 : 0)
        }
        .onboardingFullBleedBackground(BrutalPalette.cream)
        .onAppear {
            viewModel.setPhoneDailyHours(viewModel.phoneDailyHours)
        }
    }

    private var hoursDisplay: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("\(wholeHours)")
                    .font(.jakarta(size: 88, weight: .heavy, design: .rounded))
                    .foregroundStyle(ink)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("h")
                    .font(.jakarta(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(ink.opacity(0.7))

                if hasHalf {
                    Text("30")
                        .font(.jakarta(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(ink.opacity(0.7))
                        .monospacedDigit()
                        .transition(.opacity)
                }
            }
            .animation(.snappy(duration: 0.3), value: wholeHours)
            .animation(.snappy(duration: 0.3), value: hasHalf)

            HStack(spacing: 6) {
                Circle()
                    .fill(intensity.color)
                    .frame(width: 9, height: 9)
                    .overlay { Circle().strokeBorder(ink, lineWidth: 1.5) }
                Text(languageManager.text(intensity.labelKey))
                    .font(.jakarta(.subheadline, design: .rounded, weight: .black))
                    .foregroundStyle(ink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(intensity.color.opacity(0.28), in: Capsule())
            .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
            .animation(.snappy(duration: 0.25), value: wholeHours)
        }
    }
}

/// Chunky neo-brutalist slider with snapping and a satisfying draggable thumb.
private struct SmoothHoursSlider: View {
    @Binding var hours: Double
    var onStepChange: () -> Void

    private let range: ClosedRange<Double> = 0...8
    private let step: Double = 0.5
    private let thumb: CGFloat = 38
    private let trackHeight: CGFloat = 18

    @State private var dragging = false

    private let ink = BrutalPalette.ink

    var body: some View {
        GeometryReader { geo in
            let usable = max(1, geo.size.width - thumb)
            let frac = CGFloat((hours - range.lowerBound) / (range.upperBound - range.lowerBound))
            let x = usable * frac

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white)
                    .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                    .frame(height: trackHeight)

                Capsule()
                    .fill(LinearGradient(colors: [BrutalPalette.pink, BrutalPalette.yellow], startPoint: .leading, endPoint: .trailing))
                    .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                    .frame(width: max(trackHeight, x + thumb / 2), height: trackHeight)

                ZStack {
                    Circle().fill(ink).frame(width: thumb, height: thumb).offset(y: 3)
                    Circle()
                        .fill(BrutalPalette.pink)
                        .frame(width: thumb, height: thumb)
                        .overlay { Circle().strokeBorder(ink, lineWidth: 3) }
                    Image(systemName: "iphone")
                        .font(.jakarta(size: 15, weight: .black))
                        .foregroundStyle(ink)
                }
                .scaleEffect(dragging ? 1.16 : 1.0)
                .offset(x: x)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: dragging)
            }
            .frame(height: thumb, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !dragging { dragging = true }
                        let loc = min(max(0, value.location.x - thumb / 2), usable)
                        let raw = range.lowerBound + Double(loc / usable) * (range.upperBound - range.lowerBound)
                        let snapped = min(range.upperBound, max(range.lowerBound, (raw / step).rounded() * step))
                        if snapped != hours {
                            hours = snapped
                            onStepChange()
                        }
                    }
                    .onEnded { _ in dragging = false }
            )
        }
        .frame(height: thumb)
    }
}
