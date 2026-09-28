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

    private let logoHeight: CGFloat = 84
    private let gap: CGFloat = 44
    /// Fixed slot per logo, so the strip's width is known without measuring anything.
    private let slotWidth: CGFloat = 176

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

                Spacer().frame(height: 44)

                marquee
                    .ov2Reveal(delay: 0.3)

                Spacer().frame(height: 24)
            }
        } footer: {
            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear { logos = Self.loadLogos() }
    }

    // MARK: - Marquee

    private var slotCount: Int { logos.isEmpty ? Self.placeholderSymbols.count : logos.count }
    /// Width of one strip plus the gap to the next copy: the distance after which the
    /// second copy sits exactly where the first was.
    private var period: CGFloat { CGFloat(slotCount) * (slotWidth + gap) }

    /// A fixed-height, full-width frame with the sliding strips drawn as an **overlay**:
    /// an overlay never takes part in its parent's layout, so however wide the strips
    /// are they cannot widen the page. The first version put them in the layout and the
    /// whole column stretched off screen with them.
    private var marquee: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: logoHeight + 16)
            .overlay(alignment: .leading) {
                TimelineView(.animation) { context in
                    HStack(spacing: gap) {
                        strip
                        strip
                    }
                    .fixedSize()
                    .offset(x: -marqueeOffset(at: context.date))
                }
            }
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

    /// 38 points per second, wrapped on one strip period.
    private func marqueeOffset(at date: Date) -> CGFloat {
        let travelled: Double = date.timeIntervalSinceReferenceDate * 38.0
        let wrapped: Double = travelled.truncatingRemainder(dividingBy: Double(period))
        return CGFloat(wrapped)
    }

    private var strip: some View {
        HStack(spacing: gap) {
            ForEach(0..<slotCount, id: \.self) { i in
                slot(i)
                    .frame(width: slotWidth, height: logoHeight)
            }
        }
    }

    @ViewBuilder
    private func slot(_ i: Int) -> some View {
        if logos.isEmpty {
            Image(systemName: Self.placeholderSymbols[i % Self.placeholderSymbols.count])
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(OV2.inkTertiary)
        } else {
            Image(uiImage: logos[i])
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
        }
    }

    private static let placeholderSymbols = [
        "building.columns.fill", "books.vertical.fill", "graduationcap.fill",
        "text.book.closed.fill", "building.2.fill", "scroll.fill",
    ]

    private static func loadLogos() -> [UIImage] {
        let urls = Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: nil) ?? []
        return urls
            .filter { $0.lastPathComponent.hasPrefix("university_") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { UIImage(contentsOfFile: $0.path) }
    }
}
