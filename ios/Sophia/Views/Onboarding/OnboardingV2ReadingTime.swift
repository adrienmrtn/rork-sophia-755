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
                OV2EndTitle(text: languageManager.text("onboardingV2.readingTime.title"))
                    .padding(.top, OV2End.top)
                    .dsStagger(0)

                SkyView(hour: hour)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))
                    .padding(.top, 24)
                    .dsStagger(1)
                    .accessibilityHidden(true)

                timeReadout
                    .padding(.top, 20)
                    .dsStagger(2)

                sliderBlock
                    .padding(.top, 14)
                    .padding(.horizontal, 8)
                    .dsStagger(3)
            }
            .padding(.horizontal, OV2End.side)
            .padding(.bottom, 16)
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

    /// L'heure en très gros, et le moment de la journée dessous.
    private var timeReadout: some View {
        VStack(spacing: 6) {
            Text(Self.label(hour: Int(hour)))
                .font(.jakarta(size: 54, weight: .heavy))
                .tracking(-1)
                .foregroundStyle(DS.ink)
                .monospacedDigit()
                .contentTransition(.numericText(value: hour))
                .animation(DSCalmMotion.state, value: hour)

            Text(Self.moment(hour: Int(hour), languageManager: languageManager))
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .animation(DSCalmMotion.state, value: Int(hour))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var sliderBlock: some View {
        VStack(spacing: 6) {
            Slider(value: $hour, in: range, step: 1)
                .tint(DS.accent)
                .accessibilityLabel(Text(languageManager.text("onboardingV2.readingTime.title")))
                .accessibilityValue(Text(Self.label(hour: Int(hour))))
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
            .font(DS.sans(.footnote, .semibold))
            .foregroundStyle(DS.inkSecondary)
            .monospacedDigit()
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

    /// Opacité de la bande orangée du bas : nulle en plein jour et en pleine nuit, elle ne
    /// monte qu'au cœur de l'aube et du crépuscule.
    var glowOpacity: Double {
        let lifted: Double = max(0.0, glow - 0.4) * 1.5
        return min(1.0, lifted)
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

    /// Ciel en aplat : bleu nuit → bleu ciel.
    var sky: Color {
        blend(night: SkyModel.nightSky, day: SkyModel.daySky)
    }

    /// Colline de gauche, la plus claire.
    var hillLeft: Color {
        blend(night: SkyModel.nightHillLeft, day: SkyModel.dayHillLeft)
    }

    /// Colline de droite, plus sombre, dessinée par-dessus.
    var hillRight: Color {
        blend(night: SkyModel.nightHillRight, day: SkyModel.dayHillRight)
    }

    private static let nightSky = (r: 0.078, g: 0.141, b: 0.431)
    private static let daySky = (r: 0.612, g: 0.796, b: 0.918)
    private static let nightHillLeft = (r: 0.055, g: 0.106, b: 0.302)
    private static let dayHillLeft = (r: 0.302, g: 0.620, b: 0.420)
    private static let nightHillRight = (r: 0.031, g: 0.063, b: 0.200)
    private static let dayHillRight = (r: 0.184, g: 0.478, b: 0.329)

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

/// Sky, sun and moon for an hour of the day, drawn in flat shapes like the rest of the
/// illustrations. The hour is continuous so the slider animates through dawn and dusk
/// rather than jumping between states.
private struct SkyView: View {
    let hour: Double

    private var model: SkyModel { SkyModel(hour: hour) }

    /// Crème des étoiles, des nuages, de la lune et du liseré du soleil.
    private static let cream = Color(red: 0.984, green: 0.953, blue: 0.878)
    private static let sunFill = Color(red: 0.957, green: 0.725, blue: 0.180)
    private static let glowFill = Color(red: 0.957, green: 0.639, blue: 0.251)

    /// Fixed star positions: the same sky every time the page appears.
    private static let stars: [(x: Double, y: Double, size: Double)] = [
        (0.12, 0.18, 4.0), (0.27, 0.10, 3.0), (0.41, 0.24, 4.0), (0.58, 0.08, 5.0),
        (0.70, 0.20, 3.0), (0.84, 0.14, 4.0), (0.92, 0.32, 3.0), (0.20, 0.38, 3.0),
        (0.50, 0.40, 3.0), (0.78, 0.42, 3.0),
    ]

    var body: some View {
        GeometryReader { geo in
            let size: CGSize = geo.size
            let m: SkyModel = model
            let sun: CGPoint = m.sunPoint(in: size)
            let moon: CGPoint = m.moonPoint(in: size)
            let day: Double = m.daylight
            let night: Double = 1.0 - day

            ZStack {
                m.sky
                glowLayer(m, size: size)
                starsLayer(size: size).opacity(night)
                cloudsLayer(size: size).opacity(day)
                moonLayer(m).position(moon).opacity(night)
                sunLayer.position(sun).opacity(0.15 + 0.85 * day)
                hillsLayer(m, size: size)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: hour)
    }

    /// Bande orangée sur l'horizon, à l'aube et au crépuscule.
    private func glowLayer(_ m: SkyModel, size: CGSize) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            Rectangle()
                .fill(Self.glowFill)
                .frame(height: size.height * 0.46)
        }
        .opacity(m.glowOpacity)
    }

    private func starsLayer(size: CGSize) -> some View {
        ZStack {
            ForEach(Self.stars.indices, id: \.self) { i in
                let star = Self.stars[i]
                Circle()
                    .fill(Self.cream)
                    .frame(width: CGFloat(star.size), height: CGFloat(star.size))
                    .position(x: size.width * CGFloat(star.x), y: size.height * CGFloat(star.y))
            }
        }
    }

    private func cloudsLayer(size: CGSize) -> some View {
        let firstX: CGFloat = size.width * 0.14 + 35
        let firstY: CGFloat = size.height * 0.22 + 11
        let secondX: CGFloat = size.width * 0.62 + 27
        let secondY: CGFloat = size.height * 0.36 + 9
        return ZStack {
            Capsule()
                .fill(Self.cream)
                .frame(width: 70, height: 22)
                .position(x: firstX, y: firstY)
            Capsule()
                .fill(Self.cream)
                .frame(width: 54, height: 18)
                .position(x: secondX, y: secondY)
        }
    }

    /// Croissant : un disque crème entamé par un disque de la couleur du ciel.
    private func moonLayer(_ m: SkyModel) -> some View {
        ZStack {
            Circle().fill(Self.cream)
            Circle()
                .fill(m.sky)
                .frame(width: 30, height: 30)
                .offset(x: 9, y: -7)
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
    }

    private var sunLayer: some View {
        Circle()
            .fill(Self.sunFill)
            .overlay(Circle().strokeBorder(Self.cream, lineWidth: 5))
            .frame(width: 52, height: 52)
    }

    /// Deux collines en ellipses qui dépassent par le bas.
    private func hillsLayer(_ m: SkyModel, size: CGSize) -> some View {
        let leftWidth: CGFloat = size.width * 0.9
        let leftX: CGFloat = size.width * 0.25
        let leftY: CGFloat = size.height + 5
        let rightWidth: CGFloat = size.width * 0.95
        let rightX: CGFloat = size.width * 0.775
        let rightY: CGFloat = size.height + 18
        return ZStack {
            Ellipse()
                .fill(m.hillLeft)
                .frame(width: leftWidth, height: 130)
                .position(x: leftX, y: leftY)
            Ellipse()
                .fill(m.hillRight)
                .frame(width: rightWidth, height: 132)
                .position(x: rightX, y: rightY)
        }
    }
}
