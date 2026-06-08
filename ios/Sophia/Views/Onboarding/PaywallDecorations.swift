import SwiftUI

// MARK: - Figma tokens

enum PaywallDesign {
    static let background = Color(red: 254 / 255, green: 245 / 255, blue: 233 / 255)
    static let orange = Color(red: 1, green: 0.698, blue: 0.18)
    static let accentPink = Color(red: 1, green: 0.522, blue: 0.71)
    static let creamHighlight = Color(red: 1, green: 0.925, blue: 0.796)
    static let lockedPill = Color(red: 1, green: 0.835, blue: 0.553)
    static let bubbleBlue = Color(red: 0.584, green: 0.847, blue: 0.949)
    static let bubblePurple = Color(red: 0.878, green: 0.686, blue: 0.984)
    static let bubbleOrange = Color(red: 1, green: 0.671, blue: 0.435)
    static let greyStarFill = Color(red: 0.757, green: 0.784, blue: 0.812)
    static let freeCheckFill = Color(red: 0.847, green: 0.827, blue: 0.792)
    static let deniedFill = Color(red: 0.8, green: 0.8, blue: 0.8)

    static func freePillColor(for subject: Subject) -> Color {
        switch subject {
        case .art: Color(red: 0.584, green: 0.925, blue: 0.973)
        case .litterature: Color(red: 1, green: 0.769, blue: 0.78)
        case .comprendreLeMonde: Color(red: 0.698, green: 0.91, blue: 1)
        case .histoire: Color(red: 1, green: 0.835, blue: 0.553)
        case .sciences: Color(red: 0.698, green: 0.949, blue: 0.78)
        case .mythologie: Color(red: 0.82, green: 0.78, blue: 1)
        }
    }
}

// MARK: - Card chrome

struct PaywallBrutalCard: ViewModifier {
    var fill: Color = .white
    var border: Color = BrutalPalette.ink
    var borderWidth: CGFloat = 3
    var corner: CGFloat = 17
    var shadow: Color = BrutalPalette.ink
    var shadowOffset: CGSize = CGSize(width: 3, height: 3)

    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(border, lineWidth: borderWidth)
            }
            .background(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(shadow)
                    .offset(x: shadowOffset.width, y: shadowOffset.height)
            }
            .padding(.bottom, shadowOffset.height)
            .padding(.trailing, shadowOffset.width)
    }
}

extension View {
    func paywallBrutalCard(
        fill: Color = .white,
        border: Color = BrutalPalette.ink,
        borderWidth: CGFloat = 3,
        corner: CGFloat = 17,
        shadow: Color = BrutalPalette.ink
    ) -> some View {
        modifier(PaywallBrutalCard(fill: fill, border: border, borderWidth: borderWidth, corner: corner, shadow: shadow))
    }
}

// MARK: - Shapes

struct PaywallStarShape: Shape {
    var points: Int = 5
    var innerRatio: CGFloat = 0.45

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        var path = Path()

        for index in 0..<(points * 2) {
            let angle = (Double(index) * .pi / Double(points)) - .pi / 2
            let radius = index.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct PaywallBlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0.62 * w, y: 0.04 * h))
        path.addCurve(
            to: CGPoint(x: 0.96 * w, y: 0.42 * h),
            control1: CGPoint(x: 0.9 * w, y: 0.02 * h),
            control2: CGPoint(x: 0.98 * w, y: 0.22 * h)
        )
        path.addCurve(
            to: CGPoint(x: 0.72 * w, y: 0.94 * h),
            control1: CGPoint(x: 0.94 * w, y: 0.68 * h),
            control2: CGPoint(x: 0.9 * w, y: 0.92 * h)
        )
        path.addCurve(
            to: CGPoint(x: 0.18 * w, y: 0.82 * h),
            control1: CGPoint(x: 0.5 * w, y: 0.98 * h),
            control2: CGPoint(x: 0.3 * w, y: 0.96 * h)
        )
        path.addCurve(
            to: CGPoint(x: 0.04 * w, y: 0.34 * h),
            control1: CGPoint(x: 0.02 * w, y: 0.64 * h),
            control2: CGPoint(x: 0.02 * w, y: 0.46 * h)
        )
        path.addCurve(
            to: CGPoint(x: 0.62 * w, y: 0.04 * h),
            control1: CGPoint(x: 0.12 * w, y: 0.08 * h),
            control2: CGPoint(x: 0.34 * w, y: -0.02 * h)
        )
        return path
    }
}

// MARK: - Decorative views

struct PaywallStickerStar: View {
    var fill: Color = PaywallDesign.orange
    var size: CGFloat = 28
    var rotation: Double = 0

