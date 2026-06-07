import SwiftUI

struct GlobalRankProfileCard: View {
    let progress: GlobalLevelProgress

    @State private var appeared = false
    @State private var shimmerOffset: CGFloat = -160

    private let ink = BrutalPalette.ink

    private var nextRankText: String {
        guard let next = progress.rank.next, let remaining = progress.xpToNextRank else {
            return "Niveau max"
        }
        return "\(remaining) XP avant \(next.rawValue)"
    }

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(ink)
                .offset(y: 7)

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 16) {
                    GlobalRankAnimatedIcon(rank: progress.rank, size: 82, intensity: .profile)
                        .scaleEffect(appeared ? 1 : 0.65)
                        .opacity(appeared ? 1 : 0)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text("NIV. \(progress.level)")
                                .font(.system(.caption, design: .rounded, weight: .black))
                                .foregroundStyle(.white)
                                .tracking(0.8)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(ink, in: Capsule())

                            Text("\(progress.xp) XP")
                                .font(.system(.caption, design: .rounded, weight: .heavy))
                                .foregroundStyle(ink.opacity(0.55))
                                .monospacedDigit()
                        }

                        Text(progress.rank.rawValue)
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text("Rang global")
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink.opacity(0.58))
                    }

                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 9) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white)
                                .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            progress.rank.primaryColor,
                                            progress.rank.secondaryColor,
                                            progress.rank.primaryColor
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .overlay {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [.clear, .white.opacity(0.7), .clear],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .mask {
                                            Rectangle()
                                                .frame(width: 80, height: 22)
                                                .offset(x: shimmerOffset)
                                        }
                                }
                                .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                                .frame(width: max(22, geo.size.width * CGFloat(progress.progressToNextRank)))
                        }
                    }
                    .frame(height: 22)

                    Text(nextRankText)
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink.opacity(0.62))
                        .monospacedDigit()
                }
            }
            .padding(20)
            .background(
                ZStack {
                    progress.rank.primaryColor
                    RadialGradient(
                        colors: [Color.white.opacity(0.65), .clear],
                        center: .topTrailing,
                        startRadius: 10,
                        endRadius: 220
                    )
                    diagonalPattern.opacity(0.12)
                }
            )
            .clipShape(.rect(cornerRadius: 26))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(ink, lineWidth: 3)
            }
        }
        .padding(.bottom, 7)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
                appeared = true
            }
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                shimmerOffset = 260
            }
        }
    }

    private var diagonalPattern: some View {
        GeometryReader { geo in
            Path { path in
                let spacing: CGFloat = 22
                var x: CGFloat = -geo.size.height
                while x < geo.size.width + geo.size.height {
                    path.move(to: CGPoint(x: x, y: geo.size.height))
                    path.addLine(to: CGPoint(x: x + geo.size.height, y: 0))
                    x += spacing
                }
            }
            .stroke(ink, lineWidth: 1.4)
        }
    }
}

struct GlobalRankUpCelebrationView: View {
    let previousRank: GlobalRank
    let newRank: GlobalRank
    let newLevel: Int
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var cardScale: CGFloat = 0.72
    @State private var iconScale: CGFloat = 0.35
    @State private var glowPulse = false
    @State private var confettiTrigger = 0
    @State private var orbit = false

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream
    private let yellow = Color(red: 1.0, green: 0.84, blue: 0.35)

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            ConfettiView(trigger: confettiTrigger)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                Text("Nouveau rang !")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)

                Text("Tu viens d’atteindre le niveau \(newLevel)")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.58))
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)

                Spacer(minLength: 26)

                rankCard
                    .scaleEffect(cardScale)
                    .opacity(appeared ? 1 : 0)

                Spacer(minLength: 28)

                HStack(spacing: 10) {
                    rankChip(previousRank, faded: true)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(ink)
                    rankChip(newRank, faded: false)
                }
                .opacity(appeared ? 1 : 0)

                Spacer(minLength: 28)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onContinue()
                } label: {
                    Text("Continuer")
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundStyle(ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(DuolingoButtonStyle(fill: yellow, shimmer: nil))
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)
            }
        }
        .onAppear { runSequence() }
    }

    private var rankCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(ink)
                .frame(width: 270, height: 310)
                .offset(y: 10)

            ZStack {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [newRank.primaryColor, newRank.secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                ForEach(0..<12, id: \.self) { index in
                    Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "star.fill")
                        .font(.system(size: index.isMultiple(of: 3) ? 14 : 9, weight: .black))
                        .foregroundStyle(ink.opacity(0.18))
                        .offset(
                            x: cos(Double(index) / 12 * .pi * 2 + (orbit ? .pi : 0)) * 105,
                            y: sin(Double(index) / 12 * .pi * 2 + (orbit ? .pi : 0)) * 122
                        )
                }

                Circle()
                    .fill(newRank.secondaryColor.opacity(glowPulse ? 0.7 : 0.35))
                    .frame(width: 176, height: 176)
                    .blur(radius: glowPulse ? 28 : 16)

                VStack(spacing: 18) {
                    GlobalRankAnimatedIcon(rank: newRank, size: 134, intensity: .celebration)
                        .scaleEffect(iconScale)

                    Text(newRank.rawValue)
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(ink)

                    Text("RANG GLOBAL")
                        .font(.system(.caption, design: .rounded, weight: .black))
                        .foregroundStyle(.white)
                        .tracking(1.2)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(ink, in: Capsule())
                }
            }
            .frame(width: 270, height: 310)
            .clipShape(.rect(cornerRadius: 36))
            .overlay {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .strokeBorder(ink, lineWidth: 4)
            }
        }
    }

    private func rankChip(_ rank: GlobalRank, faded: Bool) -> some View {
        HStack(spacing: 7) {
            Image(systemName: rank.symbolName)
                .font(.system(size: 13, weight: .black))
            Text(rank.rawValue)
                .font(.system(.caption, design: .rounded, weight: .black))
        }
        .foregroundStyle(ink.opacity(faded ? 0.45 : 1))
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(faded ? Color.white : rank.primaryColor, in: Capsule())
        .overlay { Capsule().strokeBorder(ink.opacity(faded ? 0.45 : 1), lineWidth: 2) }
    }

    private func runSequence() {
        withAnimation(.spring(response: 0.75, dampingFraction: 0.76)) {
            appeared = true
            cardScale = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            confettiTrigger += 1
            withAnimation(.spring(response: 0.58, dampingFraction: 0.55)) {
                iconScale = 1
            }
        }
        withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true).delay(0.45)) {
            glowPulse = true
        }
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false).delay(0.4)) {
            orbit = true
        }
    }
}

