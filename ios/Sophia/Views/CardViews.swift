import SwiftUI

extension CollectibleCardRarity {
    var primaryColor: Color {
        switch self {
        case .commune: Color(red: 0.92, green: 0.93, blue: 0.94)
        case .rare: Color(red: 0.58, green: 0.78, blue: 1.0)
        case .epique: Color(red: 0.78, green: 0.58, blue: 1.0)
        case .legendaire: Color(red: 1.0, green: 0.78, blue: 0.30)
        }
    }

    var secondaryColor: Color {
        switch self {
        case .commune: Color(red: 0.76, green: 0.78, blue: 0.82)
        case .rare: Color(red: 0.22, green: 0.56, blue: 1.0)
        case .epique: Color(red: 0.56, green: 0.28, blue: 0.95)
        case .legendaire: Color(red: 1.0, green: 0.45, blue: 0.67)
        }
    }

    var symbolName: String {
        switch self {
        case .commune: "circle.hexagongrid.fill"
        case .rare: "diamond.fill"
        case .epique: "sparkles"
        case .legendaire: "crown.fill"
        }
    }

    var shouldBurstConfetti: Bool {
        switch self {
        case .epique, .legendaire: true
        case .commune, .rare: false
        }
    }
}

struct CardsProfileSection: View {
    let progressManager: ProgressManager
    let onShowAllCards: () -> Void

    private let ink = BrutalPalette.ink

    private var unlocked: [CollectibleCard] { progressManager.unlockedCards }
    private var total: Int { CardData.allCards.count }
    private var fraction: Double { total == 0 ? 0 : Double(unlocked.count) / Double(total) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CARTES À COLLECTER")
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .foregroundStyle(ink.opacity(0.55))
                    .tracking(1.2)
                Spacer()
                Button(action: onShowAllCards) {
                    Text("Voir tout →")
                        .font(.system(.subheadline, design: .rounded, weight: .black))
                        .foregroundStyle(ink)
                }
            }
            .padding(.horizontal, 8)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(unlocked.count)")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(ink)
                        .monospacedDigit()
                    Text("/ \(total)")
                        .font(.system(.title3, design: .rounded, weight: .black))
                        .foregroundStyle(ink.opacity(0.45))
                    Text("cartes")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink.opacity(0.55))
                    Spacer()
                    Text("\(Int((fraction * 100).rounded()))%")
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(ink, in: Capsule())
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white)
                            .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                        Capsule()
                            .fill(LinearGradient(colors: [BrutalPalette.pink, BrutalPalette.yellow], startPoint: .leading, endPoint: .trailing))
                            .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                            .frame(width: max(18, geo.size.width * CGFloat(fraction)))
                    }
                }
                .frame(height: 18)

                if progressManager.recentlyUnlockedCards.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.stack.badge.plus")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(ink)
                            .frame(width: 48, height: 48)
                            .background(BrutalPalette.yellow, in: Circle())
                            .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                        Text("Termine un cours pour débloquer tes premières cartes.")
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink.opacity(0.62))
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(progressManager.recentlyUnlockedCards) { card in
                                CollectibleMiniCard(card: card, unlocked: true)
                                    .frame(width: 92)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .padding(16)
            .brutalCard()
        }
    }
}

struct QuizStatsProfileCard: View {
    let stats: QuizStatsSummary

    private let ink = BrutalPalette.ink

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUIZZ RÉUSSIS")
                .font(.system(.caption, design: .rounded, weight: .black))
                .foregroundStyle(ink.opacity(0.55))
                .tracking(1.2)
                .padding(.horizontal, 8)

            HStack(spacing: 12) {
                statBlock(
                    icon: "checkmark.circle.fill",
                    value: "\(stats.correctAnswerCount)",
                    label: "bonnes réponses",
                    fill: BrutalPalette.yellow
                )
                statBlock(
                    icon: "target",
                    value: "\(stats.successPercent)%",
                    label: "réussite",
                    fill: BrutalPalette.pink
                )
            }
        }
    }

    private func statBlock(icon: String, value: String, label: String, fill: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(ink)
                .frame(width: 42, height: 42)
                .background(fill, in: Circle())
                .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }

            Text(value)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(ink)
                .monospacedDigit()

            Text(label)
                .font(.system(.caption, design: .rounded, weight: .black))
                .foregroundStyle(ink.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .brutalCard()
    }
}

