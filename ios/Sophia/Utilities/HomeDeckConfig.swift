import Foundation

/// Réglage du fil d'accueil, piloté depuis Supabase en **lecture seule** : `app_config`,
/// clé `home_deck`, `{"head_pool": 5, "exploration_every": 4}`.
///
/// Même mécanique que `PaywallExperiment` : la dernière valeur connue de l'appareil sert
/// tout de suite, la nouvelle est lue en arrière-plan au lancement, et une ligne absente ou
/// un réseau coupé laisse les valeurs par défaut de `DeckTuning`. Rien n'attend le réseau.
enum HomeDeckConfig {
    static let key = "home_deck"
    private static let storageKey = "sophia_home_deck_config"

    private(set) static var tuning: DeckTuning = loadSaved()
    private static var didStart = false

    /// Lance la lecture du réglage, une fois par lancement. Le fil déjà affiché ne bouge pas.
    static func start() {
        guard !didStart else { return }
        didStart = true
        Task {
            await refresh()
        }
    }

    static func refresh() async {
        guard let data = await PaywallExperiment.fetchRow(key: key) else { return }
        let decoded: DeckTuning? = PaywallExperiment.parse(data)
        let parsed: DeckTuning = decoded ?? .fallback
        tuning = parsed
        if let encoded = try? JSONEncoder().encode(parsed) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private static func loadSaved() -> DeckTuning {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode(DeckTuning.self, from: data) else {
            return .fallback
        }
        return saved
    }
}
