import SwiftUI
import RevenueCatUI

struct ContentView: View {
    var onResetOnboarding: (() -> Void)? = nil

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
                        autoSwipeCourseId: $autoSwipeCourseId,
                        onLockedTap: {
                            if storeVM.isPremium { return }
                            showPaywall = true
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    )
                }

                Tab("Biblio", systemImage: "books.vertical.fill", value: 1) {
                    LibraryView(
                        progressManager: progressManager,
                        isPremium: storeVM.isPremium,
                        onShowPaywall: {
                            showPaywall = true
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        },
                        selectedCourse: $selectedCourse
                    )
                }

                Tab("Profil", systemImage: "person.fill", value: 2) {
                    ProfileView(
                        progressManager: progressManager,
                        store: storeVM,
                        selectedCourse: $selectedCourse,
                        onShowPaywall: {
                            showPaywall = true
                        },
                        onResetOnboarding: onResetOnboarding
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
                    return
                }
                // Freemium: lock courses from non-priority subjects.
                if !FreemiumGate.isUnlocked(course.subject, isPremium: false) {
                    selectedCourse = nil
                    pendingCourse = nil
                    showPaywall = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    return
                }
                // Freemium: 1 free course per day. Reading the slides is free for the
                // first course of the day; further attempts open the paywall.
                if progressManager.hasCompletedCourseToday {
                    selectedCourse = nil
                    pendingCourse = nil
                    showPaywall = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } else {
                    progressManager.incrementFreeCoursesOpened()
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
            SophiaPaywallView(
                context: .coursGratuit,
                onPurchased: { showPaywall = false },
                onRestored: { showPaywall = false }
            )
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
