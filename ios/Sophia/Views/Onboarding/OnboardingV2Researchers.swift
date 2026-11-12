import SwiftUI
import UIKit

/// Écran 4 — Chercheurs. Quatre portraits « papier » de vrais auteurs de l'app qui se
/// chevauchent, le titre « écrites par de vrais chercheurs », et leurs institutions en
/// pastilles. Les noms et les institutions viennent du catalogue (`AuthorStore`) ; seuls les
/// portraits illustrés sont embarqués dans les assets.
struct OnboardingV2Researchers: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onNext: () -> Void

    @State private var professors: [Professor] = []
    @State private var portraitsShown = 0
    @State private var textIn = false
    @State private var pillsIn = false

    struct Professor: Identifiable {
        /// Le slug de l'auteur dans le catalogue.
        let id: String
        /// Nom de l'imageset du portrait illustré.
        let asset: String
        /// Nom de l'auteur, lu par VoiceOver ; nil si le catalogue ne le connaît pas.
        let name: String?
        /// Son institution, ou à défaut son titre : le texte de sa pastille.
        let credential: String?
    }

    /// Les auteurs qui ont un portrait illustré : slug du catalogue → imageset.
    private static let portraits: [(slug: String, asset: String)] = [
        (slug: "stacy-jankowski", asset: "onb_prof_stacy"),
        (slug: "simon-lea", asset: "onb_prof_simon"),
        (slug: "dusan-nikolic", asset: "onb_prof_dusan"),
        (slug: "guido-manuel-de-la-torre-olvera", asset: "onb_prof_guido"),
    ]

    private static let portraitSize: CGFloat = 92
    private static let portraitOverlap: CGFloat = 22
    /// Bleu nuit du texte des pastilles, sur leur fond bleu pâle.
    private static let pillInk = Color(red: 0.102, green: 0.227, blue: 0.420)

    /// Les pastilles, sans doublon (deux auteurs peuvent partager une université).
    private var credentials: [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for professor in professors {
            guard let credential = professor.credential, !credential.isEmpty else { continue }
            if seen.insert(credential).inserted {
                result.append(credential)
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 22) {
                portraitRow

                OV2Markup.elevate(languageManager.text("onboardingV2.intro.researchers.title"))
                    .font(DS.title(.title, .regular))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .lineLimit(5)
                    .minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
                    .opacity(textIn ? 1 : 0)
                    .offset(y: textIn || reduceMotion ? 0 : 14)

                if !credentials.isEmpty {
                    pills
                }

                Text(languageManager.text("onboardingV2.intro.researchers.subtitle"))
                    .font(DS.sans(.subheadline, .regular))
                    .foregroundStyle(OV2.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(textIn ? 1 : 0)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
                .padding(.top, 14)
        }
        .ov2Background()
        .onAppear { loadProfessors() }
        .task { await play() }
    }

    // MARK: - Portraits

    private var portraitRow: some View {
        HStack(spacing: -Self.portraitOverlap) {
            ForEach(Array(professors.enumerated()), id: \.element.id) { index, professor in
                portrait(professor, shown: index < portraitsShown)
                    .zIndex(Double(index))
            }
        }
        .frame(height: Self.portraitSize)
    }

    private func portrait(_ professor: Professor, shown: Bool) -> some View {
        Image(professor.asset)
            .resizable()
            .scaledToFill()
            .frame(width: Self.portraitSize, height: Self.portraitSize)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(DS.surface, lineWidth: 4))
            .scaleEffect(shown || reduceMotion ? 1 : 0.3)
            .opacity(shown ? 1 : 0)
            .accessibilityLabel(Text(professor.name ?? ""))
            .accessibilityHidden(professor.name == nil)
    }

    // MARK: - Institutions

    private var pills: some View {
        OnboardingV2PillFlow(spacing: 8, lineSpacing: 8) {
            ForEach(Array(credentials.enumerated()), id: \.element) { index, credential in
                Text(credential)
                    .font(DS.sans(.footnote, .semibold))
                    .foregroundStyle(Self.pillInk)
                    .lineLimit(1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous).fill(DS.accentTint)
                    )
                    .scaleEffect(pillsIn || reduceMotion ? 1 : 0.8)
                    .opacity(pillsIn ? 1 : 0)
                    .animation(
                        reduceMotion ? .easeOut(duration: 0.2) : DS.Motion.snappy.delay(Double(index) * 0.07),
                        value: pillsIn
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Données et animation

    /// Les quatre auteurs illustrés, avec ce que le catalogue sait d'eux. Un auteur absent
    /// du catalogue garde son portrait, sans nom ni pastille.
    private func loadProfessors() {
        guard professors.isEmpty else { return }
        let language: AppLanguage = languageManager.current
        var loaded: [Professor] = []
        for entry in Self.portraits {
            guard UIImage(named: entry.asset) != nil else { continue }
            let author: CourseAuthor? = AuthorStore.author(slug: entry.slug)
            loaded.append(Professor(
                id: entry.slug,
                asset: entry.asset,
                name: author?.name,
                credential: author.flatMap { Self.credential(of: $0, language: language) }
            ))
        }
        professors = loaded
    }

    /// L'institution de l'auteur ; sinon la première partie de son titre (« Docteur en
    /// philosophie, chercheur indépendant » → « Docteur en philosophie »).
    private static func credential(of author: CourseAuthor, language: AppLanguage) -> String? {
        if let institution = author.institution?.trimmingCharacters(in: .whitespacesAndNewlines), !institution.isEmpty {
            return institution
        }
        guard let title = author.title(for: language) else { return nil }
        let first: String = title
            .split(separator: ",", maxSplits: 1)
            .first
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) } ?? ""
        return first.isEmpty ? nil : first
    }

    /// Les portraits se posent un à un, puis le titre, puis les pastilles en cascade.
    private func play() async {
        guard !textIn else { return }
        if reduceMotion {
            portraitsShown = Self.portraits.count
            textIn = true
            pillsIn = true
            return
        }

        await pause(0.2)
        for count in 1...Self.portraits.count {
            if Task.isCancelled { return }
            withAnimation(DS.Motion.pop) {
                portraitsShown = count
            }
            Haptics.tick(0.4)
            await pause(0.12)
        }
        if Task.isCancelled { return }
        withAnimation(DS.Motion.reveal) {
            textIn = true
        }
        await pause(0.25)
        if Task.isCancelled { return }
        pillsIn = true
        Haptics.soft()
    }

    private func pause(_ seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

// MARK: - Pastilles qui passent à la ligne

/// Place les pastilles les unes après les autres et passe à la ligne quand la largeur est
/// dépassée, chaque ligne centrée.
struct OnboardingV2PillFlow: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth: CGFloat = proposal.width ?? .greatestFiniteMagnitude
        let rows: [Row] = layoutRows(maxWidth: maxWidth, subviews: subviews)
        let width: CGFloat = rows.map(\.width).max() ?? 0
        let height: CGFloat = rows.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: min(maxWidth, width), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let rows: [Row] = layoutRows(maxWidth: bounds.width, subviews: subviews)
        var y: CGFloat = bounds.minY
        for row in rows {
            var x: CGFloat = bounds.minX + (bounds.width - row.width) / 2
            for index in row.indices {
                let size: CGSize = subviews[index].sizeThatFits(.unspecified)
                let fitted = CGSize(width: min(size.width, bounds.width), height: size.height)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - fitted.height) / 2),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(fitted)
                )
                x += fitted.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private func layoutRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let ideal: CGSize = subviews[index].sizeThatFits(.unspecified)
            let size = CGSize(width: min(ideal.width, maxWidth), height: ideal.height)
            let projected: CGFloat = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if !current.indices.isEmpty && projected > maxWidth {
                rows.append(current)
                current = Row(indices: [index], width: size.width, height: size.height)
            } else {
                current.width = projected
                current.height = max(current.height, size.height)
                current.indices.append(index)
            }
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
