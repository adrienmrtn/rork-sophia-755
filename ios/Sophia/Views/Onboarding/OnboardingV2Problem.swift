import SwiftUI

/// « Se cultiver c'est long… et cher » : le problème, en trois phrases. Le gras avance mot
/// à mot au rythme de la lecture, ligne après ligne ; une fois la dernière phrase lue, un
/// coup de surligneur passe sur « personnalisé » et « clair ». Pas de bouton : on tape pour
/// passer.
struct OnboardingV2Problem: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    /// Number of words, across all lines, already in bold.
    @State private var boldCount = 0
    @State private var highlighted = false
    @State private var canTap = false
    @State private var hintPulse = false
    @State private var animTask: Task<Void, Never>?

    private var lines: [[String]] {
        (1...3).map { languageManager.text("onboardingV2.problem.line\($0)").split(separator: " ").map(String.init) }
    }

    /// Words that get the highlighter, comma-separated in the strings file.
    private var highlightWords: Set<String> {
        Set(
            languageManager.text("onboardingV2.problem.highlights")
                .split(separator: ",")
                .map { Self.normalized(String($0)) }
                .filter { !$0.isEmpty }
        )
    }

    private var totalWords: Int { lines.reduce(0) { $0 + $1.count } }

    var body: some View {
        ZStack {
            OV2.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    ForEach(lines.indices, id: \.self) { lineIndex in
                        lineView(lineIndex)
                    }
                }
                .padding(.horizontal, 30)

                Spacer()

                Text(languageManager.text("onboardingV2.tapToContinue"))
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(OV2.inkTertiary)
                    .opacity(canTap ? (hintPulse ? 1 : 0.4) : 0)
                    .padding(.bottom, 48)
            }
        }
        .ov2Background()
        .contentShape(Rectangle())
        .onTapGesture {
            guard canTap else {
                // Impatient tap: the rest lands at once, highlighter included.
                animTask?.cancel()
                withAnimation(.easeOut(duration: 0.3)) { boldCount = totalWords }
                withAnimation(.easeOut(duration: 0.5)) { highlighted = true }
                allowTap()
                return
            }
            OnboardingHaptics.primaryCTA()
            onNext()
        }
        .onAppear { play() }
        .onDisappear { animTask?.cancel() }
    }

    // MARK: - Lines

    /// Index of the first word of a line, in the running count.
    private func firstWordIndex(ofLine lineIndex: Int) -> Int {
        lines.prefix(lineIndex).reduce(0) { $0 + $1.count }
    }

    private func lineView(_ lineIndex: Int) -> some View {
        let words = lines[lineIndex]
        let base = firstWordIndex(ofLine: lineIndex)
        let isLast = lineIndex == lines.count - 1
        let style: Font.TextStyle = isLast ? .title2 : .title
        return OV2FlowLayout(spacing: 7, lineSpacing: 8) {
            ForEach(words.indices, id: \.self) { i in
                wordCell(
                    words[i],
                    bold: base + i < boldCount,
                    style: style,
                    highlight: isLast && highlightWords.contains(Self.normalized(words[i]))
                )
            }
        }
    }

    /// One word, in a slot as wide as its bold form so the line never shifts when the
    /// bold arrives. A highlighted word carries a marker stroke behind it that sweeps in
    /// from the left once the reading is over.
    private func wordCell(_ word: String, bold: Bool, style: Font.TextStyle, highlight: Bool) -> some View {
        ZStack {
            Text(word).font(DS.title(style, .heavy)).opacity(0)
            if highlight {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(OV2.warm.opacity(0.55))
                    .padding(.horizontal, -5)
                    .padding(.vertical, 2)
                    .rotationEffect(.degrees(-1.5))
                    .scaleEffect(x: highlighted ? 1 : 0.02, y: 1, anchor: .leading)
                    .opacity(highlighted ? 1 : 0)
            }
            Text(word)
                .font(DS.title(style, bold ? .heavy : .semibold))
                .foregroundStyle(bold ? OV2.ink : OV2.inkTertiary.opacity(0.5))
                .animation(.easeOut(duration: 0.25), value: bold)
        }
        .fixedSize()
    }

    private static func normalized(_ word: String) -> String {
        word.lowercased().trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespaces))
    }

    // MARK: - Animation

    private func play() {
        guard boldCount < totalWords || !highlighted else { allowTap(); return }
        animTask?.cancel()
        animTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            let lineEnds = Set(lines.indices.map { firstWordIndex(ofLine: $0) + lines[$0].count })
            while boldCount < totalWords {
                if Task.isCancelled { return }
                boldCount += 1
                OnboardingHaptics.selection()
                // A breath at the end of each sentence, a steady pace inside it.
                let pause: UInt64 = lineEnds.contains(boldCount) ? 900_000_000 : 150_000_000
                try? await Task.sleep(nanoseconds: pause)
            }
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: 0.55)) { highlighted = true }
            OnboardingHaptics.primaryCTA()
            try? await Task.sleep(nanoseconds: 500_000_000)
            if Task.isCancelled { return }
            allowTap()
        }
    }

    private func allowTap() {
        guard !canTap else { return }
        withAnimation(.easeInOut(duration: 0.4)) { canTap = true }
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) { hintPulse = true }
    }
}
