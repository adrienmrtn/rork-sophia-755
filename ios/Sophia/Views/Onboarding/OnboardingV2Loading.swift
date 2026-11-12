import SwiftUI
import UIKit

/// « On prépare ton parcours de connaissances » : trois étapes qui se chargent l'une après
/// l'autre comme un vrai chargement (vite au début, de plus en plus lentement vers la fin,
/// chacune à son rythme) et se cochent, une carte qui pose une question pendant l'attente,
/// puis la preuve sociale : des utilisateurs en photo, les étoiles et la note,
/// « 500 000 utilisateurs lisent des cours sur Sophia tous les mois », et le CTA
/// « voir mon profil ».
struct OnboardingV2Loading: View {
    @Environment(LanguageManager.self) private var languageManager
    var firstName: String = ""
    let onNext: () -> Void

    @State private var progress: [Double] = [0, 0, 0]
    @State private var completed: [Bool] = [false, false, false]
    @State private var allDone = false
    @State private var animTask: Task<Void, Never>?
    @State private var photos: [UIImage] = []
    /// Réponse à la carte « Aimes-tu apprendre en écoutant ? » ; nil tant que rien n'est choisi.
    /// Elle n'arrête ni n'accélère le chargement.
    @State private var listens: Bool?
    /// Départ, durée et valeur de départ de la barre de chaque étape : de quoi afficher un
    /// pourcentage qui défile avec elle. `nil` tant que l'étape n'a pas commencé.
    @State private var stepStarts: [Date?] = [nil, nil, nil]
    @State private var stepSpans: [Double] = [0, 0, 0]
    @State private var stepOrigins: [Double] = [0, 0, 0]

    /// Durée de chaque barre : trois chargements différents, comme trois vraies étapes.
    private static let durations: [Double] = [1.3, 2.2, 1.6]

    private var stepKeys: [String] {
        ["onboardingV2.loading.step1", "onboardingV2.loading.step2", "onboardingV2.loading.step3"]
    }

    /// L'étape en cours : la première qui n'est pas cochée.
    private var activeStep: Int? {
        completed.firstIndex(of: false)
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
        // Trois étapes, la carte question, les photos et deux phrases : trop haut pour un
        // petit iPhone en grande taille de texte. Défile, avec le bouton épinglé.
        OV2ScrollableContent {
            VStack(spacing: 0) {
                DSHighlightTitle(text: titleText, style: .title, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, OV2End.top)
                    .dsStagger(0)

                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { i in
                        stepRow(i)
                    }
                }
                .padding(.top, 10)
                .dsStagger(1)

                OV2EndDottedLine()
                    .stroke(DS.inkTertiary.opacity(0.7), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.5, 6]))
                    .frame(width: 2, height: 30)
                    .padding(.vertical, 10)
                    .dsStagger(2)
                    .accessibilityHidden(true)

