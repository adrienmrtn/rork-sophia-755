import SwiftUI

/// Les pages « à propos de toi », juste avant les objectifs : prénom, âge, culture générale,
/// motivation ; puis, après les objectifs, les sujets qui intéressent (six rangées à cocher).
/// Le prénom n'est pas répété dans les questions : il sert ensuite là où il porte (« Sophia va
/// t'aider à atteindre tous tes objectifs », profil, chargement, après le compte).
///
/// Mise en page commune (style « Elevate arrondi ») : titre centré en graisse moyenne,
/// sous-titre gris, illustration ronde quand la hauteur le permet, puis les réponses en cartes
/// d'option (`OV2CoreOptionRow`) et le CTA épinglé. L'en-tête (flèche retour, progression) est
/// posé par le coordinateur.

// MARK: - Prénom

/// « Comment tu t'appelles ? » : un champ, le clavier qui arrive tout seul, « Continuer » dès
/// qu'il y a un prénom, et « Passer » pour qui ne veut pas le donner.
struct OnboardingV2Name: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var name = ""
    @FocusState private var focused: Bool

    private var trimmed: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        // Le clavier prend la moitié d'un petit écran : l'illustration se réduit (ou s'efface)
        // selon la hauteur qui reste, le contenu défile au besoin, le CTA reste épinglé.
        OV2CorePage { height in
            pageBody(height: height)
        } footer: {
            VStack(spacing: 0) {
                OnboardingV2Button(
                    title: languageManager.text("common.continue"),
                    enabled: !trimmed.isEmpty,
                    bottomPadding: 8,
                    action: commit
                )
                skipButton
                    .padding(.horizontal, OV2CoreMetrics.sideInset)
                    .padding(.bottom, 20)
            }
        }
        .ov2Background()
        .onAppear {
            name = vm.firstName
            // Le clavier arrive une fois la transition de page terminée.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                focused = true
            }
        }
    }

    private func pageBody(height: CGFloat) -> some View {
        let art: CGFloat = OV2CoreMetrics.artSize(base: 116, available: height, reserved: 200)
        return VStack(spacing: 0) {
            OV2CoreQuestionTitle(
                title: languageManager.text("onboardingV2.name.title"),
                subtitle: languageManager.text("onboardingV2.name.subtitle")
            )
            .padding(.top, OV2CoreMetrics.topInset)
            .dsStagger(0)

            if art > 0 {
                OV2CoreIllustration(art: .reader, size: art)
                    .padding(.top, 22)
                    .dsPopIn(delay: 0.12)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }

            field
                .padding(.horizontal, OV2CoreMetrics.sideInset)
                .padding(.top, 26)
                .dsStagger(2)

            Spacer(minLength: 12)
        }
        .animation(DS.Motion.snappy, value: art)
    }

    private var field: some View {
        TextField(
            "",
            text: $name,
            prompt: Text(languageManager.text("onboardingV2.name.placeholder"))
                .font(DS.sans(.headline, .semibold))
                .foregroundStyle(OV2.inkTertiary)
        )
        .font(DS.sans(.headline, .semibold))
        .foregroundStyle(OV2.ink)
        .multilineTextAlignment(.leading)
        .textContentType(.givenName)
        .textInputAutocapitalization(.words)
        .autocorrectionDisabled()
        .submitLabel(.continue)
        .focused($focused)
        .onSubmit {
            if !trimmed.isEmpty { commit() }
        }
        .onChange(of: name) { _, newValue in
            let limit = OnboardingV2ViewModel.firstNameMaxLength
            if newValue.count > limit {
                name = String(newValue.prefix(limit))
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 58)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .fill(OV2.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(focused ? OV2.accent : OV2.hairline, lineWidth: 1.5)
        )
        .background(
            // Le petit rebord bas des cartes du style.
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .fill(focused ? OV2.accent : OV2.hairline)
                .offset(y: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
        .animation(DS.Motion.snappy, value: focused)
    }

    /// « Passer » : bouton secondaire, contour bleu clair sur fond blanc.
    private var skipButton: some View {
        Button(action: skip) {
            Text(languageManager.text("onboardingV2.name.skip"))
                .font(DS.sans(.callout, .semibold))
                .foregroundStyle(OV2.accent)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 54)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                        .fill(OV2.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                        .strokeBorder(OV2.accent.opacity(0.33), lineWidth: 1.5)
                )
                .contentShape(Rectangle())
        }
        // Pas de vibration de style : `skip()` puis le coordinateur s'en chargent déjà.
        .buttonStyle(PressableStyle(haptic: false))
    }

    private func commit() {
        vm.firstName = trimmed
        focused = false
        onNext()
    }

    private func skip() {
        vm.firstName = ""
        focused = false
        OnboardingHaptics.selection()
        onNext()
    }
}

// MARK: - Âge

/// « Quel âge as-tu ? » : six tranches, une seule réponse.
struct OnboardingV2Age: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    var body: some View {
        OV2CorePage { height in
            pageBody(height: height)
        } footer: {
            OnboardingV2Button(
                title: languageManager.text("common.continue"),
                enabled: vm.ageRangeKey != nil,
                action: onNext
            )
        }
        .ov2Background()
    }

    private func pageBody(height: CGFloat) -> some View {
        let art: CGFloat = OV2CoreMetrics.artSize(base: 124, available: height, reserved: 506)
        return VStack(spacing: 0) {
            OV2CoreQuestionTitle(
                title: languageManager.text("onboardingV2.age.title"),
                subtitle: languageManager.text("onboardingV2.age.subtitle")
            )
            .padding(.top, OV2CoreMetrics.topInset)
            .dsStagger(0)

            if art > 0 {
                OV2CoreIllustration(art: .mirror, size: art)
                    .padding(.top, 22)
                    .dsPopIn(delay: 0.12)
            }

            rows
                .padding(.horizontal, OV2CoreMetrics.sideInset)
                .padding(.top, 24)
                .padding(.bottom, 16)
        }
    }

    private var rows: some View {
        VStack(spacing: 10) {
            ForEach(Array(OnboardingV2ViewModel.ageRangeKeys.enumerated()), id: \.element) { index, key in
                OV2CoreOptionRow(
                    label: OnboardingV2ViewModel.ageRangeLabel(key, language: languageManager.current),
                    isSelected: vm.ageRangeKey == key,
                    action: {
                        withAnimation(DS.Motion.snappy) {
                            vm.ageRangeKey = key
                        }
                    }
                )
                .dsStagger(index, base: 0.18)
            }
        }
    }
}

