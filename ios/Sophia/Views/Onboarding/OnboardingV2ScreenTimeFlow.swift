import SwiftUI

// MARK: - Time formatting helper

enum OnboardingScreenTimeFormat {
    /// « 3h30 » / « 3h » / « 45 min » selon la valeur.
    static func label(minutes: Int, language: AppLanguage) -> String {
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m == 0 ? "\(h)h" : String(format: "%dh%02d", h, m)
        }
        return String(format: AppLocalizable.string("onboardingV2.screenTime.minutes", language: language), minutes)
    }
}

// MARK: - Page 1/4 — Slider temps d'écran

/// « Combien de temps passes-tu par jour sur ton téléphone ? »
/// Slider de 30 min à 10 h par blocs de 30 min ; le grand chiffre roule en slide-up.
struct OnboardingV2PhoneTime: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var minutes: Double = 180
    @State private var lastStep: Int = 6

    private let range: ClosedRange<Double> = 30...600
    private let step: Double = 30

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 84)

            Text(languageManager.text("onboardingV2.phoneTime.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .ov2Reveal(delay: 0.1)

            Spacer()

            Text(OnboardingScreenTimeFormat.label(minutes: Int(minutes), language: languageManager.current))
                .font(.system(size: 68, weight: .heavy, design: .rounded))
                .foregroundStyle(OV2.accent)
                .monospacedDigit()
                .contentTransition(.numericText(value: minutes))
                .animation(.spring(response: 0.35, dampingFraction: 0.82), value: minutes)

            Spacer().frame(height: 32)

            VStack(spacing: 8) {
                Slider(value: $minutes, in: range, step: step)
                    .tint(OV2.accent)
                    .onChange(of: minutes) { _, newValue in
                        let s = Int(newValue / step)
                        if s != lastStep {
                            lastStep = s
                            vm.phoneDailyMinutes = Int(newValue)
                            OnboardingHaptics.selection()
                        }
                    }

                HStack {
                    Text(OnboardingScreenTimeFormat.label(minutes: Int(range.lowerBound), language: languageManager.current))
                    Spacer()
                    Text(OnboardingScreenTimeFormat.label(minutes: Int(range.upperBound), language: languageManager.current))
                }
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(OV2.inkTertiary)
            }
            .padding(.horizontal, 36)
            .ov2Reveal(delay: 0.3)

            Spacer()

            OnboardingV2Button(title: languageManager.text("common.continue")) {
                vm.phoneDailyMinutes = Int(minutes)
                onNext()
            }
        }
        .ov2Background()
        .onAppear {
            minutes = Double(vm.phoneDailyMinutes)
            lastStep = Int(minutes / step)
        }
    }
}

// MARK: - Page 2/4 — Ta vie en années (80 carrés)

/// 80 carrés = 80 années de vie. Les carrés se remplissent lentement en rouge selon le
/// temps d'écran quotidien (part de vie passée sur le téléphone).
struct OnboardingV2YearsGrid: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var filled: Int = 0
    @State private var showCaption = false

    private let totalYears = 80
    private let columns = 10

    private var redYears: Int {
        max(1, min(totalYears, Int(vm.phoneYearsOverLife.rounded())))
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 84)

            Text(languageManager.text("onboardingV2.yearsGrid.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .ov2Reveal(delay: 0.1)

            Spacer()

            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(0..<totalYears, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(i < filled ? OV2.danger : OV2.hairline.opacity(0.7))
                        .aspectRatio(1, contentMode: .fit)
                        .scaleEffect(i < filled ? 1 : 0.82)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: filled)
                }
            }
            .padding(.horizontal, 36)

            Spacer().frame(height: 28)

            Text(String(
                format: languageManager.text("onboardingV2.yearsGrid.caption"),
                OnboardingScreenTimeFormat.label(minutes: vm.phoneDailyMinutes, language: languageManager.current),
                redYears
            ))
            .font(DS.sans(.subheadline, .semibold))
            .foregroundStyle(OV2.inkSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 36)
            .opacity(showCaption ? 1 : 0)
            .offset(y: showCaption ? 0 : 12)

            Spacer()

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear { animateFill() }
    }

    private func animateFill() {
        let target = redYears
        let perSquare = 0.07
        for i in 1...target {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * perSquare) {
                filled = i
                if i % 3 == 0 { OnboardingHaptics.selection() }
                if i == target { OnboardingHaptics.counterComplete() }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(target) * perSquare + 0.2) {
            withAnimation(.easeOut(duration: 0.5)) { showCaption = true }
        }
    }
}

// MARK: - Page 3/4 — « Transforme ce temps en culture »

/// Moment doux : la phrase « Avec Sophia, transforme ce temps en culture » se met en gras
/// progressivement (mot par mot). Pas de CTA : on tape n'importe où pour continuer.
struct OnboardingV2Transform: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var boldCount = 0
    @State private var showHint = false
    @State private var advanced = false

    private var words: [String] {
        languageManager.text("onboardingV2.transform.text")
            .split(separator: " ")
            .map(String.init)
    }

    private var styledText: Text {
        let all = words
        var result = Text("")
        for (i, word) in all.enumerated() {
            let isBold = i < boldCount
            let isLast = i == all.count - 1
            let suffix = isLast ? "" : " "
            let color: Color = isBold ? (isLast ? OV2.accent : OV2.ink) : OV2.inkTertiary
            let piece = Text(word + suffix)
                .font(DS.title(.title, isBold ? .heavy : .regular))
                .foregroundColor(color)
            result = result + piece
        }
        return result
    }

    var body: some View {
        ZStack {
            OV2.bg.ignoresSafeArea()

            styledText
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
                .animation(.easeOut(duration: 0.35), value: boldCount)

            VStack {
                Spacer()
                Text(languageManager.text("onboardingV2.transform.tapHint"))
                    .font(DS.sans(.footnote, .semibold))
                    .foregroundStyle(OV2.inkTertiary)
                    .opacity(showHint ? 1 : 0)
                    .padding(.bottom, 40)
            }
        }
        .ov2Background()
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .onAppear { animate() }
    }

    private func animate() {
        let count = words.count
        guard count > 0 else {
            showHint = true
            return
        }
        for i in 1...count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * 0.35) {
                boldCount = i
                OnboardingHaptics.selection()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(count) * 0.35 + 0.4) {
            withAnimation(.easeIn(duration: 0.6)) { showHint = true }
        }
    }

    private func advance() {
        guard !advanced else { return }
        advanced = true
        onNext()
    }
}
