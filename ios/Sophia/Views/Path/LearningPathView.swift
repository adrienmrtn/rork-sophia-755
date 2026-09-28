import SwiftUI

/// Screens pushed from the path header.
enum PathRoute: Hashable {
    case collections
}

/// The "Parcours" tab. Every collection is a level drawn as a winding trail of pods, closed
/// by a quiz pod. Levels open one after the other, the courses of a level one after the
/// other, and whatever changed since the reader last looked (a course finished from the
/// home, a level passed) is played back as an animation when they come back.
struct LearningPathView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?

    @State private var snapshot: LearningPathSnapshot = .empty
    /// States as drawn. They trail the real ones while a change is being animated.
    @State private var displayedStates: [String: PathNodeState] = [:]
    @State private var hasLoadedSeenStates = false
    @State private var hasSettledOnce = false
    @State private var isVisible = false
    @State private var revealTask: Task<Void, Never>? = nil
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var quizLevel: PathLevel? = nil
    @State private var toast: PathToast? = nil
    @State private var toastTask: Task<Void, Never>? = nil
    @State private var shakeCounts: [String: Int] = [:]
    @State private var poppingNodeId: String? = nil
    @State private var celebratingLevelId: String? = nil
    @State private var showExplain = false

    private struct PathToast: Identifiable {
        let id = UUID()
        let text: String
        let icon: String
    }

    /// Cheap fingerprint of everything the path depends on.
    private var progressSignature: String {
        "\(progressManager.completedCount)|\(progressManager.passedPathLevelCount)|\(languageManager.current.rawValue)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.canvas.ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    trail
                }

                if let toast {
                    toastView(toast)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }

                if showExplain {
                    FirstOpenExplanation(
                        icon: "point.bottomleft.forward.to.point.topright.scurvepath",
                        title: languageManager.text("explain.path.title"),
                        message: languageManager.text("explain.path.body"),
                        onDismiss: {
                            showExplain = false
                            TutorialFlags.markSeen(.path)
                        }
                    )
                    .transition(.opacity)
                    .zIndex(20)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: toast?.id)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: PathRoute.self) { route in
                switch route {
                case .collections:
                    CollectionsArchiveView(
                        progressManager: progressManager,
                        selectedCourse: $selectedCourse
                    )
                }
            }
            .navigationDestination(for: LearningCollection.self) { collection in
                CollectionDetailView(
                    collection: collection,
                    progressManager: progressManager,
                    selectedCourse: $selectedCourse
                )
            }
        }
        .fullScreenCover(item: $quizLevel) { level in
            PathQuizView(
                level: level,
                isLastLevel: snapshot.levels.last?.id == level.id,
                progressManager: progressManager
            )
            .sophiaColorScheme()
        }
        .onAppear {
            isVisible = true
            refresh()
            presentExplanationIfNeeded()
        }
        .onDisappear {
            isVisible = false
            revealTask?.cancel()
            revealTask = nil
        }
        .onChange(of: progressSignature) { _, _ in
            refresh()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(languageManager.text("path.title"))
                    .font(DS.title(.largeTitle, .semibold))
                    .foregroundStyle(DS.ink)

                Spacer()

                NavigationLink(value: PathRoute.collections) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.jakarta(size: 12, weight: .semibold))
                        Text(languageManager.text("path.collections"))
                            .font(DS.sans(.caption, .semibold))
                    }
                    .foregroundStyle(DS.accentSoft)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(DS.accentTint, in: Capsule())
                }
                .buttonStyle(SoftPressButtonStyle())
            }

            currentLevelCard
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var currentLevelCard: some View {
        if let level = snapshot.activeLevel {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                scrollToCurrentNode()
            } label: {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(String(format: languageManager.text("path.levelCaption"), level.number)
                            .uppercased(with: languageManager.current.foundationLocale))
                            .font(DS.sans(.caption2, .semibold))
                            .tracking(1.1)
                            .foregroundStyle(DS.accentSoft)
                        Text(level.collection.title)
                            .font(DS.title(.subheadline, .semibold))
                            .foregroundStyle(DS.ink)
                            .lineLimit(1)
                        CalmProgressBar(
                            fraction: Double(level.completedCourseCount) / Double(max(level.courseCount, 1)),
                            height: 5
                        )
                        .padding(.top, 2)
                    }

                    Text(String(format: languageManager.text("path.courses.count"), level.completedCourseCount, level.courseCount))
                        .font(DS.sans(.caption, .medium))
                        .foregroundStyle(DS.inkSecondary)
                        .monospacedDigit()
                        .fixedSize()

                    Image(systemName: "arrow.down.circle.fill")
                        .font(.jakarta(size: 20, weight: .medium))
                        .foregroundStyle(DS.accentSoft)
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(DS.surface)
                .clipShape(.rect(cornerRadius: DS.Radius.control))
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                        .strokeBorder(DS.hairline, lineWidth: 1)
                }
            }
            .buttonStyle(SoftPressButtonStyle())
        } else if snapshot.isEverythingPassed {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.jakarta(size: 18, weight: .medium))
                    .foregroundStyle(PathPalette.gold)
                Text(languageManager.text("path.allPassed"))
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                Spacer()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.accentTint)
            .clipShape(.rect(cornerRadius: DS.Radius.control))
        }
    }

    // MARK: - Trail

    private var trail: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 30) {
                    ForEach(snapshot.levels) { level in
                        PathLevelSection(
                            level: level,
                            displayedStates: displayedStates,
                            currentNodeId: snapshot.currentNodeId,
                            shakeCounts: shakeCounts,
                            poppingNodeId: poppingNodeId,
                            isCelebrating: celebratingLevelId == level.id,
                            accentIndex: level.number - 1,
                            onTapNode: { node in
                                handleTap(node: node, in: level)
                            }
                        )
                        .id(level.id)
                    }

                    pathEnd
                }
                .padding(.top, 6)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .onAppear { scrollProxy = proxy }
        }
    }

    private var pathEnd: some View {
        VStack(spacing: 10) {
            Image(systemName: snapshot.isEverythingPassed ? "flag.checkered" : "flag.fill")
                .font(.jakarta(size: 26, weight: .medium))
                .foregroundStyle(snapshot.isEverythingPassed ? PathPalette.gold : DS.inkTertiary)
                .frame(width: 64, height: 64)
                .background(DS.surfaceMuted, in: Circle())
            Text(languageManager.text(snapshot.isEverythingPassed ? "path.end.doneTitle" : "path.end.title"))
                .font(DS.title(.headline, .semibold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
            Text(languageManager.text(snapshot.isEverythingPassed ? "path.end.doneBody" : "path.end.body"))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 36)
        .padding(.top, 8)
    }

    // MARK: - Taps

    private func handleTap(node: PathNode, in level: PathLevel) {
        let shown = displayedStates[node.id] ?? node.state
        switch shown {
        case .locked:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.linear(duration: 0.45)) {
                shakeCounts[node.id, default: 0] += 1
            }
            showToast(lockedMessage(for: node, in: level), icon: "lock.fill")
        case .available, .completed:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if node.isQuiz {
                quizLevel = level
            } else if let course = node.course {
                selectedCourse = course
            }
        }
    }

    private func lockedMessage(for node: PathNode, in level: PathLevel) -> String {
        if !level.isUnlocked {
            return String(format: languageManager.text("path.locked.level"), max(1, level.number - 1))
        }
        if node.isQuiz {
            return languageManager.text("path.locked.quiz")
        }
        return languageManager.text("path.locked.course")
    }

    // MARK: - Toast

    private func showToast(_ text: String, icon: String) {
        toastTask?.cancel()
        toast = PathToast(text: text, icon: icon)
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    private func toastView(_ toast: PathToast) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: toast.icon)
                    .font(.jakarta(size: 13, weight: .semibold))
                Text(toast.text)
                    .font(DS.sans(.subheadline, .medium))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DS.accent, in: RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
            .dsSoftShadow()
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Refresh and reveal

    private func refresh() {
        let fresh = LearningPathEngine.snapshot(progressManager: progressManager)
        snapshot = fresh
        let actual = fresh.nodeStates
        if !hasLoadedSeenStates {
            hasLoadedSeenStates = true
            if let seen = LearningPathSeenStore.load() {
                displayedStates = seen
            } else {
                // First visit: nothing to replay, the path is shown as it is.
                displayedStates = actual
                LearningPathSeenStore.save(actual)
            }
        }
        reconcile(with: actual)
    }

    /// Brings the drawn states in line with the real ones: regressions at once, progress as a
    /// staged animation while the screen is showing (otherwise it waits for the next visit).
    private func reconcile(with actual: [String: PathNodeState]) {
        var upgrades: [String] = []
        for id in snapshot.orderedNodeIds {
            guard let target = actual[id] else { continue }
            guard let shown = displayedStates[id] else {
                displayedStates[id] = target
                continue
            }
            if shown < target {
                upgrades.append(id)
            } else if shown != target {
                displayedStates[id] = target
            }
        }

        guard isVisible else { return }
        revealTask?.cancel()
        if upgrades.isEmpty {
            LearningPathSeenStore.save(actual)
            if !hasSettledOnce {
                hasSettledOnce = true
                revealTask = Task { await settleOnCurrentNode() }
            }
        } else {
            hasSettledOnce = true
            revealTask = Task { await reveal(upgrades: upgrades, actual: actual) }
        }
    }

    private func settleOnCurrentNode() async {
        try? await Task.sleep(for: .milliseconds(250))
        guard !Task.isCancelled else { return }
        scrollToCurrentNode()
    }

    private func reveal(upgrades: [String], actual: [String: PathNodeState]) async {
        try? await Task.sleep(for: .milliseconds(400))
        guard !Task.isCancelled, let first = upgrades.first else { return }
        scrollTo(nodeId: first)
        try? await Task.sleep(for: .milliseconds(550))

        for id in upgrades {
            guard !Task.isCancelled else { return }
            guard let target = actual[id] else { continue }
            switch target {
            case .completed:
                await animateCompletion(of: id)
            case .available:
                await animateUnlock(of: id)
            case .locked:
                displayedStates[id] = target
            }
        }

        guard !Task.isCancelled else { return }
        LearningPathSeenStore.save(actual)
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }
        scrollToCurrentNode()
    }

    /// The pod fills with its colour and pops, and the connector below it lights up.
    private func animateCompletion(of id: String) async {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
            displayedStates[id] = .completed
            poppingNodeId = id
        }
        try? await Task.sleep(for: .milliseconds(420))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            poppingNodeId = nil
        }
        try? await Task.sleep(for: .milliseconds(380))
    }

    /// The lock rattles and gives way; when it was the first pod of a level, the level's
    /// banner comes back to life under a shower of confetti.
    private func animateUnlock(of id: String) async {
        withAnimation(.linear(duration: 0.45)) {
            shakeCounts[id, default: 0] += 1
        }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.8)
        try? await Task.sleep(for: .milliseconds(430))
        withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) {
            displayedStates[id] = .available
            poppingNodeId = id
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if let level = snapshot.level(containing: id), level.nodes.first?.id == id {
            celebratingLevelId = level.id
            scrollTo(levelId: level.id)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showToast(String(format: languageManager.text("path.unlocked.toast"), level.number), icon: "sparkles")
            AnalyticsService.trackPathLevelUnlocked(collectionId: level.collection.id, level: level.number)
            let levelId = level.id
            Task {
                try? await Task.sleep(for: .seconds(3.2))
                if celebratingLevelId == levelId {
                    celebratingLevelId = nil
                }
            }
            try? await Task.sleep(for: .milliseconds(900))
        }

        try? await Task.sleep(for: .milliseconds(420))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            poppingNodeId = nil
        }
        try? await Task.sleep(for: .milliseconds(300))
    }

    // MARK: - Scrolling

    private func scrollTo(levelId: String) {
        guard let proxy = scrollProxy else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            proxy.scrollTo(levelId, anchor: .top)
        }
    }

    private func scrollTo(nodeId: String) {
        guard let proxy = scrollProxy, let level = snapshot.level(containing: nodeId) else { return }
        // The level first, so a lazily built section exists before its pod is asked for.
        proxy.scrollTo(level.id, anchor: .top)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeInOut(duration: 0.5)) {
                proxy.scrollTo(nodeId, anchor: .center)
            }
        }
    }

    private func scrollToCurrentNode() {
        if let id = snapshot.currentNodeId {
            scrollTo(nodeId: id)
        } else if let last = snapshot.levels.last {
            scrollTo(levelId: last.id)
        }
    }

    // MARK: - First visit

    private func presentExplanationIfNeeded() {
        guard !TutorialFlags.seen(.path) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard !TutorialFlags.seen(.path) else { return }
            withAnimation(.easeIn(duration: 0.3)) {
                showExplain = true
            }
        }
    }
}

