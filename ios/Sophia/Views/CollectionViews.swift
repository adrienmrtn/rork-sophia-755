import SwiftUI

struct CollectionsOverviewView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?

    private let ink = BrutalPalette.ink

    private var collections: [LearningCollection] { ContentCatalog.activeCollections }

    /// Highlight an in-progress collection first, else the first untouched one, else the first.
    private var featured: LearningCollection? {
        collections.first { c in
            let done = progressManager.completedCount(for: c)
            return done > 0 && done < c.courseIds.count
        }
        ?? collections.first { progressManager.completedCount(for: $0) == 0 }
        ?? collections.first
    }

    private var rest: [LearningCollection] {
        guard let featured else { return collections }
        return collections.filter { $0.id != featured.id }
    }

    private func accentIndex(for collection: LearningCollection) -> Int {
        collections.firstIndex(of: collection) ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(languageManager.text("collections.title"))
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .foregroundStyle(ink.opacity(0.55))
                    .tracking(1.2)
                Text(languageManager.text("collections.subtitle"))
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.62))
            }
            .padding(.horizontal, 20)

            if let featured {
                NavigationLink(value: featured) {
                    CollectionFeaturedHero(
                        collection: featured,
                        progressManager: progressManager,
                        accentIndex: accentIndex(for: featured)
                    )
                }
                .buttonStyle(BrutalCardButtonStyle(depth: 2))
                .padding(.horizontal, 20)
            }

            LazyVStack(spacing: 18) {
                ForEach(rest, id: \.id) { collection in
                    NavigationLink(value: collection) {
                        CollectionOverviewCard(
                            collection: collection,
                            progressManager: progressManager,
                            accentIndex: accentIndex(for: collection)
                        )
                    }
                    .buttonStyle(BrutalCardButtonStyle(depth: 2))
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Featured hero

private struct CollectionFeaturedHero: View {
    @Environment(LanguageManager.self) private var languageManager
    let collection: LearningCollection
    let progressManager: ProgressManager
    let accentIndex: Int

    private let ink = BrutalPalette.ink
    private let depth: CGFloat = 7

    private var completed: Int { progressManager.completedCount(for: collection) }
    private var total: Int { collection.courseIds.count }
    private var fraction: Double { total == 0 ? 0 : Double(completed) / Double(total) }
    private var isComplete: Bool { completed == total && total > 0 }
    private var started: Bool { completed > 0 }

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(ink)
                .offset(y: depth)

            VStack(alignment: .leading, spacing: 0) {
                CollectionCoverView(collection: collection, accentIndex: accentIndex)
                    .frame(height: 190)
                    .overlay(alignment: .topLeading) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill").font(.system(size: 10, weight: .black))
                            Text(languageManager.text("collections.featured"))
                                .font(.system(.caption2, design: .rounded, weight: .black))
                                .tracking(0.6)
                        }
                        .foregroundStyle(ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(BrutalPalette.yellow, in: Capsule())
                        .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
                        .padding(12)
                    }
                    .overlay(alignment: .topTrailing) {
                        CompletionRing(fraction: fraction, size: 48)
                            .padding(12)
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(ink).frame(height: 3)
                    }

                VStack(alignment: .leading, spacing: 12) {
                    Text(collection.title)
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundStyle(ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(collection.description)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.6))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        Text(isComplete
                            ? languageManager.text("collections.complete")
                            : String(format: languageManager.text("collections.progress"), completed, total))
                            .font(.system(.caption, design: .rounded, weight: .black))
                            .monospacedDigit()
                            .foregroundStyle(ink.opacity(0.7))

                        Spacer()

                        HStack(spacing: 6) {
                            Text(isComplete
                                ? languageManager.text("collections.pathComplete")
                                : (started ? languageManager.text("library.section.continue") : languageManager.text("collections.badge.path")))
                                .font(.system(.caption, design: .rounded, weight: .black))
                            Image(systemName: "arrow.right").font(.system(size: 12, weight: .black))
                        }
                        .foregroundStyle(ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(BrutalPalette.pink, in: Capsule())
                        .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
                    }
                }
                .padding(16)
                .background(Color.white)
            }
            .clipShape(.rect(cornerRadius: 28))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(ink, lineWidth: 3)
            }
        }
        .padding(.bottom, depth)
    }
}

// MARK: - Completion ring

struct CompletionRing: View {
    let fraction: Double
    var size: CGFloat = 46

