import Foundation

struct LegalSection: Identifiable {
    let id: String
    let title: String
    let body: String
}

enum LegalDocumentContent {
    static func terms(language: AppLanguage) -> [LegalSection] {
        language == .french ? termsFrench : termsEnglish
    }

    static func privacy(language: AppLanguage) -> [LegalSection] {
        language == .french ? privacyFrench : privacyEnglish
    }

    // MARK: - Terms (FR)

    private static let termsFrench: [LegalSection] = [
        LegalSection(id: "1", title: "1. Acceptation des conditions", body: "En téléchargeant, installant ou utilisant l'application Sophia (ci-après « l'Application »), vous acceptez d'être lié par les présentes Conditions Générales d'Utilisation (« CGU »). Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser l'Application."),
        LegalSection(id: "2", title: "2. Description du service", body: "Sophia est une application mobile éducative de culture générale proposant des cours, quiz et contenus interactifs. L'Application est disponible sur iOS et peut proposer des contenus gratuits ainsi que des abonnements premium."),
        LegalSection(id: "3", title: "3. Compte et utilisation", body: "L'Application ne nécessite pas de création de compte. Vos données de progression sont stockées localement sur votre appareil. Vous êtes responsable de la sauvegarde de vos données. La réinstallation de l'Application peut entraîner la perte de votre progression."),
        LegalSection(id: "4", title: "4. Abonnements et achats", body: "Sophia propose des abonnements premium (mensuel et annuel) via l'App Store d'Apple. Les prix sont affichés dans l'Application et peuvent varier selon votre pays. Le paiement est prélevé sur votre compte Apple ID à la confirmation de l'achat. L'abonnement se renouvelle automatiquement sauf si le renouvellement automatique est désactivé au moins 24 heures avant la fin de la période en cours. Vous pouvez gérer et annuler vos abonnements dans les réglages de votre compte App Store."),
        LegalSection(id: "5", title: "5. Essai gratuit", body: "Un essai gratuit peut être proposé aux nouveaux utilisateurs. À l'expiration de la période d'essai, l'abonnement sera automatiquement converti en abonnement payant sauf annulation préalable. Toute partie non utilisée de la période d'essai gratuit sera perdue lors de l'achat d'un abonnement."),
        LegalSection(id: "6", title: "6. Propriété intellectuelle", body: "L'ensemble des contenus de l'Application (textes, illustrations, design, logo, cours, quiz) sont protégés par le droit d'auteur et restent la propriété exclusive de Sophia. Toute reproduction, distribution ou utilisation non autorisée est strictement interdite."),
        LegalSection(id: "7", title: "7. Limitation de responsabilité", body: "Les contenus proposés dans l'Application sont fournis à titre éducatif et informatif. Sophia ne garantit pas l'exactitude, l'exhaustivité ou l'actualité des informations présentées. L'Application est fournie « en l'état » sans garantie d'aucune sorte."),
        LegalSection(id: "8", title: "8. Modification des conditions", body: "Sophia se réserve le droit de modifier les présentes CGU à tout moment. Les utilisateurs seront informés des modifications significatives. La poursuite de l'utilisation de l'Application après modification vaut acceptation des nouvelles conditions."),
        LegalSection(id: "9", title: "9. Droit applicable", body: "Les présentes CGU sont soumises au droit français. Tout litige relatif à l'interprétation ou à l'exécution des présentes sera soumis aux tribunaux compétents."),
        LegalSection(id: "10", title: "10. Contact", body: "Pour toute question relative aux présentes CGU, vous pouvez nous contacter via l'App Store ou par email à l'adresse indiquée sur notre page App Store."),
    ]

    // MARK: - Terms (EN)

