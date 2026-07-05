import SwiftUI
import WidgetKit

struct CourseOfDayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CourseOfDayEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            case .systemLarge:
                largeView
            default:
                mediumView
            }
        }
        .widgetURL(URL(string: entry.snapshot.deepLinkURL))
    }

    private var smallView: some View {
        ZStack(alignment: .bottomLeading) {
            courseImage
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            LinearGradient(
                colors: [.clear, WidgetSubjectStyle.ink.opacity(0.72)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                badge
                Text(entry.snapshot.title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            }
            .padding(10)
        }
        .background(WidgetSubjectStyle.cream)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(WidgetSubjectStyle.ink, lineWidth: 2.5)
        }
    }

    private var mediumView: some View {
        HStack(spacing: 0) {
            courseImage
                .frame(width: 118)
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                badge
                Text(entry.snapshot.title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(WidgetSubjectStyle.ink)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)

                subjectPill
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WidgetSubjectStyle.pastel(for: entry.snapshot.subjectKey))
        }
        .background(WidgetSubjectStyle.cream)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(WidgetSubjectStyle.ink, lineWidth: 2.5)
        }
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                courseImage
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .clipped()

                LinearGradient(
                    colors: [.clear, WidgetSubjectStyle.ink.opacity(0.55)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 150)

                badge
                    .padding(12)
            }

            VStack(alignment: .leading, spacing: 10) {
                subjectPill
                Text(entry.snapshot.title)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(WidgetSubjectStyle.ink)
                    .lineLimit(4)
                    .minimumScaleFactor(0.85)

                Text("Ouvre Sophia pour lire ce cours.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetSubjectStyle.ink.opacity(0.6))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WidgetSubjectStyle.pastel(for: entry.snapshot.subjectKey))
        }
        .background(WidgetSubjectStyle.cream)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(WidgetSubjectStyle.ink, lineWidth: 2.5)
        }
    }

    private var badge: some View {
        Text("Cours du jour")
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundStyle(WidgetSubjectStyle.ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay {
                Capsule().strokeBorder(WidgetSubjectStyle.ink, lineWidth: 1.5)
            }
    }

    private var subjectPill: some View {
        Text(entry.snapshot.subjectLabel)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(WidgetSubjectStyle.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.85))
            .clipShape(Capsule())
            .overlay {
                Capsule().strokeBorder(WidgetSubjectStyle.ink, lineWidth: 1.5)
            }
    }

    @ViewBuilder
    private var courseImage: some View {
        if let url = DailyCourseStore.imageURL(for: entry.snapshot),
           let uiImage = UIImage(contentsOfFile: url.path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            WidgetSubjectStyle.pastel(for: entry.snapshot.subjectKey)
                .overlay {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(WidgetSubjectStyle.ink.opacity(0.35))
                }
        }
    }
}