    private let ink = BrutalPalette.ink

    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }

            Circle()
                .trim(from: 0, to: max(0.001, fraction))
                .stroke(
                    LinearGradient(colors: [BrutalPalette.pink, BrutalPalette.yellow], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: size * 0.13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(size * 0.14)

            if fraction >= 1 {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.34, weight: .black))
                    .foregroundStyle(ink)
            } else {
                Text("\(Int(fraction * 100))%")
                    .font(.system(size: size * 0.26, weight: .black, design: .rounded))
                    .foregroundStyle(ink)
                    .monospacedDigit()
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Regular overview card (with completion ring)

private struct CollectionOverviewCard: View {
    @Environment(LanguageManager.self) private var languageManager
    let collection: LearningCollection
    let progressManager: ProgressManager
    let accentIndex: Int

    @State private var appeared = false

    private let ink = BrutalPalette.ink
    private let depth: CGFloat = 6

    private var completed: Int { progressManager.completedCount(for: collection) }
    private var total: Int { collection.courseIds.count }
    private var fraction: Double { total == 0 ? 0 : Double(completed) / Double(total) }
    private var isComplete: Bool { completed == total && total > 0 }

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(ink)
                .offset(y: depth)

            VStack(alignment: .leading, spacing: 0) {
                CollectionCoverView(collection: collection, accentIndex: accentIndex)
                    .frame(height: 150)
                    .overlay(alignment: .topLeading) {
                        statusBadge
                            .padding(12)
                    }
                    .overlay(alignment: .topTrailing) {
                        CompletionRing(fraction: fraction, size: 44)
                            .padding(12)
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(ink).frame(height: 3)
                    }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(collection.title)
                                .font(.system(.title3, design: .rounded, weight: .black))
                                .foregroundStyle(ink)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(collection.description)
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundStyle(ink.opacity(0.58))
                                .lineLimit(2)
                        }
                        Spacer(minLength: 6)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(ink)
                            .frame(width: 34, height: 34)
                            .background(Color.white, in: Circle())
                            .overlay { Circle().strokeBorder(ink, lineWidth: 2) }
                    }

                    HStack(spacing: 8) {
                        Image(systemName: isComplete ? "checkmark.seal.fill" : "square.grid.2x2.fill")
                            .font(.system(size: 12, weight: .black))
                        Text(isComplete
                            ? languageManager.text("collections.complete")
                            : String(format: languageManager.text("collections.progress"), completed, total))
                            .font(.system(.caption, design: .rounded, weight: .black))
                            .monospacedDigit()
                        Spacer()
                        Text("+\(total * ProgressManager.globalCollectionXPPerCourse) XP")
                            .font(.system(.caption2, design: .rounded, weight: .black))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(BrutalPalette.yellow, in: Capsule())
                            .overlay { Capsule().strokeBorder(ink, lineWidth: 1.8) }
                    }
                    .foregroundStyle(ink.opacity(0.72))
                }
                .padding(16)
                .background(Color.white)
            }
            .clipShape(.rect(cornerRadius: 26))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(ink, lineWidth: 3)
            }
        }
        .padding(.bottom, depth)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(Double(accentIndex % 5) * 0.035)) {
                appeared = true
            }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: isComplete ? "checkmark" : "sparkles")
                .font(.system(size: 11, weight: .black))
            Text(isComplete
                ? languageManager.text("collections.badge.complete")
                : languageManager.text("collections.badge.path"))
                .font(.system(.caption2, design: .rounded, weight: .black))
                .tracking(0.8)
        }
        .foregroundStyle(isComplete ? .white : ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isComplete ? ink : Color.white, in: Capsule())
        .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
    }
}

// MARK: - Detail

struct CollectionDetailView: View {
    @Environment(LanguageManager.self) private var languageManager
    let collection: LearningCollection
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    @Environment(\.dismiss) private var dismiss

    @State private var appeared = false

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    private var completed: Int { progressManager.completedCount(for: collection) }
    private var total: Int { collection.courseIds.count }
    private var fraction: Double { total == 0 ? 0 : Double(completed) / Double(total) }

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                    hero
                        .padding(.horizontal, 20)

                    pathSection
                        .padding(.bottom, 40)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.84)) {
                appeared = true
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 42, height: 42)
                    .background(Color.white, in: Circle())
                    .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
            }
            .buttonStyle(BrutalIconButtonStyle())

            Spacer()

            Text("\(completed)/\(total)")
                .font(.system(.caption, design: .rounded, weight: .black))
                .foregroundStyle(.white)
                .monospacedDigit()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ink, in: Capsule())
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            CollectionCoverView(collection: collection, accentIndex: ContentCatalog.activeCollections.firstIndex(of: collection) ?? 0)
                .frame(height: 200)
                .clipShape(.rect(cornerRadius: 26))
                .overlay { RoundedRectangle(cornerRadius: 26).strokeBorder(ink, lineWidth: 3) }
                .overlay(alignment: .topTrailing) {
                    CompletionRing(fraction: fraction, size: 52)
                        .padding(12)
                }
                .background {
                    RoundedRectangle(cornerRadius: 26).fill(ink).offset(y: 6)
                }
                .padding(.bottom, 6)

            Text(collection.title)
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(collection.description)
                .font(.system(.body, design: .rounded, weight: .heavy))
                .foregroundStyle(ink.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var pathSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageManager.text("collections.path"))
                .font(.system(.caption, design: .rounded, weight: .black))
                .foregroundStyle(ink.opacity(0.55))
                .tracking(1.2)
                .padding(.horizontal, 26)

            CollectionTrailView(
                collection: collection,
                progressManager: progressManager,
                onSelect: { course in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedCourse = course
                }
            )
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Trail (Duolingo-style winding path with a reward chest)

