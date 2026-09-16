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
    /// Locked as soon as the last card is committed, so a double tap / swipe+button
    /// cannot schedule a second `onNext()` while the fly-off animation is in flight.
    @State private var isFinishing = false
    @State private var hasAdvanced = false
    /// True while a card is flying off. `isFinishing` only ever guarded the *last* card, so
    /// two fast taps on the second-to-last one each scheduled their own `index += 1`: the
    /// deck ran one past its end, `finishing` was never true, and the screen sat there with
    /// no cards and two buttons that did nothing — an onboarding you can only leave by
    /// reinstalling. One commit at a time, and the advance below no longer depends on
    /// catching the exact last card.
    @State private var isCommitting = false

    var body: some View {
        // The deck was a fixed 420pt tall between two flexible spacers. On an iPhone SE, or
        // at a large Dynamic Type size, the title plus the deck plus the buttons exceeded
        // the screen and the ❤️ / ✕ row was pushed off the bottom — the one screen in the
        // flow you cannot skip. The deck is sized from the height actually left over.
        GeometryReader { geo in
        VStack(spacing: 0) {
            Spacer().frame(height: geo.size.height < 620 ? 40 : 72)

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
                completionView(height: deckHeight(in: geo))
            } else {
                cardStack(height: deckHeight(in: geo))
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
                .disabled(isCommitting || isFinishing)
                .padding(.bottom, geo.size.height < 620 ? 16 : 28)
                .ov2Reveal(delay: 0.3)
            } else {
                Color.clear.frame(height: 60)
            }
        }
        .frame(width: geo.size.width, height: geo.size.height)
        }
        .ov2Background()
        .onAppear {
            if courses.isEmpty {
                courses = vm.recommendedCourses(language: languageManager.current)
                vm.rememberSwipedCourses(courses)
            }
            // Nothing to swipe is also "no cards left", and has to move on rather than
            // present an empty deck.
            if courses.isEmpty { finishDeck() }
            // Entrée dédiée à cette page : les cartes montent et se posent en douceur.
            withAnimation(.spring(response: 0.62, dampingFraction: 0.74).delay(0.15)) {
                enter = true
            }
        }
    }

    // MARK: - Card stack

    /// Height left for the deck once the title and the buttons have taken theirs.
    ///
    /// The card is 3:4, so the width it can use is the binding constraint on a wide screen
    /// and the height is on a short one; whichever runs out first decides.
    private func deckHeight(in geo: GeometryProxy) -> CGFloat {
        let chrome: CGFloat = geo.size.height < 620 ? 230 : 290
        let byHeight = geo.size.height - chrome
        let byWidth = (geo.size.width - 48) * 4 / 3
        return max(min(byHeight, byWidth, 420), 220)
    }

    private func cardStack(height: CGFloat) -> some View {
        ZStack {
            ForEach(Array(courses.enumerated()), id: \.element.id) { i, course in
                if i >= index, i < index + 3 {
                    let depth = i - index
                    courseCard(course, height: height)
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
        .frame(height: height)
    }

    /// The card keeps its 3:4 proportions inside whatever height the deck was given.
    private func courseCard(_ course: Course, height: CGFloat) -> some View {
        let width = height * 3 / 4
        return cardBody(course, width: width, height: height)
    }

    private func cardBody(_ course: Course, width: CGFloat, height: CGFloat) -> some View {
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
            .frame(width: width, height: height)
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
        .frame(width: width, height: height)
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

    private func completionView(height: CGFloat) -> some View {
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
        .frame(height: height)
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
                // Un swipe rapide ("flick") peut se terminer avant que la distance
                // parcourue par le doigt ne dépasse le seuil de 100pt : on prend donc
                // aussi en compte la vélocité via `predictedEndTranslation`, qui
                // extrapole la position finale si le doigt continuait sur sa lancée.
                let width = value.translation.width
                let predictedWidth = value.predictedEndTranslation.width
                let crossedByDistance = abs(width) > 100
                let crossedByVelocity = abs(predictedWidth) > 200
                if crossedByDistance || crossedByVelocity {
                    let like = crossedByDistance ? width > 0 : predictedWidth > 0
                    swipeTop(like: like)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { drag = .zero }
                }
            }
    }

    private func swipeTop(like: Bool) {
        guard !isCommitting, !isFinishing, !hasAdvanced, index < courses.count else { return }
        isCommitting = true
        let finishing = index == courses.count - 1
        if finishing { isFinishing = true }

        let course = courses[index]
        vm.toggleLiked(course.id, liked: like)
        OnboardingHaptics.swipeCommit()
        withAnimation(.easeOut(duration: 0.28)) {
            drag = CGSize(width: like ? 600 : -600, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            drag = .zero
            index += 1
            isCommitting = false
            // Driven by the deck being empty rather than by recognising the last card, so
            // there is no arrangement of taps that can leave this screen with nothing to
            // show and nowhere to go.
            if index >= courses.count { finishDeck() }
        }
    }

    /// Runs the completion beat and leaves. Safe to call more than once.
    private func finishDeck() {
        guard !hasAdvanced else { return }
        isFinishing = true
        if !done {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { done = true }
            OnboardingHaptics.counterComplete()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { checkIn = true }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard !hasAdvanced else { return }
            hasAdvanced = true
            onNext()
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
