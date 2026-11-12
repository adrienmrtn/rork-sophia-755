import SwiftUI
import UIKit

/// Briques du design « Elevate arrondi » propres à la zone « cours » : lecteur, quiz du cours,
/// fin de cours, série, entraînement et lecteur audio. Les briques communes à toute l'app
/// vivent dans `ElevateKit.swift` ; ici, seulement ce que ces écrans partagent entre eux
/// (le quiz et l'entraînement dessinent leurs questions avec les mêmes pièces).

// MARK: - Couleurs et typographie

/// Les tons « or » des récompenses (XP, combo, étoiles, trophée) et le vert foncé du verdict :
/// des couleurs porteuses de sens, communes au quiz, au résultat, à la fin de cours et à la série.
enum CoursePalette {
    /// Safran des barres d'XP, des étoiles et de la flamme (#E6B233).
    static let gold: Color = DS.warm
    /// Or soutenu des pictogrammes (#B17F10).
    static let goldDeep = Color(red: 0.694, green: 0.498, blue: 0.063)
    /// Fond pâle des pastilles d'XP et de combo (#FBEFC9).
    static let goldTint = Color(red: 0.984, green: 0.937, blue: 0.788)
    /// Texte des pastilles d'XP et de combo (#6B4E00).
    static let goldInk = Color(red: 0.420, green: 0.306, blue: 0.0)
    /// Texte d'une bonne réponse et titre d'un verdict réussi (#1F4D36).
    static let successInk = Color(red: 0.122, green: 0.302, blue: 0.212)
    /// Piste neutre des barres de progression.
    static let track: Color = DS.ink.opacity(0.12)
}

/// Plus Jakarta Sans à une taille précise de maquette, toujours relative à un style de texte
/// pour suivre la taille de police choisie par l'utilisateur.
enum CourseType {
    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        Font.custom("Plus Jakarta Sans", size: size, relativeTo: style).weight(weight)
    }
}

// MARK: - Boutons

/// Pastille ronde blanche bordée (fermer, options, écouter) : le contenu d'un bouton d'en-tête.
struct CourseRoundIcon: View {
    let systemName: String
    var size: CGFloat = 44
    var tint: Color = DS.ink

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.36, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(DS.surface, in: Circle())
            .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
            .contentShape(Circle())
    }
}

/// Le CTA bleu du style, sans vibration propre : pour les boutons dont l'action choisit
/// elle-même son retour haptique (le « Continuer » du lecteur vibre plus fort à un
/// changement de section qu'à un simple passage).
struct CourseCTAStyle: ButtonStyle {
    var fill: Color = DS.accent
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.sans(.headline, .semibold))
            .foregroundStyle(foreground)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous).fill(fill)
            )
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(DS.Motion.press, value: configuration.isPressed)
    }
}

// MARK: - Pastilles

/// Pastille dorée : « +10 XP gagnés », « +12 XP ».
struct CourseGoldPill: View {
    let text: String
    var systemImage: String? = nil
    var font: Font = DS.sans(.footnote, .heavy)

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(CoursePalette.goldDeep)
            }
            Text(text)
                .font(font)
                .monospacedDigit()
                .foregroundStyle(CoursePalette.goldInk)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(CoursePalette.goldTint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Pastille de combo du quiz : une petite flamme et « x3 ». La flamme rebondit à chaque
/// bonne réponse de plus.
struct CourseQuizComboPill: View {
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(CoursePalette.goldDeep)
                .symbolEffect(.bounce, value: count)
            Text("x\(count)")
                .font(DS.sans(.footnote, .heavy))
                .monospacedDigit()
                .foregroundStyle(CoursePalette.goldInk)
                .contentTransition(.numericText(value: Double(count)))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(CoursePalette.goldTint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Matière

/// La vignette ronde d'une matière : son illustration (`badge_subject_…`), sinon son
/// pictogramme sur fond teinté.
struct CourseSubjectAvatar: View {
    let subject: Subject
    var size: CGFloat = 36

    private var assetName: String {
        switch subject {
        case .histoire: return "badge_subject_histoire"
        case .sciences: return "badge_subject_sciences"
        case .litterature: return "badge_subject_litterature"
        case .art: return "badge_subject_art"
        case .mythologie: return "badge_subject_mythologie"
        case .comprendreLeMonde: return "badge_subject_comprendreLeMonde"
        }
    }

    var body: some View {
        Group {
            if let image = UIImage(named: assetName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                SubjectBadgeView(subject: subject, iconSize: size * 0.9, cornerRadius: size / 2)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

// MARK: - Coche dessinée

private struct CourseCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.05))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.maxY - rect.height * 0.08))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.12))
        return path
    }
}

