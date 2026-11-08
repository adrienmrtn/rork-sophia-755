import SwiftUI

/// La fiche d'un cours (écran « Cours » de la maquette) : couverture, matière et durée, titre,
/// accroche, carte créateur avec « Suivre », introduction, compteurs, puis le bouton qui ouvre
/// le lecteur (« Lire le cours », « Reprendre · section n sur N », « Relire »), et les autres
/// cours du même créateur.
struct CourseDetailView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    let course: Course
    let progressManager: ProgressManager
    let onStart: () -> Void
    let onOpenCreator: (CourseAuthor) -> Void
    let onOpenCourse: (Course) -> Void

    @State private var showOriginal = false
    /// Incrémenté quand le paquet du cours arrive : la fiche se redessine avec l'accroche et
    /// l'introduction du vrai contenu.
    @State private var contentTick = 0

    private var language: AppLanguage { languageManager.current }
    private var content: CourseContentV2? { CourseContentStore.content(courseId: course.id, language: language) }
    private var identity: CreatorIdentity { CreatorIdentity.forCourse(course.id) }
    private var saved: Bool { progressManager.isFavorite(course.id) }
    private var liked: Bool { progressManager.isLiked(course.id) }
    private var status: CourseStatus { progressManager.courseStatus(for: course.id) }
    private var sectionCount: Int { max(1, ReadingTime.sectionCount(for: course, language: language)) }

    private var hook: String {
        (content?.hero?.hook ?? content?.subtitle ?? course.description).withoutInlineMarkup
    }

    /// Les premiers paragraphes de la première section, lisibles sans ouvrir le lecteur.
    private var introduction: String {
        guard let first = content?.sections.first else { return course.description.withoutInlineMarkup }
        let paragraphs = first.blocks.compactMap { block -> String? in
            if case .paragraph(let text) = block { return text.withoutInlineMarkup }
            return nil
        }
        let picked = paragraphs.prefix(2).joined(separator: "\n\n")
        return picked.isEmpty ? course.description.withoutInlineMarkup : picked
    }

    private var otherCourses: [Course] {
        guard let author = identity.author else { return [] }
        return author.courseIds.filter { $0 != course.id }.compactMap { ContentCatalog.course(withId: $0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                let _ = contentTick
                cover
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        SubjectPill(subject: course.subject)
                        Text(String(format: languageManager.text("course.detail.meta"), sectionCount, ReadingTime.minutes(for: course, language: language)))
                            .font(DS.sans(.subheadline))
                            .foregroundStyle(DS.inkSecondary)
                    }

                    Text(course.title.withoutInlineMarkup)
                        .font(DS.title(.title, .heavy))
                        .foregroundStyle(DS.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(hook)
                        .font(DS.sans(.body))
                        .foregroundStyle(DS.inkSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    creatorCard

                    if let code = content?.originalLanguage, code != language.rawValue {
                        translationPanel(code: code)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(languageManager.text("course.detail.introduction").uppercasedInApp())
                            .font(DS.sans(.caption, .bold))
                            .foregroundStyle(DS.inkSecondary)
                            .tracking(0.6)
                        Text(introduction)
                            .font(DS.sans(.body))
                            .foregroundStyle(DS.ink)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    statsRow

                    if status == .completed {
                        Text(languageManager.text("course.detail.done"))
                            .font(DS.sans(.subheadline, .semibold))
                            .foregroundStyle(DS.success)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(DS.successTint))
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onStart()
                    } label: {
                        Text(ctaTitle)
                            .font(DS.sans(.headline, .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(DS.accent))
                    }
                    .buttonStyle(.plain)

                    if !otherCourses.isEmpty {
                        NewGenSectionTitle(text: languageManager.text("course.detail.sameCreator"))
                            .padding(.top, 8)
                        ForEach(otherCourses) { other in
                            CompactCourseRow(
                                course: other,
                                meta: "\(other.readsCount.compactCount) \(languageManager.text("creator.stat.reads")) · \(other.likesCount(liked: progressManager.isLiked(other.id)).compactCount) \(languageManager.text("common.likes"))",
                                onTap: { onOpenCourse(other) }
                            ) {
                                if progressManager.courseStatus(for: other.id) == .completed { ReadCheck() }
                            }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
        .background(DS.canvas.ignoresSafeArea())
        .task(id: course.id) {
            guard CourseContentStore.content(courseId: course.id, language: language) == nil else { return }
            _ = await CourseContentStore.ensureContent(courseId: course.id, language: language)
            contentTick += 1
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Pièces

    private var cover: some View {
        ZStack(alignment: .top) {
            Color.clear
                .frame(height: 290)
                .overlay { CourseCover(course: course, cornerRadius: 0) }
                .clipped()
            HStack {
                RoundIconButton(systemImage: "chevron.left", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    let wasSaved = saved
                    progressManager.toggleFavorite(course.id)
                    AnalyticsService.shared.log(wasSaved ? .unsave : .save, courseId: course.id, screen: "course_detail")
                } label: {
                    Image(systemName: saved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(saved ? DS.accent : DS.ink)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(DS.surface))
                        .overlay(Circle().strokeBorder(DS.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(languageManager.text(saved ? "common.unsave" : "common.save")))
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
        }
    }

    private var creatorCard: some View {
        HStack(spacing: 12) {
            CreatorLine(identity: identity, avatarSize: 44, onTap: identity.author.map { author in { onOpenCreator(author) } })
            if let author = identity.author {
                FollowButton(isFollowing: progressManager.isFollowing(author.slug), compact: true) {
                    toggleFollow(author)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
    }

    private func translationPanel(code: String) -> some View {
        let name = AppLanguage(rawValue: code)?.displayName ?? code.uppercased()
        return HStack(spacing: 8) {
            Image(systemName: "globe")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DS.accent)
            Text(String(format: languageManager.text("course.translatedFrom"), name))
                .font(DS.sans(.footnote, .semibold))
                .foregroundStyle(DS.ink)
            Spacer(minLength: 8)
            Button {
                showOriginal.toggle()
            } label: {
                Text(languageManager.text(showOriginal ? "course.seeTranslation" : "course.seeOriginal"))
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(DS.accentSoft)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DS.accentTint))
    }

    private var statsRow: some View {
        HStack(spacing: 22) {
            StatChip(systemImage: "eye", text: "\(course.readsCount.compactCount) \(languageManager.text("creator.stat.reads"))")
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                let wasLiked = liked
                progressManager.toggleLike(course.id)
                AnalyticsService.shared.log(wasLiked ? .unlike : .like, courseId: course.id, screen: "course_detail")
            } label: {
                StatChip(
                    systemImage: liked ? "heart.fill" : "heart",
                    text: course.likesCount(liked: liked).compactCount,
                    tint: liked ? Color(red: 0.93, green: 0.35, blue: 0.45) : DS.inkSecondary
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(width: 36, height: 36)
            }
            .simultaneousGesture(TapGesture().onEnded {
                AnalyticsService.shared.log(.share, courseId: course.id, props: ["channel": .string("sheet"), "target": .string("course")])
            })
        }
    }

    private var shareText: String {
        String(format: languageManager.text("share.course.message"), course.title.withoutInlineMarkup)
    }

    private var ctaTitle: String {
        switch status {
        case .notStarted:
            return languageManager.text("course.detail.read")
        case .inProgress:
            let index = min(sectionCount, progressManager.lastLessonIndex(for: course.id) + 1)
            return "\(languageManager.text("common.resume")) · \(NewGenFormat.section(index, of: sectionCount, language: language))"
        case .completed:
            return languageManager.text("course.detail.reread")
        }
    }

    private func toggleFollow(_ author: CourseAuthor) {
        let wasFollowing = progressManager.isFollowing(author.slug)
        progressManager.toggleFollow(author.slug)
        AnalyticsService.shared.log(wasFollowing ? .unfollow : .follow, courseId: course.id, screen: "course_detail", props: ["creator": .string(author.slug)])
    }
}
