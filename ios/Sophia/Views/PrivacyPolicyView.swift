import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header
                LegalHeader(title: "Confidentialité", onClose: { dismiss() })

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Group {
                            sectionTitle("1. Introduction")
                            sectionBody("La presente Politique de Confidentialite decrit comment Sophia (ci-apres \"nous\", \"notre\" ou \"l'Application\") collecte, utilise et protege vos informations personnelles. Nous nous engageons a proteger votre vie privee et a traiter vos donnees de maniere transparente.")

                            sectionTitle("2. Donnees collectees")
                            sectionBody("Sophia est concue selon le principe de minimisation des donnees. L'Application stocke les informations suivantes uniquement sur votre appareil :\n\n- Votre progression dans les cours et quiz\n- Vos preferences (centres d'interet, age)\n- Votre streak (jours consecutifs d'utilisation)\n- Vos cours favoris\n\nCes donnees ne sont jamais transmises a nos serveurs ni a des tiers.")

                            sectionTitle("3. Donnees d'abonnement")
                            sectionBody("Si vous souscrivez a un abonnement premium, la transaction est geree entierement par Apple via l'App Store. Nous n'avons pas acces a vos informations de paiement (numero de carte, adresse de facturation). Nous recevons uniquement la confirmation de votre statut d'abonnement via RevenueCat, notre partenaire de gestion des abonnements.")

                            sectionTitle("4. RevenueCat")
                            sectionBody("Nous utilisons RevenueCat pour gerer les abonnements in-app. RevenueCat peut collecter un identifiant anonyme d'appareil pour verifier votre statut d'abonnement. Aucune donnee personnelle identifiable n'est partagee. Pour plus d'informations, consultez la politique de confidentialite de RevenueCat sur leur site web.")
                        }

                        Group {
                            sectionTitle("5. Donnees analytiques")
                            sectionBody("L'Application peut collecter des donnees analytiques anonymes fournies par Apple (App Analytics) pour ameliorer l'experience utilisateur. Ces donnees sont agregees et ne permettent pas de vous identifier personnellement. Vous pouvez desactiver le partage d'analytics dans les reglages de votre iPhone (Reglages > Confidentialite > Analyses et ameliorations).")

                            sectionTitle("6. Stockage des donnees")
                            sectionBody("Toutes vos donnees de progression sont stockees localement sur votre appareil via UserDefaults. Elles ne sont pas sauvegardees dans le cloud. La desinstallation de l'Application entraine la suppression definitive de ces donnees.")

                            sectionTitle("7. Partage de donnees")
                            sectionBody("Nous ne vendons, ne louons et ne partageons aucune donnee personnelle avec des tiers a des fins commerciales ou publicitaires. Les seules donnees transmises sont celles necessaires au fonctionnement des abonnements (via Apple et RevenueCat).")

                            sectionTitle("8. Droits des utilisateurs")
                            sectionBody("Conformement au Reglement General sur la Protection des Donnees (RGPD) et aux lois applicables, vous disposez des droits suivants :\n\n- Droit d'acces a vos donnees\n- Droit de rectification\n- Droit a l'effacement (reinitialisation dans les parametres)\n- Droit a la portabilite\n- Droit d'opposition\n\nPour exercer ces droits, contactez-nous via l'adresse indiquee sur notre page App Store.")

                            sectionTitle("9. Protection des mineurs")
                            sectionBody("Sophia est une application educative accessible a tous les ages. Nous ne collectons sciemment aucune donnee personnelle de mineurs de moins de 16 ans. L'Application ne contient aucun contenu inapproprie.")

                            sectionTitle("10. Modifications")
                            sectionBody("Nous nous reservons le droit de modifier cette politique a tout moment. Toute modification sera communiquee via une mise a jour de l'Application. La date de derniere mise a jour est indiquee ci-dessous.\n\nDerniere mise a jour : Mars 2025")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 48)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(.title3, design: .rounded, weight: .heavy))
            .foregroundStyle(ink)
    }

    private func sectionBody(_ text: String) -> some View {
        Text(text)
            .font(.system(.subheadline, design: .rounded, weight: .medium))
            .foregroundStyle(ink.opacity(0.75))
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
    }
}

/// Shared neo-brutalist header for legal sheets.
struct LegalHeader: View {
    let title: String
    let onClose: () -> Void
    private let ink = BrutalPalette.ink

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(ink)
                    .frame(width: 38, height: 38)
                    .background(Color.white, in: Circle())
                    .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ink)
                .frame(height: 2.5)
        }
    }
}