/// Une coche qui se dessine, de la couleur voulue (la coche verte du panneau de verdict).
/// Apparaît d'un coup avec « Réduire les animations ».
struct CourseDrawnCheck: View {
    var color: Color = DS.success
    var lineWidth: CGFloat = 2.6
    var delay: Double = 0
    @State private var drawn = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        CourseCheckShape()
            .trim(from: 0, to: drawn ? 1 : 0)
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .onAppear {
                guard !drawn else { return }
                if reduceMotion {
                    drawn = true
                } else {
                    withAnimation(.easeOut(duration: 0.32).delay(delay)) { drawn = true }
                }
            }
            .accessibilityHidden(true)
    }
}

/// Pastille rouge avec une croix : la mauvaise réponse.
struct CourseQuizCrossBadge: View {
    var size: CGFloat = 26

    var body: some View {
        Image(systemName: "xmark")
            .font(.system(size: size * 0.42, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(DS.danger, in: Circle())
            .dsPopIn()
            .accessibilityHidden(true)
    }
}

// MARK: - Quiz : en-tête

/// Haut d'un quiz : fermer, progression en segments, pastille de combo.
struct CourseQuizTopBar: View {
    let total: Int
    /// Nombre de segments remplis (la question en cours comprise).
    let filled: Int
    let closeLabel: String
    /// « Question 2 sur 8 », lu par VoiceOver sur la barre.
    let progressLabel: String
    /// Combo en cours ; la pastille n'apparaît qu'à partir de 2.
    var combo: Int = 0
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                CourseRoundIcon(systemName: "xmark")
            }
            .buttonStyle(.pressable)
            .accessibilityLabel(Text(closeLabel))

            progress
                .accessibilityLabel(Text(progressLabel))

            if combo >= 2 {
                CourseQuizComboPill(count: combo)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    /// Un segment par question ; au-delà de seize, une barre continue (une longue session
    /// d'entraînement donnerait des pointillés).
    @ViewBuilder
    private var progress: some View {
        if total <= 16 {
            DSSegmentedProgress(total: total, filled: filled)
        } else {
            DSProgressBar(
                value: Double(filled) / Double(max(total, 1)),
                height: 6,
                track: DS.hairline.opacity(0.75)
            )
        }
    }
}

/// L'énoncé : sur-titre « MATIÈRE · QUESTION n SUR N » avec la vignette de la matière, puis
/// la question centrée en graisse légère (les passages entre `**` en gras bleu).
struct CourseQuizQuestionHeader: View {
    let subject: Subject
    let eyebrow: String
    let question: String
    /// Ligne discrète sous le sur-titre (le cours d'où vient la question, à l'entraînement).
    var caption: String? = nil

    private var questionSize: CGFloat {
        if question.count > 120 { return 20 }
        if question.count > 70 { return 23 }
        return 26
    }

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    CourseSubjectAvatar(subject: subject, size: 20)
                    Text(eyebrow.uppercasedInApp())
                        .font(DS.sans(.caption, .heavy))
                        .tracking(0.8)
                        .foregroundStyle(DS.accent)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                if let caption, !caption.isEmpty {
                    Text(caption)
                        .font(DS.sans(.footnote, .medium))
                        .foregroundStyle(DS.inkSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }

            questionText
                .font(CourseType.font(questionSize, .regular, relativeTo: .title2))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity)
    }

    private var questionText: Text {
        let parts: [String] = question.components(separatedBy: "**")
        var result = Text("")
        for (index, part) in parts.enumerated() where !part.isEmpty {
            if index % 2 == 1 {
                result = result + Text(part).fontWeight(.bold).foregroundColor(DS.accent)
            } else {
                result = result + Text(part)
            }
        }
        return result
    }
}

// MARK: - Quiz : réponses

private extension DSOptionState {
    /// Couleur du texte d'une carte de réponse selon son état.
    var courseTextColor: Color {
        switch self {
        case .idle, .selected: return DS.ink
        case .correct: return CoursePalette.successInk
        case .wrong: return DS.danger
        case .dimmed: return DS.inkSecondary
        }
    }
}

/// Une réponse de QCM : une carte sans lettre. La bonne passe en vert avec une coche qui se
/// dessine, la mauvaise choisie en rouge avec une croix, les autres s'estompent.
struct CourseQuizOptionCard: View {
    let text: String
    let state: DSOptionState