                questionCard
                    .dsStagger(3)

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
        .ov2Background()
        .onAppear {
            if photos.isEmpty { photos = Array(OnboardingStudentPhotos.load().prefix(5)) }
            startLoading()
        }
        .onDisappear { animTask?.cancel() }
    }

    // MARK: - Étapes

    /// Une étape : son nom, et à droite une coche bleue (terminée), le pourcentage (en cours,
    /// avec la barre dessous) ou un rond vide (à venir).
    private func stepRow(_ i: Int) -> some View {
        let isDone: Bool = completed[i]
        let isActive: Bool = activeStep == i
        return VStack(spacing: 10) {
            HStack(spacing: 12) {
                Text(languageManager.text(stepKeys[i]))
                    .font(DS.sans(.callout, .semibold))
                    .foregroundStyle(isDone || isActive ? DS.ink : DS.inkSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                stepStatus(i, isDone: isDone, isActive: isActive)
            }
            .frame(minHeight: 24)

            if isActive {
                LoadingBar(value: progress[i])
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 16)
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
    private func stepStatus(_ i: Int, isDone: Bool, isActive: Bool) -> some View {
        if isDone {
            DSCheckBadge(size: 24, fill: DS.accent)
                .transition(.scale.combined(with: .opacity))
        } else if isActive {
            LoadingPercent(
                start: stepStarts[i],
                span: stepSpans[i],
                origin: stepOrigins[i],
                locale: languageManager.locale
            )
        } else {
            Circle()
                .strokeBorder(DS.hairline, lineWidth: 1.5)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Carte question

    /// Une question posée pendant le chargement. On peut y répondre ou non : les étapes
    /// continuent de toute façon et le bouton du bas s'active à la fin.
    private var questionCard: some View {
        VStack(spacing: 6) {
            Text(languageManager.text("onboardingV2.loading.question.eyebrow"))
                .font(DS.sans(.footnote, .regular))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
            Text(languageManager.text("onboardingV2.loading.question.title"))
                .font(DS.sans(.body, .bold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                answerButton(titleKey: "onboardingV2.loading.question.no", value: false)
                answerButton(titleKey: "onboardingV2.loading.question.yes", value: true)
            }
            .padding(.top, 10)
        }
        .padding(EdgeInsets(top: 18, leading: 16, bottom: 16, trailing: 16))
        .frame(maxWidth: .infinity)
        .ov2EndCard()
    }

    private func answerButton(titleKey: String, value: Bool) -> some View {
        let selected: Bool = listens == value
        return Button {
            guard listens != value else { return }
            Haptics.select()
            withAnimation(DS.Motion.snappy) { listens = value }
        } label: {
            Text(languageManager.text(titleKey))
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(selected ? DS.accent : DS.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
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

    /// Les trois étapes sont une mise en scène (aucun réseau, aucune dépendance) : le CTA
    /// doit donc **toujours** finir par s'activer. C'est la page que l'App Store décrirait
    /// comme « indefinite loading » si elle restait bloquée, alors elle reprend là où elle
    /// s'était arrêtée quand la page réapparaît, et l'interruption elle-même débloque le CTA.
    private func startLoading() {
        guard !allDone else { return }
        animTask?.cancel()
        animTask = Task { @MainActor in
            await playSteps()
            withAnimation(.easeInOut(duration: 0.3)) { allDone = true }
        }
    }

    /// Chaque barre part vite et ralentit en approchant du bout (courbe en exponentielle
    /// inversée), sur sa propre durée ; la suivante démarre quand la précédente est cochée.
    private func playSteps() async {
        for i in 0..<3 where !completed[i] {
            let remaining = Self.durations[i] * (1 - progress[i])
            // Repères du pourcentage affiché à côté de la barre (affichage seulement).
            stepOrigins[i] = progress[i]
            stepSpans[i] = remaining
            stepStarts[i] = Date()
            withAnimation(.timingCurve(0.05, 0.75, 0.3, 1.0, duration: remaining)) { progress[i] = 1 }
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000) + 80_000_000)
            if Task.isCancelled { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { completed[i] = true }
            OnboardingHaptics.loadingStepComplete(step: i)
            try? await Task.sleep(nanoseconds: 180_000_000)
        }
    }
}

// MARK: - Barre et pourcentage

/// Barre de l'étape en cours. Elle ne porte aucune animation propre : c'est la courbe du
/// chargement (`playSteps`) qui la remplit, sur la durée de l'étape.
private struct LoadingBar: View {
    let value: Double

    var body: some View {
        GeometryReader { geo in
            let clamped: Double = min(max(value, 0.0), 1.0)
            let width: CGFloat = max(8, geo.size.width * CGFloat(clamped))
            ZStack(alignment: .leading) {
                Capsule().fill(DS.accentTint)
                Capsule()
                    .fill(DS.accent)
                    .frame(width: width)
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}

/// Pourcentage de l'étape en cours. Il est recalculé à chaque image à partir du départ et
/// de la durée de l'étape, sur la même courbe que la barre : le nombre défile avec elle au
/// lieu de sauter de 0 à 100.
private struct LoadingPercent: View {
    let start: Date?
    let span: Double
    let origin: Double
    let locale: Locale

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: false)) { context in
            Text(verbatim: text(at: context.date))
                .font(DS.sans(.footnote, .medium))
                .foregroundStyle(DS.inkSecondary)
                .monospacedDigit()
        }
    }

    private func text(at date: Date) -> String {
        let value: Double = min(max(fraction(at: date), 0.0), 1.0)
        return value.formatted(.percent.precision(.fractionLength(0)).locale(locale))
    }

    private func fraction(at date: Date) -> Double {
        guard let start, span > 0 else { return origin }
        let elapsed: Double = date.timeIntervalSince(start)
        let time: Double = min(max(elapsed / span, 0.0), 1.0)
        let eased: Double = LoadingCurve.value(at: time)
        return origin + (1.0 - origin) * eased
    }
}

/// La courbe de remplissage des barres, `timingCurve(0.05, 0.75, 0.3, 1.0)`, évaluée à la
/// main pour le pourcentage : une Bézier cubique de (0, 0) à (1, 1).
private enum LoadingCurve {
    /// Avancement (0 à 1) à l'instant `time` (0 à 1).
    static func value(at time: Double) -> Double {
        let target: Double = min(max(time, 0.0), 1.0)
        // L'abscisse de la courbe est croissante : on cherche son paramètre par dichotomie.
        var low: Double = 0.0
        var high: Double = 1.0
        for _ in 0..<24 {
            let mid: Double = (low + high) / 2.0
            if bezier(mid, first: 0.05, second: 0.3) < target {
                low = mid
            } else {
                high = mid
            }
        }
        let parameter: Double = (low + high) / 2.0
        return bezier(parameter, first: 0.75, second: 1.0)
    }

    /// Coordonnée d'une Bézier cubique allant de 0 à 1, de points de contrôle `first` et `second`.
    private static func bezier(_ s: Double, first: Double, second: Double) -> Double {
        let inverse: Double = 1.0 - s
        let a: Double = 3.0 * inverse * inverse * s * first
        let b: Double = 3.0 * inverse * s * s * second
        let c: Double = s * s * s
        return a + b + c
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
