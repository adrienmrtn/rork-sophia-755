import SwiftUI

struct FavoritesView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    @State private var hapticTrigger: Int = 0

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    private var favorites: [Course] {
        progressManager.favoriteCourses
    }

    var body: some View {
        NavigationStack {
            ZStack {
                cream.ignoresSafeArea()

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
                }
            }
            .navigationBarHidden(true)
            .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(languageManager.text("library.filter.favorites"))
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)

            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.white)
                Text(String(format: languageManager.text("favorites.badge.count"), favorites.count))
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .tracking(0.5)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(ink, in: Capsule())
        }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            // Big brutalist heart card
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(ink)
                    .offset(y: 6)

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(BrutalPalette.pink)
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(ink, lineWidth: 3)
                    }
                    .overlay {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 72, weight: .heavy))
                            .foregroundStyle(ink)
                    }
            }
            .frame(width: 160, height: 160)
            .padding(.bottom, 28)

            Text(languageManager.text("favorites.empty.title"))
                .font(.system(.title, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)

            Text(languageManager.text("favorites.empty.subtitle"))
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ink.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
