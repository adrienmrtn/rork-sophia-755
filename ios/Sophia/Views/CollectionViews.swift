import SwiftUI

/// Standalone Collections tab (separate page from the Library).
///
/// Calm / editorial art direction: soft canvas, clean cards, a single blue accent and a
/// minimalist vertical "path" for the collection detail (replacing the former gamified
/// Duolingo-style winding trail, reward chest, completion rings and XP badges).
struct CollectionsView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?

    @State private var showExplain = false

    var body: some View {
        NavigationStack {
            ZStack {
                DS.canvas.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(languageManager.text("library.tab.collections"))
                                .font(DS.title(.largeTitle, .semibold))
                                .foregroundStyle(DS.ink)
                            Text(languageManager.text("collections.subtitle"))
                                .font(DS.sans(.subheadline))
                                .foregroundStyle(DS.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        CollectionsOverviewView(
                            progressManager: progressManager,
                            selectedCourse: $selectedCourse
                        )
                    }
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)

                if showExplain {
                    FirstOpenExplanation(
                        icon: "square.stack.3d.up",
                        title: languageManager.text("explain.collections.title"),
                        message: languageManager.text("explain.collections.body"),
                        onDismiss: {
                            showExplain = false
                            TutorialFlags.markSeen(.collections)
                        }
                    )
                    .transition(.opacity)
                    .zIndex(20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: LearningCollection.self) { collection in
                CollectionDetailView(
                    collection: collection,
                    progressManager: progressManager,
                    selectedCourse: $selectedCourse
                )
            }
        }
        .onAppear {
            guard !TutorialFlags.seen(.collections) else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard !TutorialFlags.seen(.collections) else { return }
                withAnimation(.easeIn(duration: 0.3)) { showExplain = true }
            }
        }
    }
}

struct CollectionsOverviewView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?

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
        VStack(alignment: .leading, spacing: 18) {
            if let featured {
                NavigationLink(value: featured) {
                    CollectionFeaturedCard(
                        collection: featured,
                        progressManager: progressManager,
                        accentIndex: accentIndex(for: featured)
                    )
                }
                .buttonStyle(SoftPressButtonStyle())
                .padding(.horizontal, 20)
            }

            if !rest.isEmpty {
                Text(languageManager.text("collections.title"))
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(DS.inkTertiary)
                    .tracking(1.2)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
            }

            LazyVStack(spacing: 14) {
                ForEach(rest, id: \.id) { collection in
                    NavigationLink(value: collection) {
                        CollectionRowCard(
                            collection: collection,
                            progressManager: progressManager,
                            accentIndex: accentIndex(for: collection)
                        )
                    }
                    .buttonStyle(SoftPressButtonStyle())
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Shared press feedback

/// Subtle press feedback (gentle scale) that doesn't intercept scroll gestures.
struct SoftPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Progress bar

private struct CollectionProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(DS.hairline)
                Capsule()
                    .fill(DS.accent)
                    .frame(width: max(fraction > 0 ? 8 : 0, geo.size.width * fraction))
            }
        }
        .frame(height: 5)
    }
}

// MARK: - Featured card

private struct CollectionFeaturedCard: View {
    @Environment(LanguageManager.self) private var languageManager
    let collection: LearningCollection
    let progressManager: ProgressManager
    let accentIndex: Int