struct AllCardsView: View {
    let progressManager: ProgressManager
    var onDismiss: () -> Void

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(CardData.allCards) { card in
                            CollectibleCardTile(
                                card: card,
                                unlocked: progressManager.isCardUnlocked(card)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mes cartes")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .foregroundStyle(ink)
                Text("\(progressManager.unlockedCards.count) / \(CardData.allCards.count) débloquées")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.55))
                    .monospacedDigit()
            }
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 42, height: 42)
                    .background(Color.white, in: Circle())
                    .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
            }
            .buttonStyle(BrutalIconButtonStyle())
        }
    }
}

struct CollectibleCardTile: View {
    let card: CollectibleCard
    let unlocked: Bool

    var body: some View {
        CollectibleCardArtView(card: card, unlocked: unlocked, compact: false)
            .frame(maxWidth: .infinity)
    }
}

struct CollectibleMiniCard: View {
    let card: CollectibleCard
    let unlocked: Bool

    var body: some View {
        CollectibleCardArtView(card: card, unlocked: unlocked, compact: true)
            .frame(width: 92, height: 154)
    }
}

struct CollectibleCardArtView: View {
    let card: CollectibleCard
    let unlocked: Bool
    var compact: Bool

    private let ink = BrutalPalette.ink

    var body: some View {
        VStack(spacing: 0) {
            art
                .frame(height: compact ? 86 : 150)
                .overlay(alignment: .topTrailing) {
                    rarityBadge
                        .padding(compact ? 6 : 9)
                }
                .overlay(alignment: .bottom) {
                    Rectangle().fill(ink).frame(height: compact ? 2 : 3)
                }

            VStack(alignment: .leading, spacing: compact ? 3 : 7) {
                Text(card.name)
                    .font(.system(compact ? .caption : .subheadline, design: .rounded, weight: .black))
                    .foregroundStyle(ink.opacity(unlocked ? 1 : 0.62))
                    .lineLimit(2, reservesSpace: !compact)
                    .multilineTextAlignment(.leading)

                Text(card.rarity.rawValue)
                    .font(.system(.caption2, design: .rounded, weight: .black))
                    .foregroundStyle(ink.opacity(0.55))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, compact ? 8 : 12)
            .padding(.vertical, compact ? 8 : 12)
            .background(card.rarity.primaryColor.opacity(unlocked ? 1 : 0.55))
        }
        .background(Color.white)
        .clipShape(.rect(cornerRadius: compact ? 14 : 22))
        .overlay {
            RoundedRectangle(cornerRadius: compact ? 14 : 22, style: .continuous)
                .strokeBorder(ink, lineWidth: compact ? 2 : 3)
        }
        .frame(height: compact ? 154 : nil, alignment: .top)
        .shadow(color: ink.opacity(0.9), radius: 0, x: 0, y: compact ? 3 : 4)
        .opacity(unlocked ? 1 : 0.72)
        .padding(.bottom, compact ? 4 : 6)
    }

    @ViewBuilder
    private var art: some View {
        if unlocked, let image = UIImage(named: card.imageAssetName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .clipped()
        } else if unlocked {
            fallbackArt
        } else {
            lockedArt
        }
    }

    private var fallbackArt: some View {
        ZStack {
            LinearGradient(colors: [card.rarity.primaryColor, card.rarity.secondaryColor], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: compact ? 38 : 68, weight: .black))
                .foregroundStyle(ink.opacity(0.45))
        }
    }

    private var lockedArt: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.82), Color(white: 0.95)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "person.crop.square.fill")
                .font(.system(size: compact ? 34 : 62, weight: .black))
                .foregroundStyle(ink.opacity(0.22))
            Image(systemName: "lock.fill")
                .font(.system(size: compact ? 14 : 22, weight: .black))
                .foregroundStyle(ink)
                .padding(9)
                .background(Color.white, in: Circle())
                .overlay { Circle().strokeBorder(ink, lineWidth: 2) }
                .offset(x: compact ? 22 : 40, y: compact ? 22 : 42)
        }
    }

    private var rarityBadge: some View {
        Image(systemName: card.rarity.symbolName)
            .font(.system(size: compact ? 10 : 13, weight: .black))
            .foregroundStyle(ink)
            .frame(width: compact ? 24 : 32, height: compact ? 24 : 32)
            .background(unlocked ? card.rarity.secondaryColor : Color.white, in: Circle())
            .overlay { Circle().strokeBorder(ink, lineWidth: compact ? 1.8 : 2.3) }
    }
}

