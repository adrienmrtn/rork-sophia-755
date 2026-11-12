import SwiftUI

/// « Revoir les questions » : chaque question de la partie, la bonne réponse, ce que j'ai
/// répondu et ce que l'adversaire a répondu. Tout vient de `DuelSummary.review`, rempli par
/// `DuelGameModel` pendant la partie : aucun appel au serveur.
struct DuelReviewView: View {
    @Environment(LanguageManager.self) private var languageManager
    let entries: [DuelReviewEntry]
    /// Le nombre de questions de la partie, hors question décisive.
    let questionCount: Int
    let player: DuelPlayerIdentity
    let opponent: DuelOpponent
    let onClose: () -> Void

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(entries) { entry in
                            card(entry)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
        }
    }

    // MARK: - En-tête

    private var header: some View {
        HStack(spacing: 12) {
            Text(languageManager.text("duel.review.open"))
                .font(DS.title(.title3, .heavy))
                .foregroundStyle(DS.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            Button {
                DuelHaptics.tap()
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(DS.ink)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(DS.surface))
                    .overlay(Circle().strokeBorder(DS.hairline, lineWidth: 1.5))
            }
            .buttonStyle(PressableStyle(scale: 0.94, haptic: false))
            .accessibilityLabel(Text(languageManager.text("duel.result.done")))
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    // MARK: - Une question

    private func card(_ entry: DuelReviewEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(counter(entry).uppercased())
                .font(.jakarta(size: 11, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(entry.isTiebreak ? DS.accent : DS.inkSecondary)

            HStack(alignment: .top, spacing: 12) {
                if entry.question.kind == .portrait {
                    DuelQuestionImage(url: entry.question.imageURL)
                        .frame(width: 64, height: 80)
                        .allowsHitTesting(false)
                }
                Text(entry.question.question)
                    .font(DS.sans(.callout, .bold))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let correct = correctText(entry.question) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(DS.success)
                    Text(correct)
                        .font(DS.sans(.subheadline, .heavy))
                        .foregroundStyle(DS.success)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(DS.successTint))
            }

            VStack(spacing: 8) {
                answerRow(
                    avatarId: player.avatarId,
                    initial: player.initial,
                    name: languageManager.text("duel.you"),
                    text: myText(entry),
                    answered: entry.iAnswered,
                    point: entry.playerPoint
                )
                answerRow(
                    avatarId: opponent.avatarId,
                    initial: opponent.initial,
                    name: "@\(opponent.handle)",
                    text: theirText(entry),
                    answered: entry.theyAnswered,
                    point: entry.opponentPoint
                )
            }
        }
        .dsCard(padding: 16, shadow: false)
    }

    /// « Question 3 / 20 », ou « Mort subite » pour la question décisive.
    private func counter(_ entry: DuelReviewEntry) -> String {
        if entry.isTiebreak { return languageManager.text("duel.suddenDeath.title") }
        return String(format: languageManager.text("duel.game.counter"), entry.index + 1, questionCount)
    }

    /// Un joueur : son avatar, son nom, ce qu'il a répondu, et s'il a marqué.
    private func answerRow(avatarId: String?, initial: String, name: String, text: String?, answered: Bool, point: Bool) -> some View {
        HStack(spacing: 10) {
            AvatarCircle(avatarId: avatarId, initial: initial, size: 28)
                .overlay(Circle().strokeBorder(DS.hairline, lineWidth: 1))
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(DS.sans(.caption, .bold))
                    .foregroundStyle(DS.inkSecondary)
                    .lineLimit(1)
                Text(text ?? languageManager.text("duel.review.noAnswer"))
                    .font(DS.sans(.subheadline, answered ? .semibold : .medium))
                    .foregroundStyle(answered ? DS.ink : DS.inkTertiary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            mark(answered: answered, point: point)
        }
        .accessibilityElement(children: .combine)
    }

    /// La coche de celui qui a marqué, la croix d'une réponse qui n'a rien rapporté ; rien pour
    /// une question restée sans réponse.
    @ViewBuilder
    private func mark(answered: Bool, point: Bool) -> some View {
        if point {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(DS.success))
        } else if answered {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(DS.danger))
        } else {
            Image(systemName: "minus")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(DS.inkTertiary)
                .frame(width: 24, height: 24)
                .background(Circle().strokeBorder(DS.hairline, lineWidth: 1.5))
        }
    }

    // MARK: - Textes des réponses

    /// La bonne réponse : l'option juste, ou la valeur exacte au curseur.
    private func correctText(_ question: DuelQuestion) -> String? {
        if question.kind == .slider {
            return question.correctValue.map { DuelFormat.sliderValue($0, unit: question.unit) }
        }
        return optionText(question, index: question.correctIndex)
    }

    private func optionText(_ question: DuelQuestion, index: Int?) -> String? {
        guard let index, let options = question.options, options.indices.contains(index) else { return nil }
        return options[index]
    }

    /// Ma réponse en clair ; nil si je n'ai pas répondu.
    private func myText(_ entry: DuelReviewEntry) -> String? {
        if entry.question.kind == .slider {
            return entry.mine?.v.map { DuelFormat.sliderValue($0, unit: entry.question.unit) }
        }
        return optionText(entry.question, index: entry.mine?.c)
    }

    /// La réponse de l'adversaire en clair ; nil s'il n'a pas répondu ou si l'app ne la connaît pas.
    private func theirText(_ entry: DuelReviewEntry) -> String? {
        if entry.question.kind == .slider {
            return entry.theirs?.value.map { DuelFormat.sliderValue($0, unit: entry.question.unit) }
        }
        return optionText(entry.question, index: entry.theirs?.choice)
    }
}
