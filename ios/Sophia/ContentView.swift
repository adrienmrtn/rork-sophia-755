import SwiftUI
import RevenueCatUI

struct ContentView: View {
    @State private var progressManager = ProgressManager()
    @State private var storeVM = StoreViewModel()
    @State private var selectedTab: Int = 0
    @State private var selectedCourse: Course? = nil
    @State private var showPaywall: Bool = false

    @State private var showSwipeTutorial: Bool = false
    @State private var pendingCourse: Course? = nil
    @State private var autoSwipeCourseId: String? = nil

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "house.fill", value: 0) {
                    HomeView(
                        progressManager: progressManager,
                        selectedCourse: $selectedCourse,
                        autoSwipeCourseId: $autoSwipeCourseId
                    )
                }

                Tab("Biblio", systemImage: "books.vertical.fill", value: 1) {
                    LibraryView(
                        progressManager: progressManager,
                        selectedCourse: $selectedCourse
                    )
                }

                Tab("Favoris", systemImage: "heart.fill", value: 2) {
                    FavoritesView(
                        progressManager: progressManager,
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
                    progressManager.incrementFreeCoursesOpened()
                    if progressManager.freeCoursesOpened >= 4 {
                        selectedCourse = nil
                        pendingCourse = nil
                        showPaywall = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } else {
                        pendingCourse = course
                    }
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
        .onAppear {
            if !progressManager.hasSeenSwipeTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        showSwipeTutorial = true
                    }
                }
            }
        }
    }
}
