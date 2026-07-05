import SwiftUI

struct WidgetTutorialView: View {
    @Environment(LanguageManager.self) private var languageManager
    var showsCloseButton: Bool = true
    var embedInParentScrollView: Bool = false
    var onDismiss: (() -> Void)? = nil

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    private let steps: [(icon: String, titleKey: String, bodyKey: String)] = [
        ("iphone", "widget.tutorial.step1.title", "widget.tutorial.step1.body"),
        ("hand.tap.fill", "widget.tutorial.step2.title", "widget.tutorial.step2.body"),
        ("plus.circle.fill", "widget.tutorial.step3.title", "widget.tutorial.step3.body"),
        ("magnifyingglass", "widget.tutorial.step4.title", "widget.tutorial.step4.body"),
        ("square.grid.2x2.fill", "widget.tutorial.step5.title", "widget.tutorial.step5.body"),
    ]

    var body: some View {
        Group {
            if embedInParentScrollView {
                tutorialContent
            } else {
                ZStack {
                    cream.ignoresSafeArea()
                    ScrollView {
                        tutorialContent
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                    }
                }
            }
        }
    }

    private var tutorialContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !embedInParentScrollView {
                header
            }

            widgetPreview
                .frame(maxWidth: .infinity)

            VStack(spacing: 12) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    tutorialStep(number: index + 1, icon: step.icon, titleKey: step.titleKey, bodyKey: step.bodyKey)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(languageManager.text("widget.tutorial.title"))
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)

                Text(languageManager.text("widget.tutorial.subtitle"))
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.6))
            }

            Spacer(minLength: 8)

            if showsCloseButton, let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(ink)
                        .frame(width: 38, height: 38)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                }
            }
        }
        .padding(.top, 8)
    }

    private var widgetPreview: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                miniWidgetMock(width: 92, height: 92, titleLines: 2)
                miniWidgetMock(width: 170, height: 92, titleLines: 1, isWide: true)
            }

            miniWidgetMock(width: 170, height: 150, titleLines: 2, isLarge: true)
        }
        .padding(16)
        .brutalOnboardingCard()
    }

    private func miniWidgetMock(width: CGFloat, height: CGFloat, titleLines: Int, isWide: Bool = false, isLarge: Bool = false) -> some View {
        ZStack(alignment: isWide || isLarge ? .topLeading : .bottomLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(BrutalPalette.pastel(for: .histoire))

            if isWide || isLarge {
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(ink.opacity(0.12))
                        .frame(width: isLarge ? 0 : 44)
                    if isLarge {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(ink.opacity(0.12))
                            .frame(height: 58)
                            .frame(maxWidth: .infinity)
                    }
                    Spacer(minLength: 0)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(languageManager.text("widget.label"))
                    .font(.system(size: 7, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .overlay { Capsule().strokeBorder(ink, lineWidth: 1) }

                ForEach(0..<titleLines, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ink.opacity(0.25))
                        .frame(width: isWide ? 90 : 70, height: 6)
                }
            }
            .padding(8)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ink, lineWidth: 2)
        }
    }

    private func tutorialStep(number: Int, icon: String, titleKey: String, bodyKey: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(BrutalPalette.pink)
                    .frame(width: 34, height: 34)
                    .overlay { Circle().strokeBorder(ink, lineWidth: 2) }
                Text("\(number)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(ink)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(ink)
                    Text(languageManager.text(titleKey))
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                }

                Text(languageManager.text(bodyKey))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .brutalOnboardingCard(depth: 3)
    }
}
