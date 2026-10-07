import SwiftUI

/// Les pages « à propos de toi », juste avant les objectifs : prénom, âge, culture générale
/// (curseur), motivation ; puis, après les objectifs, les sujets qui intéressent (six carrés).
/// Le prénom n'est pas répété dans les questions : il sert ensuite là où il porte (« Sophia va
/// t'aider à atteindre tous tes objectifs », profil, chargement, après le compte).

// MARK: - En-tête commun

/// Titre et sous-titre d'une page question.
private struct OnboardingV2QuestionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
            if let subtitle {
                Text(subtitle)
                    .font(DS.sans(.body, .medium))
                    .foregroundStyle(OV2.inkSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 28)
        .ov2Reveal(delay: 0.1)
    }
}

// MARK: - Ligne de choix unique

/// Une réponse parmi plusieurs : pastille (emoji) facultative, libellé, rond coché à droite.
/// Même dessin que les lignes de la page objectifs, avec un rond à la place de la case.
private struct OnboardingV2ChoiceRow: View {
    var emoji: String? = nil
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let emoji {
                    Text(emoji)
                        .font(.system(size: 24))
                        .frame(width: 44, height: 44)
                        .background((isSelected ? OV2.accent : OV2.accentSoft).opacity(isSelected ? 0.16 : 0.12), in: Circle())
                }
                Text(label)
                    .font(DS.sans(.body, .semibold))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                radio
            }
            .padding(.horizontal, 16)
            .padding(.vertical, emoji == nil ? 16 : 14)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .fill(isSelected ? OV2.accentSoft.opacity(0.06) : OV2.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .strokeBorder(isSelected ? OV2.accent : OV2.hairline, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(SoftPressButtonStyle())
    }

    private var radio: some View {
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
}

// MARK: - Prénom

/// « Comment tu t'appelles ? » : un champ, le clavier qui arrive tout seul, « Continuer » dès
/// qu'il y a un prénom, et un « Passer » discret pour qui ne veut pas le donner.
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
        // Le clavier prend la moitié d'un petit écran : le contenu défile, le CTA reste épinglé.
        OV2ScrollableContent {
            VStack(spacing: 0) {
                Spacer().frame(height: 72)

                OnboardingV2QuestionHeader(
                    title: languageManager.text("onboardingV2.name.title"),
                    subtitle: languageManager.text("onboardingV2.name.subtitle")
                )

                Spacer().frame(height: 36)

                field
                    .padding(.horizontal, 24)
                    .ov2Reveal(delay: 0.25)

                Spacer().frame(height: 24)
            }
        } footer: {
            VStack(spacing: 0) {
                OnboardingV2Button(
                    title: languageManager.text("common.continue"),
                    enabled: !trimmed.isEmpty,
                    action: commit
                )
                Button(action: skip) {
                    Text(languageManager.text("onboardingV2.name.skip"))
                        .font(DS.sans(.subheadline, .semibold))
                        .foregroundStyle(OV2.inkSecondary)
                        .underline()
                }
                .padding(.bottom, 24)
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

    private var field: some View {
        TextField(
            "",
            text: $name,
            prompt: Text(languageManager.text("onboardingV2.name.placeholder"))
                .font(DS.title(.title2, .semibold))
                .foregroundStyle(OV2.inkTertiary)
        )
        .font(DS.title(.title2, .semibold))
        .foregroundStyle(OV2.ink)
        .multilineTextAlignment(.center)
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
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(OV2.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(focused ? OV2.accent : OV2.hairline, lineWidth: focused ? 2 : 1)
        )
        .animation(.easeOut(duration: 0.2), value: focused)
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

    @State private var revealed = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 72)

            OnboardingV2QuestionHeader(
                title: languageManager.text("onboardingV2.age.title"),
                subtitle: languageManager.text("onboardingV2.age.subtitle")
            )

            Spacer().frame(height: 24)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Array(OnboardingV2ViewModel.ageRangeKeys.enumerated()), id: \.element) { index, key in
                        OnboardingV2ChoiceRow(
                            label: OnboardingV2ViewModel.ageRangeLabel(key, language: languageManager.current),
                            isSelected: vm.ageRangeKey == key
                        ) {
                            OnboardingHaptics.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                vm.ageRangeKey = key
                            }
                        }
                        .opacity(index < revealed ? 1 : 0)
                        .offset(y: index < revealed ? 0 : 18)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }

            OnboardingV2Button(
                title: languageManager.text("common.continue"),
                enabled: vm.ageRangeKey != nil,
                action: onNext
            )
        }
        .ov2Background()
        .onAppear {
            revealRows(count: OnboardingV2ViewModel.ageRangeKeys.count)
        }
    }

    private func revealRows(count: Int) {
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + Double(i) * 0.07) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    revealed = i + 1
                }
            }
        }
    }
}