struct GlobalRankAnimatedIcon: View {
    enum Intensity {
        case profile
        case celebration
    }

    let rank: GlobalRank
    var size: CGFloat
    var intensity: Intensity = .profile

    @State private var pulse = false
    @State private var rotate = false
    @State private var float = false
    @State private var sparkle = false

    private let ink = BrutalPalette.ink

    var body: some View {
        ZStack {
            Circle()
                .fill(ink)
                .frame(width: size, height: size)
                .offset(y: size * 0.055)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [rank.primaryColor, rank.secondaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay { Circle().strokeBorder(ink, lineWidth: max(2.5, size * 0.04)) }
                .shadow(color: rank.secondaryColor.opacity(pulse ? 0.85 : 0.35), radius: pulse ? size * 0.23 : size * 0.12, y: pulse ? 8 : 4)

            rankSpecificEffect

            Image(systemName: rank.symbolName)
                .font(.system(size: size * 0.43, weight: .black))
                .foregroundStyle(ink)
                .symbolEffect(.bounce, value: sparkle)
                .symbolEffect(.variableColor.iterative.reversing, value: pulse)
                .rotationEffect(.degrees(symbolRotation))
                .offset(y: float ? -size * 0.035 : size * 0.025)
                .scaleEffect(pulse ? 1.06 : 0.96)
        }
        .frame(width: size, height: size + size * 0.08)
        .onAppear { startAnimations() }
    }

    @ViewBuilder
    private var rankSpecificEffect: some View {
        switch rank {
        case .curieux:
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: size * (index == 0 ? 0.16 : 0.10), weight: .black))
                    .foregroundStyle(ink.opacity(0.45))
                    .offset(
                        x: cos(Double(index) / 5 * .pi * 2) * size * 0.34,
                        y: sin(Double(index) / 5 * .pi * 2) * size * 0.34
                    )
                    .scaleEffect(sparkle ? 1.25 : 0.6)
                    .opacity(sparkle ? 1 : 0.25)
            }
        case .erudit:
            RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
                .stroke(ink.opacity(0.22), lineWidth: 2)
                .frame(width: size * 0.54, height: size * 0.36)
                .rotation3DEffect(.degrees(float ? 8 : -8), axis: (x: 0, y: 1, z: 0))
        case .savant:
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(ink.opacity(0.18), lineWidth: 2)
                    .frame(width: size * (0.55 + CGFloat(index) * 0.16))
                    .scaleEffect(pulse ? 1.05 : 0.88)
            }
        case .maitre:
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.25, weight: .black))
                .foregroundStyle(ink.opacity(0.25))
                .offset(x: size * 0.28, y: -size * 0.26)
                .scaleEffect(sparkle ? 1.2 : 0.75)
        case .legende:
            Circle()
                .trim(from: 0.08, to: 0.92)
                .stroke(ink.opacity(0.23), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: size * 0.76, height: size * 0.76)
                .rotationEffect(.degrees(rotate ? 360 : 0))
        }
    }

    private var symbolRotation: Double {
        switch rank {
        case .curieux: return rotate ? 8 : -8
        case .erudit: return rotate ? -5 : 5
        case .savant: return 0
        case .maitre: return rotate ? 6 : -6
        case .legende: return rotate ? 12 : -12
        }
    }

    private func startAnimations() {
        let pulseDuration = intensity == .celebration ? 0.72 : 1.25
        withAnimation(.easeInOut(duration: pulseDuration).repeatForever(autoreverses: true)) {
            pulse = true
            float = true
        }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            rotate = true
        }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            sparkle = true
        }
    }
}
