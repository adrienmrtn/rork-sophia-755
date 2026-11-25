import SwiftUI

/// Une question posée dans le fil du cours, sur ce qu'on vient de lire.
///
/// Trois formats, dessinés avec les pièces du quiz (`CourseQuizOptionCard`,
/// `CourseQuizTrueFalseCard`) : une bonne réponse parmi plusieurs, vrai ou faux, et des
/// éléments à remettre dans l'ordre. La question ne bloque pas la lecture : on peut continuer
/// sans répondre, il n'y a ni vies ni points. Le verdict s'affiche sous la question.
struct CourseInlineQuestionView: View {
    let question: QuestionBlockV2

    /// `choice` et `truefalse` : l'option choisie.
    @State private var picked: Int? = nil
    /// `order` : les éléments posés, dans l'ordre choisi (index dans `items`).
    @State private var placed: [Int] = []
    @State private var orderValidated = false

    private var language: AppLanguage { AppLanguage.currentPersisted() }

    var body: some View {
        VStack(spacing: 14) {
            DSHighlightTitle(text: question.prompt, style: .title3)
                .frame(maxWidth: .infinity)

            switch question.kind {
            case "truefalse":
                trueFalse
            case "order":
                order
            default:
                choice
            }

            if let verdict {
                verdictCard(correct: verdict)
                    .transition(.opacity.combined(with: .offset(y: 8)))
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
    }

    // MARK: Verdict

    /// nil tant qu'on n'a pas répondu ; sinon, la réponse était-elle juste.
    private var verdict: Bool? {
        switch question.kind {
        case "order":
            guard orderValidated else { return nil }
            return placed == Array(orderItems.indices)
        default:
            guard let picked else { return nil }
            return picked == question.answer
        }
    }

    private func verdictCard(correct: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                if correct {
                    DSCheckBadge(size: 26)
                } else {
                    CourseQuizCrossBadge(size: 26)
                }
                Text(AppLocalizable.string(correct ? "quiz.feedback.correct" : "quiz.feedback.wrong", language: language))
                    .font(CourseType.font(19, .bold, relativeTo: .headline))
                    .foregroundStyle(correct ? CoursePalette.successInk : DS.danger)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            if let explanation = question.explanation, !explanation.isEmpty {
                Text(explanation)
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .fill(correct ? DS.successTint : DS.dangerTint)
        )
    }

    private func answer(_ index: Int) {
        guard picked == nil else { return }
        withAnimation(DS.Motion.snappy) {
            picked = index
        }
        if index == question.answer {
            Haptics.success()
        } else {
            Haptics.error()
        }
    }

    private func state(for index: Int) -> DSOptionState {
        guard let picked else { return .idle }
        if index == question.answer { return .correct }
        if index == picked { return .wrong }
        return .dimmed
    }

    // MARK: Une bonne réponse parmi plusieurs

    private var choice: some View {
        VStack(spacing: 10) {
            ForEach(Array((question.options ?? []).enumerated()), id: \.offset) { index, option in
                Button {
                    answer(index)
                } label: {
                    CourseQuizOptionCard(text: option, state: state(for: index))
                }
                .buttonStyle(.plain)
                .disabled(picked != nil)
            }
        }
    }

    // MARK: Vrai ou faux

    private var trueFalse: some View {
        HStack(spacing: 10) {
            ForEach(Array((question.options ?? []).prefix(2).enumerated()), id: \.offset) { index, option in
                Button {
                    answer(index)
                } label: {
                    CourseQuizTrueFalseCard(text: option, isTrue: index == 0, state: state(for: index))
                }
                .buttonStyle(.plain)
                .disabled(picked != nil)
            }
        }
    }

    // MARK: Remettre dans l'ordre

    private var orderItems: [String] { question.items ?? [] }

    /// Ordre d'affichage des éléments à placer : fixe et mélangé, le même à chaque rendu.
    private var poolOrder: [Int] {
        let count = orderItems.count
        guard count > 1 else { return Array(0..<count) }
        // Un pas premier avec le nombre d'éléments les parcourt tous une fois, sans les
        // laisser dans l'ordre de départ.
        var step = 2
        while Self.gcd(step, count) != 1 { step += 1 }
        return (0..<count).map { ($0 * step + 2) % count }
    }

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        b == 0 ? a : gcd(b, a % b)
    }

    private var order: some View {
        VStack(spacing: 8) {
            ForEach(0..<orderItems.count, id: \.self) { slot in
                orderSlot(slot)
            }

            if !orderValidated {
                if placed.count < orderItems.count {
                    Text(AppLocalizable.string("quiz.chronological.instruction", language: language))
                        .font(DS.sans(.footnote))
                        .foregroundStyle(DS.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)

                    ForEach(poolOrder.filter { !placed.contains($0) }, id: \.self) { item in
                        Button {
                            Haptics.select()
                            withAnimation(DS.Motion.snappy) {
                                placed.append(item)
                            }
                        } label: {
                            CourseQuizOptionCard(text: orderItems[item], state: .idle)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button {
                        let correct = placed == Array(orderItems.indices)
                        withAnimation(DS.Motion.snappy) {
                            orderValidated = true
                        }
                        if correct {
                            Haptics.success()
                        } else {
                            Haptics.error()
                        }
                    } label: {
                        Text(AppLocalizable.string("quiz.chronological.validate", language: language))
                    }
                    .buttonStyle(DSSecondaryButtonStyle())
                    .padding(.top, 2)
                }
            }
        }
    }

    /// Une case numérotée. Avant validation : l'élément posé (toucher pour l'enlever) ou une
    /// case vide. Après : le bon élément à sa place, avec sa date, en vert ou en rouge selon
    /// que la case était bien remplie.
    @ViewBuilder
    private func orderSlot(_ slot: Int) -> some View {
        let item: Int? = orderValidated ? slot : (slot < placed.count ? placed[slot] : nil)
        let wasRight = slot < placed.count && placed[slot] == slot
        let slotState: DSOptionState = orderValidated ? (wasRight ? .correct : .wrong) : .idle
        let label: String? = {
            guard orderValidated, let labels = question.labels, labels.indices.contains(slot), !labels[slot].isEmpty else { return nil }
            return labels[slot]
        }()

        Button {
            guard !orderValidated, slot < placed.count else { return }
            Haptics.tap()
            withAnimation(DS.Motion.snappy) {
                _ = placed.remove(at: slot)
            }
        } label: {
            HStack(spacing: 12) {
                Text("\(slot + 1)")
                    .font(DS.sans(.caption, .heavy))
                    .monospacedDigit()
                    .foregroundStyle(DS.accent)
                    .frame(width: 24, height: 24)
                    .background(DS.accentTint, in: Circle())

                Text(item.map { orderItems[$0] } ?? " ")
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let label {
                    Text(label)
                        .font(DS.sans(.subheadline, .heavy))
                        .monospacedDigit()
                        .foregroundStyle(DS.ink)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 50)
            .dsOptionCard(slotState)
            .opacity(item == nil ? 0.55 : 1)
            .contentShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(orderValidated || slot >= placed.count)
    }
}