// MARK: - Culture générale

/// « Comment évalues-tu ta culture générale ? » : un curseur à quatre crans, de « pas
/// terrible » à « très bonne », avec l'emoji et le libellé du cran au-dessus.
struct OnboardingV2Knowledge: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    /// Position continue du pouce (0 … levelCount − 1) : il suit le doigt sans à-coups, puis
    /// se pose sur le cran le plus proche quand on le lâche.
    @State private var level: Double = 1
    @State private var step: Int = 1
    @State private var dragging = false

    private static let levelCount = OnboardingV2ViewModel.knowledgeLevelCount
    private static let thumbSize: CGFloat = 30

    var body: some View {
        OV2ScrollableContent {
            VStack(spacing: 0) {
                Spacer().frame(height: 72)

                OnboardingV2QuestionHeader(
                    title: languageManager.text("onboardingV2.knowledge.title"),
                    subtitle: languageManager.text("onboardingV2.knowledge.subtitle")
                )

                Spacer().frame(height: 36)

                VStack(spacing: 12) {
                    Text(OnboardingV2ViewModel.knowledgeLevelEmoji(step))
                        .font(.system(size: 72))
                        .id("emoji-\(step)")
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                    Text(OnboardingV2ViewModel.knowledgeLevelLabel(step, language: languageManager.current))
                        .font(DS.title(.title, .heavy))
                        .foregroundStyle(OV2.accent)
                        .id("label-\(step)")
                        .transition(.opacity.combined(with: .offset(y: 6)))
                }
                .frame(height: 150)
                .animation(.spring(response: 0.38, dampingFraction: 0.78), value: step)
                .ov2Reveal(delay: 0.25)

                Spacer().frame(height: 28)

                slider
                    .padding(.horizontal, 36)
                    .ov2Reveal(delay: 0.35)

                Spacer().frame(height: 24)
            }
        } footer: {
            OnboardingV2Button(title: languageManager.text("common.continue")) {
                vm.knowledgeLevel = step
                onNext()
            }
        }
        .ov2Background()
        .onAppear {
            step = vm.knowledgeLevel
            level = Double(step)
        }
    }

    // MARK: - Curseur

    /// Le rail, quatre crans, le pouce ; puis les libellés, un par cran, à largeur égale.
    private var slider: some View {
        VStack(spacing: 14) {
            GeometryReader { geo in
                let inset = Self.thumbSize / 2
                let span = max(geo.size.width - inset * 2, 1)
                let thumbX = inset + span * CGFloat(level) / CGFloat(Self.levelCount - 1)
                let midY = geo.size.height / 2

                ZStack(alignment: .leading) {
                    Capsule().fill(OV2.hairline).frame(height: 6)
                    Capsule().fill(OV2.accent).frame(width: thumbX, height: 6)

                    ForEach(0..<Self.levelCount, id: \.self) { i in
                        Circle()
                            .fill(i <= step ? OV2.accent : OV2.hairline)
                            .overlay(Circle().strokeBorder(OV2.bg, lineWidth: 2))
                            .frame(width: 14, height: 14)
                            .position(x: Self.tickX(i, inset: inset, span: span), y: midY)
                    }

                    Circle()
                        .fill(.white)
                        .overlay(Circle().strokeBorder(OV2.accent, lineWidth: 3))
                        .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
                        .frame(width: Self.thumbSize, height: Self.thumbSize)
                        .scaleEffect(dragging ? 1.12 : 1)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: dragging)
                        .position(x: thumbX, y: midY)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            dragging = true
                            let fraction = (value.location.x - inset) / span
                            move(to: Double(min(max(fraction, 0), 1)) * Double(Self.levelCount - 1))
                        }
                        .onEnded { _ in
                            dragging = false
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                level = Double(step)
                            }
                        }
                )
            }
            .frame(height: Self.thumbSize + 8)
            .accessibilityElement()
            .accessibilityLabel(Text(languageManager.text("onboardingV2.knowledge.title")))
            .accessibilityValue(Text(OnboardingV2ViewModel.knowledgeLevelLabel(step, language: languageManager.current)))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: move(to: Double(min(step + 1, Self.levelCount - 1)), snap: true)
                case .decrement: move(to: Double(max(step - 1, 0)), snap: true)
                @unknown default: break
                }
            }

            tickLabels
        }
    }

    /// Le pouce suit la position donnée ; le cran change (emoji, libellé, vibration) dès que
    /// le pouce dépasse la moitié du chemin vers le cran voisin.
    private func move(to value: Double, snap: Bool = false) {
        if snap {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { level = value }
        } else {
            level = value
        }
        let s = Int(value.rounded())
        if s != step {
            step = s
            vm.knowledgeLevel = s
            OnboardingHaptics.selection()
        }
    }

    private static func tickX(_ i: Int, inset: CGFloat, span: CGFloat) -> CGFloat {
        inset + span * CGFloat(i) / CGFloat(levelCount - 1)
    }

    /// Un libellé centré sous chaque cran, tous de la même largeur, sur deux lignes au plus.
    private var tickLabels: some View {
        GeometryReader { geo in
            let inset = Self.thumbSize / 2
            let span = max(geo.size.width - inset * 2, 1)
            let labelWidth = span / CGFloat(Self.levelCount - 1) - 6
            ForEach(0..<Self.levelCount, id: \.self) { i in
                Text(OnboardingV2ViewModel.knowledgeLevelLabel(i, language: languageManager.current))
                    .font(DS.sans(.caption, i == step ? .bold : .medium))
                    .foregroundStyle(i == step ? OV2.accent : OV2.inkTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(width: labelWidth)
                    .position(x: Self.tickX(i, inset: inset, span: span), y: 16)
            }
        }
        .frame(height: 34)
        .animation(.easeInOut(duration: 0.2), value: step)
    }
}

