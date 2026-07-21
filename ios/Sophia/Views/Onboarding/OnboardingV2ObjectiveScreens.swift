import SwiftUI

// MARK: - Questions (cultivate / impress / curiosity)

/// « Avec Sophia, tu sauras répondre à ces questions » — les questions défilent en douceur.
struct OnboardingV2QuestionsScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var index = 0
    @State private var appeared = false

    private var questions: [String] {
        (1...10).map { languageManager.text("onboardingV2.questions.q\($0)") }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 84)

            Text(languageManager.text("onboardingV2.questions.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .ov2Reveal(delay: 0.1)

            Spacer()

            ZStack {
                ForEach(Array(questions.enumerated()), id: \.offset) { i, q in
                    if i == index {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "sparkle.magnifyingglass")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(OV2.accentSoft)
                            Text(q)
                                .font(DS.title(.title2, .bold))
                                .foregroundStyle(OV2.ink)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(22)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(OV2.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(OV2.hairline, lineWidth: 1))
                        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                    }
                }
            }
            .frame(height: 200)
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)

            Spacer()

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
        .task {
            // Rotation douce des questions tant que l'écran est visible.
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if Task.isCancelled { break }
                withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                    index = (index + 1) % questions.count
                }
                OnboardingHaptics.selection()
            }
        }
    }
}

// MARK: - Réduire le temps d'écran (graphe 2,2×)

/// Graphe animé (non linéaire) : courbe qui monte, et « 2,2× moins de temps d'écran ».
struct OnboardingV2ScreenTimeGraph: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var progress: CGFloat = 0
    @State private var shown: Double = 0
    @State private var titleIn = false

    private let target = 2.2

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 84)

            Text(languageManager.text("onboardingV2.screenTime.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .opacity(titleIn ? 1 : 0)
                .offset(y: titleIn ? 0 : 14)

            Spacer()

            ZStack(alignment: .bottomLeading) {
                // Ligne de base
                Rectangle().fill(OV2.hairline).frame(height: 1).frame(maxHeight: .infinity, alignment: .bottom)

                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    RisingCurve()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(colors: [OV2.accentSoft, OV2.accent], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                        )
                        .overlay(alignment: .topTrailing) {
                            Circle()
                                .fill(OV2.accent)
                                .frame(width: 14, height: 14)
                                .position(x: w * progress, y: h - (h * curveY(progress)))
                                .opacity(progress > 0.05 ? 1 : 0)
                        }
                }

                VStack(alignment: .trailing, spacing: 0) {
                    Text(String(format: "%.1f×", shown).replacingOccurrences(of: ".", with: ","))
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundStyle(OV2.accent)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 8)
            }
            .frame(height: 220)
            .padding(.horizontal, 32)

            Spacer().frame(height: 24)

            Text(languageManager.text("onboardingV2.screenTime.caption"))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(OV2.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .ov2Reveal(delay: 0.6)

            Spacer()

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { titleIn = true }
            withAnimation(.timingCurve(0.2, 0.9, 0.3, 1.0, duration: 1.6).delay(0.3)) {
                progress = 1.0
            }
            animateNumber()
        }
    }

    private func curveY(_ t: CGFloat) -> CGFloat {
        // même profil que RisingCurve (accélération), pour positionner le point.
        CGFloat(pow(Double(t), 1.9))
    }

    private func animateNumber() {
        let steps = 44
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * (1.6 / Double(steps))) {
                let t = Double(i) / Double(steps)
                withAnimation(.easeOut(duration: 0.08)) {
                    shown = target * pow(t, 1.9)
                }
                if i % 10 == 0 { OnboardingHaptics.selection() }
                if i == steps { OnboardingHaptics.counterComplete() }
            }
        }
    }
}

/// Courbe montante non linéaire (accélération vers la droite).
private struct RisingCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.height))
        let steps = 40
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let x = rect.width * CGFloat(t)
            let y = rect.height - rect.height * CGFloat(pow(t, 1.9))
            p.addLine(to: CGPoint(x: x, y: y))
        }
        return p
    }
}

// MARK: - Réussir ses études (carrousel d'avis)

/// Carrousel d'avis d'utilisateurs sur l'amélioration de leurs notes.
struct OnboardingV2ExamsReviews: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var page = 0

    private var reviews: [(quote: String, author: String)] {
        (1...4).map {
            (languageManager.text("onboardingV2.exams.quote\($0)"),
             languageManager.text("onboardingV2.exams.author\($0)"))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 72)

            Text(languageManager.text("onboardingV2.exams.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .ov2Reveal(delay: 0.1)

            Spacer()

            TabView(selection: $page) {
                ForEach(Array(reviews.enumerated()), id: \.offset) { i, review in
                    reviewCard(review).tag(i)
                        .padding(.horizontal, 28)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 260)

            Spacer()

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if Task.isCancelled { break }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    page = (page + 1) % reviews.count
                }
            }
        }
    }

    private func reviewCard(_ review: (quote: String, author: String)) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill").font(.system(size: 14)).foregroundStyle(OV2.warm)
                }
            }
            Text(review.quote)
                .font(DS.sans(.body, .medium))
                .foregroundStyle(OV2.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text(review.author)
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(OV2.inkSecondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 220)
        .background(OV2.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(OV2.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }
}
