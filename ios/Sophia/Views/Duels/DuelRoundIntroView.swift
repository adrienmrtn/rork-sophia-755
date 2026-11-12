import SwiftUI

/// Les matières des questions de duel (clés du serveur), rattachées aux matières de l'app pour
/// leur nom, leur pictogramme et leur couleur.
enum DuelSubjects {
    static func subject(_ key: String) -> Subject? {
        switch key {
        case "history": .histoire
        case "science": .sciences
        case "literature": .litterature
        case "art": .art
        case "mythology": .mythologie
        case "world": .comprendreLeMonde
        default: nil
        }
    }

    static func name(_ key: String, language: AppLanguage) -> String {
        subject(key)?.localizedName(language: language) ?? key.capitalized
    }

    static func icon(_ key: String) -> String {
        subject(key)?.icon ?? "questionmark"
    }

    static func color(_ key: String) -> Color {
        subject(key)?.color ?? DuelPalette.saffron
    }
}

/// L'annonce d'une manche, par-dessus l'écran de jeu : trois matières au choix (et le temps qui
/// reste pour choisir), la matière que l'adversaire est en train de choisir puis celle qu'il a
/// retenue, ou le sprint final. Fond blanc, comme le reste du duel.
struct DuelRoundIntroView: View {
    @Environment(LanguageManager.self) private var languageManager
    let model: DuelGameModel
    let intro: DuelGameModel.RoundIntro
    let opponentHandle: String
    /// L'annonce couvre l'écran de jeu : elle porte son propre bouton pour quitter le duel.
    let onQuit: () -> Void

    var body: some View {
        ZStack {
            DS.canvas.opacity(0.98).ignoresSafeArea()

            VStack(spacing: 20) {
                Text(String(format: languageManager.text("duel.round.title"), intro.number).uppercased())
                    .font(.jakarta(size: 12, weight: .heavy))
                    .tracking(1.6)
                    .foregroundStyle(DS.accent)

                switch intro.kind {
                case .pick:
                    if intro.mine {
                        myPick
                    } else {
                        theirPick
                    }
                case .sprint:
                    sprint
                case .mixed:
                    EmptyView()
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 520)
        }
        .overlay(alignment: .topLeading) {
            // Même place que le bouton de l'écran de jeu, qu'elle recouvre.
            RoundIconButton(
                systemImage: "xmark",
                accessibilityLabel: languageManager.text("duel.quit.title"),
                action: onQuit
            )
            .padding(.leading, 24)
            .padding(.top, 8)
        }
    }

    // MARK: - À moi de choisir

    private var myPick: some View {
        VStack(spacing: 18) {
            Text(languageManager.text("duel.round.pick.title"))
                .font(DS.title(.title, .semibold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)

            if let deadline = intro.deadline, intro.chosen == nil {
                TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                    let window = max(deadline.timeIntervalSince(intro.opensAt), 0.1)
                    let remaining = max(deadline.timeIntervalSince(timeline.date), 0)
                    DuelProgressBar(progress: min(remaining / window, 1), tint: DS.accent, track: DS.accentTint, height: 5)
                }
            } else {
                Color.clear.frame(height: 5)
            }

            VStack(spacing: 10) {
                ForEach(Array(intro.options.enumerated()), id: \.element) { index, subject in
                    Button {
                        model.pickSubject(subject)
                    } label: {
                        subjectCard(subject, selected: intro.chosen == subject, dimmed: intro.chosen != nil && intro.chosen != subject)
                    }
                    // Le choix vibre déjà (`DuelHaptics.lock`).
                    .buttonStyle(PressableStyle(scale: 0.97, haptic: false))
                    .disabled(intro.chosen != nil)
                    .dsStagger(index, step: 0.07, base: 0.1)
                }
            }
        }
    }

    // MARK: - À l'adversaire de choisir

    private var theirPick: some View {
        VStack(spacing: 18) {
            if let chosen = intro.chosen {
                Text(String(format: languageManager.text("duel.round.pick.theirChoice"), opponentHandle))
                    .font(DS.sans(.headline, .semibold))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
                subjectCard(chosen, selected: true, dimmed: false)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            } else {
                DuelPulseRings(color: DS.accent)
                    .frame(width: 64, height: 64)
                    .padding(.vertical, 26)
                Text(String(format: languageManager.text("duel.round.pick.theirs"), opponentHandle))
                    .font(DS.title(.title3, .semibold))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)
                DuelWaitingDots(color: DS.accent)
            }
        }
    }

    // MARK: - Sprint

    private var sprint: some View {
        VStack(spacing: 14) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 36, weight: .heavy))
                .foregroundStyle(DS.accent)
                .frame(width: 88, height: 88)
                .background(Circle().fill(DS.accentTint))
                .dsPopIn(delay: 0.1)
            Text(languageManager.text("duel.round.sprint.title"))
                .font(DS.title(.largeTitle, .heavy))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
            Text(languageManager.text("duel.round.sprint.body"))
                .font(DS.sans(.body, .medium))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Une matière

    /// Une matière en carte d'option : sa pastille de couleur, son nom, et la coche une fois
    /// retenue.
    private func subjectCard(_ subject: String, selected: Bool, dimmed: Bool) -> some View {
        let state: DSOptionState = selected ? .selected : (dimmed ? .dimmed : .idle)
        return HStack(spacing: 14) {
            Image(systemName: DuelSubjects.icon(subject))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(DuelSubjects.color(subject)))
            Text(DuelSubjects.name(subject, language: languageManager.current))
                .font(DS.sans(.headline, selected ? .bold : .semibold))
                .foregroundStyle(DS.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 0)
            if selected {
                DSCheckBadge(size: 26, fill: DS.accent)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .dsOptionCard(state)
    }
}
