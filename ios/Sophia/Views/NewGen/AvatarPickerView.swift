import SwiftUI

/// Les soixante avatars illustrés (design/site-art/manifest-avatars.json et
/// manifest-avatars-duels.json, la direction affiche du site), embarqués dans le catalogue
/// d'images sous `avatar_01` … `avatar_60`. Un lecteur en choisit un à la place de ses initiales ;
/// le choix (`UserProgress.avatarId`) suit la progression, donc le multi-appareils. Les vingt
/// premiers servent aussi aux auteurs dans le Studio ; tous servent aux adversaires des duels.
enum Avatars {
    static let all: [String] = (1...60).map { String(format: "avatar_%02d", $0) }

    static func isValid(_ id: String?) -> Bool {
        guard let id else { return false }
        return all.contains(id)
    }
}

/// Le rond du profil : l'avatar choisi, sinon l'initiale sur le fond bleu.
struct AvatarCircle: View {
    let avatarId: String?
    let initial: String
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            if Avatars.isValid(avatarId), let avatarId {
                Image(avatarId)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle().fill(DS.accentSoft)
                Text(initial)
                    .font(.system(size: size * 0.38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

/// La feuille de choix : la grille des avatars, et « pas d'avatar » pour revenir aux initiales.
struct AvatarPickerSheet: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    let current: String?
    let initial: String
    let onPick: (String?) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Avatars.all, id: \.self) { id in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                onPick(id)
                                dismiss()
                            } label: {
                                AvatarCircle(avatarId: id, initial: initial, size: 72)
                                    .overlay(Circle().strokeBorder(current == id ? DS.accent : .clear, lineWidth: 3))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(id)
                        }
                    }
                    Button {
                        onPick(nil)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            AvatarCircle(avatarId: nil, initial: initial, size: 40)
                            Text(languageManager.text("profile.avatar.none"))
                                .font(DS.sans(.body, .semibold))
                                .foregroundStyle(DS.ink)
                            Spacer()
                            if current == nil {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(DS.accent)
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(DS.surface))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .background(DS.canvas.ignoresSafeArea())
            .navigationTitle(languageManager.text("profile.avatar.title"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }
}
