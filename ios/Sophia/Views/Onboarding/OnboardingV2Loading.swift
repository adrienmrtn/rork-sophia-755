import SwiftUI
import UIKit

/// « On prépare ton parcours de connaissances » : un chargement qui **s'arrête quatre fois**
/// pour poser une question.
///
/// La barre avance, s'arrête net à un point fixé d'avance (18 %, 41 %, 63 % puis 86 %), une
/// carte pose une question à laquelle on répond par oui ou par non, et la barre ne repart
/// qu'une fois la réponse donnée. Après la quatrième réponse elle va au bout, les trois étapes
/// sont cochées, la preuve sociale s'allume (photos, étoiles, « 500 000 utilisateurs ») et le
/// CTA « voir mon profil » s'active.
///
/// À l'arrêt, rien ne ressemble à un chargement resté bloqué : la barre passe à l'ambre avec
/// la pastille « En pause », la carte est cerclée de bleu, la page défile jusqu'à elle et
/// VoiceOver y pose son curseur.
struct OnboardingV2Loading: View {
    @Environment(LanguageManager.self) private var languageManager
    var firstName: String = ""
    let onNext: () -> Void

    /// Avancement global du chargement, de 0 à 1.
    @State private var overall: Double = 0
    /// Réponse à chaque question, dans l'ordre ; nil tant qu'elle n'a pas été donnée.
    @State private var answers: [Bool?] = [nil, nil, nil, nil]
    /// Question posée en ce moment : le chargement est à l'arrêt tant qu'elle est là.
    @State private var waitingFor: Int?
    /// Dernière question montrée dans la carte. Elle y reste, réponse choisie, pendant que le
    /// chargement reprend ; nil tant qu'aucune question n'a été posée (pas de carte).
    @State private var shownQuestion: Int?
    /// Nombre d'étapes dont la fin a déjà été marquée par une vibration.
    @State private var celebratedSteps = 0
    @State private var allDone = false
    @State private var animTask: Task<Void, Never>?
    @State private var photos: [UIImage] = []
    /// Curseur de VoiceOver sur l'intitulé de la question.
    @AccessibilityFocusState private var questionFocused: Bool

    /// Avancement global où le chargement s'arrête pour poser chaque question.
    private static let checkpoints: [Double] = [0.18, 0.41, 0.63, 0.86]
    /// Durée de chaque tronçon : jusqu'à la première question, entre deux questions, puis de
    /// la dernière réponse jusqu'au bout.
    private static let legDurations: [Double] = [1.3, 1.6, 1.5, 1.6, 1.2]
    /// Part de l'avancement global où se termine chacune des trois étapes affichées. Aucun
    /// arrêt ne tombe sur une de ces bornes.
    private static let stepEnds: [Double] = [0.34, 0.70, 1.0]
    /// Identifiant de la carte question, pour faire défiler la page jusqu'à elle.
    private static let questionAnchor = "ov2-loading-question"
    /// Texte de la pastille « En pause » : un ambre assez sombre pour rester lisible.
    private static let pausedInk = Color(red: 0.52, green: 0.36, blue: 0.02)

    private var stepKeys: [String] {
        ["onboardingV2.loading.step1", "onboardingV2.loading.step2", "onboardingV2.loading.step3"]
    }

    /// Les quatre questions, dans l'ordre où elles sont posées.
    private var questionKeys: [String] {
        [
            "onboardingV2.loading.question.q1",
            "onboardingV2.loading.question.q2",
            "onboardingV2.loading.question.q3",
            "onboardingV2.loading.question.q4",
        ]
    }

    /// Nom stable de chaque question dans l'événement d'analyse.
    private static let questionAnalyticsNames: [String] = [
        "reads_daily", "curious", "too_much_phone", "wants_to_remember",
    ]

    private var isPaused: Bool { waitingFor != nil }

    private func isStepDone(_ i: Int) -> Bool {
        overall >= Self.stepEnds[i] - 0.0001
    }

    /// L'étape en cours : la première qui n'est pas terminée.
    private var activeStep: Int? {
        (0..<Self.stepEnds.count).first { !isStepDone($0) }
    }

    private var completedSteps: Int {
        (0..<Self.stepEnds.count).filter { isStepDone($0) }.count
    }

    /// « 41 % », au format de la langue.
    private var percentText: String {
        min(max(overall, 0.0), 1.0).formatted(.percent.precision(.fractionLength(0)).locale(languageManager.locale))
    }

