import SwiftUI

nonisolated enum PostCompletionRewardStep: Identifiable, Sendable {
    case globalRankUp(previous: GlobalRank, new: GlobalRank, newLevel: Int)
    case collectionProgress(CollectionProgressEvent)
    case collectionCompleted(CollectionProgressEvent, awardedXP: Int)
    case streak(streak: Int, subject: Subject, lastActiveDate: String?)

    var id: String {
        switch self {
        case .globalRankUp(_, let new, let newLevel): "rank-\(new.rawValue)-\(newLevel)"
        case .collectionProgress(let event): "collection-progress-\(event.collection.id)-\(event.newCompletedCount)"
        case .collectionCompleted(let event, let awardedXP): "collection-completed-\(event.collection.id)-\(awardedXP)"
        case .streak(let streak, let subject, _): "streak-\(subject.rawValue)-\(streak)"
        }
    }
}

struct PostCompletionRewardFlowView: View {
    let steps: [PostCompletionRewardStep]
    let progressManager: ProgressManager
    let onFinished: () -> Void

    @State private var index: Int = 0

    private var currentStep: PostCompletionRewardStep? {
        guard steps.indices.contains(index) else { return nil }
        return steps[index]
    }

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            if let currentStep {
                stepView(currentStep)
                    .id(currentStep.id)
                    .transition(.opacity.combined(with: .scale(scale: 0.965)))
            }
        }
    }

    @ViewBuilder
    private func stepView(_ step: PostCompletionRewardStep) -> some View {
        switch step {
        case .globalRankUp(let previous, let new, let newLevel):
            GlobalRankUpCelebrationView(
                previousRank: previous,
                newRank: new,
                newLevel: newLevel,
                onContinue: {
                    progressManager.clearPendingGlobalRankUp()
                    advance()
                }
            )
        case .collectionProgress(let event):
            CollectionProgressCelebrationView(event: event, onContinue: advance)
        case .collectionCompleted(let event, let awardedXP):
            CollectionCompletedCelebrationView(
                event: event,
                awardedXP: awardedXP,
                onContinue: advance
            )
        case .streak(let streak, let subject, let lastActiveDate):
            StreakCelebrationView(
                streak: streak,
                subject: subject,
                lastActiveDate: lastActiveDate,
                onReturnHome: advance
            )
        }
    }

    private func advance() {
        if index < steps.count - 1 {
            withAnimation(.easeInOut(duration: 0.28)) {
                index += 1
            }
        } else {
            onFinished()
        }
    }
}
