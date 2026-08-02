import SwiftUI

/// Page 2 — choix de la langue. Langue de l'appareil présélectionnée (`LanguageManager`).
/// Liste verticale scrollable : on met en avant le geste de slide pour les langues hors écran.
struct OnboardingV2Language: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var revealed = 0
    @State private var showScrollHint = true
    @State private var hintBounce = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 72)

            VStack(spacing: 10) {
                Text(languageManager.text("onboardingV2.language.title"))
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                Text(languageManager.text("onboardingV2.language.subtitle"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(OV2.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .ov2Reveal(delay: 0.1)

            Spacer().frame(height: 28)

            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element.id) { index, language in
                            languageRow(language)
                                .opacity(index < revealed ? 1 : 0)
                                .offset(y: index < revealed ? 0 : 18)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, offset in
                    if offset > 24, showScrollHint {
                        withAnimation(.easeOut(duration: 0.25)) { showScrollHint = false }
                    }
                }

                if showScrollHint {
                    scrollHint
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .allowsHitTesting(false)
                }
            }

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            for i in 0..<AppLanguage.allCases.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + Double(i) * 0.06) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        revealed = i + 1
                    }
                }
            }
            withAnimation(
                .easeInOut(duration: 0.9)
                .repeatForever(autoreverses: true)
                .delay(0.6)
            ) {
                hintBounce = true
            }
        }
    }

    private var scrollHint: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [OV2.bg.opacity(0), OV2.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 56)

            HStack(spacing: 8) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .offset(y: hintBounce ? 3 : 0)
                Text(languageManager.text("onboardingV2.language.scrollHint"))
                    .font(DS.sans(.caption, .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .offset(y: hintBounce ? 3 : 0)
            }
            .foregroundStyle(OV2.inkSecondary)
            .padding(.bottom, 8)
            .background(OV2.bg)
        }
    }

    private func languageRow(_ language: AppLanguage) -> some View {
        let isSelected = languageManager.current == language
        return Button {
            OnboardingHaptics.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                languageManager.setLanguage(language)
            }
        } label: {
            HStack(spacing: 12) {
                Text(language.flag).font(.system(size: 26))
                Text(language.displayName)
                    .font(DS.sans(.body, .semibold))
                    .foregroundStyle(OV2.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? OV2.accent : OV2.hairline, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(OV2.accent).frame(width: 22, height: 22)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .fill(OV2.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .strokeBorder(isSelected ? OV2.accent : OV2.hairline, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(SoftPressButtonStyle())
    }
}