// MARK: - Motivation

/// « Pourquoi veux-tu améliorer ta culture générale ? » : cinq raisons, une seule réponse.
struct OnboardingV2Motivation: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var revealed = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 72)

            OnboardingV2QuestionHeader(
                title: languageManager.text("onboardingV2.motivation.title"),
                subtitle: languageManager.text("onboardingV2.motivation.subtitle")
            )

            Spacer().frame(height: 24)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Array(OnboardingV2ViewModel.motivationKeys.enumerated()), id: \.element) { index, key in
                        OnboardingV2ChoiceRow(
                            emoji: OnboardingV2ViewModel.motivationEmoji(key),
                            label: OnboardingV2ViewModel.motivationLabel(key, language: languageManager.current),
                            isSelected: vm.motivationKey == key
                        ) {
                            OnboardingHaptics.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                vm.motivationKey = key
                            }
                        }
                        .opacity(index < revealed ? 1 : 0)
                        .offset(y: index < revealed ? 0 : 18)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }

            OnboardingV2Button(
                title: languageManager.text("common.continue"),
                enabled: vm.motivationKey != nil,
                action: onNext
            )
        }
        .ov2Background()
        .onAppear {
            for i in 0..<OnboardingV2ViewModel.motivationKeys.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + Double(i) * 0.07) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        revealed = i + 1
                    }
                }
            }
        }
    }
}

