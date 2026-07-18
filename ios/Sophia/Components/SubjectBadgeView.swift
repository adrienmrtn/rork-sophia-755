import SwiftUI

/// Calm subject badge — an SF Symbol icon on a soft accent-tint surface (no emoji, no border).
struct SubjectBadgeView: View {
    let subject: Subject
    var unlocked: Bool = true
    var iconSize: CGFloat = 28
    var cornerRadius: CGFloat = 12

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(unlocked ? DS.accentTint : DS.surfaceMuted)

            Image(systemName: unlocked ? subject.icon : "lock.fill")
                .font(.system(size: iconSize * 0.5, weight: .medium))
                .foregroundStyle(unlocked ? DS.accentSoft : DS.inkTertiary)
        }
    }
}
