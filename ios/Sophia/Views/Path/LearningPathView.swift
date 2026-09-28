import SwiftUI

/// Screens pushed from the path's top bar.
enum PathRoute: Hashable {
    case collections
}

/// The "Parcours" tab. Every collection is a level drawn as a winding trail of pods, closed
/// by a quiz pod. Levels open one after the other, the courses of a level one after the
/// other, and whatever changed since the reader last looked (a course finished from the
/// home, a level passed) is played back as an animation when they come back.
///
/// A translucent bar sits at the top. It reads "Parcours" until a level's banner slides
/// under it; from then on it names that level, and each banner that passes takes its turn.
struct LearningPathView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?

    /// Coordinate space of the trail, in which the banners report where they are.
    nonisolated static let scrollSpace = "learningPathScroll"

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
    /// Levels whose banner has slid under the top bar; the last of them is the one the bar names.
    @State private var passedBannerIds: Set<String> = []
    @State private var barHeight: CGFloat = 52

    private struct PathToast: Identifiable {
        let id = UUID()
        let text: String
        let icon: String
    }

    /// Cheap fingerprint of everything the path depends on.
    private var progressSignature: String {
        "\(progressManager.completedCount)|\(progressManager.passedPathLevelCount)|\(languageManager.current.rawValue)"
    }

    /// The level the top bar names: the last one whose banner went under it.
    private var compactLevel: PathLevel? {
        snapshot.levels.last { passedBannerIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.canvas.ignoresSafeArea()

                trail

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
                            barHeight: barHeight,
                            onTapNode: { node in
                                handleTap(node: node, in: level)
                            },
                            onBannerCrossing: { passed in
                                bannerCrossed(levelId: level.id, passed: passed)
                            }
                        )
                        .id(level.id)
                    }

                    pathEnd
                }
                .padding(.top, 14)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .coordinateSpace(.named(Self.scrollSpace))
            .safeAreaInset(edge: .top, spacing: 0) {
                topBar
            }
            .onAppear { scrollProxy = proxy }
        }
    }

    private func bannerCrossed(levelId: String, passed: Bool) {
        if passed {
            passedBannerIds.insert(levelId)
        } else {
            passedBannerIds.remove(levelId)
        }
    }

    // MARK: - Top bar

    /// Navigation-bar-like strip: translucent, the page title in the middle until a level's
    /// banner slides underneath, then that level's title and progress.
    private var topBar: some View {
        HStack(spacing: 8) {
            jumpToCurrentButton

            ZStack {
                if let level = compactLevel {
                    VStack(spacing: 1) {
                        Text(level.collection.title)
                            .font(DS.title(.headline, .semibold))
                            .foregroundStyle(DS.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                        Text(compactSubtitle(for: level))
                            .font(DS.sans(.caption2, .medium))
                            .foregroundStyle(DS.inkSecondary)
                            .lineLimit(1)
                    }
                    .id(level.id)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                } else {
                    Text(languageManager.text("path.title"))
                        .font(DS.title(.headline, .semibold))
                        .foregroundStyle(DS.ink)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .clipped()
            .multilineTextAlignment(.center)

            collectionsButton
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(.bar, ignoresSafeAreaEdges: .top)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DS.hairline)
                .frame(height: 0.5)
                .opacity(compactLevel == nil ? 0 : 1)
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            if height > 0 { barHeight = height }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: compactLevel?.id)
    }

    private func compactSubtitle(for level: PathLevel) -> String {
        let levelText = String(format: languageManager.text("path.levelCaption"), level.number)
        let coursesText = String(format: languageManager.text("path.courses.count"), level.completedCourseCount, level.courseCount)
        return "\(levelText) · \(coursesText)"
    }

    private var jumpToCurrentButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            scrollToCurrentNode()
        } label: {
            Image(systemName: "arrow.down.circle")
                .font(.jakarta(size: 18, weight: .medium))
                .foregroundStyle(DS.accentSoft)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(SoftPressButtonStyle())
        .accessibilityLabel(languageManager.text("library.section.continue"))
        .opacity(snapshot.currentNodeId == nil ? 0 : 1)
        .disabled(snapshot.currentNodeId == nil)
    }

    private var collectionsButton: some View {
        NavigationLink(value: PathRoute.collections) {
            HStack(spacing: 6) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.jakarta(size: 12, weight: .semibold))
                Text(languageManager.text("path.collections"))
                    .font(DS.sans(.caption, .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(DS.accentSoft)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(DS.accentTint, in: Capsule())
        }
        .buttonStyle(SoftPressButtonStyle())
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
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            toast = PathToast(text: text, icon: icon)
        }
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                toast = nil
            }
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
            // Once per session: land on the pod to play. After that the page keeps whatever
            // position the reader left it in.
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
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }
        scrollToCurrentNode()
    }

    private func reveal(upgrades: [String], actual: [String: PathNodeState]) async {
        try? await Task.sleep(for: .milliseconds(400))
        guard !Task.isCancelled, let first = upgrades.first else { return }
        scrollTo(nodeId: first)
        try? await Task.sleep(for: .milliseconds(650))

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
    let barHeight: CGFloat
    let onTapNode: (PathNode) -> Void
    let onBannerCrossing: (Bool) -> Void

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
            PathLevelBannerHost(
                level: level,
                isUnlocked: displayedUnlocked,
                isPassed: displayedPassed,
                accentIndex: accentIndex,
                barHeight: barHeight,
                onCrossingChange: onBannerCrossing
            )
            .overlay {
                if isCelebrating {
                    PathConfettiBurst(colors: confettiColors, pieceCount: 80, duration: 3.0, origin: CGPoint(x: 0.5, y: 0.45))
                        .frame(height: 360)
                }
            }
            .padding(.horizontal, 20)
            .zIndex(2)

            // Room above the first pod for its "start" bubble, which used to hide under the banner.
            trailBody
                .padding(.top, 30)
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

// MARK: - Banner host

/// The banner of a level as it lives in the trail: it tracks its own position under the top
/// bar, shrinks and fades as it slides underneath (the "retract"), and tells the page once
/// when it crosses the bar, so the page only re-renders on a crossing, not on every frame.
private struct PathLevelBannerHost: View {
    let level: PathLevel
    let isUnlocked: Bool
    let isPassed: Bool
    let accentIndex: Int
    let barHeight: CGFloat
    let onCrossingChange: (Bool) -> Void

    /// 0 while the banner is well below the bar, 1 once it is under it.
    @State private var retract: CGFloat = 0
    @State private var hasCrossed = false

    var body: some View {
        NavigationLink(value: level.collection) {
            PathLevelBanner(
                level: level,
                isUnlocked: isUnlocked,
                isPassed: isPassed,
                accentIndex: accentIndex
            )
        }
        .buttonStyle(SoftPressButtonStyle())
        .scaleEffect(1 - 0.06 * retract, anchor: .top)
        .opacity(1 - 0.35 * retract)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.frame(in: .named(LearningPathView.scrollSpace)).minY
        } action: { minY in
            let distanceBelowBar = minY - barHeight
            let newRetract = min(1, max(0, (72 - distanceBelowBar) / 72))
            if abs(newRetract - retract) > 0.005 {
                retract = newRetract
            }
            // A little hysteresis so the bar does not flicker right at the edge.
            let crossed = hasCrossed ? (minY < barHeight + 4) : (minY < barHeight - 4)
            if crossed != hasCrossed {
                hasCrossed = crossed
                onCrossingChange(crossed)
            }
        }
    }
}
