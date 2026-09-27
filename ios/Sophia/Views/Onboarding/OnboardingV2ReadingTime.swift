import SwiftUI
import UIKit

/// « À quelle heure veux-tu lire ton cours ? » Un curseur de 5 h à 23 h ; au-dessus, le
/// ciel change avec l'heure et le soleil traverse l'écran de gauche à droite, se lève à
/// l'aube et se couche le soir, la lune prenant le relais la nuit. L'heure choisie devient
/// celle du rappel quotidien, demandé juste après.
struct OnboardingV2ReadingTime: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var hour: Double = 8
    @State private var lastStep = 8

    private let range: ClosedRange<Double> = 5...23

    var body: some View {
        OV2ScrollableContent {
            VStack(spacing: 0) {
                Spacer().frame(height: 84)

                Text(languageManager.text("onboardingV2.readingTime.title"))
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .ov2Reveal(delay: 0.05)

                Spacer().frame(height: 10)

                Text(languageManager.text("onboardingV2.readingTime.subtitle"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(OV2.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
                    .ov2Reveal(delay: 0.15)

                Spacer().frame(height: 28)

                SkyView(hour: hour)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                    .padding(.horizontal, 24)
                    .ov2Reveal(delay: 0.25, yOffset: 20)

                Spacer().frame(height: 26)

                Text(Self.label(hour: Int(hour)))
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(OV2.ink)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: hour))
                    .animation(.spring(response: 0.35, dampingFraction: 0.82), value: hour)

                Text(Self.moment(hour: Int(hour), languageManager: languageManager))
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(OV2.inkSecondary)
                    .padding(.top, 2)

                Spacer().frame(height: 18)

                VStack(spacing: 8) {
                    Slider(value: $hour, in: range, step: 1)
                        .tint(OV2.accent)
                        .onChange(of: hour) { _, newValue in
                            let s = Int(newValue)
                            if s != lastStep {
                                lastStep = s
                                OnboardingHaptics.selection()
                            }
                        }
                    HStack {
                        Text(Self.label(hour: Int(range.lowerBound)))
                        Spacer()
                        Text(Self.label(hour: Int(range.upperBound)))
                    }
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(OV2.inkTertiary)
                }
                .padding(.horizontal, 36)
                .ov2Reveal(delay: 0.35)

                Spacer().frame(height: 24)
            }
        } footer: {
            OnboardingV2Button(title: languageManager.text("common.continue")) {
                vm.reminderHour = Int(hour)
                onNext()
            }
        }
        .ov2Background()
        .onAppear {
            hour = Double(vm.reminderHour)
            lastStep = vm.reminderHour
        }
    }

    static func label(hour: Int) -> String {
        String(format: "%02d:00", hour)
    }

    private static func moment(hour: Int, languageManager: LanguageManager) -> String {
        switch hour {
        case ..<9: languageManager.text("onboardingV2.readingTime.morning")
        case ..<13: languageManager.text("onboardingV2.readingTime.lateMorning")
        case ..<18: languageManager.text("onboardingV2.readingTime.afternoon")
        case ..<21: languageManager.text("onboardingV2.readingTime.evening")
        default: languageManager.text("onboardingV2.readingTime.night")
        }
    }
}

// MARK: - Sky

/// Sky, sun and moon for an hour of the day. The hour is continuous so the slider
/// animates through dawn and dusk rather than jumping between states.
private struct SkyView: View {
    let hour: Double

    /// 0 at 5 h, 1 at 23 h: where the sun is along its arc.
    private var progress: Double { (hour - 5) / 18 }

    /// How much daylight there is: 0 at night, 1 in full day, ramping over dawn and dusk.
    private var daylight: Double {
        let sunrise = smooth((hour - 5.5) / 2.0)   // 5:30 → 7:30
        let sunset = 1 - smooth((hour - 19.0) / 2.5) // 19:00 → 21:30
        return min(sunrise, sunset)
    }

