import SwiftUI
import Observation

/// État du nouvel onboarding (V2).
///
/// Les centres d'intérêt viennent de la page « Quels sujets t'intéressent le plus ? » ; quand
/// elle n'a rien donné, ils sont **dérivés des objectifs** choisis (mapping ci-dessous). Ils
/// sont persistés sous la même clé qu'avant (`sophia_user_interests`) pour que l'accueil et les
/// recommandations existants restent pertinents sans autre changement.
@Observable
@MainActor
final class OnboardingV2ViewModel {
    /// Prénom tapé sur la page « Comment tu t'appelles ? » ; vide quand elle a été passée.
    var firstName: String = "" {
        didSet { OnboardingResumeStore.firstName = firstName }
    }
    /// Tranche d'âge (`ageRangeKeys`), nil tant que la page n'a pas été répondue.
    var ageRangeKey: String? = nil {
        didSet { OnboardingResumeStore.ageRangeKey = ageRangeKey }
    }
    /// Culture générale auto-évaluée, de 0 (« pas terrible ») à 3 (« très bonne »).
    var knowledgeLevel: Int = 1 {
        didSet { OnboardingResumeStore.knowledgeLevel = knowledgeLevel }
    }
    /// Pourquoi la personne veut progresser (`motivationKeys`), nil tant que pas répondu.
    var motivationKey: String? = nil {
        didSet { OnboardingResumeStore.motivationKey = motivationKey }
    }
    /// Objectifs sélectionnés (multi-sélection), dans l'ordre de sélection.
    var objectiveKeys: [String] = [] {
        didSet { OnboardingResumeStore.objectiveKeys = objectiveKeys }
    }
    /// Matières choisies sur la page des sujets (clés de stockage), dans l'ordre de sélection.
    var topicKeys: [String] = [] {
        didSet { OnboardingResumeStore.topicKeys = topicKeys }
    }
    /// Cours « aimés » lors du swipe — utilisés pour préremplir les favoris.
    var likedCourseIds: [String] = [] {
        didSet { OnboardingResumeStore.likedCourseIds = likedCourseIds }
    }
    /// Cours présentés dans le swipe — exclus des recommandations de l'écran profil pour ne
    /// pas remontrer les mêmes cours.
    var swipedCourseIds: [String] = [] {
        didSet { OnboardingResumeStore.swipedCourseIds = swipedCourseIds }
    }
    /// Temps d'écran quotidien déclaré (en minutes, par blocs de 30) — écran « temps téléphone ».
    /// Sert à l'écran « ta vie en années » (remplissage rouge).
    /// Hour of the day (local, 5…23) the user wants to read their course. Becomes the
    /// daily reminder once notifications are allowed.
    var reminderHour: Int = DailyCourseReminder.storedHour {
        didSet { DailyCourseReminder.storedHour = reminderHour }
    }

    var phoneDailyMinutes: Int = 180 {
        didSet { OnboardingResumeStore.phoneDailyMinutes = phoneDailyMinutes }
    }

    /// Restaure les réponses déjà données : fermer l'app au milieu de l'onboarding ne doit
    /// pas effacer ce que la personne a rempli avant.
    init() {
        firstName = OnboardingResumeStore.firstName
        ageRangeKey = OnboardingResumeStore.ageRangeKey
        if let level = OnboardingResumeStore.knowledgeLevel { knowledgeLevel = level }
        motivationKey = OnboardingResumeStore.motivationKey
        objectiveKeys = OnboardingResumeStore.objectiveKeys
        topicKeys = OnboardingResumeStore.topicKeys
        likedCourseIds = OnboardingResumeStore.likedCourseIds
        swipedCourseIds = OnboardingResumeStore.swipedCourseIds
        let storedMinutes = OnboardingResumeStore.phoneDailyMinutes
        if storedMinutes > 0 { phoneDailyMinutes = storedMinutes }
    }

    /// Nombre d'années (sur une vie de 80 ans) équivalent au temps passé sur le téléphone.
    var phoneYearsOverLife: Double {
        80.0 * Double(phoneDailyMinutes) / (24.0 * 60.0)
    }

    // MARK: - Prénom

    static let firstNameMaxLength = 24

