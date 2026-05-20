import SwiftUI

struct FavoritesView: View {
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    @State private var hapticTrigger: Int = 0

    private var favorites: [Course] {
        progressManager.favoriteCourses
    }

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(favorites) { course in
                                LibraryCardView(
                                    course: course,
                                    status: progressManager.courseStatus(for: course.id),
                                    onTap: {
                                        hapticTrigger += 1
                                        selectedCourse = course
                                    },
                                    progressManager: progressManager
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
            .background(SophiaTheme.background)
            .navigationTitle("Favoris")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 52))
                .foregroundStyle(Color.black.opacity(0.2))
            Text("Aucun favori")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(SophiaTheme.textPrimary)
            Text("Appuie sur le cœur d'un cours\npour le retrouver ici.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
