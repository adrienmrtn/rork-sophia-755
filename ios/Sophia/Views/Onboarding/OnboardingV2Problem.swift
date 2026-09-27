import SwiftUI

/// « Se cultiver c'est long… et cher » : le problème, en trois phrases qui arrivent l'une
/// après l'autre, juste avant « Sophia va t'aider ». Pas de bouton : on tape pour passer.
struct OnboardingV2Problem: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var revealed = 0
    @State private var canTap = false
    @State private var hintPulse = false
    @State private var animTask: Task<Void, Never>?

    private var lines: [String] {
        (1...3).map { languageManager.text("onboardingV2.problem.line\($0)") }
    }

    var body: some View {
        ZStack {
            OV2.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 26) {
                    ForEach(lines.indices, id: \.self) { i in
                        let isLast = i == lines.count - 1
                        Text(lines[i])
                            .font(DS.title(isLast ? .title2 : .title, .heavy))
                            .foregroundStyle(isLast ? OV2.accent : OV2.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(i < revealed ? 1 : 0)
                            .offset(y: i < revealed ? 0 : 16)
                            .blur(radius: i < revealed ? 0 : 6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)

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
                // Impatient tap: the rest of the text lands at once.
                animTask?.cancel()
                withAnimation(.easeOut(duration: 0.35)) { revealed = lines.count }
                allowTap()
                return
            }
            OnboardingHaptics.primaryCTA()
            onNext()
        }
        .onAppear { play() }
        .onDisappear { animTask?.cancel() }
    }

    private func play() {
        guard revealed < lines.count else { allowTap(); return }
        animTask?.cancel()
        animTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            for i in revealed..<lines.count {
                if Task.isCancelled { return }
                withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) { revealed = i + 1 }
                OnboardingHaptics.selection()
                try? await Task.sleep(nanoseconds: i == lines.count - 2 ? 1_900_000_000 : 1_500_000_000)
            }
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