    var body: some View {
        HStack(spacing: 12) {
            Text(text)
                .font(DS.sans(.subheadline, state == .correct ? .bold : .semibold))
                .foregroundStyle(state.courseTextColor)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if state == .correct {
                DSCheckBadge(size: 26)
            } else if state == .wrong {
                CourseQuizCrossBadge(size: 26)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 54)
        .dsOptionCard(state)
        .contentShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
    }
}

/// Une réponse « Vrai » ou « Faux » : deux cartes côte à côte, dans le même style.
struct CourseQuizTrueFalseCard: View {
    let text: String
    /// La carte « Vrai » (première option) porte une coche, l'autre une croix.
    let isTrue: Bool
    let state: DSOptionState

    var body: some View {
        VStack(spacing: 10) {
            icon
                .frame(width: 30, height: 30)
            Text(text)
                .font(DS.sans(.headline, state == .correct ? .bold : .semibold))
                .foregroundStyle(state.courseTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 20)
        .dsOptionCard(state)
        .contentShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .correct:
            DSCheckBadge(size: 30)
        case .wrong:
            CourseQuizCrossBadge(size: 30)
        case .idle, .selected, .dimmed:
            Image(systemName: isTrue ? "checkmark" : "xmark")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(DS.accent)
                .frame(width: 30, height: 30)
                .background(DS.accentTint, in: Circle())
        }
    }
}

// MARK: - Quiz : ordre chronologique

/// Verdict d'une case de la frise une fois la réponse validée.
enum CourseQuizSlotVerdict {
    case pending
    case correct
    case wrong
}

private struct CourseQuizSlotChrome: ViewModifier {
    let filled: Bool
    let state: DSOptionState

    func body(content: Content) -> some View {
        if filled {
            content.dsOptionCard(state)
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                        .strokeBorder(DS.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                )
        }
    }
}

/// Une case numérotée de la question « ordre chronologique » : vide (pointillés), remplie
/// (carte bordée avec sa poignée), puis verte ou rouge une fois la réponse validée.
struct CourseQuizChronoSlotRow: View {
    /// Position dans la frise, à partir de 0.
    let position: Int
    /// Le texte posé dans la case ; nil si elle est vide.
    let text: String?
    let emptyText: String
    let verdict: CourseQuizSlotVerdict

    private var filled: Bool { text != nil }

    private var state: DSOptionState {
        switch verdict {
        case .pending: return .idle
        case .correct: return .correct
        case .wrong: return .wrong
        }
    }

    private var badgeFill: Color {
        switch verdict {
        case .correct: return DS.success
        case .wrong: return DS.danger
        case .pending: return filled ? DS.accentTint : DS.surface
        }
    }

    private var badgeText: Color {
        switch verdict {
        case .correct, .wrong: return .white
        case .pending: return filled ? DS.accent : DS.inkTertiary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("\(position + 1)")
                .font(DS.sans(.footnote, .heavy))
                .foregroundStyle(badgeText)
                .frame(width: 28, height: 28)
                .background(badgeFill, in: Circle())
                .overlay {
                    Circle().strokeBorder(DS.hairline, lineWidth: filled ? 0 : 1)
                }

            Text(text ?? emptyText)
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(filled ? state.courseTextColor : DS.inkTertiary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            trailing
                .frame(width: 22, height: 22)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 56)
        .modifier(CourseQuizSlotChrome(filled: filled, state: state))
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var trailing: some View {
        if !filled {
            Color.clear
        } else if verdict == .correct {
            DSCheckBadge(size: 22)
        } else if verdict == .wrong {
            CourseQuizCrossBadge(size: 22)
        } else {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.inkTertiary)
        }
    }
}

/// Une réponse encore à placer dans la frise.
struct CourseQuizChronoPoolRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(DS.accent)
                .frame(width: 28, height: 28)
                .background(DS.accentTint, in: Circle())

            Text(text)
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 52)
        .dsOptionCard(.idle)
        .contentShape(Rectangle())
    }
}

// MARK: - Quiz : curseur

/// « Ta réponse » / « Bonne réponse » sous le curseur, une fois la réponse validée.
struct CourseQuizSliderResultPill: View {
    let label: String
    let value: String
    let tint: Color
    let fill: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label.uppercasedInApp())
                .font(DS.sans(.caption2, .heavy))
                .tracking(0.6)
                .foregroundStyle(DS.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(fill, in: RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))
    }
}

