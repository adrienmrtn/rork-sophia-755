import SwiftUI

struct OnboardingTopicsCarouselScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let title: String
    let subtitle: String
    let categories: [(name: String, courses: [(title: String, courseId: String)])]
    let onNext: () -> Void
    @State private var appeared: Bool = true

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .lineSpacing(-2)
                        .foregroundStyle(BrutalPalette.ink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .lineSpacing(1)
                        .foregroundStyle(BrutalPalette.ink.opacity(0.58))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 34)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                }
                .padding(.top, 54)
                .padding(.bottom, 6)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(Array(categories.enumerated()), id: \.offset) { catIdx, category in
                            VStack(alignment: .leading, spacing: 12) {
                                BrutalPill(
                                    text: category.name,
                                    background: OnboardingPastels.at(catIdx),
                                    foreground: BrutalPalette.ink
                                )
                                .padding(.horizontal, 24)

                                ContinuousScrollingRow(
                                    courses: category.courses,
                                    categoryIndex: catIdx,
                                    appeared: appeared
                                )
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 126)
                }

                Spacer(minLength: 0)
            }

            VStack {
                Spacer()
                OnboardingPrimaryButton(title: languageManager.text("common.continue"), action: onNext)
                    .background(
                        LinearGradient(
                            colors: [BrutalPalette.cream.opacity(0), BrutalPalette.cream, BrutalPalette.cream],
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

    private let cardWidth: CGFloat = 150
    private let spacing: CGFloat = 14
    private let speed: CGFloat = 28

    var body: some View {
        let extendedCourses = courses + courses + courses

        GeometryReader { _ in
            HStack(spacing: spacing) {
                ForEach(Array(extendedCourses.enumerated()), id: \.offset) { idx, course in
                    OnboardingMiniCard(
                        title: course.title,
                        courseId: course.courseId,
                        accent: OnboardingPastels.at(categoryIndex)
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
        .frame(height: 132)
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
    let accent: Color
    @State private var image: UIImage?

    private let w: CGFloat = 150
    private let h: CGFloat = 84
    private let corner: CGFloat = 14
    private let depth: CGFloat = 4

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(BrutalPalette.ink)
                .frame(width: w, height: h + 48)
                .offset(y: depth)

            VStack(spacing: 0) {
                Color(red: 0.96, green: 0.93, blue: 0.88)
                    .frame(width: w, height: h)
                    .overlay {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        } else {
                            accent
                        }
                    }
                    .clipShape(.rect(cornerRadii: .init(topLeading: corner, topTrailing: corner)))
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(BrutalPalette.ink).frame(height: 2.5)
                    }

                Text(title)
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(width: w, height: 48, alignment: .topLeading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(accent)
                    .clipShape(.rect(cornerRadii: .init(bottomLeading: corner, bottomTrailing: corner)))
            }
            .frame(width: w)
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
            }
        }
        .onAppear {
            image = CourseImageMap.loadImage(for: courseId)
        }
    }
}