    private static let termsEnglish: [LegalSection] = [
        LegalSection(id: "1", title: "1. Acceptance of terms", body: "By downloading, installing, or using the Sophia app (the \"App\"), you agree to be bound by these Terms of Service (\"Terms\"). If you do not accept these terms, please do not use the App."),
        LegalSection(id: "2", title: "2. Description of the service", body: "Sophia is an educational general-knowledge mobile app offering courses, quizzes, and interactive content. The App is available on iOS and may offer free content as well as premium subscriptions."),
        LegalSection(id: "3", title: "3. Account and use", body: "The App does not require account creation. Your progress data is stored locally on your device. You are responsible for backing up your data. Reinstalling the App may result in loss of your progress."),
        LegalSection(id: "4", title: "4. Subscriptions and purchases", body: "Sophia offers premium subscriptions (monthly and annual) through Apple's App Store. Prices are displayed in the App and may vary by country. Payment is charged to your Apple ID account upon purchase confirmation. Subscriptions renew automatically unless auto-renew is turned off at least 24 hours before the end of the current period. You can manage and cancel subscriptions in your App Store account settings."),
        LegalSection(id: "5", title: "5. Free trial", body: "A free trial may be offered to new users. When the trial period ends, the subscription will automatically convert to a paid subscription unless cancelled beforehand. Any unused portion of a free trial is forfeited when purchasing a subscription."),
        LegalSection(id: "6", title: "6. Intellectual property", body: "All App content (text, illustrations, design, logo, courses, quizzes) is protected by copyright and remains the exclusive property of Sophia. Any unauthorized reproduction, distribution, or use is strictly prohibited."),
        LegalSection(id: "7", title: "7. Limitation of liability", body: "Content in the App is provided for educational and informational purposes. Sophia does not guarantee the accuracy, completeness, or timeliness of the information presented. The App is provided \"as is\" without warranty of any kind."),
        LegalSection(id: "8", title: "8. Changes to terms", body: "Sophia reserves the right to modify these Terms at any time. Users will be notified of significant changes. Continued use of the App after changes constitutes acceptance of the new terms."),
        LegalSection(id: "9", title: "9. Governing law", body: "These Terms are governed by French law. Any dispute relating to the interpretation or performance of these Terms shall be submitted to the competent courts."),
        LegalSection(id: "10", title: "10. Contact", body: "For any questions regarding these Terms, you can contact us via the App Store or by email at the address listed on our App Store page."),
    ]

    // MARK: - Privacy (FR)

    private static let privacyFrench: [LegalSection] = [
        LegalSection(id: "1", title: "1. Introduction", body: "La présente Politique de Confidentialité décrit comment Sophia (ci-après « nous », « notre » ou « l'Application ») collecte, utilise et protège vos informations personnelles. Nous nous engageons à protéger votre vie privée et à traiter vos données de manière transparente."),
        LegalSection(id: "2", title: "2. Données collectées", body: "Sophia est conçue selon le principe de minimisation des données. L'Application stocke les informations suivantes uniquement sur votre appareil :\n\n- Votre progression dans les cours et quiz\n- Vos préférences (centres d'intérêt, âge)\n- Votre streak (jours consécutifs d'utilisation)\n- Vos cours favoris\n\nCes données ne sont jamais transmises à nos serveurs ni à des tiers."),
        LegalSection(id: "3", title: "3. Données d'abonnement", body: "Si vous souscrivez à un abonnement premium, la transaction est gérée entièrement par Apple via l'App Store. Nous n'avons pas accès à vos informations de paiement (numéro de carte, adresse de facturation). Nous recevons uniquement la confirmation de votre statut d'abonnement via RevenueCat, notre partenaire de gestion des abonnements."),
        LegalSection(id: "4", title: "4. RevenueCat", body: "Nous utilisons RevenueCat pour gérer les abonnements in-app. RevenueCat peut collecter un identifiant anonyme d'appareil pour vérifier votre statut d'abonnement. Aucune donnée personnelle identifiable n'est partagée. Pour plus d'informations, consultez la politique de confidentialité de RevenueCat sur leur site web."),
        LegalSection(id: "5", title: "5. Données analytiques", body: "L'Application peut collecter des données analytiques anonymes fournies par Apple (App Analytics) pour améliorer l'expérience utilisateur. Ces données sont agrégées et ne permettent pas de vous identifier personnellement. Vous pouvez désactiver le partage d'analytics dans les réglages de votre iPhone (Réglages > Confidentialité > Analyses et améliorations)."),
        LegalSection(id: "6", title: "6. Stockage des données", body: "Toutes vos données de progression sont stockées localement sur votre appareil via UserDefaults. Elles ne sont pas sauvegardées dans le cloud. La désinstallation de l'Application entraîne la suppression définitive de ces données."),
        LegalSection(id: "7", title: "7. Partage de données", body: "Nous ne vendons, ne louons et ne partageons aucune donnée personnelle avec des tiers à des fins commerciales ou publicitaires. Les seules données transmises sont celles nécessaires au fonctionnement des abonnements (via Apple et RevenueCat)."),
        LegalSection(id: "8", title: "8. Droits des utilisateurs", body: "Conformément au Règlement Général sur la Protection des Données (RGPD) et aux lois applicables, vous disposez des droits suivants :\n\n- Droit d'accès à vos données\n- Droit de rectification\n- Droit à l'effacement (réinitialisation dans les paramètres)\n- Droit à la portabilité\n- Droit d'opposition\n\nPour exercer ces droits, contactez-nous via l'adresse indiquée sur notre page App Store."),
        LegalSection(id: "9", title: "9. Protection des mineurs", body: "Sophia est une application éducative accessible à tous les âges. Nous ne collectons sciemment aucune donnée personnelle de mineurs de moins de 16 ans. L'Application ne contient aucun contenu inapproprié."),
        LegalSection(id: "10", title: "10. Modifications", body: "Nous nous réservons le droit de modifier cette politique à tout moment. Toute modification sera communiquée via une mise à jour de l'Application.\n\nDernière mise à jour : Mars 2025"),
    ]

