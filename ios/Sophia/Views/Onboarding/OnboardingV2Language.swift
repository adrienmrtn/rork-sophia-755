import SwiftUI

/// Page 2 — choix de la langue. Langue de l'appareil présélectionnée (`LanguageManager`).
/// Liste verticale scrollable : on met en avant le geste de slide pour les langues hors écran.
struct OnboardingV2Language: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onNext: () -> Void

    @State private var showScrollHint = true
    @State private var hintBounce = false
    /// Incrémenté à chaque choix : fait rebondir le drapeau de l'en-tête.
    @State private var flagPulse = 0

    /// Au-delà, les rangées sont hors écran : inutile d'allonger la cascade d'apparition.
    private static let maxStaggeredRows = 9

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 20)

            ZStack(alignment: .bottom) {
                languageList

                if showScrollHint {
                    scrollHint
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .allowsHitTesting(false)
                }
            }
            .padding(.top, 16)

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
                .padding(.top, 14)
        }
        .ov2Background()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 0.9)
                .repeatForever(autoreverses: true)
                .delay(0.6)
            ) {
                hintBounce = true
            }
        }
    }

    // MARK: - En-tête

    private var header: some View {
        VStack(spacing: 0) {
            Text(languageManager.text("onboardingV2.language.title"))
                .font(DS.title(.title2, .medium))
                .tracking(0.2)
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text(languageManager.text("onboardingV2.language.subtitle"))
                .font(DS.sans(.subheadline, .regular))
                .foregroundStyle(OV2.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            flagBadge
                .padding(.top, 14)
        }
        .dsStagger(0)
    }

    /// Le drapeau de la langue choisie, dans une pastille qui rebondit à chaque changement.
    private var flagBadge: some View {
        ZStack {
            Circle().fill(DS.accentTint)
            Text(languageManager.current.flag)
                .font(.system(size: 36))
                .id(languageManager.current.id)
                .transition(.scale(scale: 0.4).combined(with: .opacity))
        }
        .frame(width: 72, height: 72)
        .scaleEffect(flagScale)
        .animation(DS.Motion.pop, value: flagPulse)
        .accessibilityHidden(true)
    }

    /// Le rebond alterne deux échelles voisines : chaque choix relance le ressort.
    private var flagScale: CGFloat {
        flagPulse.isMultiple(of: 2) ? 1 : 1.04
    }

    // MARK: - Liste

    private var languageList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 9) {
                ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element.id) { index, language in
                    languageRow(language)
                        .dsStagger(min(index, Self.maxStaggeredRows) + 1, step: 0.045)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 2)
            .padding(.bottom, 40)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, offset in
            if offset > 24, showScrollHint {
                withAnimation(.easeOut(duration: 0.25)) { showScrollHint = false }
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
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
            .background(OV2.bg)
        }
    }

    private func languageRow(_ language: AppLanguage) -> some View {
        let isSelected: Bool = languageManager.current == language
        return Button {
            Haptics.select()
            withAnimation(DS.Motion.snappy) {
                languageManager.setLanguage(language)
                flagPulse += 1
            }
        } label: {
            HStack(spacing: 12) {
                Text(language.flag)
                    .font(.system(size: 24))
                Text(language.displayName)
                    .font(DS.sans(.callout, .semibold))
                    .foregroundStyle(OV2.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isSelected {
                    DSCheckBadge(size: 22, fill: DS.accent)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minHeight: 52)
            .dsOptionCard(isSelected ? .selected : .idle)
            .contentShape(Rectangle())
        }
        // La carte s'enfonce sans vibrer : la vibration du choix part au relâchement.
        .buttonStyle(PressableStyle(scale: 0.98, haptic: false))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
