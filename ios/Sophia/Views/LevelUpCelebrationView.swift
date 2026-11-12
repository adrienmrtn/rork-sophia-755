import SwiftUI

struct LevelUpCelebrationView: View {
    @Environment(LanguageManager.self) private var languageManager
    let subject: Subject
    let previousLevel: Int
    let newLevel: Int
    let onContinue: () -> Void

    @State private var appeared: Bool = false
    @State private var badgeScale: CGFloat = 0.5
    @State private var levelScale: CGFloat = 0.6
    @State private var showNewLevel: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                GeometryReader { geo in
                    ScrollView {
                        levelSummary
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: geo.size.height)
                    }
                    .scrollIndicators(.hidden)
                }

                // Vibre par son style.
                Button {
                    onContinue()
                } label: {
                    Text(languageManager.text("common.continue"))
                }
                .buttonStyle(DSPrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(showNewLevel ? 1 : 0)
                .offset(y: showNewLevel ? 0 : 18)
            }

            if showNewLevel, !reduceMotion {
                PathConfettiBurst(
                    colors: [CoursePalette.gold, CoursePalette.goldTint, DS.accent, DS.accentTint],
                    pieceCount: 50,
                    duration: 2.4,
                    origin: CGPoint(x: 0.5, y: 0.28)
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .onAppear { runSequence() }
        .sophiaColorScheme()
    }

    private var levelSummary: some View {
        VStack(spacing: 14) {
            subjectMedallion
                .scaleEffect(badgeScale)
                .opacity(appeared ? 1 : 0)

            Text(languageManager.text("levelUp.title"))
                .font(CourseType.font(26, .semibold, relativeTo: .title))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)

            Text(subject.localizedShortName(language: languageManager.current))
                .font(DS.sans(.callout))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)

            levelTransition
                .padding(.top, 10)
        }
    }

    /// L'illustration de la matière, avec l'éclair du niveau gagné posé dessus.
    private var subjectMedallion: some View {
        CourseSubjectAvatar(subject: subject, size: 132)
            .overlay(alignment: .bottomTrailing) {
                AnimatedRewardBadge(kind: .levelUp, size: 20, showGlow: false)
                    .frame(width: 38, height: 38)
                    .background(DS.surface, in: Circle())
                    .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1.5) }
                    .offset(x: 4, y: 4)
                    .scaleEffect(showNewLevel ? 1 : 0.3)
                    .opacity(showNewLevel ? 1 : 0)
            }
    }

    /// « NIV. 1 → NIV. 2 » : l'ancien niveau s'efface, le nouveau arrive en gras bleu.
    private var levelTransition: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(String(format: languageManager.text("common.levelShort"), previousLevel))
                .font(DS.title(.title2, .medium))
                .foregroundStyle(DS.inkTertiary.opacity(showNewLevel ? 0.6 : 1))
                .scaleEffect(showNewLevel ? 0.9 : 1)

            Image(systemName: "arrow.forward")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DS.accent)
                .opacity(showNewLevel ? 1 : 0.3)

            Text(String(format: languageManager.text("common.levelShort"), newLevel))
                .font(CourseType.font(44, .heavy, relativeTo: .largeTitle))
                .foregroundStyle(DS.accent)
                .scaleEffect(levelScale)
                .opacity(showNewLevel ? 1 : 0)
        }
    }

    private func runSequence() {
        if reduceMotion {
            appeared = true
            badgeScale = 1.0
            showNewLevel = true
            levelScale = 1.0
            Haptics.celebrate()
            return
        }

        withAnimation(DS.Motion.pop) {
            appeared = true
            badgeScale = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Le nouveau niveau se pose : la vibration de récompense.
            Haptics.celebrate()
            withAnimation(DS.Motion.pop) {
                showNewLevel = true
                levelScale = 1.0
            }
        }
    }
}
