import SwiftUI
import Supabase

/// Gestion de compte pour les utilisateurs déjà installés (création optionnelle) :
/// - déconnecté → proposition de créer un compte / se connecter (Apple ou Google),
/// - connecté → e-mail, déconnexion, suppression définitive du compte.
struct AccountView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var showSignOutAlert = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                DS.canvas.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        if auth.isSignedIn {
                            signedInContent
                        } else {
                            signedOutContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            .alert(languageManager.text("account.signOut.title"), isPresented: $showSignOutAlert) {
                Button(languageManager.text("settings.reset.alert.cancel"), role: .cancel) {}
                Button(languageManager.text("account.signOut.confirm"), role: .destructive) {
                    Task { await auth.signOut() }
                }
            } message: {
                Text(languageManager.text("account.signOut.message"))
            }
            .alert(languageManager.text("account.delete.title"), isPresented: $showDeleteAlert) {
                Button(languageManager.text("settings.reset.alert.cancel"), role: .cancel) {}
                Button(languageManager.text("account.delete.confirm"), role: .destructive) {
                    performDelete()
                }
            } message: {
                Text(languageManager.text("account.delete.message"))
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(languageManager.text("account.title"))
                .font(DS.title(.largeTitle, .semibold))
                .foregroundStyle(DS.ink)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.jakarta(size: 15, weight: .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(width: 40, height: 40)
                    .background(DS.surface, in: Circle())
                    .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
            }
        }
    }

    // MARK: - Signed out

    private var signedOutContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(languageManager.text("account.signedOut.headline"))
                    .font(DS.title(.title3, .semibold))
                    .foregroundStyle(DS.ink)
                Text(languageManager.text("account.signedOut.body"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .dsCard()

            AuthProvidersView(onSignedIn: { dismiss() })
        }
    }

    // MARK: - Signed in

    private var signedInContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                infoRow(
                    label: languageManager.text("account.email"),
                    value: auth.currentUser?.email ?? "—"
                )
                if let handle = SocialService.shared.myHandle {
                    Rectangle().fill(DS.hairline).frame(height: 1)
                    infoRow(
                        label: "@",
                        value: "@\(handle)"
                    )
                }
                Rectangle().fill(DS.hairline).frame(height: 1)
                infoRow(
                    label: languageManager.text("account.provider"),
                    value: providerLabel
                )
            }
            .dsCard()
            .task {
                await SocialService.shared.refreshMyHandle()
            }

            if let deleteError {
                Text(deleteError)
                    .font(DS.sans(.footnote, .medium))
                    .foregroundStyle(DS.danger)
            }

            Button {
                showSignOutAlert = true
            } label: {
                Text(languageManager.text("account.signOut.action"))
            }
            .buttonStyle(DSSecondaryButtonStyle())
            .disabled(isDeleting)

            Button {
                showDeleteAlert = true
            } label: {
                HStack(spacing: 8) {
                    if isDeleting { ProgressView().tint(.white) }
                    Text(languageManager.text("account.delete.action"))
                }
            }
            .buttonStyle(DSPrimaryButtonStyle(fill: DS.danger))
            .disabled(isDeleting)
        }
    }

    private var providerLabel: String {
        let raw = auth.currentUser?.identities?.first?.provider ?? ""
        switch raw {
        case "apple": return "Apple"
        case "google": return "Google"
        default: return raw.isEmpty ? "—" : raw.capitalized
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(DS.sans(.body, .medium))
                .foregroundStyle(DS.inkSecondary)
            Spacer()
            Text(value)
                .font(DS.sans(.body, .semibold))
                .foregroundStyle(DS.ink)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func performDelete() {
        guard !isDeleting else { return }
        deleteError = nil
        isDeleting = true
        Task {
            do {
                try await auth.deleteAccount()
                isDeleting = false
                dismiss()
            } catch {
                isDeleting = false
                deleteError = languageManager.text("account.delete.error")
            }
        }
    }
}
