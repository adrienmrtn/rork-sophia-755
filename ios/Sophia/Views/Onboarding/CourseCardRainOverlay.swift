import SwiftUI

struct CourseCardRainOverlay: View {
    let isActive: Bool

    @Environment(LanguageManager.self) private var languageManager

    @State private var fallingCards: [FallingCardModel] = []
    @State private var spawnTimer: Timer?
    @State private var spawnSessionID = UUID()
    @State private var overlaySize: CGSize = .zero

    private let spawnInterval: TimeInterval = 0.22
    private let pool: [(courseId: String, colorIndex: Int)] = [
        ("course_1_la_naissance_de_l_islam_622", 0),
        ("course_101_1984_george_orwell", 2),
        ("course_4_le_couronnement_de_charlemagne_800", 0),
        ("course_7_jeanne_d_arc_et_la_guerre_de_cent_ans_14", 0),
        ("course_11_la_prise_de_la_bastille_1789", 0),
        ("course_21_rosa_parks_et_montgomery_1955", 0),
        ("course_31_le_plan_marshall_1947_1952", 5),
        ("course_103_hamlet_shakespeare", 2),
        ("course_144_la_nouvelle_vague_francaise", 3),
        ("course_161_la_naissance_des_dieux_grecs_cronos_zeus", 4),
        ("course_210_la_guerre_en_ukraine_expliquee", 5),
        ("course_226_l_ia_et_l_emploi", 5),
    ]

    private var localizedPool: [(title: String, courseId: String, colorIndex: Int)] {
        let titles = Dictionary(
            uniqueKeysWithValues: LocalizedContentLoader.courses(for: languageManager.current).map { ($0.id, $0.title) }
        )
        return pool.compactMap { item in
            guard let title = titles[item.courseId] else { return nil }
            return (title, item.courseId, item.colorIndex)
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(fallingCards) { card in
                    OnboardingRainCard(
                        title: card.title,
                        courseId: card.courseId,
                        accent: OnboardingPastels.at(card.colorIndex)
                    )
                    .scaleEffect(card.scale)
                    .rotationEffect(.degrees(card.rotation))
                    .position(x: card.x, y: card.yOffset)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .onAppear {
                overlaySize = geo.size
            }
            .onChange(of: geo.size) { _, size in
                overlaySize = size
            }
            .onChange(of: isActive) { _, active in
                if active {
                    startSpawning(in: geo.size)
                } else {
                    stopSpawning(clearCards: false)
                }
            }
            .onChange(of: languageManager.current) { _, _ in
                guard isActive, overlaySize != .zero else { return }
                startSpawning(in: overlaySize)
            }
            .onDisappear {
                stopSpawning(clearCards: true)
            }
        }
        .allowsHitTesting(false)
    }

    private func startSpawning(in size: CGSize) {
        stopSpawning()
        spawnSessionID = UUID()
        let session = spawnSessionID
        spawnCard(in: size, session: session)
        spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { _ in
            spawnCard(in: size, session: session)
        }
    }

    private func stopSpawning(clearCards: Bool = true) {
        spawnTimer?.invalidate()
        spawnTimer = nil
        if clearCards {
            fallingCards.removeAll()
        }
    }

    private func spawnCard(in size: CGSize, session: UUID) {
        guard isActive, session == spawnSessionID else { return }

        let pool = localizedPool
        guard !pool.isEmpty else { return }

        let visibleIds = Set(fallingCards.map(\.courseId))
        let available = pool.filter { !visibleIds.contains($0.courseId) }
        let pick = (available.randomElement() ?? pool.randomElement()) ?? pool[0]

        let cardWidth: CGFloat = OnboardingRainCard.layoutWidth
        let cardHeight: CGFloat = OnboardingRainCard.layoutHeight
        let x = CGFloat.random(in: (cardWidth / 2)...(size.width - cardWidth / 2))
        let rotation = Double.random(in: -10...10)
        let scale = CGFloat.random(in: 0.82...1.0)
        let startY: CGFloat = -cardHeight / 2
        let endY = size.height + cardHeight
        let duration = Double.random(in: 2.0...2.8)

        var card = FallingCardModel(
            title: pick.title,
            courseId: pick.courseId,
            x: x,
            yOffset: startY,
            rotation: rotation,
            scale: scale,
            colorIndex: pick.colorIndex
        )
        fallingCards.append(card)
        let cardId = card.id

        withAnimation(.linear(duration: duration)) {
            if let idx = fallingCards.firstIndex(where: { $0.id == cardId }) {
                fallingCards[idx].yOffset = endY
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            fallingCards.removeAll { $0.id == cardId }
        }

        if fallingCards.count > 14 {
            fallingCards.removeFirst(fallingCards.count - 14)
        }
    }
}

/// Compact course card tuned for the projection rain animation.
struct OnboardingRainCard: View {
    let title: String
    let courseId: String
    let accent: Color

    static let layoutWidth: CGFloat = 124
    static let layoutHeight: CGFloat = 116

    @State private var image: UIImage?

    private let imageHeight: CGFloat = 68
    private let labelHeight: CGFloat = 48
    private let corner: CGFloat = 12
    private let depth: CGFloat = 4

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(BrutalPalette.ink)
                .frame(width: Self.layoutWidth, height: imageHeight + labelHeight)
                .offset(y: depth)

            VStack(spacing: 0) {
                ZStack {
                    Color(red: 0.96, green: 0.93, blue: 0.88)
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        accent
                    }
                }
                .frame(width: Self.layoutWidth, height: imageHeight)
                .clipped()

                Text(title)
                    .font(.jakarta(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(BrutalPalette.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .frame(width: Self.layoutWidth, height: labelHeight, alignment: .topLeading)
                    .background(accent)
            }
            .frame(width: Self.layoutWidth, height: imageHeight + labelHeight)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
            }
        }
        .frame(width: Self.layoutWidth, height: Self.layoutHeight)
        .onAppear {
            image = CourseImageMap.loadImage(for: courseId)
        }
    }
}

private struct FallingCardModel: Identifiable {
    let id = UUID()
    let title: String
    let courseId: String
    let x: CGFloat
    var yOffset: CGFloat
    let rotation: Double
    let scale: CGFloat
    let colorIndex: Int
}
