import SwiftUI

/// "You learned something, well done": shown over home once a shield-originated visit
/// has finished its course and quiz. TikTok is already unlocked by the time this appears;
/// the screen just says so and offers the way back.
struct TikTokUnlockedView: View {
    @Environment(LanguageManager.self) private var languageManager
    let onBackToTikTok: () -> Void
    let onStay: () -> Void

    private var blocker: TikTokBlockerManager { TikTokBlockerManager.shared }

    @State private var appeared = false
    @State private var hapticTrigger = 0

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(DS.successTint)
                        .frame(width: 132, height: 132)
                    Circle()
                        .strokeBorder(DS.success.opacity(0.25), lineWidth: 1)
                        .frame(width: 164, height: 164)
                        .scaleEffect(appeared ? 1 : 0.7)
                        .opacity(appeared ? 1 : 0)
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(DS.success)
                        .scaleEffect(appeared ? 1 : 0.5)
                }
                .padding(.bottom, 28)

                Text(languageManager.text("tiktokBlocker.unlocked.title"))
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Text(String(format: languageManager.text("tiktokBlocker.unlocked.subtitle"), blocker.unlockMinutes))
                    .font(DS.sans(.body, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 10)

                if let until = blocker.unlockedUntil {
                    VStack(spacing: 4) {
                        Text(languageManager.text("tiktokBlocker.unlocked.timer").uppercased())
                            .font(DS.sans(.caption2, .semibold))
                            .tracking(1.2)
                            .foregroundStyle(DS.inkTertiary)
                        Text(until, style: .timer)
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(DS.accent)
                    }
                    .padding(.top, 26)
                }

                if !blocker.canOpenTikTok {
                    Text(languageManager.text("tiktokBlocker.unlocked.notInstalled"))
                        .font(DS.sans(.caption, .medium))
                        .foregroundStyle(DS.inkTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                        .padding(.top, 14)
                }

                Spacer()

                VStack(spacing: 12) {
                    if blocker.canOpenTikTok {
                        Button {
                            hapticTrigger += 1
                            onBackToTikTok()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.up.forward.app.fill")
                                    .font(.jakarta(size: 16, weight: .semibold))
                                Text(languageManager.text("tiktokBlocker.unlocked.back"))
                                    .font(DS.sans(.headline, .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(DS.accent, in: RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
                        }
                        .buttonStyle(SoftPressButtonStyle())
                    }

                    Button {
                        hapticTrigger += 1
                        onStay()
                    } label: {
                        Text(languageManager.text("tiktokBlocker.unlocked.stay"))
                            .font(DS.sans(.subheadline, .semibold))
                            .foregroundStyle(DS.inkSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(SoftPressButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .safeAreaPadding(.bottom)
        }
        .sensoryFeedback(.success, trigger: appeared)
        .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.05)) {
                appeared = true
            }
        }
        // The window can run out while this sits on screen (phone left on the table):
        // nothing to celebrate any more, so it steps aside.
        .task {
            while !Task.isCancelled {
                if !blocker.isUnlockWindowOpen {
                    onStay()
                    return
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
}

/// Thin reminder at the top of the reader while TikTok waits for this course.
struct TikTokLockBanner: View {
    @Environment(LanguageManager.self) private var languageManager

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.jakarta(size: 11, weight: .bold))
            Text(languageManager.text("tiktokBlocker.banner"))
                .font(DS.sans(.caption, .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(DS.accentSoft)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(DS.accentTint, in: Capsule())
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
