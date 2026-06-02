import SwiftUI

struct SubjectBadgeView: View {
    let subject: Subject
    var unlocked: Bool = true
    var emojiSize: CGFloat = 28
    var cornerRadius: CGFloat = 12

    private let ink = BrutalPalette.ink

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(unlocked ? BrutalPalette.pastel(for: subject) : Color(white: 0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(ink, lineWidth: 2)
                }

            if unlocked {
                Text(subject.emoji)
                    .font(.system(size: emojiSize))
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: emojiSize * 0.55, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.55))
            }
        }
    }
}