// MARK: - Level section

/// One level: its banner, then its pods down a winding trail with the connectors behind.
private struct PathLevelSection: View {
    @Environment(LanguageManager.self) private var languageManager
    let level: PathLevel
    let displayedStates: [String: PathNodeState]
    let currentNodeId: String?
    let shakeCounts: [String: Int]
    let poppingNodeId: String?
    let isCelebrating: Bool
    let accentIndex: Int
    let onTapNode: (PathNode) -> Void

    private func shownState(_ node: PathNode) -> PathNodeState {
        displayedStates[node.id] ?? node.state
    }

    private var displayedUnlocked: Bool {
        guard let first = level.nodes.first else { return level.isUnlocked }
        return shownState(first) != .locked
    }

    private var displayedPassed: Bool {
        guard let quiz = level.nodes.last else { return level.isPassed }
        return shownState(quiz) == .completed
    }

    private var confettiColors: [Color] {
        var colors: [Color] = [PathPalette.gold, DS.accentSoft]
        var seen = Set<String>()
        for node in level.nodes {
            guard let subject = node.course?.subject, !seen.contains(subject.storageKey) else { continue }
            seen.insert(subject.storageKey)
            colors.append(PathPalette.tint(for: subject))
        }
        return colors
    }

    var body: some View {
        VStack(spacing: 18) {
            NavigationLink(value: level.collection) {
                PathLevelBanner(
                    level: level,
                    isUnlocked: displayedUnlocked,
                    isPassed: displayedPassed,
                    accentIndex: accentIndex
                )
            }
            .buttonStyle(SoftPressButtonStyle())
            .overlay {
                if isCelebrating {
                    PathConfettiBurst(colors: confettiColors, pieceCount: 80, duration: 3.0, origin: CGPoint(x: 0.5, y: 0.45))
                        .frame(height: 360)
                }
            }
            .padding(.horizontal, 20)
            .zIndex(2)

            trailBody
        }
    }

