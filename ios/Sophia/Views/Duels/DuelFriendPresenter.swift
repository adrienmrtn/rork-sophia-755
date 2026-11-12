import SwiftUI
import UIKit

/// D'où part un duel entre amis : un défi que je lance, ou une invitation que je viens d'accepter.
enum DuelFriendEntry {
    case challenge(userId: UUID, handle: String, avatarId: String?)
    case incoming(DuelFriendStart)
}

/// Ouvre un duel entre amis par-dessus l'écran en cours, quel qu'il soit.
///
/// Une invitation peut arriver n'importe où (en pleine lecture d'un cours, dans les réglages) :
/// la partie est donc présentée par UIKit depuis l'écran le plus haut, et non par une feuille
/// SwiftUI attachée à un onglet, qui ne pourrait pas passer devant une autre feuille.
@MainActor
enum DuelFriendPresenter {
    /// L'écran de duel entre amis actuellement présenté, s'il y en a un.
    private static weak var current: UIViewController?

    static func present(_ entry: DuelFriendEntry) {
        // Une partie (ou un défi) est en cours : un second ne s'ouvre pas par-dessus.
        guard !DuelLiveService.shared.isInFriendDuel else { return }
        DuelLiveService.shared.isInFriendDuel = true
        // Un duel précédent est resté sur son écran de résultat : il laisse la place.
        if let previous = current, previous.presentingViewController != nil {
            previous.dismiss(animated: false) {
                DuelLiveService.shared.isInFriendDuel = true
                show(entry)
            }
        } else {
            show(entry)
        }
    }

    private static func show(_ entry: DuelFriendEntry) {
        guard let top = AuthService.topViewController() else {
            DuelLiveService.shared.isInFriendDuel = false
            return
        }
        let host = UIHostingController(rootView: AnyView(EmptyView()))
        let flow = DuelFriendFlowView(entry: entry) { [weak host] in
            host?.dismiss(animated: true)
        }
        .sophiaColorScheme()
        .environment(LanguageManager.shared)
        .environment(AppearanceManager.shared)
        .environment(AuthService.shared)
        .environment(\.locale, LanguageManager.shared.locale)
        .environment(\.layoutDirection, LanguageManager.shared.layoutDirection)
        host.rootView = AnyView(flow)
        host.modalPresentationStyle = .fullScreen
        host.view.backgroundColor = DS.uiCanvas
        current = host
        top.present(host, animated: true)
    }
}

/// Le bandeau d'une invitation reçue, dans sa propre petite fenêtre en haut de l'écran : il
/// passe devant tout (feuilles, lecteur de cours) sans bloquer ce qui se trouve dessous.
@MainActor
final class DuelInviteBanner {
    static let shared = DuelInviteBanner()

    private var window: UIWindow?

    private init() {}

    func show() {
        guard window == nil else { return }
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        guard let scene else { return }

        let banner = DuelInviteBannerView()
            .environment(LanguageManager.shared)
            .environment(AppearanceManager.shared)
            .environment(\.locale, LanguageManager.shared.locale)
            .environment(\.layoutDirection, LanguageManager.shared.layoutDirection)
        let host = UIHostingController(rootView: banner)
        host.view.backgroundColor = .clear

        let window = UIWindow(windowScene: scene)
        // Une bande en haut de l'écran : le reste de l'app reste touchable.
        window.frame = CGRect(x: 0, y: 0, width: scene.screen.bounds.width, height: 240)
        window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.alert.rawValue + 1)
        window.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = false
        self.window = window
    }

    func hide() {
        window?.isHidden = true
        window = nil
    }
}

/// « @ami te défie en duel » : son avatar, le temps qui reste, Refuser et Accepter.
struct DuelInviteBannerView: View {
    @Environment(LanguageManager.self) private var languageManager
    @State private var service = DuelLiveService.shared
    @State private var appeared = false
    @State private var answering = false

    var body: some View {
        VStack {
            if let invite = service.incoming {
                card(invite)
                    .offset(y: appeared ? 0 : -180)
                    .opacity(appeared ? 1 : 0)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) { appeared = true }
        }
    }

    private func card(_ invite: DuelIncomingInvite) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                DuelAvatar(avatarId: invite.from.avatarId, initial: invite.from.initial, size: 46, ring: DuelPalette.saffron, ringWidth: 3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(invite.from.handle)")
                        .font(DS.sans(.headline, .bold))
                        .foregroundStyle(DS.ink)
                        .lineLimit(1)
                    Text(languageManager.text("duel.invite.banner"))
                        .font(DS.sans(.subheadline, .medium))
                        .foregroundStyle(DS.inkSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
                DuelTrophyCount(value: invite.from.trophies, size: 14, color: DS.ink)
            }

            countdownBar

            HStack(spacing: 10) {
                Button {
                    respond(invite, accept: false)
                } label: {
                    Text(languageManager.text("friends.requests.decline"))
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(DS.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous).fill(DS.surface))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous)
                                .strokeBorder(DS.hairline, lineWidth: 1.5)
                        )
                }
                // La réponse vibre déjà (`DuelHaptics.lock`).
                .buttonStyle(PressableStyle(scale: 0.96, haptic: false))

                Button {
                    respond(invite, accept: true)
                } label: {
                    Text(languageManager.text("friends.requests.accept"))
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous).fill(DS.accent))
                }
                .buttonStyle(PressableStyle(scale: 0.96, haptic: false))
            }
            .disabled(answering)
        }
        .dsCard(padding: 14)
    }

    /// Le temps qui reste pour répondre, en barre qui se vide.
    private var countdownBar: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            let remaining = max(service.incomingDeadline?.timeIntervalSince(timeline.date) ?? 0, 0)
            DuelProgressBar(progress: min(remaining / 15, 1), tint: DS.accent, track: DS.accentTint, height: 5)
        }
    }

    private func respond(_ invite: DuelIncomingInvite, accept: Bool) {
        guard !answering else { return }
        answering = true
        DuelHaptics.lock()
        Task {
            let start = await DuelLiveService.shared.respond(to: invite, accept: accept)
            if let start {
                DuelFriendPresenter.present(.incoming(start))
            }
        }
    }
}