// MARK: - Sujets

/// « Quels sujets t'intéressent le plus ? » : les six matières en carrés, deux par ligne,
/// sélection multiple.
struct OnboardingV2Topics: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var revealed = 0

    private static let spacing: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            let side = Self.squareSide(for: geo.size)
            VStack(spacing: 0) {
                Spacer().frame(height: geo.size.height < 700 ? 48 : 72)

                OnboardingV2QuestionHeader(
                    title: languageManager.text("onboardingV2.topics.title"),
                    subtitle: languageManager.text("onboardingV2.topics.subtitle")
                )

                Spacer().frame(height: 22)

                // Les carrés sont dimensionnés pour tenir ; le défilement n'est qu'un filet
                // (grande taille de texte, très petit écran).
                ScrollView(showsIndicators: false) {
                    grid(side: side)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }

                OnboardingV2Button(
                    title: languageManager.text("common.continue"),
                    enabled: !vm.topicKeys.isEmpty,
                    action: onNext
                )
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ov2Background()
        .onAppear {
            for i in 0..<Subject.allCases.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + Double(i) * 0.07) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        revealed = i + 1
                    }
                }
            }
        }
    }

    /// Deux carrés par ligne dans la largeur et, quand c'est possible, trois lignes dans la
    /// hauteur ; jamais plus petits que 96 pt.
    private static func squareSide(for size: CGSize) -> CGFloat {
        let byWidth: CGFloat = (min(size.width, OV2.readableWidth) - 48 - spacing) / 2
        let chrome: CGFloat = size.height < 700 ? 300 : 330
        let byHeight: CGFloat = (size.height - chrome - spacing * 2) / 3
        return max(96, min(byWidth, byHeight))
    }

    private func grid(side: CGFloat) -> some View {
        let columns = Array(repeating: GridItem(.fixed(side), spacing: Self.spacing), count: 2)
        return LazyVGrid(columns: columns, spacing: Self.spacing) {
            ForEach(Array(Subject.allCases.enumerated()), id: \.element) { index, subject in
                square(subject, index: index, side: side)
            }
        }
        .frame(width: side * 2 + Self.spacing)
    }

    private func square(_ subject: Subject, index: Int, side: CGFloat) -> some View {
        let isSelected = vm.isTopicSelected(subject.storageKey)
        return Button {
            OnboardingHaptics.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                vm.toggleTopic(subject.storageKey)
            }
        } label: {
            VStack(spacing: 10) {
                Text(subject.emoji)
                    .font(.system(size: side * 0.3))
                    .frame(width: side * 0.46, height: side * 0.46)
                    .background(subject.color.opacity(isSelected ? 0.24 : 0.14), in: Circle())
                Text(subject.localizedShortName(language: languageManager.current))
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 8)
            }
            .frame(width: side, height: side)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .fill(isSelected ? OV2.accentSoft.opacity(0.08) : OV2.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .strokeBorder(isSelected ? OV2.accent : OV2.hairline, lineWidth: isSelected ? 2 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    ZStack {
                        Circle().fill(OV2.accent)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 24, height: 24)
                    .padding(10)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .shadow(color: .black.opacity(isSelected ? 0.08 : 0.04), radius: 10, y: 5)
        }
        .buttonStyle(SoftPressButtonStyle())
        .opacity(index < revealed ? 1 : 0)
        .offset(y: index < revealed ? 0 : 18)
        .scaleEffect(index < revealed ? 1 : 0.94)
    }
}
