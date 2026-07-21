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

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Blocs équilibrés entre le haut de l'écran et le bouton ancré en bas.
                            Spacer(minLength: 28)

                            SubjectBadgeView(subject: subject, iconSize: 56, cornerRadius: DS.Radius.card)
                                .frame(width: 116, height: 116)
                                .scaleEffect(badgeScale)
                                .opacity(appeared ? 1 : 0)

                            Spacer(minLength: 28)

                            Text(languageManager.text("levelUp.title"))
                                .font(DS.title(.largeTitle, .semibold))
                                .foregroundStyle(DS.ink)
                                .multilineTextAlignment(.center)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 14)

                            Text(subject.localizedShortName(language: languageManager.current))
                                .font(DS.sans(.subheadline))
                                .foregroundStyle(DS.inkSecondary)
                                .padding(.top, 6)
                                .opacity(appeared ? 1 : 0)

                            HStack(alignment: .firstTextBaseline, spacing: 16) {
                                Text(String(format: languageManager.text("common.levelShort"), previousLevel))
                                    .font(DS.title(.title2, .medium))
                                    .foregroundStyle(DS.inkTertiary.opacity(showNewLevel ? 0.6 : 1))
                                    .scaleEffect(showNewLevel ? 0.9 : 1)

                                Image(systemName: "arrow.right")
                                    .font(.jakarta(size: 18, weight: .medium))
                                    .foregroundStyle(DS.accentSoft)
                                    .opacity(showNewLevel ? 1 : 0.3)

                                Text(String(format: languageManager.text("common.levelShort"), newLevel))
                                    .font(.jakarta(size: 44, weight: .semibold))
                                    .foregroundStyle(DS.ink)
                                    .scaleEffect(levelScale)
                                    .opacity(showNewLevel ? 1 : 0)
                            }
                            .padding(.top, 24)

                            Spacer(minLength: 32)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geo.size.height)
                    }
                    .scrollIndicators(.hidden)
                }

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onContinue()
                } label: {
                    Text(languageManager.text("common.continue"))
                }
                .buttonStyle(DSPrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(showNewLevel ? 1 : 0)
                .offset(y: showNewLevel ? 0 : 18)
            }
        }
        .onAppear { runSequence() }
    }

    private func runSequence() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) {
            appeared = true
            badgeScale = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                showNewLevel = true
                levelScale = 1.0
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}
