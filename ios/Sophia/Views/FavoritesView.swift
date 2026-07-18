import SwiftUI

struct FavoritesView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    @State private var hapticTrigger: Int = 0

    private var favorites: [Course] {
        progressManager.favoriteCourses
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.canvas.ignoresSafeArea()

                if favorites.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            header
                                .padding(.horizontal, 20)
                                .padding(.top, 4)
                                .padding(.bottom, 18)

                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 14),
                                    GridItem(.flexible(), spacing: 14)
                                ],
                                alignment: .leading,
                                spacing: 18
                            ) {
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
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationBarHidden(true)
            .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(languageManager.text("library.filter.favorites"))
                .font(DS.title(.largeTitle, .semibold))
                .foregroundStyle(DS.ink)

            HStack(spacing: 6) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text(String(format: languageManager.text("favorites.badge.count"), favorites.count))
                    .font(DS.sans(.caption, .medium))
            }
            .foregroundStyle(DS.accentSoft)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(DS.accentTint, in: Capsule())
        }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle().fill(DS.accentTint)
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 44, weight: .regular))
                    .foregroundStyle(DS.accentSoft)
            }
            .frame(width: 136, height: 136)
            .padding(.bottom, 28)

            Text(languageManager.text("favorites.empty.title"))
                .font(DS.title(.title2, .semibold))
                .foregroundStyle(DS.ink)

            Text(languageManager.text("favorites.empty.subtitle"))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