// MARK: - Culture générale

/// « Comment évalues-tu ta culture générale ? » : quatre niveaux, de « pas terrible » à « très
/// bonne », une seule réponse. Le niveau déjà connu (« correcte » par défaut) est présélectionné,
/// si bien que « Continuer » est toujours disponible.
struct OnboardingV2Knowledge: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var step: Int = 1

    private static let levelCount = OnboardingV2ViewModel.knowledgeLevelCount

    var body: some View {
        OV2CorePage { height in
            pageBody(height: height)
        } footer: {
            OnboardingV2Button(title: languageManager.text("common.continue")) {
                vm.knowledgeLevel = step
                onNext()
            }
        }
        .ov2Background()
        .onAppear {
            step = vm.knowledgeLevel
        }
    }

    private func pageBody(height: CGFloat) -> some View {
        let art: CGFloat = OV2CoreMetrics.artSize(base: 124, available: height, reserved: 430)
        return VStack(spacing: 0) {
            OV2CoreQuestionTitle(
                title: languageManager.text("onboardingV2.knowledge.title"),
                subtitle: languageManager.text("onboardingV2.knowledge.subtitle")
            )
            .padding(.top, OV2CoreMetrics.topInset)
            .dsStagger(0)

            if art > 0 {
                OV2CoreIllustration(art: .growth, size: art)
                    .padding(.top, 22)
                    .dsPopIn(delay: 0.12)
            }

            rows
                .padding(.horizontal, OV2CoreMetrics.sideInset)
                .padding(.top, 24)
                .padding(.bottom, 16)
        }
    }

    private var rows: some View {
        VStack(spacing: 10) {
            ForEach(0..<Self.levelCount, id: \.self) { level in
                OV2CoreOptionRow(
                    label: OnboardingV2ViewModel.knowledgeLevelLabel(level, language: languageManager.current),
                    isSelected: step == level,
                    action: { select(level) }
                )
                .dsStagger(level, base: 0.18)
            }
        }
    }

    private func select(_ level: Int) {
        guard level != step else { return }
        withAnimation(DS.Motion.snappy) {
            step = level
        }
        vm.knowledgeLevel = level
    }
}

