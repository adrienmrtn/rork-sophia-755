import SwiftUI
import RevenueCatUI
import StoreKit
import UIKit

struct ContentView: View {
    @StateObject private var progressManager = ProgressManager()
    @StateObject private var storeVM = StoreViewModel()
    @State private var selectedTab: Int = 0
    @State private var selectedCourse: Course? = nil
    @State private var showPaywall: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    @State private var showSwipeTutorial: Bool = false
    @State private var pendingCourse: Course? = nil
    @State private var autoSwipeCourseId: String? = nil
    @State private var freemiumSubjects: Set<String> = []

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "house.fill", value: 0) {
                    HomeView(
                        progressManager: progressManager,
                        selectedCourse: $selectedCourse,
                        autoSwipeCourseId: $autoSwipeCourseId,
                        isPremium: storeVM.isPremium,
                        freemiumSubjects: freemiumSubjects,
                        onShowPaywallFromStart: {
                            showPaywall = true
                        },
                        onShowPaywallFromQuizBanner: {
                            showPaywall = true
                        }
                    )
                }

                Tab("Biblio", systemImage: "books.vertical.fill", value: 1) {
                    LibraryView(
                        progressManager: progressManager,
                        selectedCourse: $selectedCourse
                    )
                }

                Tab("Progression", systemImage: "chart.bar.fill", value: 2) {
                    ProgressionView(
                        progressManager: progressManager,
                        store: storeVM,
                        selectedCourse: $selectedCourse
                    )
                }

                Tab("Options", systemImage: "gearshape.fill", value: 3) {
                    SettingsView(
                        progressManager: progressManager,
                        store: storeVM,
                        onShowPaywall: {
                            showPaywall = true
                        }
                    )
                }
            }
            .tint(SophiaTheme.emerald)
            .preferredColorScheme(.dark)
            .sensoryFeedback(.selection, trigger: selectedTab)
            .onChange(of: selectedCourse) { _, newCourse in
                guard let course = newCourse else { return }
                if storeVM.isPremium {
                    pendingCourse = course
                } else {
                    if !freemiumSubjects.isEmpty && !freemiumSubjects.contains(course.subject.rawValue) {
                        selectedCourse = nil
                        pendingCourse = nil
                        showPaywall = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        return
                    }

                    if progressManager.hasCompletedDailyFreeCourseToday {
                        selectedCourse = nil
                        pendingCourse = nil
                        showPaywall = true
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        return
                    }

                    pendingCourse = course
                }
            }
            .fullScreenCover(item: $pendingCourse) { course in
                CourseView(
                    course: course,
                    progressManager: progressManager,
                    isPremium: storeVM.isPremium,
                    onDismissToHome: {
                        let courseId = course.id
                        pendingCourse = nil
                        selectedCourse = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            autoSwipeCourseId = courseId
                        }
                    }
                )
            }
            .onChange(of: pendingCourse) { _, newValue in
                if newValue == nil {
                    selectedCourse = nil
                }
            }

            if showSwipeTutorial {
                SwipeTutorialOverlay(onDismiss: {
                    withAnimation(.easeOut(duration: 0.35)) {
                        showSwipeTutorial = false
                    }
                    progressManager.markSwipeTutorialSeen()
                })
                .transition(.opacity)
            }

        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .onPurchaseCompleted { _ in
                    showPaywall = false
                }
                .onRestoreCompleted { _ in
                    showPaywall = false
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sophiaRequestReview)) { _ in
            requestReviewIfAllowed()
        }
        .onAppear {
            freemiumSubjects = loadFreemiumSubjects()
            progressManager.requestNotificationsPermissionIfNeeded()
            rescheduleNotifications()
            if !progressManager.hasSeenSwipeTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        showSwipeTutorial = true
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            freemiumSubjects = loadFreemiumSubjects()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                freemiumSubjects = loadFreemiumSubjects()
                rescheduleNotifications()
            }
        }
    }

    private func loadFreemiumSubjects() -> Set<String> {
        if let raw = UserDefaults.standard.array(forKey: "sophia_freemium_subjects") as? [String], raw.count == 3 {
            return Set(raw)
        }

        let best3 = bestFreemiumSubjectsFromThemeLevels()
        if best3.count == 3 {
            UserDefaults.standard.set(best3, forKey: "sophia_freemium_subjects")
            return Set(best3)
        }

        let fallback = Array(Subject.allCases.prefix(3)).map(\.rawValue)
        UserDefaults.standard.set(fallback, forKey: "sophia_freemium_subjects")
        return Set(fallback)
    }

    private func bestFreemiumSubjectsFromThemeLevels() -> [String] {
        guard let data = UserDefaults.standard.data(forKey: "sophia_theme_levels"),
              let decodedAny = (try? JSONDecoder().decode([String: Double].self, from: data)) ?? (try? JSONDecoder().decode([String: Int].self, from: data).mapValues { v in
                  switch max(0, min(2, v)) {
                  case 0: 0.15
                  case 1: 0.50
                  default: 0.85
                  }
              }) else { return [] }

        let order = Subject.allCases
        let ranked = order
            .map { subject in
                (subject: subject, value: decodedAny[subject.rawValue] ?? 0)
            }
            .sorted { lhs, rhs in
                if lhs.value != rhs.value { return lhs.value > rhs.value }
                return order.firstIndex(of: lhs.subject) ?? 0 < order.firstIndex(of: rhs.subject) ?? 0
            }

        return Array(ranked.prefix(3)).map(\.subject.rawValue)
    }

    private func rescheduleNotifications() {
        let objective = UserDefaults.standard.string(forKey: "sophia_onboarding_primary_objective")
        progressManager.rescheduleDailyNotifications(primaryObjective: objective)
    }

    private func requestReviewIfAllowed() {
        let key = "sophia_last_review_request_date"
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let today = f.string(from: Date())
        if let last = UserDefaults.standard.string(forKey: key),
           let lastDate = f.date(from: last) {
            let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: lastDate), to: Calendar.current.startOfDay(for: Date())).day ?? 0
            if days < 90 { return }
        }
        UserDefaults.standard.set(today, forKey: key)

        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}