    /// Le titre, avec « parcours de connaissances » en gras bleu dans les langues qui ont la
    /// version balisée ; le titre existant, prénom compris, dans les autres.
    private var titleText: String {
        let language: AppLanguage = languageManager.current
        let plain: String = OnboardingV2ViewModel.personalizedText(
            "onboardingV2.loading.title",
            name: firstName,
            language: language
        )
        let name: String = firstName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "*", with: "")
        if name.isEmpty {
            return OV2End.marked("onboardingV2.loading.titleMarked", fallback: plain, language: language)
        }
        let namedTemplate: String = OV2End.marked("onboardingV2.loading.titleMarkedNamed", fallback: "", language: language)
        if namedTemplate.isEmpty { return plain }
        return namedTemplate.replacingOccurrences(of: "{name}", with: name)
    }

    var body: some View {
        // La barre, trois étapes, la carte question, les photos et deux phrases : trop haut
        // pour un petit iPhone en grande taille de texte. Défile, avec le bouton épinglé ; la
        // page se place d'elle-même sur la carte quand une question arrive.
        ScrollViewReader { scroll in
            OV2ScrollableContent {
                VStack(spacing: 0) {
                    DSHighlightTitle(text: titleText, style: .title, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, OV2End.top)
                        .dsStagger(0)

                    overallProgress
                        .padding(.top, 18)
                        .dsStagger(1)

                    VStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { i in
                            stepRow(i)
                        }
                    }
                    .padding(.top, 6)
                    .animation(DSCalmMotion.state, value: completedSteps)
                    .animation(DSCalmMotion.state, value: isPaused)
                    .dsStagger(2)

                    if let question = shownQuestion {
                        OV2EndDottedLine()
                            .stroke(DS.inkTertiary.opacity(0.7), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.5, 6]))
                            .frame(width: 2, height: 26)
                            .padding(.vertical, 8)
                            .accessibilityHidden(true)
                            .transition(.opacity)

                        questionCard(question)
                            .id(Self.questionAnchor)
                            .transition(.opacity.combined(with: .offset(y: 12)))
                    }

                    socialProof
                        .padding(.top, 26)
                        .opacity(allDone ? 1 : 0.45)
                        .animation(.easeInOut(duration: 0.5), value: allDone)
                }
                .padding(.horizontal, OV2End.side)
                .padding(.bottom, 20)
            } footer: {
                OnboardingV2Button(
                    title: languageManager.text("onboardingV2.loading.cta"),
                    enabled: allDone,
                    action: onNext
                )
            }
            .onChange(of: waitingFor) { _, question in
                guard question != nil else { return }
                // Laisse la carte prendre sa place avant d'y amener la page.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        scroll.scrollTo(Self.questionAnchor, anchor: .center)
                    }
                }
            }
        }
        .ov2Background()
        .onAppear {
            if photos.isEmpty { photos = Array(OnboardingStudentPhotos.load().prefix(5)) }
            startLoading()
        }
        .onDisappear { animTask?.cancel() }
    }

    // MARK: - Avancement global

    /// Le pourcentage et la barre du chargement entier. À l'arrêt, la barre passe à l'ambre
    /// et la pastille « En pause » apparaît : on voit que c'est la question qui retient tout.
    private var overallProgress: some View {
        let pausedText: String = languageManager.text("onboardingV2.loading.paused")
        return VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text(verbatim: percentText)
                    .font(DS.title(.title3, .heavy))
                    .foregroundStyle(DS.ink)
                    .monospacedDigit()
                Spacer(minLength: 8)
                if isPaused {
                    HStack(spacing: 5) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(pausedText)
                            .font(DS.sans(.caption, .bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(Self.pausedInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule(style: .continuous).fill(DS.warm.opacity(0.24)))
                    .transition(.opacity)
                }
            }
            .frame(minHeight: 28)

            LoadingBar(value: overall, paused: isPaused)
        }
        .animation(DSCalmMotion.state, value: isPaused)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(OV2Markup.plain(titleText)))
        .accessibilityValue(Text(verbatim: isPaused ? percentText + ", " + pausedText : percentText))
    }

    // MARK: - Étapes

    /// Une étape : son nom, et à droite une coche bleue (terminée), un indicateur (en cours :
    /// il tourne, ou marque la pause quand une question attend) ou un rond vide (à venir).
    private func stepRow(_ i: Int) -> some View {
        let isDone: Bool = isStepDone(i)
        let isActive: Bool = activeStep == i
        return HStack(spacing: 12) {
            Text(languageManager.text(stepKeys[i]))
                .font(DS.sans(.callout, .semibold))
                .foregroundStyle(isDone || isActive ? DS.ink : DS.inkSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            stepStatus(isDone: isDone, isActive: isActive)
        }
        .frame(minHeight: 24)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            if i < 2 {
                Rectangle()
                    .fill(DS.hairline.opacity(0.75))
                    .frame(height: 1.5)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(isDone ? languageManager.text("onboardingV2.loading.stepDone") : ""))
    }

    @ViewBuilder
    private func stepStatus(isDone: Bool, isActive: Bool) -> some View {
        if isDone {
            DSCheckBadge(size: 24, fill: DS.accent)
                .transition(.opacity)
        } else if isActive, isPaused {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(DS.warm)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
                .transition(.opacity)
        } else if isActive {
            ProgressView()
                .controlSize(.small)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
                .transition(.opacity)
        } else {
            Circle()
                .strokeBorder(DS.hairline, lineWidth: 1.5)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Carte question

    /// La question qui retient le chargement. Tant qu'elle attend sa réponse, la carte est
    /// cerclée de bleu ; une fois la réponse donnée, elle reste en place, estompée, jusqu'à
    /// ce que la question suivante la remplace.
    private func questionCard(_ question: Int) -> some View {
        let isWaiting: Bool = waitingFor == question
        return VStack(spacing: 6) {
            questionDots(current: question)
                .padding(.bottom, 4)

            Text(languageManager.text("onboardingV2.loading.question.eyebrow"))
                .font(DS.sans(.footnote, .regular))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)

            Text(languageManager.text(questionKeys[question]))
                .font(DS.sans(.body, .bold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($questionFocused)
                .id(question)
                .transition(.opacity)

            HStack(spacing: 10) {
                answerButton(titleKey: "onboardingV2.loading.question.no", value: false, question: question)
                answerButton(titleKey: "onboardingV2.loading.question.yes", value: true, question: question)
            }
            .padding(.top, 10)
            .disabled(!isWaiting)
        }
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        .frame(maxWidth: .infinity)
        .ov2EndCard(border: isWaiting ? DS.accent : DS.hairline)
        .opacity(isWaiting ? 1 : 0.55)
        .animation(DSCalmMotion.state, value: isWaiting)
        .accessibilityElement(children: .contain)
    }

    /// Quatre points : les questions déjà répondues et celle en cours en bleu, les autres en gris.
    private func questionDots(current: Int) -> some View {
        HStack(spacing: 5) {
            ForEach(0..<Self.checkpoints.count, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index <= current ? DS.accent : DS.hairline)
                    .frame(width: index == current ? 16 : 6, height: 6)
            }
        }
        .animation(DSCalmMotion.state, value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(current + 1) / \(Self.checkpoints.count)"))
    }

    private func answerButton(titleKey: String, value: Bool, question: Int) -> some View {
        let selected: Bool = answers[question] == value
        return Button {
            answer(value, to: question)
        } label: {
            Text(languageManager.text(titleKey))
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(selected ? DS.accent : DS.ink)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .dsOptionCard(selected ? .selected : .idle, cornerRadius: 14)
        }
        .buttonStyle(PressableStyle(haptic: false))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - Preuve sociale

    /// Photos, étoiles et note, « 500 000 utilisateurs », puis la phrase et l'invitation.
    private var socialProof: some View {
        VStack(spacing: 6) {
            if !photos.isEmpty {
                OnboardingV2PhotoRow(photos: photos, size: 36)
                    .padding(.bottom, 6)
            }
            HStack(spacing: 8) {
                OV2EndStars(size: 17, baseDelay: 0.4)
                Text(verbatim: ratingText)
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(DS.ink)
            }
            Text(languageManager.text("onboardingV2.loading.social.count"))
                .font(DS.title(.title3, .heavy))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
            Text(languageManager.text("onboardingV2.loading.social.body"))
                .font(DS.sans(.subheadline, .regular))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(languageManager.text("onboardingV2.loading.social.join"))
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    /// « 4,8 » au séparateur décimal de la langue.
    private var ratingText: String {
        (4.8).formatted(.number.precision(.fractionLength(1)).locale(languageManager.locale))
    }

    // MARK: - Chargement

    /// Le chargement est une mise en scène (aucun réseau, aucune dépendance) : il n'attend
    /// jamais rien d'autre que les quatre réponses, et finit donc **toujours** par activer le
    /// CTA une fois la dernière donnée. C'est la page que l'App Store décrirait comme
    /// « indefinite loading » si elle semblait bloquée : à l'arrêt, c'est la question qui est
    /// mise en avant (barre en pause, carte cerclée, page amenée dessus), et la page reprend
    /// là où elle en était quand elle réapparaît.
    private func startLoading() {
        // Une question attend : c'est la réponse qui relancera le chargement.
        guard !allDone, waitingFor == nil else { return }
        animTask?.cancel()
        animTask = Task { @MainActor in
            await runLoading()
        }
    }

    /// Avance jusqu'au prochain arrêt et y pose sa question ; sans question restante, va au
    /// bout et active le CTA.
    private func runLoading() async {
        if let question = answers.firstIndex(where: { $0 == nil }) {
            let legStart: Double = question == 0 ? 0 : Self.checkpoints[question - 1]
            await advance(from: legStart, to: Self.checkpoints[question], duration: Self.legDurations[question])
            if Task.isCancelled { return }
            ask(question)
            return
        }

        let lastCheckpoint: Double = Self.checkpoints[Self.checkpoints.count - 1]
        await advance(from: lastCheckpoint, to: 1, duration: Self.legDurations[Self.legDurations.count - 1])
        if Task.isCancelled { return }
        withAnimation(.easeInOut(duration: 0.3)) { allDone = true }
    }

    /// Fait avancer la barre jusqu'à `target`, vite au début puis de plus en plus lentement,
    /// pour qu'elle s'y pose exactement. `duration` est celle du tronçon entier (de `legStart`
    /// à `target`) : une reprise en cours de route ne dure que ce qu'il en reste.
    private func advance(from legStart: Double, to target: Double, duration: Double) async {
        let origin: Double = overall
        guard target > origin else { return }
        let legLength: Double = max(target - legStart, 0.0001)
        let span: Double = max(duration * (target - origin) / legLength, 0.05)
        let started: Date = Date()

        while !Task.isCancelled {
            let time: Double = min(Date().timeIntervalSince(started) / span, 1.0)
            let eased: Double = 1.0 - (1.0 - time) * (1.0 - time)
            overall = origin + (target - origin) * eased
            celebrateFinishedSteps()
            if time >= 1.0 { break }
            try? await Task.sleep(for: .milliseconds(33))
        }
        if Task.isCancelled { return }
        overall = target
        celebrateFinishedSteps()
    }

    /// Une vibration à la fin de chaque étape, une seule fois.
    private func celebrateFinishedSteps() {
        let done: Int = completedSteps
        guard done > celebratedSteps else { return }
        for step in celebratedSteps..<done {
            OnboardingHaptics.loadingStepComplete(step: step)
        }
        celebratedSteps = done
    }

    /// Arrête le chargement sur la question `question` : la carte apparaît (ou change de
    /// question) et VoiceOver y est amené.
    private func ask(_ question: Int) {
        overall = Self.checkpoints[question]
        withAnimation(DSCalmMotion.reveal) {
            shownQuestion = question
            waitingFor = question
        }
        Haptics.soft()
        Task { @MainActor in
            // Le temps que la carte soit en place et la page amenée dessus.
            try? await Task.sleep(for: .milliseconds(500))
            guard waitingFor == question else { return }
            questionFocused = true
        }
    }

    /// Enregistre la réponse, la laisse voir un instant, puis relance le chargement.
    private func answer(_ value: Bool, to question: Int) {
        guard waitingFor == question, answers[question] == nil else { return }
        Haptics.select()
        withAnimation(DSCalmMotion.state) { answers[question] = value }
        AnalyticsService.shared.log(
            .onboardingStep,
            props: [
                "step": .string("loading_question"),
                "question": .string(Self.questionAnalyticsNames[question]),
                "answer": .bool(value),
            ]
        )
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(380))
            withAnimation(DSCalmMotion.state) { waitingFor = nil }
            startLoading()
        }
    }
}

// MARK: - Barre

/// Barre du chargement entier. Elle ne porte aucune animation de largeur : c'est
/// `OnboardingV2Loading.advance` qui la remplit, image par image. En pause, elle passe à
/// l'ambre.
private struct LoadingBar: View {
    let value: Double
    var paused: Bool = false

    var body: some View {
        GeometryReader { geo in
            let clamped: Double = min(max(value, 0.0), 1.0)
            let width: CGFloat = max(10, geo.size.width * CGFloat(clamped))
            ZStack(alignment: .leading) {
                Capsule().fill(DS.accentTint)
                Capsule()
                    .fill(paused ? DS.warm : DS.accent)
                    .frame(width: width)
            }
        }
        .frame(height: 10)
        .accessibilityHidden(true)
    }
}

/// Trait vertical, tracé en pointillés entre les étapes et la carte question.
private struct OV2EndDottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}