    private var trailBody: some View {
        ZStack(alignment: .top) {
            PathTrailBaseShape(count: level.nodes.count, phase: level.wavePhase)
                .stroke(DS.hairline, style: StrokeStyle(lineWidth: 4, lineCap: .round))

            ForEach(Array(level.nodes.dropLast().enumerated()), id: \.element.id) { index, node in
                let filled = shownState(node) == .completed
                PathSegmentShape(index: index, phase: level.wavePhase)
                    .trim(from: 0, to: filled ? 1 : 0)
                    .stroke(segmentColor(after: node), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .animation(.easeInOut(duration: 0.55).delay(filled ? 0.25 : 0), value: filled)
            }

            VStack(spacing: 0) {
                ForEach(level.nodes) { node in
                    podRow(node)
                }
            }
        }
        .frame(height: CGFloat(level.nodes.count) * PathLayout.rowHeight)
    }

    private func segmentColor(after node: PathNode) -> Color {
        if let course = node.course {
            return PathPalette.tint(for: course.subject)
        }
        return DS.accent
    }

    private func podRow(_ node: PathNode) -> some View {
        let state = shownState(node)
        let isCurrent = node.id == currentNodeId && state == .available
        let diameter = node.isQuiz ? PathLayout.quizPodSize : PathLayout.podSize
        let tint = accentTint(node)

        return VStack(spacing: 8) {
            ZStack {
                Button {
                    onTapNode(node)
                } label: {
                    podFace(node, state: state, diameter: diameter, tint: tint)
                }
                .buttonStyle(PathPodPressStyle(plateColor: plateColor(node, state: state, tint: tint), diameter: diameter))
                .background {
                    if isCurrent {
                        PathPulseHalo(tint: tint, diameter: diameter)
                            .offset(y: -PathLayout.plateDepth / 2)
                    }
                }
                .overlay(alignment: .top) {
                    if isCurrent {
                        PathStartBubble(
                            text: languageManager.text("home.start").uppercased(with: languageManager.current.foundationLocale),
                            tint: tint
                        )
                        .offset(y: -50)
                        .transition(.scale(scale: 0.7, anchor: .bottom).combined(with: .opacity))
                    }
                }
                .modifier(PathShakeEffect(shakes: CGFloat(shakeCounts[node.id] ?? 0)))
                .scaleEffect(poppingNodeId == node.id ? 1.16 : 1)
            }
            .frame(height: PathLayout.podAreaHeight)

            Text(caption(node))
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(state == .locked ? DS.inkTertiary : DS.inkSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 132)
        }
        .frame(maxWidth: .infinity)
        .frame(height: PathLayout.rowHeight, alignment: .top)
        .offset(x: PathLayout.xOffset(for: node.index + level.wavePhase))
        .zIndex(isCurrent ? 1 : 0)
        .id(node.id)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(caption(node))
        .accessibilityValue(accessibilityState(state))
    }

    @ViewBuilder
    private func podFace(_ node: PathNode, state: PathNodeState, diameter: CGFloat, tint: Color) -> some View {
        if let course = node.course {
            PathPodFace(state: state, tint: tint, icon: course.subject.icon, diameter: diameter)
        } else {
            PathQuizPodFace(state: state, diameter: diameter)
        }
    }

    private func accentTint(_ node: PathNode) -> Color {
        if let course = node.course {
            return PathPalette.tint(for: course.subject)
        }
        return PathPalette.gold
    }

    private func plateColor(_ node: PathNode, state: PathNodeState, tint: Color) -> Color {
        switch state {
        case .locked:
            return PathPalette.lockedPlate
        case .available:
            return node.isQuiz ? PathPalette.plate(for: PathPalette.gold) : PathPalette.availablePlate
        case .completed:
            return PathPalette.plate(for: tint)
        }
    }

    private func caption(_ node: PathNode) -> String {
        if let course = node.course {
            return course.title
        }
        return languageManager.text("path.quizPod")
    }

    private func accessibilityState(_ state: PathNodeState) -> String {
        switch state {
        case .locked: languageManager.text("path.status.locked")
        case .available: languageManager.text("home.start")
        case .completed: languageManager.text("collections.complete")
        }
    }
}