    var body: some View {
        PaywallStarShape()
            .fill(fill)
            .overlay {
                PaywallStarShape()
                    .stroke(BrutalPalette.ink, lineWidth: 3)
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .shadow(color: BrutalPalette.ink, radius: 0, x: 3, y: 1)
    }
}

struct PaywallStarCluster: View {
    var body: some View {
        ZStack {
            PaywallStickerStar(size: 22, rotation: -9)
                .offset(x: -18, y: 4)
            PaywallStickerStar(size: 26, rotation: 3)
            PaywallStickerStar(size: 20, rotation: 8)
                .offset(x: 20, y: -2)
        }
        .frame(width: 72, height: 36)
    }
}

struct PaywallGreyStarBadge: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(PaywallDesign.greyStarFill)
                .frame(width: 42, height: 42)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(BrutalPalette.ink, lineWidth: 3)
                }
                .shadow(color: BrutalPalette.ink, radius: 0, x: 3, y: 1)
            Image(systemName: "star.fill")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(BrutalPalette.ink.opacity(0.35))
        }
    }
}

struct PaywallLightbulbView: View {
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle()
                .fill(PaywallDesign.orange)
                .frame(width: size * 0.72, height: size * 0.72)
                .offset(y: size * 0.08)
            PaywallLightbulbBulb()
                .fill(PaywallDesign.orange)
                .overlay {
                    PaywallLightbulbBulb()
                        .stroke(BrutalPalette.ink, lineWidth: 3)
                }
                .frame(width: size * 0.55, height: size * 0.62)
                .offset(y: -size * 0.04)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(BrutalPalette.ink)
                .frame(width: size * 0.22, height: size * 0.08)
                .offset(y: size * 0.34)
        }
        .frame(width: size, height: size)
        .shadow(color: BrutalPalette.ink, radius: 0, x: 3, y: 1)
    }
}

private struct PaywallLightbulbBulb: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: rect.width * 0.08, y: 0, width: rect.width * 0.84, height: rect.height * 0.78))
        path.addRect(CGRect(x: rect.width * 0.28, y: rect.height * 0.72, width: rect.width * 0.44, height: rect.height * 0.28))
        return path
    }
}

struct PaywallSpeechPill: View {
    let title: String
    let fill: Color

    var body: some View {
        Text(title)
            .font(.system(size: 15.5, weight: .heavy, design: .rounded))
            .foregroundStyle(BrutalPalette.ink)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(fill, in: Capsule())
            .overlay {
                Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 3.2)
            }
            .shadow(color: BrutalPalette.ink, radius: 0, x: 3.2, y: 1.1)
    }
}

struct PaywallDiscountBadge: View {
    let text: String

    var body: some View {
        ZStack {
            PaywallStarShape(points: 8, innerRatio: 0.58)
                .fill(PaywallDesign.accentPink)
                .overlay {
                    PaywallStarShape(points: 8, innerRatio: 0.58)
                        .stroke(BrutalPalette.ink, lineWidth: 2.5)
                }
            Text(text)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(BrutalPalette.ink)
                .rotationEffect(.degrees(7))
        }
        .frame(width: 62, height: 62)
        .shadow(color: BrutalPalette.ink.opacity(0.15), radius: 0, x: 2, y: 2)
    }
}

struct PaywallFeatureMark: View {
    enum Kind {
        case premiumCheck
        case freeCheck
        case denied
    }

    let kind: Kind

    var body: some View {
        Group {
            switch kind {
            case .premiumCheck:
                checkCircle(fill: PaywallDesign.orange)
            case .freeCheck:
                checkCircle(fill: PaywallDesign.freeCheckFill)
            case .denied:
                deniedMark
            }
        }
        .frame(width: 22, height: 22)
        .shadow(color: BrutalPalette.ink, radius: 0, x: 3, y: 1)
    }

    private func checkCircle(fill: Color) -> some View {
        ZStack {
            Circle()
                .fill(fill)
                .overlay { Circle().strokeBorder(BrutalPalette.ink, lineWidth: 2) }
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
        }
    }

    private var deniedMark: some View {
        ZStack {
            Circle()
                .fill(PaywallDesign.deniedFill.opacity(0.5))
                .overlay { Circle().strokeBorder(BrutalPalette.ink, lineWidth: 2) }
            Image(systemName: "xmark")
                .font(.system(size: 8, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
        }
    }
}

struct PaywallPlanRadio: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? PaywallDesign.orange : Color.white)
                .overlay { Circle().strokeBorder(BrutalPalette.ink, lineWidth: 2.75) }
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
            }
        }
        .frame(width: 36, height: 36)
    }
}
