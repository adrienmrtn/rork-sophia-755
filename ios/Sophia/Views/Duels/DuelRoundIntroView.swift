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
/// retenue, ou le sprint final.
struct DuelRoundIntroView: View {
    @Environment(LanguageManager.self) private var languageManager
    let model: DuelGameModel
    let intro: DuelGameModel.RoundIntro
    let opponentHandle: String

    var body: some View {
        ZStack {
            DuelPalette.night.opacity(0.96).ignoresSafeArea()

            VStack(spacing: 22) {
                Text(String(format: languageManager.text("duel.round.title"), intro.number).uppercased())
                    .font(DS.sans(.subheadline, .bold))
                    .tracking(2.2)
                    .foregroundStyle(DuelPalette.saffron)

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
            .padding(.horizontal, 28)
            .frame(maxWidth: 520)
        }
    }

    // MARK: - À moi de choisir

    private var myPick: some View {
        VStack(spacing: 18) {
            Text(languageManager.text("duel.round.pick.title"))
                .font(.jakarta(size: 30, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            if let deadline = intro.deadline, intro.chosen == nil {
                TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                    let window = max(deadline.timeIntervalSince(intro.opensAt), 0.1)
                    let remaining = max(deadline.timeIntervalSince(timeline.date), 0)
                    DuelProgressBar(progress: min(remaining / window, 1), tint: DuelPalette.saffron, track: Color.white.opacity(0.18), height: 5)
                }
            } else {
                Color.clear.frame(height: 5)
            }

            VStack(spacing: 12) {
                ForEach(intro.options, id: \.self) { subject in
                    Button {
                        model.pickSubject(subject)
                    } label: {
                        subjectCard(subject, selected: intro.chosen == subject, dimmed: intro.chosen != nil && intro.chosen != subject)
                    }
                    .buttonStyle(SoftPressButtonStyle())
                    .disabled(intro.chosen != nil)
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
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                subjectCard(chosen, selected: true, dimmed: false)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            } else {
                DuelPulseRings(color: .white)
                    .frame(width: 64, height: 64)
                    .padding(.vertical, 26)
                Text(String(format: languageManager.text("duel.round.pick.theirs"), opponentHandle))
                    .font(.jakarta(size: 22, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Sprint

    private var sprint: some View {
        VStack(spacing: 14) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 52, weight: .heavy))
                .foregroundStyle(DuelPalette.saffron)
            Text(languageManager.text("duel.round.sprint.title"))
                .font(.jakarta(size: 34, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(languageManager.text("duel.round.sprint.body"))
                .font(DS.sans(.body, .medium))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Une matière

    private func subjectCard(_ subject: String, selected: Bool, dimmed: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: DuelSubjects.icon(subject))
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Circle().fill(DuelSubjects.color(subject)))
            Text(DuelSubjects.name(subject, language: languageManager.current))
                .font(.jakarta(size: 19, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 0)
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(DuelPalette.saffron)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white.opacity(selected ? 0.18 : 0.1)))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(selected ? DuelPalette.saffron : Color.white.opacity(0.14), lineWidth: selected ? 2.5 : 1)
        )
        .opacity(dimmed ? 0.4 : 1)
        .scaleEffect(selected ? 1.02 : 1)
    }
}
