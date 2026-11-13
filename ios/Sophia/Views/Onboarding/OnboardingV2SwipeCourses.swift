import SwiftUI

/// Page 5 — recommandations de cours à swiper (like / dislike), 8 cartes.
/// Les « likes » préremplissent les favoris (cf. `OnboardingV2ViewModel.persistAndComplete`).
/// À la fin : « c'est noté » puis avance automatique.
///
/// Style « Elevate arrondi » : titre à gauche (son cœur en gras bleu), une pile de cartes bleu
/// pâle — vignette du cours, titre, auteur, matière — et deux boutons ronds (pouce vers le
/// bas, pouce vers le haut). La pile se vide à vue d'œil : chaque cours restant dépasse en
/// haut de la carte du dessus, et un bord disparaît à chaque oui ou non, jusqu'à la dernière
/// carte. Le geste, ses seuils et ses vibrations sont inchangés.
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
    /// Nom de l'auteur de chaque cours du paquet (identifiant du cours → nom), quand il est connu.
    @State private var authorNames: [String: String] = [:]

    var body: some View {
        // The deck was a fixed 420pt tall between two flexible spacers. On an iPhone SE, or
        // at a large Dynamic Type size, the title plus the deck plus the buttons exceeded
        // the screen and the like / pass row was pushed off the bottom — the one screen in the
        // flow you cannot skip. The deck is sized from the height actually left over.
        GeometryReader { geo in
            let compact: Bool = geo.size.height < 620
            let cardWidth: CGFloat = max(geo.size.width - OV2CoreMetrics.sideInset * 2, 200)
            let height: CGFloat = deckHeight(in: geo)
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, OV2CoreMetrics.sideInset)
                    .padding(.top, compact ? 12 : 22)
                    .dsStagger(0)

                Spacer(minLength: 12)

                if done {
                    completionView(height: height)
                } else {
                    deck(width: cardWidth, height: height)
                        .scaleEffect(enter ? 1 : 0.94)
                        .opacity(enter ? 1 : 0)
                        .offset(y: enter ? 0 : 36)
                }

                Spacer(minLength: 12)

                if !done {
                    buttons
                        .disabled(isCommitting || isFinishing)
                        .padding(.bottom, compact ? 16 : 28)
                        .ov2Reveal(delay: 0.3)
                } else {
                    Color.clear.frame(height: Self.buttonSize + (compact ? 16 : 28))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ov2Background()
        .onAppear {
            if courses.isEmpty {
                courses = vm.recommendedCourses(language: languageManager.current)
                vm.rememberSwipedCourses(courses)
                authorNames = Self.resolveAuthorNames(for: courses)
            }
            // Nothing to swipe is also "no cards left", and has to move on rather than
            // present an empty deck.
            if courses.isEmpty { finishDeck() }
            // Entrée dédiée à cette page : la pile monte et se pose en douceur, sans rebond.
            withAnimation(.spring(response: 0.55, dampingFraction: 1).delay(0.15)) {
                enter = true
            }
        }
    }

    // MARK: - En-tête

    /// « Choisis les **premiers cours** que tu vas lire », aligné à gauche. La consigne qui
    /// suivait a été retirée : la pile et les deux boutons disent déjà quoi faire.
    private var header: some View {
        OV2CoreHighlightTitle(
            text: OV2CoreText.marked(
                "onboardingV2.swipe.title",
                highlightKey: "elevateOnboardingCore.swipe.titleHighlight",
                language: languageManager.current
            ),
            size: 26
        )
    }

    // MARK: - Card stack

    private static let buttonSize: CGFloat = 64
    /// Nombre de cartes de dessous montrées au plus (le paquet en compte huit).
    private static let maxPlates: Int = 7
    /// De combien chaque carte de dessous dépasse au-dessus de celle qui la précède.
    private static let plateStep: CGFloat = 6
    /// De combien chaque carte de dessous est plus étroite que celle qui la précède.
    private static let plateInset: CGFloat = 16
    /// Hauteur réservée au-dessus de la carte du dessus pour les bords de la pile.
    private static let plateRise: CGFloat = 42
    /// Hauteur d'une carte hors vignette : marges, titre, auteur, filet, matière.
    private static let cardChrome: CGFloat = 210
    private static let maxThumbnail: CGFloat = 196
    private static let minThumbnail: CGFloat = 64

    /// Height left for the deck once the title and the buttons have taken theirs.
    ///
    /// The card is as wide as the page; its height is the thumbnail plus a fixed block of
    /// text, so the thumbnail is what shrinks on a short screen.
    private func deckHeight(in geo: GeometryProxy) -> CGFloat {
        let chrome: CGFloat = geo.size.height < 620 ? 190 : 218
        let byHeight: CGFloat = geo.size.height - chrome
        let tallest: CGFloat = Self.plateRise + Self.cardChrome + Self.maxThumbnail
        let shortest: CGFloat = Self.plateRise + Self.cardChrome + Self.minThumbnail
        return max(min(byHeight, tallest), shortest)
    }

    /// La pile : le bord d'une carte par cours qui attend dessous (il dépasse en haut, de plus
    /// en plus étroit et pâle), la carte suivante juste sous celle du dessus, et la carte du
    /// dessus, qui suit le doigt. À chaque réponse, c'est le bord le plus proche qui rentre sous
    /// la carte du dessus (il devient la carte suivante) ; les bords plus lointains gardent leur
    /// place et leur taille. La pile s'amincit donc par l'avant, jusqu'à la dernière carte, seule.
    private func deck(width: CGFloat, height: CGFloat) -> some View {
        let cardHeight: CGFloat = height - Self.plateRise
        let thumbnail: CGFloat = min(Self.maxThumbnail, max(Self.minThumbnail, cardHeight - Self.cardChrome))
        let remaining: Int = max(courses.count - index, 0)
        // Cartes qui attendent sous celle du dessus.
        let waiting: Int = min(max(remaining - 1, 0), Self.maxPlates)
        // Le bord le plus lointain de la pile entière, fixe pendant tout l'écran.
        let deepest: Int = min(max(courses.count - 1, 0), Self.maxPlates)
        return ZStack(alignment: .top) {
            // De la plus lointaine à la plus proche, pour que chacune recouvre la précédente.
            ForEach(0..<Self.maxPlates, id: \.self) { slot in
                let depth: Int = Self.maxPlates - slot
                // Les bords restants sont les plus lointains : `deepest` est le fond de la
                // pile au départ, et chaque réponse retire le bord le plus proche.
                let present: Bool = depth <= deepest && depth > deepest - waiting
                plate(width: width - CGFloat(depth) * Self.plateInset, depth: depth)
                    .offset(y: present ? Self.plateRise - CGFloat(depth) * Self.plateStep : Self.plateRise)
                    .opacity(present ? 1 : 0)
            }
            ForEach(Array(courses.enumerated()), id: \.element.id) { i, course in
                if i >= index, i < index + 2 {
                    let depth = i - index
                    courseCard(course, width: width, height: cardHeight, thumbnail: thumbnail, isTop: depth == 0)
                        .offset(y: Self.plateRise)
                        .offset(x: depth == 0 ? drag.width : 0, y: depth == 0 ? drag.height * 0.2 : 0)
                        .rotationEffect(.degrees(depth == 0 ? Double(drag.width / 18) : 0))
                        .zIndex(Double(courses.count - i))
                        .allowsHitTesting(depth == 0)
                        .highPriorityGesture(dragGesture, including: depth == 0 ? .all : .subviews)
                        // VoiceOver annonce où l'on en est dans la pile (« 3 / 8 »).
                        .accessibilityValue(Text(verbatim: "\(i + 1) / \(courses.count)"))
                        .animation(DSCalmMotion.state, value: index)
                }
            }
        }
        .frame(width: width, height: height, alignment: .top)
        .animation(DSCalmMotion.reveal, value: remaining)
    }

    /// Le bord d'une carte qui attend sous la pile ; `depth` vaut 1 pour la plus proche.
    private func plate(width: CGFloat, depth: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
        // Plus la carte est loin, plus elle est pâle. Le fond opaque évite que les bleus
        // des cartes empilées ne s'additionnent.
        let strength: Double = max(0.06, 0.24 - Double(depth - 1) * 0.028)
        return shape
            .fill(DS.canvas)
            .overlay(shape.fill(DS.accent.opacity(strength)))
            .overlay(shape.strokeBorder(Self.cardBorder, lineWidth: 1))
            .frame(width: max(width, 0), height: 60)
            .accessibilityHidden(true)
    }

    /// Une carte de cours : vignette, titre, auteur quand il est connu, filet, matière.
    private func courseCard(_ course: Course, width: CGFloat, height: CGFloat, thumbnail: CGFloat, isTop: Bool) -> some View {
        VStack(spacing: 0) {
            cover(course, side: thumbnail)

            Text(course.title)
                .font(DS.title(.title3, .bold))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.top, 18)

            if let author = authorNames[course.id] {
                Text(author)
                    .font(DS.sans(.subheadline, .regular))
                    .foregroundStyle(OV2.inkSecondary)
                    .lineLimit(1)
                    .padding(.top, 6)
            }

            Spacer(minLength: 8)

            Rectangle()
                .fill(Self.cardBorder)
                .frame(height: 1.5)

            HStack(spacing: 8) {
                OV2CoreSubjectBadge(subject: course.subject, size: 24)
                Text(course.subject.localizedShortName(language: languageManager.current))
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(OV2.ink)
                    .lineLimit(1)
            }
            .padding(.top, 14)
        }
        .padding(.top, 26)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(width: width, height: height)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .fill(DS.accentTint)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(Self.cardBorder, lineWidth: 1.5)
        )
        .overlay(alignment: .top) {
            if isTop { likeStamp }
        }
        .contentShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .accessibilityElement(children: .combine)
        // La carte suivante attend sous celle du dessus : VoiceOver ne lit que celle du dessus.
        .accessibilityHidden(!isTop)
    }

    /// Filet et bordure de la carte : le bleu d'accent, très dilué.
    private static let cardBorder: Color = DS.accent.opacity(0.28)

    /// La couverture du cours en vignette carrée ; à défaut, un dégradé à la couleur de la
    /// matière.
    private func cover(_ course: Course, side: CGFloat) -> some View {
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
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: OV2.ink.opacity(0.16), radius: 12, y: 8)
        .accessibilityHidden(true)
    }

    /// Nom de l'auteur de chaque cours du paquet, quand le catalogue le connaît. Calculé une
    /// fois : la carte est redessinée à chaque mouvement du doigt.
    private static func resolveAuthorNames(for courses: [Course]) -> [String: String] {
        var names: [String: String] = [:]
        for course in courses {
            if let author = AuthorStore.author(forCourseId: course.id) {
                names[course.id] = author.name
            }
        }
        return names
    }

    @ViewBuilder
    private var likeStamp: some View {
        let liking = drag.width > 0
        let intensity = min(1, abs(drag.width) / 110)
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
        .padding(14)
        .accessibilityHidden(true)
    }

    private func stamp(text: String, color: Color) -> some View {
        Text(text.uppercasedInApp())
            .font(DS.title(.title3, .heavy))
            .foregroundStyle(color)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(DS.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(color, lineWidth: 2.5))
            .rotationEffect(.degrees(drag.width > 0 ? -12 : 12))
    }

    private func completionView(height: CGFloat) -> some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(OV2.success.opacity(0.12))
                if checkIn {
                    // La coche se dessine en arrivant.
                    DSCheckBadge(size: 76)
                }
            }
            .frame(width: 120, height: 120)

            Text(languageManager.text("onboardingV2.swipe.noted"))
                .font(DS.title(.title2, .semibold))
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
                    // La carte revient à sa place sans la dépasser.
                    withAnimation(.spring(response: 0.35, dampingFraction: 1)) { drag = .zero }
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
            withAnimation(DSCalmMotion.reveal) { done = true }
            OnboardingHaptics.counterComplete()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(DSCalmMotion.settle) { checkIn = true }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard !hasAdvanced else { return }
            hasAdvanced = true
            onNext()
        }
    }

    // MARK: - Boutons

    /// « Pas pour moi » en gris, « Ça m'intéresse » en bleu ; celui vers lequel la carte est
    /// tirée grossit légèrement.
    private var buttons: some View {
        let pull: CGFloat = min(1, abs(drag.width) / 110)
        let liking: Bool = drag.width > 0
        return HStack(spacing: 22) {
            swipeButton(
                systemName: "hand.thumbsdown",
                label: languageManager.text("onboardingV2.swipe.nope"),
                fill: OV2.hairline,
                tint: OV2.ink
            ) { swipeTop(like: false) }
            .scaleEffect(1 + (liking ? 0 : 0.12 * pull))

            swipeButton(
                systemName: "hand.thumbsup",
                label: languageManager.text("onboardingV2.swipe.like"),
                fill: OV2.accent,
                tint: .white
            ) { swipeTop(like: true) }
            .scaleEffect(1 + (liking ? 0.12 * pull : 0))
        }
    }

    private func swipeButton(systemName: String, label: String, fill: Color, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: Self.buttonSize, height: Self.buttonSize)
                .background(Circle().fill(fill))
                .contentShape(Circle())
        }
        // Pas de vibration de style : `swipeTop` déclenche déjà celle de la validation.
        .buttonStyle(PressableStyle(scale: 0.9, haptic: false))
        .accessibilityLabel(Text(label))
    }
}
