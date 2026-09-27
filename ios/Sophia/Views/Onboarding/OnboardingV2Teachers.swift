import SwiftUI
import UIKit

/// « Des cours écrits par des profs certifiés » : la crédibilité, avec les logos des
/// universités qui défilent en continu. Les logos sont lus dans le bundle
/// (`university_*.png`, voir `Resources/UniversityLogos/README.md`) ; sans aucun logo la
/// bande montre des pictogrammes, pour que la page ne soit jamais vide.
struct OnboardingV2Teachers: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var logos: [UIImage] = []
    @State private var offset: CGFloat = 0
    @State private var stripWidth: CGFloat = 0

    private let logoHeight: CGFloat = 44
    private let gap: CGFloat = 40

    var body: some View {
        OV2ScrollableContent {
            VStack(spacing: 0) {
                Spacer().frame(height: 84)

                ZStack {
                    Circle().fill(OV2.accent.opacity(0.10)).frame(width: 108, height: 108)
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(OV2.accent)
                }
                .ov2Reveal(delay: 0.05)

                Spacer().frame(height: 30)

                Text(languageManager.text("onboardingV2.teachers.title"))
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .ov2Reveal(delay: 0.15)

                Spacer().frame(height: 12)

                Text(languageManager.text("onboardingV2.teachers.subtitle"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(OV2.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
                    .ov2Reveal(delay: 0.25)

                Spacer().frame(height: 40)

                marquee
                    .ov2Reveal(delay: 0.35)

                Spacer().frame(height: 12)

                Text(languageManager.text("onboardingV2.teachers.caption").uppercased())
                    .font(DS.sans(.caption2, .semibold))
                    .tracking(1.2)
                    .foregroundStyle(OV2.inkTertiary)
                    .ov2Reveal(delay: 0.45)

                Spacer().frame(height: 24)
            }
        } footer: {
            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear { logos = Self.loadLogos() }
    }

    // MARK: - Marquee

    /// Two copies of the strip side by side, slid left forever: when the first copy is
    /// fully out, the offset wraps and the second is exactly where the first was.
    private var marquee: some View {
        TimelineView(.animation) { context in
            HStack(spacing: gap) {
                strip
                strip
            }
            .offset(x: -marqueeOffset(at: context.date))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: logoHeight + 16)
        .clipped()
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.12),
                    .init(color: .black, location: 0.88),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .leading, endPoint: .trailing
            )
        )
    }

    /// 38 points per second, wrapped on the strip width.
    private func marqueeOffset(at date: Date) -> CGFloat {
        guard stripWidth > 0 else { return 0 }
        let travelled: Double = date.timeIntervalSinceReferenceDate * 38.0
        let wrapped: Double = travelled.truncatingRemainder(dividingBy: Double(stripWidth))
        return CGFloat(wrapped)
    }

    private var strip: some View {
        HStack(spacing: gap) {
            if logos.isEmpty {
                ForEach(0..<6, id: \.self) { i in
                    placeholder(i)
                }
            } else {
                ForEach(logos.indices, id: \.self) { i in
                    Image(uiImage: logos[i])
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fit)
                        .frame(height: logoHeight)
                        .opacity(0.85)
                }
            }
        }
        .padding(.trailing, gap)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            stripWidth = width
        }
    }

    private func placeholder(_ i: Int) -> some View {
        let symbols = ["building.columns.fill", "books.vertical.fill", "graduationcap.fill", "text.book.closed.fill", "building.2.fill", "scroll.fill"]
        return Image(systemName: symbols[i % symbols.count])
            .font(.system(size: 30, weight: .medium))
            .foregroundStyle(OV2.inkTertiary)
            .frame(width: 72, height: logoHeight)
    }

    private static func loadLogos() -> [UIImage] {
        let urls = Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: nil) ?? []
        return urls
            .filter { $0.lastPathComponent.hasPrefix("university_") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { UIImage(contentsOfFile: $0.path) }
    }
}
