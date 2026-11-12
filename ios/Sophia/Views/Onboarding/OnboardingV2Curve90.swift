import SwiftUI
import UIKit

/// « Les petits efforts s'additionnent. Dans 90 jours, tu ne seras plus la même personne. »
///
/// Deux courbes sur 90 jours : celle de Sophia, bleue, qui s'accélère, et celle du temps
/// passé à scroller ailleurs, sombre, qui reste presque plate. Les courbes se tracent à
/// l'apparition, puis les repères de l'axe (aujourd'hui, 7, 30 et 90 jours) se posent l'un
/// après l'autre avec une vibration douce. Aucun chiffre de résultat : seulement des tendances.
struct OnboardingV2Curve90: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onNext: () -> Void

    /// L'axe horizontal est visible.
    @State private var axisIn = false
    /// Portion tracée de chaque courbe, de 0 à 1.
    @State private var sophiaTrim: CGFloat = 0
    @State private var othersTrim: CGFloat = 0
    /// Nombre de repères de l'axe déjà posés (0 à 4).
    @State private var marks = 0
    /// Les points d'arrivée des deux courbes sont posés.
    @State private var endsIn = false
    /// Les étiquettes « Sophia » et « autres applis » sont posées.
    @State private var labelsIn = false
    @State private var started = false
    @State private var animTask: Task<Void, Never>?
    /// « Continuer » n'apparaît qu'une seconde après l'arrivée sur la page : le temps de
    /// voir les courbes partir avant de pouvoir passer.
    @State private var ctaShown = false
    @State private var ctaTask: Task<Void, Never>?

    init(onNext: @escaping () -> Void) {
        self.onNext = onNext
    }

    /// Attente avant que « Continuer » n'apparaisse.
    private static let ctaDelay: Duration = .seconds(1)
    private static let markCount = 4
    /// Fond très légèrement bleuté de la carte du graphique.
    private static let cardFill = Color(red: 0.969, green: 0.976, blue: 0.992)
    private static let axisColor = Color(red: 0.765, green: 0.796, blue: 0.847)

    private var markKeys: [String] {
        [
            "onboardingV2.curve90.today",
            "onboardingV2.curve90.day7",
            "onboardingV2.curve90.day30",
            "onboardingV2.curve90.day90",
        ]
    }

    var body: some View {
        OV2ScrollableContent {
            VStack(spacing: 0) {
                DSHighlightTitle(
                    text: languageManager.text("onboardingV2.curve90.title"),
                    style: .title,
                    alignment: .leading
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, OV2End.top)
                .dsStagger(0)

                chartCard
                    .padding(.top, 28)
                    .dsStagger(1)
            }
            .padding(.horizontal, OV2End.side)
            .padding(.bottom, 16)
        } footer: {
            // Le bouton garde sa place (rien ne bouge quand il arrive) ; tant qu'il est
            // invisible, il ne répond ni au doigt ni à VoiceOver.
            OnboardingV2Button(title: languageManager.text("common.continue"), enabled: ctaShown, action: onNext)
                .opacity(ctaShown ? 1 : 0)
                .allowsHitTesting(ctaShown)
                .accessibilityHidden(!ctaShown)
        }
        .ov2Background()
        .onAppear {
            play()
            revealCTA()
        }
        .onDisappear {
            animTask?.cancel()
            animTask = nil
            ctaTask?.cancel()
            ctaTask = nil
        }
    }

    /// Montre « Continuer » après `ctaDelay`. Une tâche annulée (page quittée) ne laisse pas
    /// le bouton caché : il est remontré à la prochaine apparition, après la même attente.
    private func revealCTA() {
        guard !ctaShown else { return }
        ctaTask?.cancel()
        ctaTask = Task { @MainActor in
            try? await Task.sleep(for: Self.ctaDelay)
            if Task.isCancelled { return }
            withAnimation(.easeOut(duration: 0.3)) { ctaShown = true }
        }
    }

    // MARK: - Carte du graphique

    private var chartCard: some View {
        VStack(spacing: 2) {
            chart
            markLabels
        }
        .padding(EdgeInsets(top: 18, leading: 12, bottom: 12, trailing: 12))
        .ov2EndCard(fill: Self.cardFill)
        .overlay(alignment: .topTrailing) {
            sophiaBadge
                .scaleEffect(labelsIn ? 1 : 0.5, anchor: .topTrailing)
                .opacity(labelsIn ? 1 : 0)
                .padding(.top, 12)
                .padding(.trailing, 16)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(languageManager.text("onboardingV2.curve90.a11y")))
    }

    private var chart: some View {
        GeometryReader { geo in
            let size: CGSize = geo.size
            let start: CGPoint = Curve90Geometry.point(x: 18, y: 256, in: size)
            let sophiaEnd: CGPoint = Curve90Geometry.point(x: 298, y: 40, in: size)
            let othersEnd: CGPoint = Curve90Geometry.point(x: 298, y: 232, in: size)
            let pillTop: CGFloat = size.height * 0.645

            ZStack(alignment: .topTrailing) {
                Curve90BaselineShape()
                    .stroke(Self.axisColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .opacity(axisIn ? 1 : 0)

                ForEach(0..<Self.markCount, id: \.self) { index in
                    Curve90TickShape(index: index)
                        .stroke(Self.axisColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .opacity(marks > index ? 1 : 0)
                }

                Curve90OthersShape()
                    .trim(from: 0, to: othersTrim)
                    .stroke(DS.ink, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))

                Curve90SophiaShape()
                    .trim(from: 0, to: sophiaTrim)
                    .stroke(DS.accent, style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round))

                dot(color: DS.accent, diameter: 12, shown: marks > 0)
                    .position(start)
                dot(color: DS.ink, diameter: 12, shown: endsIn)
                    .position(othersEnd)
                dot(color: DS.accent, diameter: 14, shown: endsIn)
                    .position(sophiaEnd)

                othersPill
                    .scaleEffect(labelsIn ? 1 : 0.5, anchor: .trailing)
                    .opacity(labelsIn ? 1 : 0)
                    .padding(.trailing, 4)
                    .offset(y: pillTop)
            }
            .frame(width: size.width, height: size.height, alignment: .topTrailing)
        }
        .aspectRatio(Curve90Geometry.designWidth / Curve90Geometry.designHeight, contentMode: .fit)
    }

    private func dot(color: Color, diameter: CGFloat, shown: Bool) -> some View {
        Circle()
            .fill(color)
            .frame(width: diameter, height: diameter)
            .scaleEffect(shown ? 1 : 0.01)
            .opacity(shown ? 1 : 0)
    }

    /// Les quatre repères de l'axe, sous le graphique.
    private var markLabels: some View {
        HStack(spacing: 4) {
            ForEach(0..<Self.markCount, id: \.self) { index in
                if index > 0 { Spacer(minLength: 0) }
                Text(languageManager.text(markKeys[index]))
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(DS.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .opacity(marks > index ? 1 : 0)
                    .offset(y: marks > index ? 0 : 5)
            }
        }
        .padding(.horizontal, 6)
    }

    /// Étiquette de la courbe bleue : le vrai logo Sophia, en couleur (`sophia_mark`, le
    /// symbole rose et le nom, celui de l'accueil), sur une pastille blanche cerclée du bleu
    /// de la courbe.
    private var sophiaBadge: some View {
        Group {
            if UIImage(named: "sophia_mark") != nil {
                Image("sophia_mark")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 18)
            } else {
                Text(verbatim: "Sophia")
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(DS.ink)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(DS.accent, lineWidth: 1.5)
        )
    }

    /// Étiquette de la courbe sombre.
    private var othersPill: some View {
        Text(languageManager.text("onboardingV2.curve90.others"))
            .font(DS.sans(.caption, .bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(DS.ink))
    }

    // MARK: - Animation

    /// Trace les courbes puis pose les repères un à un. Rejouée une seule fois : si la page
    /// réapparaît (retour arrière), ou si « Réduire les animations » est actif, le graphique
    /// est montré terminé.
    private func play() {
        if started || reduceMotion {
            showFinished()
            return
        }
        started = true
        animTask?.cancel()
        animTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(280))
            if Task.isCancelled { return }
            withAnimation(.easeOut(duration: 0.35)) { axisIn = true }
            withAnimation(.easeInOut(duration: 1.6)) {
                sophiaTrim = 1
                othersTrim = 1
            }

            // Attente avant chaque repère : ils suivent la pointe de la courbe bleue.
            let waits: [Int] = [60, 540, 380, 620]
            for index in 0..<Self.markCount {
                try? await Task.sleep(for: .milliseconds(waits[index]))
                if Task.isCancelled { return }
                withAnimation(DSCalmMotion.settle) { marks = index + 1 }
                Haptics.soft()
            }

            withAnimation(DSCalmMotion.settle) { endsIn = true }
            try? await Task.sleep(for: .milliseconds(200))
            if Task.isCancelled { return }
            withAnimation(DSCalmMotion.settle) { labelsIn = true }
        }
    }

    private func showFinished() {
        started = true
        axisIn = true
        sophiaTrim = 1
        othersTrim = 1
        marks = Self.markCount
        endsIn = true
        labelsIn = true
    }
}

