import SwiftUI

struct TermsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        sectionTitle("1. Acceptation des conditions")
                        sectionBody("En telechargeant, installant ou utilisant l'application Sophia (ci-apres \"l'Application\"), vous acceptez d'etre lie par les presentes Conditions Generales d'Utilisation (\"CGU\"). Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser l'Application.")

                        sectionTitle("2. Description du service")
                        sectionBody("Sophia est une application mobile educative de culture generale proposant des cours, quiz et contenus interactifs. L'Application est disponible sur iOS et peut proposer des contenus gratuits ainsi que des abonnements premium.")

                        sectionTitle("3. Compte et utilisation")
                        sectionBody("L'Application ne necessite pas de creation de compte. Vos donnees de progression sont stockees localement sur votre appareil. Vous etes responsable de la sauvegarde de vos donnees. La reinstallation de l'Application peut entrainer la perte de votre progression.")

                        sectionTitle("4. Abonnements et achats")
                        sectionBody("Sophia propose des abonnements premium (mensuel et annuel) via l'App Store d'Apple. Les prix sont affiches dans l'Application et peuvent varier selon votre pays. Le paiement est preleve sur votre compte Apple ID a la confirmation de l'achat. L'abonnement se renouvelle automatiquement sauf si le renouvellement automatique est desactive au moins 24 heures avant la fin de la periode en cours. Vous pouvez gerer et annuler vos abonnements dans les reglages de votre compte App Store.")
                    }

                    Group {
                        sectionTitle("5. Essai gratuit")
                        sectionBody("Un essai gratuit peut etre propose aux nouveaux utilisateurs. A l'expiration de la periode d'essai, l'abonnement sera automatiquement converti en abonnement payant sauf annulation prealable. Toute partie non utilisee de la periode d'essai gratuit sera perdue lors de l'achat d'un abonnement.")

                        sectionTitle("6. Propriete intellectuelle")
                        sectionBody("L'ensemble des contenus de l'Application (textes, illustrations, design, logo, cours, quiz) sont proteges par le droit d'auteur et restent la propriete exclusive de Sophia. Toute reproduction, distribution ou utilisation non autorisee est strictement interdite.")

                        sectionTitle("7. Limitation de responsabilite")
                        sectionBody("Les contenus proposes dans l'Application sont fournis a titre educatif et informatif. Sophia ne garantit pas l'exactitude, l'exhaustivite ou l'actualite des informations presentees. L'Application est fournie \"en l'etat\" sans garantie d'aucune sorte.")

                        sectionTitle("8. Modification des conditions")
                        sectionBody("Sophia se reserve le droit de modifier les presentes CGU a tout moment. Les utilisateurs seront informes des modifications significatives. La poursuite de l'utilisation de l'Application apres modification vaut acceptation des nouvelles conditions.")

                        sectionTitle("9. Droit applicable")
                        sectionBody("Les presentes CGU sont soumises au droit francais. Tout litige relatif a l'interpretation ou a l'execution des presentes sera soumis aux tribunaux competents.")

                        sectionTitle("10. Contact")
                        sectionBody("Pour toute question relative aux presentes CGU, vous pouvez nous contacter via l'App Store ou par email a l'adresse indiquee sur notre page App Store.")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(SophiaTheme.background)
            .navigationTitle("Conditions generales")
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
            .foregroundStyle(SophiaTheme.textPrimary)
    }

    private func sectionBody(_ text: String) -> some View {
        Text(text)
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(Color.black.opacity(0.7))
            .lineSpacing(4)
    }
}
