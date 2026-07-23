import SwiftUI

/// Page 5 — recommandations de cours à swiper (like / dislike), 8 cartes.
/// Les « likes » préremplissent les favoris (cf. `OnboardingV2ViewModel.persistAndComplete`).
/// À la fin : « c'est noté » puis avance automatique.
struct OnboardingV2SwipeCourses: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var courses: [Course] = []
    @State private var index: Int = 0
    @State private var drag: CGSize = .zero
    @State private var done = false
    @State private var checkIn = false
    @State private var enter = false
    @State private var crossedThreshold = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 72)

            VStack(spacing: 8) {
                Text(languageManager.text("onboardingV2.swipe.title"))
                    .font(DS.title(.title2, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                Text(languageManager.text("onboardingV2.swipe.subtitle"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(OV2.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .ov2Reveal(delay: 0.1)

            Spacer()

            if done {
                completionView
            } else {
                cardStack
                    .scaleEffect(enter ? 1 : 0.86)
                    .opacity(enter ? 1 : 0)
                    .offset(y: enter ? 0 : 64)
                    .rotationEffect(.degrees(enter ? 0 : -4))
            }

            Spacer()

            if !done {
                HStack(spacing: 40) {
                    swipeButton(systemName: "xmark", tint: OV2.danger) { swipeTop(like: false) }
                    swipeButton(systemName: "heart.fill", tint: OV2.success) { swipeTop(like: true) }
                }
                .padding(.bottom, 28)
                .ov2Reveal(delay: 0.3)
            } else {
                Color.clear.frame(height: 60)
            }
        }
        .ov2Background()
        .onAppear {
            if courses.isEmpty {
                courses = vm.recommendedCourses(language: languageManager.current)
                vm.rememberSwipedCourses(courses)
            }
            // Entrée dédiée à cette page : les cartes montent et se posent en douceur.
            withAnimation(.spring(response: 0.62, dampingFraction: 0.74).delay(0.15)) {
                enter = true
            }
        }
    }

    // MARK: - Card stack

    private var cardStack: some View {
        ZStack {
            ForEach(Array(courses.enumerated()), id: \.element.id) { i, course in
                if i >= index, i < index + 3 {
                    let depth = i - index
                    courseCard(course)
                        .scaleEffect(1 - CGFloat(depth) * 0.04)
                        .offset(y: CGFloat(depth) * 12)
                        .offset(x: depth == 0 ? drag.width : 0, y: depth == 0 ? drag.height * 0.2 : 0)
                        .rotationEffect(.degrees(depth == 0 ? Double(drag.width / 18) : 0))
                        .zIndex(Double(courses.count - i))
                        .allowsHitTesting(depth == 0)
                        .highPriorityGesture(dragGesture, including: depth == 0 ? .all : .subviews)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: index)
                }
            }
        }
        .frame(height: 420)
    }

    private func courseCard(_ course: Course) -> some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let img = CourseImageMap.loadImage(for: course.id) {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    LinearGradient(
                        colors: [course.subject.color, course.subject.color.opacity(0.6)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                }
            }
            .frame(width: 300, height: 400)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.1), .black.opacity(0.75)],
                startPoint: .center, endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(course.subject.localizedShortName(language: languageManager.current).uppercased())
                    .font(DS.sans(.caption2, .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(.white.opacity(0.2), in: Capsule())
                Text(course.title)
                    .font(DS.title(.title3, .bold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
            }
            .padding(18)

            likeStamp
        }
        .frame(width: 300, height: 400)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(OV2.hairline, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
    }

    @ViewBuilder
    private var likeStamp: some View {
        let liking = drag.width > 0
        let intensity = min(1, abs(drag.width) / 110)
        VStack {
            HStack {
                if liking {
                    stamp(text: languageManager.text("onboardingV2.swipe.like"), color: OV2.success)
                        .opacity(intensity)
                    Spacer()
                } else {
                    Spacer()
                    stamp(text: languageManager.text("onboardingV2.swipe.nope"), color: OV2.danger)
                        .opacity(intensity)
                }
            }
            Spacer()
        }
        .padding(18)
    }

    private func stamp(text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(DS.title(.title2, .heavy))
            .foregroundStyle(color)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(color, lineWidth: 3))
            .rotationEffect(.degrees(drag.width > 0 ? -12 : 12))
    }

    private var completionView: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(OV2.success.opacity(0.12)).frame(width: 120, height: 120)
                Image(systemName: "checkmark")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(OV2.success)
                    .scaleEffect(checkIn ? 1 : 0.4)
                    .opacity(checkIn ? 1 : 0)
            }
            Text(languageManager.text("onboardingV2.swipe.noted"))
                .font(DS.title(.title2, .heavy))
                .foregroundStyle(OV2.ink)
                .opacity(checkIn ? 1 : 0)
        }
        .frame(height: 420)
    }

    // MARK: - Gesture / actions

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                drag = value.translation
                let crossed = abs(value.translation.width) > 100
                if crossed, !crossedThreshold {
                    crossedThreshold = true
                    OnboardingHaptics.swipeThresholdReached()
                } else if !crossed, crossedThreshold {
                    crossedThreshold = false
                }
            }
            .onEnded { value in
                crossedThreshold = false
                if abs(value.translation.width) > 100 {
                    swipeTop(like: value.translation.width > 0)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { drag = .zero }
                }
            }
    }

    private func swipeTop(like: Bool) {
        guard index < courses.count else { return }
        let course = courses[index]
        vm.toggleLiked(course.id, liked: like)
        OnboardingHaptics.swipeCommit()
        withAnimation(.easeOut(duration: 0.28)) {
            drag = CGSize(width: like ? 600 : -600, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            drag = .zero
            index += 1
            if index >= courses.count {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { done = true }
                OnboardingHaptics.counterComplete()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { checkIn = true }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { onNext() }
            }
        }
    }

    private func swipeButton(systemName: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 64, height: 64)
                .background(OV2.surface, in: Circle())
                .overlay(Circle().strokeBorder(OV2.hairline, lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
        }
        .buttonStyle(SoftPressButtonStyle())
    }
}
