import SwiftUI

/// Page « Ton profil », juste après la connexion : l'avatar et le @ du nouveau compte.
///
/// Tout est prérempli (un avatar tiré au hasard, le @ que le serveur a généré à la création du
/// compte) : on peut les changer, ou toucher « Continuer » tel quel. L'avatar suit la
/// progression (`UserProgress.avatarId`), le @ passe par `update_my_handle` comme dans le profil.
struct OnboardingV2Account: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    let onNext: () -> Void

    @State private var avatarId: String = Avatars.all.randomElement() ?? "avatar_01"
    @State private var handle = ""
    /// Le @ actuel du compte ; nil tant qu'il n'a pas pu être lu (hors ligne).
    @State private var originalHandle: String?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

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

    var body: some View {
        OV2ScrollableContent {
            VStack(spacing: 22) {
                VStack(spacing: 10) {
                    Text(languageManager.text("onboardingV2.account.title"))
                        .font(DS.title(.title, .heavy))
                        .foregroundStyle(OV2.ink)
                        .multilineTextAlignment(.center)
                    Text(languageManager.text("onboardingV2.account.subtitle"))
                        .font(DS.sans(.body, .medium))
                        .foregroundStyle(OV2.inkSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 36)
                .ov2Reveal(delay: 0.05)

                AvatarCircle(avatarId: avatarId, initial: "", size: 116)
                    .overlay(Circle().strokeBorder(OV2.accent, lineWidth: 4))
                    .dsSoftShadow()
                    .id(avatarId)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                    .ov2Reveal(delay: 0.12)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("@")
                            .font(DS.title(.title3, .semibold))
                            .foregroundStyle(OV2.inkTertiary)
                        TextField(languageManager.text("friends.handle.placeholder"), text: $handle)
                            .font(DS.title(.title3, .semibold))
                            .foregroundStyle(OV2.ink)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.asciiCapable)
                            .submitLabel(.done)
                    }
                    .padding(16)
                    .background(OV2.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                            .strokeBorder(errorMessage == nil ? OV2.hairline : OV2.danger, lineWidth: 1)
                    }

                    Text(errorMessage ?? languageManager.text("friends.handle.rules"))
                        .font(DS.sans(.caption, .medium))
                        .foregroundStyle(errorMessage == nil ? OV2.inkTertiary : OV2.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .ov2Reveal(delay: 0.18)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Avatars.all, id: \.self) { id in
                        Button {
                            OnboardingHaptics.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                avatarId = id
                            }
                        } label: {
                            AvatarCircle(avatarId: id, initial: "", size: 56)
                                .overlay(Circle().strokeBorder(avatarId == id ? OV2.accent : Color.clear, lineWidth: 3))
                                .scaleEffect(avatarId == id ? 1.06 : 1)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(id)
                    }
                }
                .ov2Reveal(delay: 0.24)
            }
            .padding(.horizontal, 24)
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
        .task { await load() }
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
            } catch {
                errorMessage = languageManager.text("friends.error.generic")
                isSaving = false
            }
        }
    }
}
