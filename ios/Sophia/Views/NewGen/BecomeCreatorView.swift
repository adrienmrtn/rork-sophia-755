import SwiftUI

/// La page « Deviens créateur » : l'illustration papier du site, la promesse, les trois étapes,
/// puis la sortie vers le Hub des créateurs dans la langue de l'app (`AppConfig.creatorHubURL`).
/// Ouverte par les cartes du fil, du profil et des pages d'événement.
struct BecomeCreatorView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private var language: AppLanguage { languageManager.current }
    private var authors: [CourseAuthor] { Array(AuthorStore.all.prefix(5)) }
    private var languagesCount: Int { AppLanguage.allCases.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                hero
                    .dsStagger(0)

                VStack(alignment: .leading, spacing: 12) {
                    if !authors.isEmpty {
                        HStack(spacing: 10) {
                            HStack(spacing: -10) {
                                ForEach(authors) { author in
                                    AuthorAvatarView(author: author, size: 32)
                                        .overlay(Circle().strokeBorder(DS.canvas, lineWidth: 2))
                                }
                            }
                            Text(languageManager.text("creator.invite.kicker"))
                                .font(DS.sans(.caption, .semibold))
                                .foregroundStyle(DS.inkSecondary)
                                .lineLimit(2)
                        }
                    }

                    Text(languageManager.text("creator.invite.title"))
                        .font(DS.title(.title, .semibold))
                        .foregroundStyle(DS.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(String(format: languageManager.text("creator.invite.body"), languagesCount))
                        .font(DS.sans(.body))
                        .foregroundStyle(DS.inkSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    FlowChips {
                        perk("pencil", languageManager.text("creator.invite.perk.write"))
                        perk("globe", String(format: languageManager.text("creator.invite.perk.languages"), languagesCount))
                        perk("chart.bar", languageManager.text("creator.invite.perk.paid"))
                    }
                    .padding(.top, 2)
                }
                .dsStagger(1)

                stepsCard
                    .dsStagger(2)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(DS.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) { cta }
    }

    // MARK: - Illustration

    private var hero: some View {
        Image("creator_poster")
            .resizable()
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .homeCard()
            .overlay(alignment: .topLeading) {
                RoundIconButton(systemImage: "chevron.left", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
                    .padding(12)
            }
    }

    // MARK: - Étapes

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                Image("creator_writing")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageManager.text("profile.creator.title"))
                        .font(DS.title(.title3, .semibold))
                        .foregroundStyle(DS.ink)
                    Text(languageManager.text("profile.creator.subtitle"))
                        .font(DS.sans(.subheadline))
                        .foregroundStyle(DS.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                step(1, languageManager.text("profile.creator.step1"))
                step(2, String(format: languageManager.text("profile.creator.step2"), languagesCount))
                step(3, languageManager.text("profile.creator.step3"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .homeCard()
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(DS.sans(.footnote, .bold))
                .foregroundStyle(DS.accent)
                .frame(width: 26, height: 26)
                .background(Circle().fill(DS.accentTint))
            Text(text)
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func perk(_ systemImage: String, _ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.accent)
            Text(text)
                .font(DS.sans(.footnote, .bold))
                .foregroundStyle(DS.ink)
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(Capsule().fill(DS.accentTint))
    }

    // MARK: - Sortie vers le Hub

    private var cta: some View {
        // Le style du CTA fournit la pression élastique et la vibration.
        Button {
            guard let url = AppConfig.creatorHubURL(language: language) else { return }
            openURL(url)
        } label: {
            HStack(spacing: 8) {
                Text(languageManager.text("creator.invite.cta"))
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 14, weight: .bold))
            }
        }
        .buttonStyle(DSPrimaryButtonStyle())
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(DS.canvas)
    }
}