    private var completed: Int { progressManager.completedCount(for: collection) }
    private var total: Int { collection.courseIds.count }
    private var fraction: Double { total == 0 ? 0 : Double(completed) / Double(total) }
    private var isComplete: Bool { completed == total && total > 0 }
    private var started: Bool { completed > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CollectionCoverView(collection: collection, accentIndex: accentIndex)
                .frame(height: 176)
                .frame(maxWidth: .infinity)
                .clipped()

            VStack(alignment: .leading, spacing: 12) {
                Text(languageManager.text("collections.featured").uppercased())
                    .font(DS.sans(.caption2, .semibold))
                    .foregroundStyle(DS.accentSoft)
                    .tracking(1.2)

                Text(collection.title)
                    .font(DS.title(.title2, .semibold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(collection.description)
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                CollectionProgressBar(fraction: fraction)
                    .padding(.top, 2)

                HStack(spacing: 10) {
                    Text(isComplete
                        ? languageManager.text("collections.complete")
                        : String(format: languageManager.text("collections.progress"), completed, total))
                        .font(DS.sans(.caption, .medium))
                        .monospacedDigit()
                        .foregroundStyle(DS.inkSecondary)

                    Spacer()

                    HStack(spacing: 5) {
                        Text(isComplete
                            ? languageManager.text("collections.pathComplete")
                            : (started ? languageManager.text("library.section.continue") : languageManager.text("home.start")))
                        Image(systemName: "arrow.right").font(.jakarta(size: 11, weight: .semibold))
                    }
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(DS.accent)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
        .dsSoftShadow()
    }
}

// MARK: - Regular row card

private struct CollectionRowCard: View {
    @Environment(LanguageManager.self) private var languageManager
    let collection: LearningCollection
    let progressManager: ProgressManager
    let accentIndex: Int

    private var completed: Int { progressManager.completedCount(for: collection) }
    private var total: Int { collection.courseIds.count }
    private var fraction: Double { total == 0 ? 0 : Double(completed) / Double(total) }
    private var isComplete: Bool { completed == total && total > 0 }

    var body: some View {
        HStack(spacing: 14) {
            CollectionCoverView(collection: collection, accentIndex: accentIndex)
                .frame(width: 84, height: 84)
                .clipShape(.rect(cornerRadius: DS.Radius.small))
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous)
                        .strokeBorder(DS.hairline, lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(collection.title)
                    .font(DS.title(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                CollectionProgressBar(fraction: fraction)

                HStack(spacing: 5) {
                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.jakarta(size: 11, weight: .medium))
                            .foregroundStyle(DS.accentSoft)
                    }
                    Text(isComplete
                        ? languageManager.text("collections.complete")
                        : String(format: languageManager.text("collections.progress"), completed, total))
                        .font(DS.sans(.caption2, .medium))
                        .monospacedDigit()
                        .foregroundStyle(DS.inkSecondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.jakarta(size: 13, weight: .semibold))
                .foregroundStyle(DS.inkTertiary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.control))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
        .dsSoftShadow()
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

    private var completed: Int { progressManager.completedCount(for: collection) }
    private var total: Int { collection.courseIds.count }
    private var fraction: Double { total == 0 ? 0 : Double(completed) / Double(total) }
    private var isComplete: Bool { completed == total && total > 0 }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                    hero
                        .padding(.horizontal, 20)

                    pathSection
                        .padding(.bottom, 44)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
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
                    .font(.jakarta(size: 15, weight: .semibold))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(width: 40, height: 40)
                    .background(DS.surface, in: Circle())
                    .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
            }
            .buttonStyle(SoftPressButtonStyle())

            Spacer()

            Text(String(format: languageManager.text("collections.progress"), completed, total))
                .font(DS.sans(.caption, .medium))
                .foregroundStyle(DS.inkSecondary)
                .monospacedDigit()
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            CollectionCoverView(collection: collection, accentIndex: ContentCatalog.activeCollections.firstIndex(of: collection) ?? 0)
                .frame(height: 190)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(.rect(cornerRadius: DS.Radius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                        .strokeBorder(DS.hairline, lineWidth: 1)
                }
                .dsSoftShadow()

            VStack(alignment: .leading, spacing: 8) {
                Text(collection.title)
                    .font(DS.title(.largeTitle, .semibold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(collection.description)
                    .font(DS.sans(.body))
                    .foregroundStyle(DS.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            CollectionProgressBar(fraction: fraction)
                .padding(.top, 2)
        }
    }

    private var pathSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(languageManager.text("collections.path").uppercased())
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(DS.inkTertiary)
                .tracking(1.2)
                .padding(.horizontal, 20)

            CollectionCourseList(
                collection: collection,
                progressManager: progressManager,
                onSelect: { course in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedCourse = course
                }
            )
            .padding(.horizontal, 20)

            if isComplete {
                completionFooter
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
            }
        }
    }

    private var completionFooter: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.jakarta(size: 18, weight: .medium))
                .foregroundStyle(DS.accentSoft)
            Text(languageManager.text("collections.pathComplete"))
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(DS.ink)
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.accentTint)
        .clipShape(.rect(cornerRadius: DS.Radius.control))
    }
}

// MARK: - Minimalist vertical course path

struct CollectionCourseList: View {
    @Environment(LanguageManager.self) private var languageManager
    let collection: LearningCollection
    let progressManager: ProgressManager
    let onSelect: (Course) -> Void

    private var courses: [Course] { collection.courses }

    private var nextIndex: Int? {
        courses.firstIndex { progressManager.courseStatus(for: $0.id) != .completed }
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(courses.enumerated()), id: \.element.id) { index, course in
                CollectionCourseRow(
                    index: index,
                    course: course,
                    status: progressManager.courseStatus(for: course.id),
                    isCurrent: nextIndex == index,
                    isLast: index == courses.count - 1,
                    language: languageManager.current,
                    onTap: { onSelect(course) }
                )
            }
        }
    }
}

private struct CollectionCourseRow: View {
    let index: Int
    let course: Course
    let status: CourseStatus
    let isCurrent: Bool
    let isLast: Bool
    let language: AppLanguage
    let onTap: () -> Void

