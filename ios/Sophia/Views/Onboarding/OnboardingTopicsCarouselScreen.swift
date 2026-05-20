import SwiftUI

struct OnboardingTopicsCarouselScreen: View {
    let title: String
    let subtitle: String
    let categories: [(name: String, courses: [(title: String, courseId: String)])]
    let onNext: () -> Void
    @State private var appeared: Bool = false

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Text(title)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(SophiaTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 15)

                    Text(subtitle)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 15)
                }
                .padding(.top, 60)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(Array(categories.enumerated()), id: \.offset) { catIdx, category in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(category.name)
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                    .foregroundStyle(Color.black.opacity(0.8))
                                    .padding(.horizontal, 24)

                                ContinuousScrollingRow(
                                    courses: category.courses,
                                    categoryIndex: catIdx,
                                    appeared: appeared
                                )
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }

                Spacer(minLength: 0)
            }

            VStack {
                Spacer()
                OnboardingButton(title: "Continuer", action: onNext)
                    .background(
                        LinearGradient(
                            colors: [SophiaTheme.background.opacity(0), SophiaTheme.background, SophiaTheme.background],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                        .offset(y: -20)
                        .allowsHitTesting(false),
                        alignment: .bottom
                    )
                    .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) {
                appeared = true
            }
        }
    }
}

private struct ContinuousScrollingRow: View {
    let courses: [(title: String, courseId: String)]
    let categoryIndex: Int
    let appeared: Bool
    @State private var scrollOffset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var isUserDragging: Bool = false
    @State private var timer: Timer?

    private let cardWidth: CGFloat = 140
    private let spacing: CGFloat = 12
    private let speed: CGFloat = 30

    var body: some View {
        let extendedCourses = courses + courses + courses

        GeometryReader { geo in
            let viewWidth = geo.size.width
            HStack(spacing: spacing) {
                ForEach(Array(extendedCourses.enumerated()), id: \.offset) { idx, course in
                    OnboardingMiniCard(
                        title: course.title,
                        courseId: course.courseId
                    )
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.5).delay(Double(categoryIndex) * 0.1 + Double(idx % courses.count) * 0.05),
                        value: appeared
                    )
                }
            }
            .offset(x: -scrollOffset + 24)
            .onAppear {
                contentWidth = CGFloat(courses.count) * (cardWidth + spacing)
                startScrolling()
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isUserDragging = true
                        timer?.invalidate()
                        timer = nil
                        scrollOffset -= value.translation.width / 10
                        if scrollOffset < 0 { scrollOffset += contentWidth }
                        if scrollOffset > contentWidth * 2 { scrollOffset -= contentWidth }
                    }
                    .onEnded { _ in
                        isUserDragging = false
                        startScrolling()
                    }
            )
        }
        .frame(height: 120)
        .clipped()
    }

    private func startScrolling() {
        let interval: TimeInterval = 1.0 / 60.0
        let step = speed * interval
        let directionMultiplier: CGFloat = categoryIndex % 2 == 0 ? 1 : -1

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            guard !isUserDragging else { return }
            scrollOffset += step * directionMultiplier
            if directionMultiplier > 0 && scrollOffset >= contentWidth * 2 {
                scrollOffset -= contentWidth
            } else if directionMultiplier < 0 && scrollOffset <= 0 {
                scrollOffset += contentWidth
            }
        }
    }
}

struct OnboardingMiniCard: View {
    let title: String
    let courseId: String
    @State private var image: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            Color(.secondarySystemBackground)
                .frame(width: 140, height: 90)
                .overlay {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    } else {
                        LinearGradient(
                            colors: [SophiaTheme.accent.opacity(0.3), SophiaTheme.accent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .clipShape(.rect(cornerRadii: .init(topLeading: 12, topTrailing: 12)))

            Text(title)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(SophiaTheme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(width: 140, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(SophiaTheme.cardBackground)
                .clipShape(.rect(cornerRadii: .init(bottomLeading: 12, bottomTrailing: 12)))
        }
        .onAppear {
            image = CourseImageMap.loadImage(for: courseId)
        }
    }
}
