import SwiftUI
import UIKit

// MARK: - Hôte

/// Posé à la racine de l'app (`ContentView`), par-dessus les onglets : montre, un par un, les
/// badges que `BadgeCelebrationCenter` met en file, et relance la vérification quand l'app
/// revient au premier plan.
private struct BadgeCelebrationHost: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    let progressManager: ProgressManager
    @State private var center = BadgeCelebrationCenter.shared

    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack {
                    if let badge = center.current {
                        BadgeCelebrationView(badge: badge) {
                            center.dismissCurrent()
                        }
                        .id(badge.id)
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: center.current?.id)
            }
            .onAppear { center.attach(progressManager) }
            .onDisappear { center.hostDidDisappear() }
            .onChange(of: scenePhase) { _, phase in
                // Une série ou un événement peut avoir bougé pendant l'absence.
                if phase == .active { center.scheduleDetection() }
            }
    }
}

extension View {
    /// La fête des badges gagnés, par-dessus tout l'écran racine.
    func badgeCelebrationHost(progressManager: ProgressManager) -> some View {
        modifier(BadgeCelebrationHost(progressManager: progressManager))
    }
}

// MARK: - Fête d'un badge

/// Un badge vient d'être gagné : fond assombri, le médaillon qui arrive en rebondissant sur
/// des rayons dorés, une pluie de confettis, son nom, sa condition, et « Continuer ».
/// Avec « Réduire les animations », tout apparaît en simple fondu.
struct BadgeCelebrationView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let badge: Badge
    let onContinue: () -> Void

    @State private var backdropVisible = false
    @State private var medalVisible = false
    @State private var textVisible = false
    @State private var raysSpinning = false
    @State private var shinePassed = false
    @State private var showConfetti = false
    /// Un toucher parti avant la fête (défilement en cours) ne doit pas la fermer aussitôt.
    @State private var canDismiss = false

    private let medalSize: CGFloat = 136

    var body: some View {
        ZStack {
            Color.black.opacity(backdropVisible ? 0.62 : 0)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { close() }
                .accessibilityHidden(true)

            card
                .padding(.horizontal, 28)
                .frame(maxWidth: 420)

            if showConfetti {
                PathConfettiBurst(
                    colors: [DS.warm, DS.accent, DS.accentSoft, DS.success],
                    pieceCount: 70,
                    duration: 2.6,
                    origin: CGPoint(x: 0.5, y: 0.36)
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .onAppear { runSequence() }
    }

    private var card: some View {
        VStack(spacing: 0) {
            ZStack {
                if !reduceMotion {
                    BadgeRaysShape(count: 14)
                        .fill(
                            RadialGradient(
                                colors: [DS.warm.opacity(0.55), DS.warm.opacity(0)],
                                center: .center,
                                startRadius: medalSize * 0.35,
                                endRadius: medalSize * 1.05
                            )
                        )
                        .frame(width: medalSize * 2.1, height: medalSize * 2.1)
                        .rotationEffect(.degrees(raysSpinning ? 360 : 0))
                        .opacity(medalVisible ? 1 : 0)
                        .scaleEffect(medalVisible ? 1 : 0.4)
                }

                BadgeMedal(badge: badge, earned: true, size: medalSize)
                    .overlay {
                        // Un reflet qui traverse le médaillon une fois posé.
                        if !reduceMotion {
                            LinearGradient(
                                colors: [Color.white.opacity(0), Color.white.opacity(0.6), Color.white.opacity(0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: medalSize * 0.38, height: medalSize * 1.5)
                            .rotationEffect(.degrees(22))
                            .offset(x: shinePassed ? medalSize : -medalSize)
                            .allowsHitTesting(false)
                        }
                    }
                    .clipShape(Circle())
                    .shadow(color: DS.warm.opacity(0.35), radius: 18, x: 0, y: 8)
                    .scaleEffect(reduceMotion ? 1 : (medalVisible ? 1 : 0.2))
                    .rotationEffect(.degrees(reduceMotion ? 0 : (medalVisible ? 0 : -24)))
                    .opacity(medalVisible ? 1 : 0)
            }
            .frame(height: medalSize + 56)
            .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                Text(languageManager.text("badgeCelebration.kicker").uppercased(with: languageManager.locale))
                    .font(DS.sans(.caption, .bold))
                    .tracking(1.2)
                    .foregroundStyle(DS.accent)
                    .multilineTextAlignment(.center)

                Text(badge.title(language: languageManager.current))
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)

                Text(badge.condition(language: languageManager.current))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)
            .opacity(textVisible ? 1 : 0)
            .offset(y: textVisible || reduceMotion ? 0 : 14)
            .accessibilityElement(children: .combine)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onContinue()
            } label: {
                Text(languageManager.text("common.continue"))
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .padding(.top, 24)
            .opacity(textVisible ? 1 : 0)
        }
        .padding(.horizontal, 22)
        .padding(.top, 10)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 30, style: .continuous).fill(DS.canvas))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.25), radius: 30, x: 0, y: 14)
        .opacity(backdropVisible ? 1 : 0)
        .scaleEffect(reduceMotion ? 1 : (backdropVisible ? 1 : 0.92))
        .accessibilityAddTraits(.isModal)
    }

    private func close() {
        guard canDismiss else { return }
        onContinue()
    }

    private func runSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { canDismiss = true }

        if reduceMotion {
            // Pas de mouvement : un fondu, et le retour haptique de réussite.
            withAnimation(.easeInOut(duration: 0.3)) {
                backdropVisible = true
                medalVisible = true
                textVisible = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }

        withAnimation(.easeOut(duration: 0.25)) { backdropVisible = true }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.58)) { medalVisible = true }
            withAnimation(.linear(duration: 22).repeatForever(autoreverses: false)) { raysSpinning = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showConfetti = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { textVisible = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.easeInOut(duration: 0.9)) { shinePassed = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
    }
}

// MARK: - Rayons

/// Des rayons en éventail autour du centre, comme un soleil derrière le médaillon.
private struct BadgeRaysShape: Shape {
    var count: Int = 12

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard count > 0 else { return path }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let step = 2 * Double.pi / Double(count)
        for index in 0..<count {
            let start = Double(index) * step
            let end = start + step * 0.45
            path.move(to: center)
            path.addLine(to: CGPoint(x: center.x + CGFloat(cos(start)) * radius, y: center.y + CGFloat(sin(start)) * radius))
            path.addLine(to: CGPoint(x: center.x + CGFloat(cos(end)) * radius, y: center.y + CGFloat(sin(end)) * radius))
            path.closeSubpath()
        }
        return path
    }
}