    private let nodeSize: CGFloat = 34

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                nodeColumn

                VStack(alignment: .leading, spacing: 4) {
                    Text(course.subject.localizedShortName(language: language).uppercased())
                        .font(DS.sans(.caption2, .semibold))
                        .foregroundStyle(DS.accentSoft)
                        .tracking(1.0)

                    Text(course.title)
                        .font(DS.title(.subheadline, .semibold))
                        .foregroundStyle(status == .completed ? DS.inkSecondary : DS.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
                .padding(.bottom, isLast ? 0 : 24)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.jakarta(size: 12, weight: .semibold))
                    .foregroundStyle(DS.inkTertiary)
                    .padding(.top, 10)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SoftPressButtonStyle())
    }

    private var nodeColumn: some View {
        VStack(spacing: 4) {
            node
            if !isLast {
                Rectangle()
                    .fill(status == .completed ? DS.accent : DS.hairline)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: nodeSize)
    }

    @ViewBuilder
    private var node: some View {
        ZStack {
            switch status {
            case .completed:
                Circle().fill(DS.accent)
                Image(systemName: "checkmark")
                    .font(.jakarta(size: nodeSize * 0.4, weight: .bold))
                    .foregroundStyle(.white)
            case .inProgress:
                Circle().fill(DS.surface)
                Circle().strokeBorder(DS.accent, lineWidth: 2)
                Image(systemName: "play.fill")
                    .font(.jakarta(size: nodeSize * 0.34, weight: .semibold))
                    .foregroundStyle(DS.accent)
            case .notStarted:
                if isCurrent {
                    Circle().fill(DS.surface)
                    Circle().strokeBorder(DS.accent, lineWidth: 2)
                    Text("\(index + 1)")
                        .font(DS.sans(.subheadline, .semibold))
                        .foregroundStyle(DS.accent)
                        .monospacedDigit()
                } else {
                    Circle().fill(DS.surfaceMuted)
                    Circle().strokeBorder(DS.hairline, lineWidth: 1)
                    Text("\(index + 1)")
                        .font(DS.sans(.subheadline, .medium))
                        .foregroundStyle(DS.inkTertiary)
                        .monospacedDigit()
                }
            }
        }
        .frame(width: nodeSize, height: nodeSize)
    }
}

// MARK: - Cover

struct CollectionCoverView: View {
    let collection: LearningCollection
    var accentIndex: Int = 0

    private var palette: (Color, Color) {
        let palettes: [(Color, Color)] = [
            (Color(red: 0.914, green: 0.937, blue: 0.973), Color(red: 0.831, green: 0.878, blue: 0.949)),
            (Color(red: 0.902, green: 0.925, blue: 0.965), Color(red: 0.784, green: 0.843, blue: 0.933)),
            (Color(red: 0.925, green: 0.949, blue: 0.976), Color(red: 0.808, green: 0.867, blue: 0.941)),
            (Color(red: 0.898, green: 0.933, blue: 0.973), Color(red: 0.769, green: 0.831, blue: 0.925)),
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

            Image(systemName: "square.stack.3d.up")
                .font(.jakarta(size: 40, weight: .light))
                .foregroundStyle(DS.accentSoft.opacity(0.55))
        }
    }
}
