import SwiftUI

struct CollectionProgressCelebrationView: View {
    @Environment(LanguageManager.self) private var languageManager
    let event: CollectionProgressEvent
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var displayedCount: Int = 0
    @State private var barFill: CGFloat = 0

    private var previousFraction: CGFloat {
        guard event.totalCount > 0 else { return 0 }
        return CGFloat(event.previousCompletedCount) / CGFloat(event.totalCount)
    }

    private var newFraction: CGFloat {
        guard event.totalCount > 0 else { return 0 }
        return CGFloat(event.newCompletedCount) / CGFloat(event.totalCount)
    }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Blocs équilibrés entre le haut de l'écran et le bouton ancré en bas.
                            Spacer(minLength: 24)

                            Text(languageManager.text("celebration.collectionAdvanced"))
                                .font(DS.title(.title, .semibold))
                                .foregroundStyle(DS.ink)
                                .multilineTextAlignment(.center)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 14)

                            Text(event.collection.title)
                                .font(DS.sans(.subheadline))
                                .foregroundStyle(DS.inkSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                                .padding(.top, 6)
                                .opacity(appeared ? 1 : 0)

                            Spacer(minLength: 22)

                            coverCard
                                .padding(.horizontal, 22)
                                .scaleEffect(appeared ? 1 : 0.92)
                                .opacity(appeared ? 1 : 0)

                            Spacer(minLength: 24)

                            progressCard
                                .padding(.horizontal, 22)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 16)

                            Spacer(minLength: 24)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geo.size.height)
                    }
                    .scrollIndicators(.hidden)
                }

                // Le style du CTA fournit la pression élastique et la vibration.
                Button {
                    onContinue()
                } label: {
                    HStack(spacing: 8) {
                        Text(languageManager.text("common.continue"))
                        Image(systemName: "arrow.forward")
                    }
                }
                .buttonStyle(DSPrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
            }
        }
        .onAppear { runSequence() }
        .sophiaColorScheme()
    }

    private var coverCard: some View {
        CollectionCoverView(collection: event.collection, accentIndex: ContentCatalog.activeCollections.firstIndex(of: event.collection) ?? 0)
            .aspectRatio(16 / 9, contentMode: .fit)
            .homeCard()
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(displayedCount)")
                    .font(.jakarta(size: 46, weight: .semibold))
                    .foregroundStyle(DS.ink)
                    .contentTransition(.numericText())
                    .monospacedDigit()
                Text("/ \(event.totalCount)")
                    .font(DS.title(.title3, .medium))
                    .foregroundStyle(DS.inkTertiary)
                Text(languageManager.text("celebration.coursesCompleted"))
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .padding(.leading, 2)
                Spacer()
            }

            DSProgressBar(value: Double(barFill), height: 8)

            HStack(spacing: 8) {
                ForEach(0..<event.totalCount, id: \.self) { index in
                    let filled = index < displayedCount
                    Circle()
                        .fill(filled ? DS.accent : DS.accentTint)
                        .overlay {
                            if filled {
                                Image(systemName: "checkmark")
                                    .font(.jakarta(size: 9, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 22, height: 22)
                    if index < event.totalCount - 1 {
                        Capsule()
                            .fill(index < displayedCount - 1 ? DS.accent : DS.hairline)
                            .frame(height: 2)
                    }
                }
            }
        }
        .dsCard()
    }

    private func runSequence() {
        displayedCount = event.previousCompletedCount
        barFill = previousFraction
        withAnimation(DS.Motion.reveal) {
            appeared = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Haptics.success()
            withAnimation(DS.Motion.reveal) {
                displayedCount = event.newCompletedCount
                barFill = newFraction
            }
        }
    }
}

struct CollectionCompletedCelebrationView: View {
    @Environment(LanguageManager.self) private var languageManager
    let event: CollectionProgressEvent
    let awardedXP: Int
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var cardScale: CGFloat = 0.85

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Blocs équilibrés entre le haut de l'écran et le bouton ancré en bas.
                            Spacer(minLength: 24)

                            Text(languageManager.text("celebration.collectionComplete"))
                                .font(DS.title(.title, .semibold))
                                .foregroundStyle(DS.ink)
                                .multilineTextAlignment(.center)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 14)

                            Text(event.collection.title)
                                .font(DS.sans(.subheadline))
                                .foregroundStyle(DS.inkSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                                .padding(.top, 6)
                                .opacity(appeared ? 1 : 0)

                            Spacer(minLength: 26)

                            completedCard
                                .padding(.horizontal, 22)
                                .scaleEffect(cardScale)
                                .opacity(appeared ? 1 : 0)

                            Spacer(minLength: 26)

                            if awardedXP > 0 {
                                xpPill
                                    .opacity(appeared ? 1 : 0)
                                    .scaleEffect(appeared ? 1 : 0.8)
                            }

                            Spacer(minLength: 28)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geo.size.height)
                    }
                    .scrollIndicators(.hidden)
                }

                Button {
                    onContinue()
                } label: {
                    Text(languageManager.text("common.continue"))
                }
                .buttonStyle(DSPrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
            }
        }
        .onAppear { runSequence() }
        .sophiaColorScheme()
    }

    private var completedCard: some View {
        CollectionCoverView(collection: event.collection, accentIndex: ContentCatalog.activeCollections.firstIndex(of: event.collection) ?? 0)
            .aspectRatio(16 / 9, contentMode: .fit)
            .overlay {
                VStack(spacing: 12) {
                    AnimatedRewardBadge(kind: .seal, size: 44)

                    Text(languageManager.text("collections.pathComplete"))
                        .font(DS.title(.title3, .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.28), in: Capsule())
                }
            }
            .homeCard()
    }

    private var xpPill: some View {
        HStack(spacing: 10) {
            AnimatedRewardBadge(kind: .xp, size: 16, showGlow: false)
                .frame(width: 18, height: 18)
            Text(String(format: languageManager.text("cards.globalXP"), awardedXP))
                .font(DS.title(.headline, .semibold))
                .monospacedDigit()
        }
        .foregroundStyle(DS.accent)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(DS.accentTint, in: Capsule())
    }

    private func runSequence() {
        withAnimation(DS.Motion.pop) {
            appeared = true
            cardScale = 1
        }
        // Une collection terminée est une récompense.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            Haptics.celebrate()
        }
    }
}