    /// Le prénom tel que tapé, sans espaces autour et borné, pour l'afficher dans les titres.
    var trimmedFirstName: String {
        String(firstName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.firstNameMaxLength))
    }

    /// `key` avec le prénom dedans : la chaîne `<key>Named` (avec `{name}` rempli) quand un
    /// prénom a été donné et que cette chaîne existe, sinon la chaîne `key` telle quelle.
    func personalizedText(_ key: String, language: AppLanguage) -> String {
        Self.personalizedText(key, name: trimmedFirstName, language: language)
    }

    static func personalizedText(_ key: String, name: String, language: AppLanguage) -> String {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty {
            let namedKey = key + "Named"
            let named = AppLocalizable.string(namedKey, language: language)
            if named != namedKey {
                return named.replacingOccurrences(of: "{name}", with: name)
            }
        }
        return AppLocalizable.string(key, language: language)
    }

    // MARK: - Âge

    static let ageRangeKeys = ["under18", "18to24", "25to34", "35to44", "45to54", "55plus"]

    static func ageRangeLabel(_ key: String, language: AppLanguage) -> String {
        AppLocalizable.string("onboardingV2.age.\(key)", language: language)
    }

    // MARK: - Culture générale

    /// Quatre crans, de « pas terrible » à « très bonne ».
    static let knowledgeLevelCount = 4

    static func knowledgeLevelLabel(_ level: Int, language: AppLanguage) -> String {
        AppLocalizable.string("onboardingV2.knowledge.level\(clampedKnowledgeLevel(level) + 1)", language: language)
    }

    static func knowledgeLevelEmoji(_ level: Int) -> String {
        ["😅", "🙂", "😎", "🤓"][clampedKnowledgeLevel(level)]
    }

    private static func clampedKnowledgeLevel(_ level: Int) -> Int {
        min(max(level, 0), knowledgeLevelCount - 1)
    }

    // MARK: - Motivation

    static let motivationKeys = ["grow", "conversations", "career", "sharp", "world"]

    static func motivationLabel(_ key: String, language: AppLanguage) -> String {
        AppLocalizable.string("onboardingV2.motivation.\(key)", language: language)
    }

    static func motivationEmoji(_ key: String) -> String {
        switch key {
        case "grow": "🌱"
        case "conversations": "💬"
        case "career": "💼"
        case "sharp": "🧠"
        case "world": "🌍"
        default: "✨"
        }
    }

    // MARK: - Objectifs

    static let objectiveKeys = ["cultivate", "reduceScreen", "exams", "impress", "curiosity"]

    static func objectiveLabel(_ key: String, language: AppLanguage) -> String {
        AppLocalizable.string("onboardingV2.objective.\(key)", language: language)
    }

    static func objectiveEmoji(_ key: String) -> String {
        switch key {
        case "cultivate": "🧠"
        case "reduceScreen": "📵"
        case "exams": "🎓"
        case "impress": "✨"
        case "curiosity": "🔭"
        default: "📚"
        }
    }

    func toggleObjective(_ key: String) {
        if let idx = objectiveKeys.firstIndex(of: key) {
            objectiveKeys.remove(at: idx)
        } else {
            objectiveKeys.append(key)
        }
    }

    func isSelected(_ key: String) -> Bool {
        objectiveKeys.contains(key)
    }

    /// Matières associées à chaque objectif (repli des recommandations et du swipe quand la
    /// page des sujets n'a rien donné).
    static func subjects(for objectiveKey: String?) -> [String] {
        switch objectiveKey {
        case "exams":
            return ["histoire", "sciences", "litterature", "comprendreLeMonde"]
        case "impress":
            return ["histoire", "art", "litterature", "mythologie"]
        case "curiosity":
            return ["sciences", "mythologie", "art", "comprendreLeMonde"]
        case "cultivate", "reduceScreen":
            return Subject.allCases.map(\.storageKey)
        default:
            return Subject.allCases.map(\.storageKey)
        }
    }

    // MARK: - Sujets

    func toggleTopic(_ key: String) {
        if let idx = topicKeys.firstIndex(of: key) {
            topicKeys.remove(at: idx)
        } else {
            topicKeys.append(key)
        }
    }

    func isTopicSelected(_ key: String) -> Bool {
        topicKeys.contains(key)
    }

    /// Matières retenues, dans l'ordre de `Subject.allCases` : celles de la page des sujets,
    /// ou, si elle n'a rien donné, l'union des matières des objectifs sélectionnés.
    var selectedSubjects: [String] {
        let chosen: Set<String> = topicKeys.isEmpty
            ? Set(objectiveKeys.flatMap { Self.subjects(for: $0) })
            : Set(topicKeys)
        return Subject.allCases.map(\.storageKey).filter { chosen.contains($0) }
    }

    // MARK: - Recommandations (swipe)

    /// 5 cours à swiper, dérivés des matières des objectifs (fallback : starters curatés).
    /// Four hand-picked hooks first, in this order, then two from the recommender.
    static let pinnedSwipeCourseIds: [String] = [
        "course_47_pourquoi_baille_t_on",
        "course_201_la_naissance_du_conflit_israelo_palestin",
        "course_149_la_joconde",
        "course_44_pourquoi_l_eau_de_mer_est_elle_salee",
    ]

    func recommendedCourses(language: AppLanguage) -> [Course] {
        let interests = Set(selectedSubjects)
        let pinned = Self.pinnedSwipeCourseIds.compactMap { ContentCatalog.course(withId: $0, language: language) }
        let rest = OnboardingCourseRecommender.recommendedCourses(
            interests: interests,
            language: language,
            limit: 2,
            excluding: Set(Self.pinnedSwipeCourseIds)
        )
        return pinned + rest.filter { course in !pinned.contains { $0.id == course.id } }
    }

    /// Mémorise les cours affichés dans le swipe pour les exclure de l'écran profil.
    func rememberSwipedCourses(_ courses: [Course]) {
        swipedCourseIds = courses.map(\.id)
    }

    // MARK: - Profil (écran récompense « Voici ton profil », avant la création de compte)

    /// Archétype dérivé des réponses (objectif principal) — sert à attribuer un surnom.
    /// On prend le premier objectif sélectionné ; fallback « cultivate » si aucun.
    var profileArchetypeKey: String {
        objectiveKeys.first ?? "cultivate"
    }

    /// Surnom attribué à l'utilisateur en fonction de ses réponses.
    func profileNickname(language: AppLanguage) -> String {
        AppLocalizable.string("onboardingV2.profile.nickname.\(profileArchetypeKey)", language: language)
    }

    /// Phrase courte qui décrit l'archétype (« qui tu es »).
    func profileTagline(language: AppLanguage) -> String {
        AppLocalizable.string("onboardingV2.profile.tagline.\(profileArchetypeKey)", language: language)
    }

    /// Emoji illustrant l'archétype.
    var profileEmoji: String {
        Self.objectiveEmoji(profileArchetypeKey)
    }

    /// Cours recommandés qui « attendent » l'utilisateur sur l'écran profil.
    /// Exclut les cours déjà vus dans le swipe pour en proposer de nouveaux.
    func awaitingCourses(language: AppLanguage) -> [Course] {
        let interests = Set(selectedSubjects)
        return OnboardingCourseRecommender.recommendedCourses(
            interests: interests,
            language: language,
            limit: 5,
            excluding: Set(swipedCourseIds)
        )
    }

    func toggleLiked(_ courseId: String, liked: Bool) {
        if liked {
            if !likedCourseIds.contains(courseId) { likedCourseIds.append(courseId) }
        } else {
            likedCourseIds.removeAll { $0 == courseId }
        }
    }

    // MARK: - Persistance

    /// Réponses des pages « à propos de toi », gardées pour l'app (accueil, profil…).
    static let firstNameDefaultsKey = "sophia_user_first_name"
    static let ageRangeDefaultsKey = "sophia_user_age_range"
    static let knowledgeLevelDefaultsKey = "sophia_user_knowledge_level"
    static let motivationDefaultsKey = "sophia_user_motivation"

    /// Persiste les intérêts (sujets choisis, sinon dérivés des objectifs), les favoris aimés
    /// et les réponses « à propos de toi », puis marque l'onboarding terminé.
    func persistAndComplete(progressManager: ProgressManager) {
        let defaults = UserDefaults.standard
        defaults.set(selectedSubjects.sorted(), forKey: OnboardingViewModel.interestsKey)

        for id in likedCourseIds where !progressManager.isFavorite(id) {
            progressManager.toggleFavorite(id)
        }

        if !objectiveKeys.isEmpty {
            defaults.set(objectiveKeys, forKey: "sophia_onboarding_objectives")
        }

        let name = trimmedFirstName
        defaults.set(name.isEmpty ? nil : name, forKey: Self.firstNameDefaultsKey)
        defaults.set(ageRangeKey, forKey: Self.ageRangeDefaultsKey)
        defaults.set(knowledgeLevel, forKey: Self.knowledgeLevelDefaultsKey)
        defaults.set(motivationKey, forKey: Self.motivationDefaultsKey)

        DailyCourseReminder.storedHour = reminderHour
        DailyCourseReminder.scheduleIfAllowed()

        OnboardingViewModel().completeOnboarding()
    }
}