// MARK: - Géométrie

/// Le graphique est dessiné dans un repère fixe de 318 × 300 (celui de la maquette), puis
/// mis à l'échelle de la place disponible.
private enum Curve90Geometry {
    static let designWidth: CGFloat = 318
    static let designHeight: CGFloat = 300
    /// Abscisses des quatre repères : aujourd'hui, 7, 30 et 90 jours.
    static let tickXs: [CGFloat] = [18, 96, 190, 298]

    static func point(x: CGFloat, y: CGFloat, in size: CGSize) -> CGPoint {
        CGPoint(x: x / designWidth * size.width, y: y / designHeight * size.height)
    }

    static func point(x: CGFloat, y: CGFloat, in rect: CGRect) -> CGPoint {
        let local: CGPoint = point(x: x, y: y, in: rect.size)
        return CGPoint(x: rect.minX + local.x, y: rect.minY + local.y)
    }
}

/// Axe horizontal.
private struct Curve90BaselineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: Curve90Geometry.point(x: 18, y: 258, in: rect))
        path.addLine(to: Curve90Geometry.point(x: 300, y: 258, in: rect))
        return path
    }
}

/// Petit trait vertical d'un repère de l'axe.
private struct Curve90TickShape: Shape {
    let index: Int

    func path(in rect: CGRect) -> Path {
        let xs: [CGFloat] = Curve90Geometry.tickXs
        let x: CGFloat = xs[min(max(index, 0), xs.count - 1)]
        var path = Path()
        path.move(to: Curve90Geometry.point(x: x, y: 252, in: rect))
        path.addLine(to: Curve90Geometry.point(x: x, y: 264, in: rect))
        return path
    }
}