struct CollectionTrailView: View {
    @Environment(LanguageManager.self) private var languageManager
    let collection: LearningCollection
    let progressManager: ProgressManager
    let onSelect: (Course) -> Void

    @State private var pulse = false

    private let ink = BrutalPalette.ink
    private let stepHeight: CGFloat = 118
    private let amplitude: CGFloat = 56
    private let nodeSize: CGFloat = 62
    private let chestSize: CGFloat = 84

    private var courses: [Course] { collection.courses }
    private var completed: Int { progressManager.completedCount(for: collection) }
    private var total: Int { collection.courseIds.count }
    private var isComplete: Bool { total > 0 && completed >= total }

    /// First not-yet-completed course → gets the pulsing "current" highlight.
    private var nextIndex: Int? {
        courses.firstIndex { progressManager.courseStatus(for: $0.id) != .completed }
    }

    private func xOffset(_ i: Int) -> CGFloat {
        amplitude * CGFloat(sin(Double(i) * .pi / 2))
    }

    private func center(_ i: Int, width: CGFloat) -> CGPoint {
        CGPoint(x: width / 2 + xOffset(i), y: stepHeight / 2 + stepHeight * CGFloat(i))
    }

    private func chestCenter(width: CGFloat) -> CGPoint {
        CGPoint(x: width / 2, y: stepHeight / 2 + stepHeight * CGFloat(courses.count))
    }

    private var totalHeight: CGFloat {
        stepHeight * CGFloat(courses.count) + chestSize + 70
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .topLeading) {
                connectors(width: w)

                ForEach(Array(courses.enumerated()), id: \.element.id) { index, course in
                    step(index: index, course: course, width: w)
                }

                chest(width: w)
            }
            .frame(width: w, height: totalHeight, alignment: .topLeading)
        }
        .frame(height: totalHeight)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private func connectors(width: CGFloat) -> some View {
        Canvas { ctx, _ in
            guard !courses.isEmpty else { return }
            var path = Path()
            path.move(to: center(0, width: width))
            for i in 1..<courses.count {
                path.addLine(to: center(i, width: width))
            }
            path.addLine(to: chestCenter(width: width))
            ctx.stroke(
                path,
                with: .color(ink.opacity(0.3)),
                style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round, dash: [1, 13])
            )
        }
    }

    @ViewBuilder
    private func step(index: Int, course: Course, width: CGFloat) -> some View {
        let c = center(index, width: width)
        let status = progressManager.courseStatus(for: course.id)
        let isNext = (nextIndex == index) && !isComplete
        let labelOnRight = xOffset(index) <= 0
        let labelWidth = width * 0.40

        ZStack(alignment: .topLeading) {
            // Course label beside the node.
            Text(course.title)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink.opacity(status == .completed ? 0.55 : 1))
                .lineLimit(3)
                .multilineTextAlignment(labelOnRight ? .leading : .trailing)
                .frame(width: labelWidth, alignment: labelOnRight ? .leading : .trailing)
                .position(
                    x: labelOnRight ? c.x + nodeSize / 2 + 12 + labelWidth / 2
                                    : c.x - nodeSize / 2 - 12 - labelWidth / 2,
                    y: c.y
                )

            Button {
                onSelect(course)
            } label: {
                TrailNode(
                    index: index,
                    status: status,
                    subject: course.subject,
                    size: nodeSize,
                    isNext: isNext,
                    pulse: pulse
                )
            }
            .buttonStyle(TrailNodeButtonStyle())
            .position(c)
        }
    }

    @ViewBuilder
    private func chest(width: CGFloat) -> some View {
        let cc = chestCenter(width: width)
        let rewardXP = progressManager.collectionCompletionXP(for: collection)

        ZStack(alignment: .topLeading) {
            // Chest medallion.
            ZStack {
                if isComplete {
                    Circle()
                        .fill(BrutalPalette.yellow.opacity(pulse ? 0.5 : 0.25))
                        .frame(width: chestSize * 1.5, height: chestSize * 1.5)
                        .blur(radius: 16)
                }
                Circle()
                    .fill(ink)
                    .frame(width: chestSize, height: chestSize)
                    .offset(y: 5)
                Circle()
                    .fill(LinearGradient(colors: isComplete ? [BrutalPalette.yellow, Color(red: 1.0, green: 0.72, blue: 0.2)] : [.white, Color(white: 0.92)], startPoint: .top, endPoint: .bottom))
                    .frame(width: chestSize, height: chestSize)
                    .overlay { Circle().strokeBorder(ink, lineWidth: 3) }
                Image(systemName: isComplete ? "trophy.fill" : "gift.fill")
                    .font(.system(size: chestSize * 0.4, weight: .black))
                    .foregroundStyle(ink)
                    .scaleEffect(isComplete && pulse ? 1.06 : 1)
            }
            .position(cc)

            // Reward caption under the chest.
            VStack(spacing: 6) {
                Text("+\(rewardXP) XP")
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .foregroundStyle(ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(BrutalPalette.yellow, in: Capsule())
                    .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
                Text(isComplete
                    ? languageManager.text("collections.pathComplete")
                    : languageManager.text("collections.reward"))
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.55))
            }
            .frame(width: width)
            .position(x: width / 2, y: cc.y + chestSize / 2 + 30)
        }
    }
}

