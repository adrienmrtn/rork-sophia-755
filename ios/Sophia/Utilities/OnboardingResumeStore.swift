import Foundation

/// Where the user got to in the onboarding, and the answers they had already given.
///
/// The flow is over twenty pages long. Closing the app halfway through used to drop everything
/// and start again at the welcome page, which is a flow people abandon rather than redo. The
/// step is stored by name rather than by index because the sequence is not fixed — the trial
/// page is removed when the served offering has no trial — so an index could resume onto a
/// different page than the one that was left.
enum OnboardingResumeStore {
    private static let stepKey = "sophia_onboarding_step"
    private static let firstNameStorageKey = "sophia_onboarding_first_name"
    private static let ageRangeStorageKey = "sophia_onboarding_age_range"
    private static let knowledgeLevelStorageKey = "sophia_onboarding_knowledge_level"
    private static let motivationStorageKey = "sophia_onboarding_motivation"
    private static let objectivesKey = "sophia_onboarding_objectives"
    private static let topicsStorageKey = "sophia_onboarding_topics"
    private static let likedKey = "sophia_onboarding_liked"
    private static let swipedKey = "sophia_onboarding_swiped"
    private static let phoneMinutesKey = "sophia_onboarding_phone_minutes"

    /// Name of the last page reached, or nil on a first run.
    static var step: String? {
        get { UserDefaults.standard.string(forKey: stepKey) }
        set { UserDefaults.standard.setValue(newValue, forKey: stepKey) }
    }

    /// Empty until the name page was answered, or when it was skipped.
    static var firstName: String {
        get { UserDefaults.standard.string(forKey: firstNameStorageKey) ?? "" }
        set { UserDefaults.standard.setValue(newValue, forKey: firstNameStorageKey) }
    }

    static var ageRangeKey: String? {
        get { UserDefaults.standard.string(forKey: ageRangeStorageKey) }
        set { UserDefaults.standard.setValue(newValue, forKey: ageRangeStorageKey) }
    }

    /// nil until the knowledge page was answered; the page's own default applies.
    static var knowledgeLevel: Int? {
        get { UserDefaults.standard.object(forKey: knowledgeLevelStorageKey) as? Int }
        set { UserDefaults.standard.setValue(newValue, forKey: knowledgeLevelStorageKey) }
    }

    static var motivationKey: String? {
        get { UserDefaults.standard.string(forKey: motivationStorageKey) }
        set { UserDefaults.standard.setValue(newValue, forKey: motivationStorageKey) }
    }

    static var objectiveKeys: [String] {
        get { UserDefaults.standard.stringArray(forKey: objectivesKey) ?? [] }
        set { UserDefaults.standard.setValue(newValue, forKey: objectivesKey) }
    }

    static var topicKeys: [String] {
        get { UserDefaults.standard.stringArray(forKey: topicsStorageKey) ?? [] }
        set { UserDefaults.standard.setValue(newValue, forKey: topicsStorageKey) }
    }

    static var likedCourseIds: [String] {
        get { UserDefaults.standard.stringArray(forKey: likedKey) ?? [] }
        set { UserDefaults.standard.setValue(newValue, forKey: likedKey) }
    }

    static var swipedCourseIds: [String] {
        get { UserDefaults.standard.stringArray(forKey: swipedKey) ?? [] }
        set { UserDefaults.standard.setValue(newValue, forKey: swipedKey) }
    }

    /// 0 means "not answered yet"; the screen's own default applies.
    static var phoneDailyMinutes: Int {
        get { UserDefaults.standard.integer(forKey: phoneMinutesKey) }
        set { UserDefaults.standard.setValue(newValue, forKey: phoneMinutesKey) }
    }

    /// Cleared once the onboarding is finished, so a later reset starts from the beginning.
    static func clear() {
        let defaults = UserDefaults.standard
        [
            stepKey, firstNameStorageKey, ageRangeStorageKey, knowledgeLevelStorageKey,
            motivationStorageKey, objectivesKey, topicsStorageKey, likedKey, swipedKey, phoneMinutesKey,
        ].forEach {
            defaults.removeObject(forKey: $0)
        }
    }
}