// MARK: - Quiz : panneau de verdict

/// Ton d'un verdict : tout bon, en partie bon, raté.
enum CourseQuizVerdictTone {
    case success
    case partial
    case failure

    var ink: Color {
        switch self {
        case .success: return CoursePalette.successInk
        case .partial: return DS.accent
        case .failure: return DS.danger
        }
    }

    var tint: Color {
        switch self {
        case .success: return DS.successTint
        case .partial: return DS.accentTint
        case .failure: return DS.dangerTint
        }
    }
}

private struct CourseQuizVerdictIcon: View {
    let tone: CourseQuizVerdictTone

    var body: some View {
        ZStack {
            Circle().fill(tone.tint)
            switch tone {
            case .success:
                CourseDrawnCheck(color: DS.success, lineWidth: 2.6, delay: 0.12)
                    .padding(9)
            case .partial:
                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(DS.accent)
            case .failure:
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(DS.danger)
            }
        }
        .frame(width: 32, height: 32)
        .dsPopIn(delay: 0.05)
        .accessibilityHidden(true)
    }
}

/// Le panneau blanc qui monte du bas après une réponse : verdict, XP gagnés, explication,
/// puis « Continuer ». `detail` accueille les lignes propres à l'écran (combo, points).
struct CourseQuizVerdictPanel<Detail: View>: View {
    private let tone: CourseQuizVerdictTone
    private let title: String
    private let xpText: String?
    private let explanation: String
    private let continueTitle: String
    private let onContinue: () -> Void
    private let detail: () -> Detail

    init(
        tone: CourseQuizVerdictTone,
        title: String,
        xpText: String? = nil,
        explanation: String = "",
        continueTitle: String,
        onContinue: @escaping () -> Void,
        @ViewBuilder detail: @escaping () -> Detail
    ) {
        self.tone = tone
        self.title = title
        self.xpText = xpText
        self.explanation = explanation
        self.continueTitle = continueTitle
        self.onContinue = onContinue
        self.detail = detail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow

            detail()

            if !explanation.isEmpty {
                Text(explanation)
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: onContinue) {
                HStack(spacing: 8) {
                    Text(continueTitle)
                    Image(systemName: "arrow.forward")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { panelBackground }
    }

    private var headerRow: some View {
        HStack(spacing: 10) {
            CourseQuizVerdictIcon(tone: tone)

            Text(title)
                .font(CourseType.font(19, .bold, relativeTo: .headline))
                .foregroundStyle(tone.ink)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            if let xpText {
                Text(xpText)
                    .font(DS.sans(.footnote, .bold))
                    .monospacedDigit()
                    .foregroundStyle(DS.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(DS.accentTint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .dsPopIn(delay: 0.18)
            }
        }
    }

    /// Fond blanc à coins hauts arrondis, avec le seul filet du haut : la bordure est
    /// dessinée plus large que le panneau pour que ses côtés et son bas restent hors écran.
    private var panelBackground: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 24,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 24,
            style: .continuous
        )
        return shape
            .fill(DS.surface)
            .overlay {
                shape
                    .strokeBorder(DS.hairline, lineWidth: 1.5)
                    .padding(.horizontal, -1.5)
                    .padding(.bottom, -48)
            }
            .ignoresSafeArea(edges: .bottom)
    }
}

extension CourseQuizVerdictPanel where Detail == EmptyView {
    init(
        tone: CourseQuizVerdictTone,
        title: String,
        xpText: String? = nil,
        explanation: String = "",
        continueTitle: String,
        onContinue: @escaping () -> Void
    ) {
        self.init(
            tone: tone,
            title: title,
            xpText: xpText,
            explanation: explanation,
            continueTitle: continueTitle,
            onContinue: onContinue,
            detail: { EmptyView() }
        )
    }
}

// MARK: - Barre d'XP

/// Barre d'XP dorée. Sans animation propre : c'est `XPProgressAnimator` qui rythme le
/// remplissage (et le remet à zéro sans transition à un passage de niveau).
struct CourseXPBar: View {
    /// Avancement entre 0 et 1.
    let fraction: Double
    var height: CGFloat = 8

    private var clamped: CGFloat { CGFloat(min(max(fraction, 0), 1)) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(CoursePalette.track)
                Capsule()
                    .fill(CoursePalette.gold)
                    .frame(width: max(clamped > 0 ? height : 0, geo.size.width * clamped))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