    // MARK: - Privacy (EN)

    private static let privacyEnglish: [LegalSection] = [
        LegalSection(id: "1", title: "1. Introduction", body: "This Privacy Policy describes how Sophia (\"we\", \"our\", or the \"App\") collects, uses, and protects your personal information. We are committed to protecting your privacy and handling your data transparently."),
        LegalSection(id: "2", title: "2. Data collected", body: "Sophia is designed with data minimization in mind. The App stores the following information only on your device:\n\n- Your progress in courses and quizzes\n- Your preferences (interests, age)\n- Your streak (consecutive days of use)\n- Your favorite courses\n\nThis data is never transmitted to our servers or to third parties."),
        LegalSection(id: "3", title: "3. Subscription data", body: "If you subscribe to a premium plan, the transaction is handled entirely by Apple via the App Store. We do not have access to your payment information (card number, billing address). We only receive confirmation of your subscription status via RevenueCat, our subscription management partner."),
        LegalSection(id: "4", title: "4. RevenueCat", body: "We use RevenueCat to manage in-app subscriptions. RevenueCat may collect an anonymous device identifier to verify your subscription status. No personally identifiable information is shared. For more information, see RevenueCat's privacy policy on their website."),
        LegalSection(id: "5", title: "5. Analytics data", body: "The App may collect anonymous analytics data provided by Apple (App Analytics) to improve the user experience. This data is aggregated and cannot be used to identify you personally. You can disable analytics sharing in your iPhone settings (Settings > Privacy > Analytics & Improvements)."),
        LegalSection(id: "6", title: "6. Data storage", body: "All your progress data is stored locally on your device via UserDefaults. It is not backed up to the cloud. Uninstalling the App permanently deletes this data."),
        LegalSection(id: "7", title: "7. Data sharing", body: "We do not sell, rent, or share personal data with third parties for commercial or advertising purposes. The only data transmitted is that required for subscriptions to work (via Apple and RevenueCat)."),
        LegalSection(id: "8", title: "8. User rights", body: "Under the General Data Protection Regulation (GDPR) and applicable laws, you have the following rights:\n\n- Right of access to your data\n- Right to rectification\n- Right to erasure (reset in Settings)\n- Right to data portability\n- Right to object\n\nTo exercise these rights, contact us via the address listed on our App Store page."),
        LegalSection(id: "9", title: "9. Protection of minors", body: "Sophia is an educational app suitable for all ages. We do not knowingly collect personal data from children under 16. The App contains no inappropriate content."),
        LegalSection(id: "10", title: "10. Changes", body: "We reserve the right to modify this policy at any time. Any changes will be communicated through an App update.\n\nLast updated: March 2025"),
    ]
}
