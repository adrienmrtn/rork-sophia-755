import SwiftUI

struct CollectionsOverviewView: View {
    let progressManager: ProgressManager
    let isPremium: Bool
    let onShowPaywall: (SophiaPaywallContext) -> Void
    @Binding var selectedCourse: Course?

    private let ink = BrutalPalette.ink

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("COLLECTIONS")
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .foregroundStyle(ink.opacity(0.55))
                    .tracking(1.2)
                Text("Des parcours guidés pour relier les idées entre elles.")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.62))
            }
            .padding(.horizontal, 20)

            LazyVStack(spacing: 18) {
                ForEach(Array(CollectionData.allCollections.enumerated()), id: \.element.id) { index, collection in
                    NavigationLink(value: collection) {
                        CollectionOverviewCard(
                            collection: collection,
                            progressManager: progressManager,
                            accentIndex: index
                        )
                    }
                    .buttonStyle(BrutalCardButtonStyle(depth: 2))
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

private struct CollectionOverviewCard: View {
    let collection: LearningCollection
    let progressManager: ProgressManager
    let accentIndex: Int

    @State private var appeared = false
    @State private var shimmerOffset: CGFloat = -120

    private let ink = BrutalPalette.ink
    private let depth: CGFloat = 6

    private var completed: Int { progressManager.completedCount(for: collection) }
    private var total: Int { collection.courseIds.count }
    private var fraction: Double { total == 0 ? 0 : Double(completed) / Double(total) }
    private var isComplete: Bool { completed == total && total > 0 }

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(ink)
                .offset(y: depth)

            VStack(alignment: .leading, spacing: 0) {
                CollectionCoverView(collection: collection, accentIndex: accentIndex)
                    .frame(height: 150)
                    .overlay(alignment: .topLeading) {
                        statusBadge
                            .padding(12)
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(ink).frame(height: 3)
                    }

                VStack(alignment: .leading, spacing: 13) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(collection.title)
                                .font(.system(.title3, design: .rounded, weight: .black))
                                .foregroundStyle(ink)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(collection.description)
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundStyle(ink.opacity(0.58))
                                .lineLimit(2)
                        }
                        Spacer(minLength: 6)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(ink)
                            .frame(width: 34, height: 34)
                            .background(Color.white, in: Circle())
                            .overlay { Circle().strokeBorder(ink, lineWidth: 2) }
                    }

                    progressBar

                    HStack(spacing: 8) {
                        Image(systemName: isComplete ? "checkmark.seal.fill" : "square.grid.2x2.fill")
                            .font(.system(size: 12, weight: .black))
                        Text(isComplete ? "Collection terminée" : "\(completed) / \(total) cours terminés")
                            .font(.system(.caption, design: .rounded, weight: .black))
                            .monospacedDigit()
                        Spacer()
                        Text("+\(total * ProgressManager.globalCollectionXPPerCourse) XP")
                            .font(.system(.caption2, design: .rounded, weight: .black))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(BrutalPalette.yellow, in: Capsule())
                            .overlay { Capsule().strokeBorder(ink, lineWidth: 1.8) }
                    }
                    .foregroundStyle(ink.opacity(0.72))
                }
                .padding(16)
                .background(Color.white)
            }
            .clipShape(.rect(cornerRadius: 26))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(ink, lineWidth: 3)
            }
        }
        .padding(.bottom, depth)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(Double(accentIndex % 5) * 0.035)) {
                appeared = true
            }
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                shimmerOffset = 320
            }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: isComplete ? "checkmark" : "sparkles")
                .font(.system(size: 11, weight: .black))
            Text(isComplete ? "TERMINÉE" : "PARCOURS")
                .font(.system(.caption2, design: .rounded, weight: .black))
                .tracking(0.8)
        }
        .foregroundStyle(isComplete ? .white : ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isComplete ? ink : Color.white, in: Capsule())
        .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(white: 0.94))
                    .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
                Capsule()
                    .fill(LinearGradient(colors: [BrutalPalette.pink, BrutalPalette.yellow], startPoint: .leading, endPoint: .trailing))
                    .overlay {
                        Capsule()
                            .fill(LinearGradient(colors: [.clear, .white.opacity(0.6), .clear], startPoint: .leading, endPoint: .trailing))
                            .mask {
                                Rectangle()
                                    .frame(width: 70, height: 16)
                                    .offset(x: shimmerOffset)
                            }
                    }
                    .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
                    .frame(width: max(12, geo.size.width * CGFloat(fraction)))
            }
        }
        .frame(height: 16)
    }
}

struct CollectionDetailView: View {
    let collection: LearningCollection
    let progressManager: ProgressManager
    let isPremium: Bool
    let onShowPaywall: (SophiaPaywallContext) -> Void
    @Binding var selectedCourse: Course?
    @Environment(\.dismiss) private var dismiss

    @State private var appeared = false

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    private var unlockedSubjects: Set<Subject> {
        FreemiumGate.unlockedSubjects(isPremium: isPremium)
    }

    private var completed: Int { progressManager.completedCount(for: collection) }
    private var total: Int { collection.courseIds.count }
    private var fraction: Double { total == 0 ? 0 : Double(completed) / Double(total) }

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                    hero
                        .padding(.horizontal, 20)

