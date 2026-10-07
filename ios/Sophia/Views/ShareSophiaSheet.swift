import SwiftUI
import UIKit

// MARK: - Le lien et les messages

/// Partager Sophia : le lien court `taap.it/sophia.culture`, qui renvoie directement vers
/// le store, et le texte qui l'accompagne.
enum SophiaShare {
    static let url = URL(string: "https://taap.it/sophia.culture")!

    /// La phrase d'invitation suivie du lien, dans la langue de l'app.
    static func message(_ languageManager: LanguageManager) -> String {
        languageManager.text("share.message") + "\n" + url.absoluteString
    }

    /// `whatsapp://send?text=…` : WhatsApp s'ouvre sur le choix du contact, le message prêt.
    static func whatsAppURL(message: String) -> URL? {
        URL(string: "whatsapp://send?text=" + encode(message))
    }

    /// `sms:&body=…` : Messages s'ouvre, le texte déjà saisi.
    static func messagesURL(message: String) -> URL? {
        URL(string: "sms:&body=" + encode(message))
    }

    private static func encode(_ text: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return text.addingPercentEncoding(withAllowedCharacters: allowed) ?? text
    }
}

// MARK: - La feuille

/// « Fais découvrir Sophia » : le lien à copier, WhatsApp, Messages, et la feuille de partage
/// du système pour tout le reste. Une feuille qu'on tire vers le bas, sans barre de titre.
struct ShareSophiaSheet: View {
    @Environment(LanguageManager.self) private var languageManager

    @State private var copied = false
    @State private var showSystemShare = false
    @State private var appeared = false

    private static let whatsAppGreen = Color(red: 0.14, green: 0.83, blue: 0.40)
    private static let messagesBlue = Color(red: 0.20, green: 0.78, blue: 0.35)

    private var message: String { SophiaShare.message(languageManager) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 26)

            ZStack {
                Circle().fill(DS.accentTint).frame(width: 76, height: 76)
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(DS.accent)
                    .rotationEffect(.degrees(appeared ? 0 : -25))
            }
            .scaleEffect(appeared ? 1 : 0.7)

            Spacer().frame(height: 16)

            Text(languageManager.text("share.title"))
                .font(DS.title(.title2, .heavy))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer().frame(height: 8)

            Text(languageManager.text("share.subtitle"))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)

            Spacer().frame(height: 22)

            linkCard
                .padding(.horizontal, 24)

            Spacer().frame(height: 14)

            HStack(spacing: 12) {
                channelButton(
                    title: languageManager.text("share.whatsapp"),
                    icon: "phone.bubble.fill",
                    tint: Self.whatsAppGreen
                ) {
                    open(SophiaShare.whatsAppURL(message: message))
                }
                channelButton(
                    title: languageManager.text("share.messages"),
                    icon: "message.fill",
                    tint: Self.messagesBlue
                ) {
                    open(SophiaShare.messagesURL(message: message))
                }
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 12)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showSystemShare = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.jakarta(size: 15, weight: .bold))
                    Text(languageManager.text("share.more"))
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 22)
        }
        .frame(maxWidth: OV2.readableWidth)
        .frame(maxWidth: .infinity)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(30)
        .presentationBackground(DS.canvas)
        .sheet(isPresented: $showSystemShare) {
            ActivityShareSheet(items: [message])
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.1)) { appeared = true }
        }
    }

    /// Le lien, en clair, et un bouton pour le copier.
    private var linkCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "link")
                .font(.jakarta(size: 15, weight: .semibold))
                .foregroundStyle(DS.accentSoft)
            Text("taap.it/sophia.culture")
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(DS.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 8)
            Button {
                UIPasteboard.general.string = SophiaShare.url.absoluteString
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeOut(duration: 0.3)) { copied = false }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.jakarta(size: 12, weight: .bold))
                    Text(languageManager.text(copied ? "share.copied" : "share.copy"))
                        .font(DS.sans(.caption, .bold))
                        .lineLimit(1)
                }
                .foregroundStyle(copied ? .white : DS.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(copied ? DS.success : DS.accentTint, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(DS.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
    }

    private func channelButton(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.jakarta(size: 15, weight: .bold))
                Text(title)
                    .font(DS.sans(.subheadline, .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(tint, in: Capsule(style: .continuous))
        }
        .buttonStyle(SoftPressButtonStyle())
    }

    /// Ouvre l'app visée ; si elle n'est pas installée, la feuille de partage du système prend
    /// le relais, pour que le bouton fasse toujours quelque chose.
    private func open(_ url: URL?) {
        guard let url else { showSystemShare = true; return }
        UIApplication.shared.open(url, options: [:]) { opened in
            if !opened {
                DispatchQueue.main.async { showSystemShare = true }
            }
        }
    }
}

// MARK: - Feuille de partage du système

/// `UIActivityViewController` dans une feuille SwiftUI : AirDrop, Mail, Notes, et toutes les
/// apps installées.
struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
