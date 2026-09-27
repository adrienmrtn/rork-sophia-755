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

/// Everything the sky needs for one hour of the day, computed with explicit types before
/// any view is built. The first version did this arithmetic inside `body`, mixing
/// `CGFloat` and `Double` literals; the Swift type-checker took hundreds of gigabytes
/// trying to resolve it. Nothing here is inferred.
private struct SkyModel {
    let hour: Double

    /// 0 at 5 h, 1 at 23 h: where the sun is along its arc.
    var progress: Double { (hour - 5.0) / 18.0 }

    /// 0 at night, 1 in full day, ramping over dawn (5:30 → 7:30) and dusk (19:00 → 21:30).
    var daylight: Double {
        let sunrise: Double = SkyModel.smooth((hour - 5.5) / 2.0)
        let sunset: Double = 1.0 - SkyModel.smooth((hour - 19.0) / 2.5)
        return min(sunrise, sunset)
    }

    /// Warm glow around dawn and dusk.
    var glow: Double {
        max(bump(center: 6.5, width: 1.8), bump(center: 20.0, width: 2.2))
    }

    /// 0 at 20 h, 1 at 24 h: where the moon is.
    var moonProgress: Double {
        hour >= 20.0 ? (hour - 20.0) / 4.0 : 0.0
    }

    func sunPoint(in size: CGSize) -> CGPoint {
        let x: Double = Double(size.width) * (0.08 + 0.84 * progress)
        let arc: Double = sin(progress * Double.pi)
        let y: Double = Double(size.height) * (0.78 - 0.55 * arc)
        return CGPoint(x: x, y: y)
    }

    func moonPoint(in size: CGSize) -> CGPoint {
        let x: Double = Double(size.width) * (0.15 + 0.7 * moonProgress)
        let y: Double = Double(size.height) * (0.5 - 0.2 * sin(moonProgress * Double.pi))
        return CGPoint(x: x, y: y)
    }

    var skyTop: Color {
        blend(night: SkyModel.nightTop, day: SkyModel.dayTop)
    }

    var skyBottom: Color {
        blend(night: SkyModel.nightBottom, day: SkyModel.dayBottom)
    }

    var ground: Color {
        blend(night: SkyModel.nightGround, day: SkyModel.dayGround)
    }

    private static let nightTop = (r: 0.06, g: 0.09, b: 0.22)
    private static let dayTop = (r: 0.36, g: 0.65, b: 0.95)
    private static let nightBottom = (r: 0.12, g: 0.16, b: 0.32)
    private static let dayBottom = (r: 0.78, g: 0.90, b: 1.0)
    private static let nightGround = (r: 0.10, g: 0.16, b: 0.22)
    private static let dayGround = (r: 0.42, g: 0.70, b: 0.48)

    private func blend(night: (r: Double, g: Double, b: Double), day: (r: Double, g: Double, b: Double)) -> Color {
        let d: Double = daylight
        let r: Double = night.r + (day.r - night.r) * d
        let g: Double = night.g + (day.g - night.g) * d
        let b: Double = night.b + (day.b - night.b) * d
        return Color(red: r, green: g, blue: b)
    }

    private static func smooth(_ x: Double) -> Double {
        let t: Double = min(1.0, max(0.0, x))
        return t * t * (3.0 - 2.0 * t)
    }

    private func bump(center: Double, width: Double) -> Double {
        let d: Double = abs(hour - center) / width
        return max(0.0, 1.0 - d * d)
    }
}

/// Sky, sun and moon for an hour of the day. The hour is continuous so the slider
/// animates through dawn and dusk rather than jumping between states.
private struct SkyView: View {
    let hour: Double

    private var model: SkyModel { SkyModel(hour: hour) }

    /// Fixed pseudo-random star positions: the same sky every time the page appears.
    private static let stars: [(x: Double, y: Double, size: Double)] = [
        (0.12, 0.18, 2.2), (0.27, 0.10, 1.6), (0.41, 0.24, 1.8), (0.58, 0.08, 2.4),
        (0.70, 0.20, 1.5), (0.84, 0.14, 2.0), (0.92, 0.32, 1.4), (0.20, 0.38, 1.3),
        (0.50, 0.40, 1.6), (0.78, 0.42, 1.2), (0.35, 0.52, 1.1), (0.64, 0.55, 1.4),
    ]

    var body: some View {
        GeometryReader { geo in
            let size: CGSize = geo.size
            let m: SkyModel = model
            let sun: CGPoint = m.sunPoint(in: size)
            let moon: CGPoint = m.moonPoint(in: size)
            let night: Double = 1.0 - m.daylight

            ZStack {
                sky(m)
                glowLayer(m, sun: sun, size: size)
                starsLayer(size: size).opacity(night)
                moonLayer(m).position(moon).opacity(night)
                sunLayer.position(sun).opacity(0.15 + 0.85 * m.daylight)
                groundLayer(m, size: size)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: hour)
    }

    private func sky(_ m: SkyModel) -> some View {
        LinearGradient(colors: [m.skyTop, m.skyBottom], startPoint: .top, endPoint: .bottom)
    }

    private func glowLayer(_ m: SkyModel, sun: CGPoint, size: CGSize) -> some View {
        let centerX: Double = size.width > 0 ? Double(sun.x / size.width) : 0.5
        let glowColor: Color = Color(red: 1.0, green: 0.62, blue: 0.32).opacity(0.55 * m.glow)
        return RadialGradient(
            colors: [glowColor, Color.clear],
            center: UnitPoint(x: centerX, y: 0.95),
            startRadius: 0,
            endRadius: size.width * 0.6
        )
    }

    private func starsLayer(size: CGSize) -> some View {
        ZStack {
            ForEach(Self.stars.indices, id: \.self) { i in
                let star = Self.stars[i]
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: CGFloat(star.size), height: CGFloat(star.size))
                    .position(x: size.width * CGFloat(star.x), y: size.height * CGFloat(star.y))
            }
        }
    }

    private func moonLayer(_ m: SkyModel) -> some View {
        ZStack {
            Circle().fill(Color(red: 0.96, green: 0.96, blue: 0.90))
            Circle().fill(m.skyTop).offset(x: 9, y: -5)
        }
        .frame(width: 30, height: 30)
        .shadow(color: Color.white.opacity(0.5), radius: 12)
    }

    private var sunLayer: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color(red: 1.0, green: 0.93, blue: 0.62), Color(red: 1.0, green: 0.72, blue: 0.25)],
                    center: .center, startRadius: 2, endRadius: 26
                )
            )
            .frame(width: 46, height: 46)
            .shadow(color: Color(red: 1.0, green: 0.78, blue: 0.3).opacity(0.7), radius: 22)
    }

    private func groundLayer(_ m: SkyModel, size: CGSize) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 120, style: .continuous)
                .fill(m.ground)
                .scaleEffect(x: 1.6, y: 1, anchor: .top)
                .offset(y: 12)
                .frame(height: size.height * 0.22)
        }
    }
}