    /// Warm glow around dawn and dusk.
    private var glow: Double {
        let dawn = bump(center: 6.5, width: 1.8)
        let dusk = bump(center: 20.0, width: 2.2)
        return max(dawn, dusk)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let sunX = w * (0.08 + 0.84 * progress)
            // Arc: low at both ends, highest in the middle of the day.
            let arc = sin(progress * .pi)
            let sunY = h * (0.78 - 0.55 * arc)
            let moonProgress = (hour >= 20 ? (hour - 20) / 4 : 0)
            let moonX = w * (0.15 + 0.7 * moonProgress)
            let moonY = h * (0.5 - 0.2 * sin(moonProgress * .pi))

            ZStack {
                // Sky
                LinearGradient(
                    colors: [skyTop, skyBottom],
                    startPoint: .top, endPoint: .bottom
                )

                // Dawn / dusk glow
                RadialGradient(
                    colors: [Color(red: 1.0, green: 0.62, blue: 0.32).opacity(0.55 * glow), .clear],
                    center: UnitPoint(x: sunX / w, y: 0.95),
                    startRadius: 0, endRadius: w * 0.6
                )

                // Stars at night
                stars(in: geo.size)
                    .opacity(1 - daylight)

                // Moon
                ZStack {
                    Circle().fill(Color(red: 0.96, green: 0.96, blue: 0.90))
                    Circle()
                        .fill(skyTop)
                        .offset(x: 9, y: -5)
                }
                .frame(width: 30, height: 30)
                .shadow(color: .white.opacity(0.5), radius: 12)
                .position(x: moonX, y: moonY)
                .opacity(1 - daylight)

                // Sun
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 1.0, green: 0.93, blue: 0.62), Color(red: 1.0, green: 0.72, blue: 0.25)],
                            center: .center, startRadius: 2, endRadius: 26
                        )
                    )
                    .frame(width: 46, height: 46)
                    .shadow(color: Color(red: 1.0, green: 0.78, blue: 0.3).opacity(0.7), radius: 22)
                    .position(x: sunX, y: sunY)
                    .opacity(0.15 + 0.85 * daylight)

                // Horizon
                VStack {
                    Spacer()
                    horizon
                        .frame(height: h * 0.22)
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: hour)
    }

    private var skyTop: Color {
        blend(
            night: Color(red: 0.06, green: 0.09, blue: 0.22),
            day: Color(red: 0.36, green: 0.65, blue: 0.95)
        )
    }

    private var skyBottom: Color {
        let base = blend(
            night: Color(red: 0.12, green: 0.16, blue: 0.32),
            day: Color(red: 0.78, green: 0.90, blue: 1.0)
        )
        return base
    }

    private var horizon: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 120, style: .continuous)
                .fill(
                    blend(
                        night: Color(red: 0.10, green: 0.16, blue: 0.22),
                        day: Color(red: 0.42, green: 0.70, blue: 0.48)
                    )
                )
                .scaleEffect(x: 1.6, y: 1, anchor: .top)
                .offset(y: 12)
        }
    }

    private func stars(in size: CGSize) -> some View {
        // Fixed pseudo-random positions: the same sky every time the page appears.
        let points: [(CGFloat, CGFloat, CGFloat)] = [
            (0.12, 0.18, 2.2), (0.27, 0.10, 1.6), (0.41, 0.24, 1.8), (0.58, 0.08, 2.4),
            (0.70, 0.20, 1.5), (0.84, 0.14, 2.0), (0.92, 0.32, 1.4), (0.20, 0.38, 1.3),
            (0.50, 0.40, 1.6), (0.78, 0.42, 1.2), (0.35, 0.52, 1.1), (0.64, 0.55, 1.4),
        ]
        return ZStack {
            ForEach(points.indices, id: \.self) { i in
                let p = points[i]
                Circle()
                    .fill(.white.opacity(0.85))
                    .frame(width: p.2, height: p.2)
                    .position(x: size.width * p.0, y: size.height * p.1)
            }
        }
    }

    private func blend(night: Color, day: Color) -> Color {
        let d = daylight
        let n = UIColor(night), y = UIColor(day)
        var nr: CGFloat = 0, ng: CGFloat = 0, nb: CGFloat = 0, na: CGFloat = 0
        var yr: CGFloat = 0, yg: CGFloat = 0, yb: CGFloat = 0, ya: CGFloat = 0
        n.getRed(&nr, green: &ng, blue: &nb, alpha: &na)
        y.getRed(&yr, green: &yg, blue: &yb, alpha: &ya)
        return Color(
            red: Double(nr + (yr - nr) * d),
            green: Double(ng + (yg - ng) * d),
            blue: Double(nb + (yb - nb) * d)
        )
    }

    private func smooth(_ x: Double) -> Double {
        let t = min(1, max(0, x))
        return t * t * (3 - 2 * t)
    }

    private func bump(center: Double, width: Double) -> Double {
        let d = abs(hour - center) / width
        return max(0, 1 - d * d)
    }
}