/// Courbe de Sophia : part à plat et s'accélère jusqu'en haut à droite.
private struct Curve90SophiaShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: Curve90Geometry.point(x: 18, y: 256, in: rect))
        path.addCurve(
            to: Curve90Geometry.point(x: 298, y: 40, in: rect),
            control1: Curve90Geometry.point(x: 120, y: 252, in: rect),
            control2: Curve90Geometry.point(x: 200, y: 190, in: rect)
        )
        return path
    }
}

/// Courbe « à scroller sur d'autres applis » : elle ondule près de l'axe et monte à peine.
private struct Curve90OthersShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: Curve90Geometry.point(x: 18, y: 256, in: rect))
        path.addCurve(
            to: Curve90Geometry.point(x: 76, y: 252, in: rect),
            control1: Curve90Geometry.point(x: 44, y: 244, in: rect),
            control2: Curve90Geometry.point(x: 58, y: 244, in: rect)
        )
        path.addCurve(
            to: Curve90Geometry.point(x: 132, y: 246, in: rect),
            control1: Curve90Geometry.point(x: 94, y: 260, in: rect),
            control2: Curve90Geometry.point(x: 112, y: 262, in: rect)
        )
        path.addCurve(
            to: Curve90Geometry.point(x: 190, y: 250, in: rect),
            control1: Curve90Geometry.point(x: 152, y: 230, in: rect),
            control2: Curve90Geometry.point(x: 170, y: 236, in: rect)
        )
        path.addCurve(
            to: Curve90Geometry.point(x: 298, y: 232, in: rect),
            control1: Curve90Geometry.point(x: 210, y: 264, in: rect),
            control2: Curve90Geometry.point(x: 240, y: 244, in: rect)
        )
        return path
    }
}
