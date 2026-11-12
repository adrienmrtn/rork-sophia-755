import SwiftUI

/// Page « Ton profil », juste après la connexion : l'avatar et le @ du nouveau compte.
///
/// Tout est prérempli (l'avatar choisi sur la page du prénom, à défaut un avatar tiré au
/// hasard ; le @ que le serveur a généré à la création du compte) : on peut les changer, ou
/// toucher « Continuer » tel quel. L'avatar suit la progression (`UserProgress.avatarId`), le
/// @ passe par `update_my_handle` comme dans le profil.
struct OnboardingV2Account: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    let onNext: () -> Void

    @State private var avatarId: String
    @State private var handle = ""
    /// Le @ actuel du compte ; nil tant qu'il n'a pas pu être lu (hors ligne).
    @State private var originalHandle: String?
    @State private var isSaving = false
    @State private var errorMessage: String?
    /// Incrémenté à chaque @ refusé : le champ se secoue.
    @State private var errorShake = 0

    /// Diamètre de l'avatar choisi, au centre du carrousel ; ses voisins sont réduits.
    private static let avatarSize: CGFloat = 104
    /// Largeur d'une case du carrousel, plus étroite que l'avatar centré : les voisins,
    /// réduits, viennent ainsi se ranger tout près de lui.
    private static let avatarSlot: CGFloat = 84
    private static let avatarSpacing: CGFloat = 18
    private static let neighbourScale: CGFloat = 0.615

    /// - Parameter initialAvatarId: l'avatar choisi plus tôt dans l'onboarding (page du
    ///   prénom) : le carrousel s'ouvre sur lui. Sans lui, un avatar est tiré au hasard.
    init(progressManager: ProgressManager, initialAvatarId: String? = nil, onNext: @escaping () -> Void) {
        self.progressManager = progressManager
        self.onNext = onNext
        let fallback: String = Avatars.all.randomElement() ?? "avatar_01"
        let start: String = Avatars.isValid(initialAvatarId) ? (initialAvatarId ?? fallback) : fallback
        _avatarId = State(initialValue: start)
    }

    private var sanitizedHandle: String {
        handle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
            .lowercased()
    }

    /// Les règles du serveur : une lettre, puis des lettres ou des chiffres, 3 à 20 caractères.
    private var handleIsValid: Bool {
        sanitizedHandle.range(of: "^[a-z][a-z0-9]{2,19}$", options: .regularExpression) != nil
    }

    private var canContinue: Bool {
        // Sans @ lu (hors ligne), la page ne bloque pas : l'avatar seul est enregistré.
        !isSaving && (originalHandle == nil || handleIsValid)
    }

    /// L'avatar centré dans le carrousel est l'avatar choisi : le défilement écrit dans
    /// `avatarId`, et changer `avatarId` (toucher un voisin, avatar déjà enregistré) fait
    /// défiler jusqu'à lui.
    private var centeredAvatar: Binding<String?> {
        Binding<String?>(
            get: { avatarId },
            set: { newValue in
                if let newValue, newValue != avatarId { avatarId = newValue }
            }
        )
    }

    var body: some View {
        OV2ScrollableContent {
            VStack(spacing: 0) {
                OV2EndTitle(text: languageManager.text("onboardingV2.account.title"))
                    .padding(.top, OV2End.topWithoutHeader)
                    .dsStagger(0)

                OV2EndSubtitle(text: languageManager.text("onboardingV2.account.subtitle"))
                    .padding(.top, 10)
                    .dsStagger(1)

                avatarCarousel
                    .padding(.top, 28)
                    // Le carrousel va d'un bord à l'autre de la colonne de contenu.
                    .padding(.horizontal, -OV2End.side)
                    .dsStagger(2)

                handleField
                    .padding(.top, 28)
                    .dsStagger(3)

                Text(errorMessage ?? languageManager.text("friends.handle.rules"))
                    .font(DS.sans(.footnote, .regular))
                    .foregroundStyle(errorMessage == nil ? DS.inkSecondary : DS.danger)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)
                    .dsStagger(4)
            }
            .padding(.horizontal, OV2End.side)
            .padding(.bottom, 20)
            .ov2ReadableWidth()
        } footer: {
            OnboardingV2Button(
                title: languageManager.text("common.continue"),
                enabled: canContinue,
                action: save
            )
        }
        .ov2Background()
        // Relancé quand la session est connue : juste après la connexion, elle peut arriver un
        // instant plus tard, et sans elle le @ ne peut pas être lu.
        .task(id: AuthService.shared.isSignedIn) { await load() }
    }

    // MARK: - Carrousel d'avatars

    /// Tous les avatars sur une ligne qui défile et s'aimante : celui du centre est choisi,
    /// grand et cerclé de bleu ; les autres sont réduits et estompés.
    private var avatarCarousel: some View {
        GeometryReader { geo in
            let margin: CGFloat = max(0, (geo.size.width - Self.avatarSlot) / 2)
            ScrollView(.horizontal) {
                HStack(spacing: Self.avatarSpacing) {
                    ForEach(Avatars.all, id: \.self) { id in
                        avatarItem(id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: centeredAvatar, anchor: .center)
            .contentMargins(.horizontal, margin, for: .scrollContent)
        }
        .frame(height: Self.avatarSize)
        .sensoryFeedback(.selection, trigger: avatarId)
    }

    private func avatarItem(_ id: String) -> some View {
        let selected: Bool = avatarId == id
        return Button {
            withAnimation(DS.Motion.snappy) {
                avatarId = id
            }
        } label: {
            AvatarCircle(avatarId: id, initial: "", size: Self.avatarSize)
                .overlay(
                    Circle()
                        .strokeBorder(DS.accent, lineWidth: 4)
                        .opacity(selected ? 1 : 0)
                )
                .scaleEffect(selected ? 1 : Self.neighbourScale)
                .opacity(selected ? 1 : 0.55)
                .animation(DS.Motion.snappy, value: selected)
                .frame(width: Self.avatarSlot, height: Self.avatarSize)
        }
        .buttonStyle(.plain)
        .zIndex(selected ? 1 : 0)
        .accessibilityLabel(id)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - Champ du @

    private var handleField: some View {
        HStack(spacing: 6) {
            Text(verbatim: "@")
                .font(DS.sans(.headline, .bold))
                .foregroundStyle(DS.inkSecondary)
            TextField(languageManager.text("friends.handle.placeholder"), text: $handle)
                .font(DS.sans(.headline, .bold))
                .foregroundStyle(DS.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .submitLabel(.done)
                .disabled(originalHandle == nil)
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .ov2EndCard(border: errorMessage == nil ? DS.hairline : DS.danger)
        .animation(DS.Motion.snappy, value: errorMessage)
        .dsShake(trigger: errorShake)
    }

    private func load() async {
        if let existing = progressManager.avatarId, Avatars.isValid(existing) {
            avatarId = existing
        }
        await SocialService.shared.refreshMyHandle()
        if let current = SocialService.shared.myHandle {
            originalHandle = current
            if handle.isEmpty {
                handle = current
            }
        }
    }

    private func save() {
        progressManager.setAvatar(avatarId)
        guard let originalHandle, sanitizedHandle != originalHandle else {
            onNext()
            return
        }
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await SocialService.shared.updateHandle(sanitizedHandle)
                isSaving = false
                onNext()
            } catch let error as SocialError {
                errorMessage = error.localizedMessage(languageManager: languageManager)
                isSaving = false
                signalError()
            } catch {
                errorMessage = languageManager.text("friends.error.generic")
                isSaving = false
                signalError()
            }
        }
    }

    /// Le @ a été refusé : secousse du champ et vibration d'erreur.
    private func signalError() {
        errorShake += 1
        Haptics.error()
    }
}