private struct TrailNode: View {
    let index: Int
    let status: CourseStatus
    let subject: Subject
    let size: CGFloat
    let isNext: Bool
    let pulse: Bool

    private let ink = BrutalPalette.ink

    private var fill: Color {
        switch status {
        case .completed: return BrutalPalette.yellow
        case .inProgress: return BrutalPalette.pink
        case .notStarted: return BrutalPalette.pastel(for: subject)
        }
    }

    var body: some View {
        ZStack {
            if isNext {
                Circle()
                    .stroke(BrutalPalette.pink.opacity(0.5), lineWidth: 4)
                    .frame(width: size + 18, height: size + 18)
                    .scaleEffect(pulse ? 1.12 : 0.96)
                    .opacity(pulse ? 0.2 : 0.8)
            }

            Circle()
                .fill(ink)
                .frame(width: size, height: size)
                .offset(y: 5)

            Circle()
                .fill(fill)
                .frame(width: size, height: size)
                .overlay { Circle().strokeBorder(ink, lineWidth: 3) }

            Group {
                switch status {
                case .completed:
                    Image(systemName: "checkmark").font(.system(size: size * 0.36, weight: .black))
                case .inProgress:
                    Image(systemName: "play.fill").font(.system(size: size * 0.34, weight: .black))
                case .notStarted:
                    Text("\(index + 1)").font(.system(size: size * 0.36, weight: .black, design: .rounded))
                }
            }
            .foregroundStyle(ink)
        }
    }
}

private struct TrailNodeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Cover

struct CollectionCoverView: View {
    let collection: LearningCollection
    var accentIndex: Int = 0

    private let ink = BrutalPalette.ink

    private var palette: (Color, Color) {
        let palettes: [(Color, Color)] = [
            (Color(red: 0.82, green: 0.78, blue: 1.0), Color(red: 0.50, green: 0.75, blue: 1.0)),
            (Color(red: 1.0, green: 0.553, blue: 0.706), Color(red: 1.0, green: 0.84, blue: 0.35)),
            (Color(red: 0.70, green: 0.95, blue: 0.80), Color(red: 0.66, green: 0.92, blue: 0.96)),
            (Color(red: 1.0, green: 0.78, blue: 0.36), Color(red: 1.0, green: 0.55, blue: 0.18)),
        ]
        return palettes[accentIndex % palettes.count]
    }

    var body: some View {
        ZStack {
            if let image = UIImage(named: collection.coverAssetName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                fallbackCover
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var fallbackCover: some View {
        ZStack {
            LinearGradient(colors: [palette.0, palette.1], startPoint: .topLeading, endPoint: .bottomTrailing)

            Circle()
                .fill(Color.white.opacity(0.24))
                .frame(width: 180, height: 180)
                .offset(x: 120, y: -70)

            Circle()
                .stroke(ink.opacity(0.18), lineWidth: 14)
                .frame(width: 170, height: 170)
                .offset(x: -120, y: 65)

            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(index.isMultiple(of: 2) ? Color.white.opacity(0.28) : ink.opacity(0.14))
                    .frame(width: 78, height: 18)
                    .rotationEffect(.degrees(-18))
                    .offset(x: CGFloat(index * 34 - 88), y: CGFloat(index * 18 - 36))
            }

            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(ink)
                    .symbolEffect(.variableColor.iterative.reversing)
                Text(collection.title)
                    .font(.system(.title3, design: .rounded, weight: .black))
                    .foregroundStyle(ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .shadow(color: Color.white.opacity(0.35), radius: 0, x: 0, y: 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(18)
        }
    }
}