// MARK: - Motivation

/// « Pourquoi veux-tu améliorer ta culture générale ? » : cinq raisons, une seule réponse.
struct OnboardingV2Motivation: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    var body: some View {
        OV2ScrollableContent {
            VStack(spacing: 0) {
                OV2CoreQuestionTitle(
                    title: languageManager.text("onboardingV2.motivation.title"),
                    subtitle: languageManager.text("onboardingV2.motivation.subtitle")
                )
                .padding(.top, OV2CoreMetrics.topInset)
                .dsStagger(0)

                rows
                    .padding(.horizontal, OV2CoreMetrics.sideInset)
                    .padding(.top, 28)
                    .padding(.bottom, 16)
            }
        } footer: {
            OnboardingV2Button(
                title: languageManager.text("common.continue"),
                enabled: vm.motivationKey != nil,
                action: onNext
            )
        }
        .ov2Background()
    }

    private var rows: some View {
        VStack(spacing: 10) {
            ForEach(Array(OnboardingV2ViewModel.motivationKeys.enumerated()), id: \.element) { index, key in
                OV2CoreOptionRow(
                    label: OnboardingV2ViewModel.motivationLabel(key, language: languageManager.current),
                    isSelected: vm.motivationKey == key,
                    action: {
                        withAnimation(DS.Motion.snappy) {
                            vm.motivationKey = key
                        }
                    },
                    leading: { pictogram(for: key) }
                )
                .dsStagger(index, base: 0.14)
            }
        }
    }

    /// Pictogramme au trait de chaque raison, dans sa couleur.
    private func pictogram(for key: String) -> some View {
        Image(systemName: Self.symbolName(for: key))
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Self.symbolColor(for: key))
            .frame(width: 26, height: 26)
            .accessibilityHidden(true)
    }

    private static func symbolName(for key: String) -> String {
        switch key {
        case "grow": return "leaf"
        case "conversations": return "bubble.left"
        case "career": return "briefcase"
        case "sharp": return "bolt"
        case "world": return "globe"
        default: return "sparkles"
        }
    }

    private static func symbolColor(for key: String) -> Color {
        switch key {
        case "grow": return DS.success
        case "conversations": return DS.danger
        case "career": return Color(red: 0.541, green: 0.353, blue: 0.0)
        case "sharp": return Color(red: 0.420, green: 0.247, blue: 0.627)
        default: return DS.accent
        }
    }
}

// MARK: - Sujets

/// « Quels sujets t'intéressent le plus ? » : les six matières, une rangée chacune avec sa
/// vignette et une case à cocher, sélection multiple.
struct OnboardingV2Topics: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    var body: some View {
        OV2ScrollableContent {
            VStack(spacing: 0) {
                OV2CoreQuestionTitle(
                    title: languageManager.text("onboardingV2.topics.title"),
                    subtitle: languageManager.text("onboardingV2.topics.subtitle")
                )
                .padding(.top, OV2CoreMetrics.topInset)
                .dsStagger(0)

                rows
                    .padding(.horizontal, OV2CoreMetrics.sideInset)
                    .padding(.top, 28)
                    .padding(.bottom, 16)
            }
        } footer: {
            OnboardingV2Button(
                title: languageManager.text("common.continue"),
                enabled: !vm.topicKeys.isEmpty,
                action: onNext
            )
        }
        .ov2Background()
    }

    private var rows: some View {
        VStack(spacing: 10) {
            ForEach(Array(Subject.allCases.enumerated()), id: \.element) { index, subject in
                OV2CoreOptionRow(
                    label: subject.localizedName(language: languageManager.current),
                    isSelected: vm.isTopicSelected(subject.storageKey),
                    showsCheckbox: true,
                    action: {
                        withAnimation(DS.Motion.snappy) {
                            vm.toggleTopic(subject.storageKey)
                        }
                    },
                    leading: { OV2CoreSubjectBadge(subject: subject, size: 30) }
                )
                .dsStagger(index, base: 0.14)
            }
        }
    }
}
