import SwiftUI

struct CollectionProgressCelebrationView: View {
    let event: CollectionProgressEvent
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var displayedCount: Int = 0
    @State private var barFill: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -120
    @State private var pulse = false

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    private var previousFraction: CGFloat {
        guard event.totalCount > 0 else { return 0 }
        return CGFloat(event.previousCompletedCount) / CGFloat(event.totalCount)
    }

    private var newFraction: CGFloat {
        guard event.totalCount > 0 else { return 0 }
        return CGFloat(event.newCompletedCount) / CGFloat(event.totalCount)
    }

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                Text("Collection avancée !")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                Text(event.collection.title)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.58))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)

                Spacer(minLength: 22)

                coverCard
                    .padding(.horizontal, 22)
                    .scaleEffect(appeared ? 1 : 0.9)
                    .opacity(appeared ? 1 : 0)

                Spacer(minLength: 24)

                progressCard
                    .padding(.horizontal, 22)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)

                Spacer(minLength: 24)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onContinue()
                } label: {
                    HStack(spacing: 8) {
                        Text("Continuer")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(.headline, design: .rounded, weight: .black))
                    .foregroundStyle(ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
                .buttonStyle(DuolingoButtonStyle(fill: BrutalPalette.pink, shimmer: nil))
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
            }
        }
        .onAppear { runSequence() }
    }

    private var coverCard: some View {
        CollectionCoverView(collection: event.collection, accentIndex: CollectionData.allCollections.firstIndex(of: event.collection) ?? 0)
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(.rect(cornerRadius: 30))
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .strokeBorder(ink, lineWidth: 3.5)
            }
            .overlay(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(BrutalPalette.yellow)
                        .overlay { Circle().strokeBorder(ink, lineWidth: 3) }
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(ink)
                        .symbolEffect(.bounce, value: pulse)
                }
                .frame(width: 58, height: 58)
                .offset(x: -14, y: 28)
            }
            .brutalOffsetPlate(depth: 5, corner: 30)
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(displayedCount)")
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .foregroundStyle(ink)
                    .contentTransition(.numericText())
                    .monospacedDigit()
                Text("/ \(event.totalCount)")
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(ink.opacity(0.45))
                Text("cours terminés")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.55))
                    .padding(.leading, 2)
                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white)
                        .overlay { Capsule().strokeBorder(ink, lineWidth: 3) }
                    Capsule()
                        .fill(LinearGradient(colors: [BrutalPalette.pink, BrutalPalette.yellow], startPoint: .leading, endPoint: .trailing))
                        .overlay {
                            Capsule()
                                .fill(LinearGradient(colors: [.clear, .white.opacity(0.7), .clear], startPoint: .leading, endPoint: .trailing))
                                .mask {
                                    Rectangle()
                                        .frame(width: 80, height: 24)
                                        .offset(x: shimmerOffset)
                                }
                        }
                        .overlay { Capsule().strokeBorder(ink, lineWidth: 3) }
                        .frame(width: max(24, geo.size.width * barFill))
                }
            }
            .frame(height: 24)

            HStack(spacing: 8) {
                ForEach(0..<event.totalCount, id: \.self) { index in
                    let filled = index < displayedCount
                    Circle()
                        .fill(filled ? BrutalPalette.yellow : Color.white)
                        .overlay { Circle().strokeBorder(ink, lineWidth: 2) }
                        .overlay {
                            if filled {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(ink)
                            }
                        }
                        .scaleEffect(filled && pulse ? 1.1 : 1)
                        .frame(width: 26, height: 26)
                    if index < event.totalCount - 1 {
                        Capsule()
                            .fill(index < displayedCount - 1 ? ink : ink.opacity(0.18))
                            .frame(height: 3)
                    }
                }
            }
        }
        .padding(18)
        .brutalOnboardingCard(depth: 5, corner: 24)
    }

    private func runSequence() {
        displayedCount = event.previousCompletedCount
        barFill = previousFraction
        withAnimation(.spring(response: 0.62, dampingFraction: 0.78)) {
            appeared = true
        }
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            shimmerOffset = 320
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.55)
            withAnimation(.spring(response: 0.95, dampingFraction: 0.78)) {
                displayedCount = event.newCompletedCount
                barFill = newFraction
                pulse = true
            }
        }
    }
}

struct CollectionCompletedCelebrationView: View {
    let event: CollectionProgressEvent
    let awardedXP: Int
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var cardScale: CGFloat = 0.72
    @State private var confettiTrigger = 0
    @State private var glow = false
    @State private var trophyBounce = 0

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            ConfettiView(trigger: confettiTrigger)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                Text("Collection terminée !")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                Text(event.collection.title)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.58))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)

                Spacer(minLength: 26)

                completedCard
                    .padding(.horizontal, 22)
                    .scaleEffect(cardScale)
                    .opacity(appeared ? 1 : 0)

                Spacer(minLength: 26)

                if awardedXP > 0 {
                    xpPill
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.75)
                }

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
                .buttonStyle(DuolingoButtonStyle(fill: BrutalPalette.yellow, shimmer: nil))
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)
            }
        }
        .onAppear { runSequence() }
    }

    private var completedCard: some View {
        CollectionCoverView(collection: event.collection, accentIndex: CollectionData.allCollections.firstIndex(of: event.collection) ?? 0)
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(.rect(cornerRadius: 34))
            .overlay {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(ink, lineWidth: 4)
            }
            .overlay {
                RadialGradient(
                    colors: [BrutalPalette.yellow.opacity(glow ? 0.48 : 0.16), .clear],
                    center: .center,
                    startRadius: 20,
                    endRadius: 190
                )
            }
            .overlay {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(BrutalPalette.yellow)
                            .overlay { Circle().strokeBorder(ink, lineWidth: 4) }
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 54, weight: .black))
                            .foregroundStyle(ink)
                            .symbolEffect(.bounce, value: trophyBounce)
                    }
                    .frame(width: 112, height: 112)

                    Text("Parcours complet")
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundStyle(ink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white, in: Capsule())
                        .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                }
            }
            .brutalOffsetPlate(depth: 5, corner: 34)
    }

    private var xpPill: some View {
        HStack(spacing: 10) {
            Image(systemName: "star.fill")
                .font(.system(size: 18, weight: .black))
            Text("+\(awardedXP) XP globaux")
                .font(.system(.title3, design: .rounded, weight: .black))
                .monospacedDigit()
        }
        .foregroundStyle(ink)
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(BrutalPalette.yellow, in: Capsule())
        .overlay { Capsule().strokeBorder(ink, lineWidth: 3) }
        .background {
            Capsule().fill(ink).offset(y: 5)
        }
        .padding(.bottom, 5)
    }

    private func runSequence() {
        withAnimation(.spring(response: 0.72, dampingFraction: 0.76)) {
            appeared = true
            cardScale = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            confettiTrigger += 1
            trophyBounce += 1
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true).delay(0.35)) {
            glow = true
        }
    }
}