                    courseList
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.84)) {
                appeared = true
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 42, height: 42)
                    .background(Color.white, in: Circle())
                    .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
            }
            .buttonStyle(BrutalIconButtonStyle())

            Spacer()

            Text("\(completed)/\(total)")
                .font(.system(.caption, design: .rounded, weight: .black))
                .foregroundStyle(.white)
                .monospacedDigit()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ink, in: Capsule())
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            CollectionCoverView(collection: collection, accentIndex: CollectionData.allCollections.firstIndex(of: collection) ?? 0)
                .frame(height: 200)
                .clipShape(.rect(cornerRadius: 26))
                .overlay { RoundedRectangle(cornerRadius: 26).strokeBorder(ink, lineWidth: 3) }
                .background {
                    RoundedRectangle(cornerRadius: 26).fill(ink).offset(y: 6)
                }
                .padding(.bottom, 6)

            Text(collection.title)
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(collection.description)
                .font(.system(.body, design: .rounded, weight: .heavy))
                .foregroundStyle(ink.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white)
                            .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                        Capsule()
                            .fill(LinearGradient(colors: [BrutalPalette.pink, BrutalPalette.yellow], startPoint: .leading, endPoint: .trailing))
                            .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                            .frame(width: max(20, geo.size.width * CGFloat(fraction)))
                            .animation(.spring(response: 0.65, dampingFraction: 0.82), value: fraction)
                    }
                }
                .frame(height: 22)

                HStack {
                    Text("\(completed) / \(total) cours terminés")
                        .font(.system(.caption, design: .rounded, weight: .black))
                        .foregroundStyle(ink.opacity(0.62))
                        .monospacedDigit()
                    Spacer()
                    Text("+\(progressManager.collectionCompletionXP(for: collection)) XP à la fin")
                        .font(.system(.caption2, design: .rounded, weight: .black))
                        .foregroundStyle(ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(BrutalPalette.yellow, in: Capsule())
                        .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
                }
            }
        }
    }

    private var courseList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COURS DE LA COLLECTION")
                .font(.system(.caption, design: .rounded, weight: .black))
                .foregroundStyle(ink.opacity(0.55))
                .tracking(1.2)
                .padding(.horizontal, 6)

            VStack(spacing: 0) {
                ForEach(Array(collection.courses.enumerated()), id: \.element.id) { index, course in
                    let unlocked = unlockedSubjects.contains(course.subject)
                    CollectionCourseRow(
                        index: index + 1,
                        course: course,
                        status: progressManager.courseStatus(for: course.id),
                        locked: !unlocked,
                        onTap: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if unlocked {
                                selectedCourse = course
                            } else {
                                onShowPaywall(.matiereBlock(for: course.subject))
                            }
                        }
                    )
                    if index < collection.courses.count - 1 {
                        Rectangle().fill(ink).frame(height: 2)
                    }
                }
            }
            .brutalCard()
        }
    }
}

private struct CollectionCourseRow: View {
    let index: Int
    let course: Course
    let status: CourseStatus
    let locked: Bool
    let onTap: () -> Void

    private let ink = BrutalPalette.ink

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(status == .completed ? BrutalPalette.yellow : BrutalPalette.pastel(for: course.subject))
                        .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 13, weight: .black))
                    } else if status == .completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .black))
                    } else {
                        Text("\(index)")
                            .font(.system(.caption, design: .rounded, weight: .black))
                            .monospacedDigit()
                    }
                }
                .foregroundStyle(ink)
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text(course.title)
                        .font(.system(.subheadline, design: .rounded, weight: .black))
                        .foregroundStyle(ink.opacity(locked ? 0.45 : 1))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(course.subject.shortName)
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink.opacity(0.5))
                }

                Spacer(minLength: 8)

                Image(systemName: locked ? "lock.fill" : "arrow.right")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(ink.opacity(locked ? 0.42 : 1))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(locked ? Color(white: 0.97) : Color.white)
        }
        .buttonStyle(.plain)
    }
}

struct CollectionCoverView: View {
    let collection: LearningCollection
    var accentIndex: Int = 0

    private let ink = BrutalPalette.ink

    private var palette: (Color, Color) {
        let palettes: [(Color, Color)] = [
            (Color(red: 0.82, green: 0.78, blue: 1.0), Color(red: 0.50, green: 0.75, blue: 1.0)),
            (Color(red: 1.0, green: 0.553, blue: 0.706), Color(red: 1.0, green: 0.84, blue: 0.35)),
            (Color(red: 0.70, green: 0.95, blue: 0.80), Color(red: 0.66, green: 0.92, blue: 0.96)),
            (Color(red: 1.0, green: 0.78, blue: 0.36), Color(red: 1.0, green: 0.55, blue: 0.18)),
        ]
        return palettes[accentIndex % palettes.count]
    }

    var body: some View {
        ZStack {
            if let image = UIImage(named: collection.coverAssetName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                fallbackCover
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var fallbackCover: some View {
        ZStack {
            LinearGradient(colors: [palette.0, palette.1], startPoint: .topLeading, endPoint: .bottomTrailing)

            Circle()
                .fill(Color.white.opacity(0.24))
                .frame(width: 180, height: 180)
                .offset(x: 120, y: -70)

            Circle()
                .stroke(ink.opacity(0.18), lineWidth: 14)
                .frame(width: 170, height: 170)
                .offset(x: -120, y: 65)

            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(index.isMultiple(of: 2) ? Color.white.opacity(0.28) : ink.opacity(0.14))
                    .frame(width: 78, height: 18)
                    .rotationEffect(.degrees(-18))
                    .offset(x: CGFloat(index * 34 - 88), y: CGFloat(index * 18 - 36))
            }

            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(ink)
                    .symbolEffect(.variableColor.iterative.reversing)
                Text(collection.title)
                    .font(.system(.title3, design: .rounded, weight: .black))
                    .foregroundStyle(ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .shadow(color: Color.white.opacity(0.35), radius: 0, x: 0, y: 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(18)
        }
    }
}