struct CardUnlockCelebrationView: View {
    let event: CardUnlockEvent
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var revealed = false
    @State private var glow = false
    @State private var confettiTrigger = 0
    @State private var promptPulse = false

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            ConfettiView(trigger: confettiTrigger)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer(minLength: 28)

                Text("Carte débloquée !")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                Text(event.card.rarity.rawValue)
                    .font(.system(.headline, design: .rounded, weight: .black))
                    .foregroundStyle(ink.opacity(0.58))
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)

                Spacer(minLength: 30)

                revealCard
                .scaleEffect(appeared ? 1 : 0.78)
                .onTapGesture { revealIfNeeded() }

                Spacer(minLength: 24)

                HStack(spacing: 10) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16, weight: .black))
                    Text("+\(event.awardResult.awardedXP) XP globaux")
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .monospacedDigit()
                }
                .foregroundStyle(ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(event.card.rarity.primaryColor, in: Capsule())
                .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                .opacity(revealed ? 1 : 0)
                .scaleEffect(revealed ? 1 : 0.8)

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
                .buttonStyle(DuolingoButtonStyle(fill: event.card.rarity.primaryColor, shimmer: nil))
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 16)
            }
        }
        .onAppear { runSequence() }
        .contentShape(Rectangle())
        .onTapGesture { revealIfNeeded() }
    }

    private var revealCard: some View {
        ZStack {
            unlockCardFace
                .blur(radius: revealed ? 0 : 10)
                .saturation(revealed ? 1 : 0.2)
                .opacity(revealed ? 1 : 0.22)
                .scaleEffect(revealed ? 1 : 0.96)
                .mask(alignment: .top) {
                    Rectangle()
                        .scaleEffect(y: revealed ? 1 : 0.02, anchor: .top)
                }

            if !revealed {
                cardBack
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .animation(.spring(response: 1.1, dampingFraction: 0.82), value: revealed)
    }

    private var unlockCardFace: some View {
        VStack(spacing: 0) {
            unlockArt
                .frame(height: 224)
                .overlay(alignment: .topTrailing) {
                    rarityBadge
                        .padding(10)
                }
                .overlay(alignment: .bottom) {
                    Rectangle().fill(ink).frame(height: 3)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(event.card.name)
                    .font(.system(.headline, design: .rounded, weight: .black))
                    .foregroundStyle(ink)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)

                Text(event.card.rarity.rawValue)
                    .font(.system(.subheadline, design: .rounded, weight: .black))
                    .foregroundStyle(ink.opacity(0.58))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(event.card.rarity.primaryColor)
        }
        .frame(width: 260, height: 360)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(ink, lineWidth: 4)
        }
        .shadow(color: ink.opacity(0.9), radius: 0, x: 0, y: 4)
    }

    @ViewBuilder
    private var unlockArt: some View {
        if let image = UIImage(named: event.card.imageAssetName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .clipped()
        } else {
            ZStack {
                LinearGradient(colors: [event.card.rarity.primaryColor, event.card.rarity.secondaryColor], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 86, weight: .black))
                    .foregroundStyle(ink.opacity(0.45))
            }
        }
    }

    private var rarityBadge: some View {
        Image(systemName: event.card.rarity.symbolName)
            .font(.system(size: 14, weight: .black))
            .foregroundStyle(ink)
            .frame(width: 34, height: 34)
            .background(event.card.rarity.secondaryColor, in: Circle())
            .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
    }

    private var cardBack: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [event.card.rarity.secondaryColor, event.card.rarity.primaryColor], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(ink, lineWidth: 4)
                }
                .overlay {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 64, weight: .black))
                        Text("SOPHIA")
                            .font(.system(.title, design: .rounded, weight: .black))
                            .tracking(3)
                        Text("Tape pour révéler")
                            .font(.system(.headline, design: .rounded, weight: .black))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(Color.white, in: Capsule())
                            .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                            .scaleEffect(promptPulse ? 1.05 : 0.96)
                    }
                    .foregroundStyle(ink)
                }
        }
        .frame(width: 260, height: 360)
        .shadow(color: ink.opacity(0.9), radius: 0, x: 0, y: 4)
    }

    private func runSequence() {
        withAnimation(.spring(response: 0.75, dampingFraction: 0.82)) {
            appeared = true
        }
        withAnimation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true).delay(0.35)) {
            promptPulse = true
        }
    }

    private func revealIfNeeded() {
        guard !revealed else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.7)
        withAnimation(.spring(response: 1.2, dampingFraction: 0.84)) {
            revealed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.7)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            if event.card.rarity.shouldBurstConfetti {
                confettiTrigger += 1
            }
            withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}
