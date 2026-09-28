import SwiftUI

// Author-facing pieces of the course reader: the byline under the hero (intro page), the
// "written by" card and the sources list at the end of the last page. All three are drawn
// by `BlockContentView` from the course's `author` / `sources` fields; nothing appears for
// house content that has neither.

// MARK: - Avatar

/// Portrait when the author has one, initials on a tinted disc otherwise.
struct AuthorAvatarView: View {
    let author: CourseAuthor
    var size: CGFloat = 40

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Circle().fill(DS.accentTint)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(author.initials)
                    .font(.jakarta(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(DS.accentSoft)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
        .onAppear {
            if image == nil { image = AuthorStore.photo(for: author) }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Byline (intro page)

/// "Par Dusan Nikolic · Historien de l'art…" under the hero hook. The intro is the free
/// page, so this is what tells a hesitant reader who stands behind the course.
struct AuthorBylineV2: View {
    let author: CourseAuthor
    let onTap: (CourseAuthor) -> Void

    private var language: AppLanguage { AppLanguage.currentPersisted() }

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap(author)
        } label: {
            HStack(spacing: 12) {
                AuthorAvatarView(author: author, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: AppLocalizable.string("course.author.by", language: language), author.name))
                        .font(DS.sans(.subheadline, .semibold))
                        .foregroundStyle(DS.ink)
                    if let title = author.title(for: language) {
                        Text(title)
                            .font(DS.sans(.caption))
                            .foregroundStyle(DS.inkSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.forward")
                    .font(.jakarta(size: 12, weight: .semibold))
                    .foregroundStyle(DS.inkTertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(format: AppLocalizable.string("course.author.by", language: language), author.name))
    }
}

// MARK: - Author card (last page)

/// The signature at the end of the course: portrait, name, pedigree, short bio, and the door
/// to the author's other courses.
struct AuthorCardV2: View {
    let author: CourseAuthor
    let onTap: (CourseAuthor) -> Void

    private var language: AppLanguage { AppLanguage.currentPersisted() }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "person.text.rectangle")
                    .font(.jakarta(size: 12, weight: .semibold))
                    .foregroundStyle(DS.accentSoft)
                Text(AppLocalizable.string("course.author.writtenBy", language: language).uppercased())
                    .font(DS.sans(.caption2, .semibold))
                    .foregroundStyle(DS.accentSoft)
                    .tracking(1.2)
            }

            HStack(alignment: .center, spacing: 14) {
                AuthorAvatarView(author: author, size: 56)
                VStack(alignment: .leading, spacing: 3) {
                    Text(author.name)
                        .font(DS.title(.title3, .semibold))
                        .foregroundStyle(DS.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let title = author.title(for: language) {
                        Text(title)
                            .font(DS.sans(.subheadline))
                            .foregroundStyle(DS.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }

            if let bio = author.bio(for: language) {
                Text(bio)
                    .font(DS.sans(.footnote))
                    .foregroundStyle(DS.inkSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onTap(author)
            } label: {
                HStack(spacing: 8) {
                    Text(AppLocalizable.string("author.otherCourses", language: language))
                    Image(systemName: "arrow.forward")
                        .font(.jakarta(size: 13, weight: .semibold))
                }
            }
            .buttonStyle(DSSecondaryButtonStyle())
        }
        .padding(DS.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .fill(DS.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                        .strokeBorder(DS.hairline, lineWidth: 1)
                }
        }
        .dsSoftShadow()
    }
}

// MARK: - Sources (last page)

/// References behind the course, folded like the "did you know" card so they never weigh
/// on the reading; a tap unfolds the list, each reference with a link when it has one.
struct SourcesCardV2: View {
    let sources: [CourseSourceV2]

    @State private var revealed = false

    private var language: AppLanguage { AppLanguage.currentPersisted() }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                    revealed.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(DS.accentTint)
                        Image(systemName: "text.book.closed")
                            .font(.jakarta(size: 15, weight: .medium))
                            .foregroundStyle(DS.accentSoft)
                    }
                    .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(AppLocalizable.string("course.sources", language: language)) · \(sources.count)")
                            .font(DS.sans(.subheadline, .semibold))
                            .foregroundStyle(DS.ink)
                        if !revealed {
                            Text(AppLocalizable.string("course.sources.hint", language: language))
                                .font(DS.sans(.caption2))
                                .foregroundStyle(DS.inkTertiary)
                        }
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.down")
                        .font(.jakarta(size: 13, weight: .semibold))
                        .foregroundStyle(DS.inkTertiary)
                        .rotationEffect(.degrees(revealed ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if revealed {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(sources.enumerated()), id: \.offset) { index, source in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(DS.sans(.caption2, .semibold))
                                .foregroundStyle(DS.accentSoft)
                                .frame(width: 18, alignment: .trailing)
                                .monospacedDigit()
                            VStack(alignment: .leading, spacing: 4) {
                                Text(source.text)
                                    .font(DS.sans(.footnote))
                                    .foregroundStyle(DS.inkSecondary)
                                    .lineSpacing(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let url = source.linkURL {
                                    Link(destination: url) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.up.right.square")
                                                .font(.jakarta(size: 11, weight: .semibold))
                                            Text(AppLocalizable.string("course.sources.open", language: language))
                                                .font(DS.sans(.caption, .semibold))
                                        }
                                        .foregroundStyle(DS.accentSoft)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.top, 14)
                .transition(.opacity)
            }
        }
        .padding(DS.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .fill(DS.surfaceMuted)
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                        .strokeBorder(DS.hairline, lineWidth: 1)
                }
        }
    }
}
