import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
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
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(SophiaTheme.background)
            .navigationTitle("Confidentialite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                        .foregroundStyle(SophiaTheme.emerald)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
    }

    private func sectionBody(_ text: String) -> some View {
        Text(text)
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(.white.opacity(0.7))
            .lineSpacing(4)
    }
}
