package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.data.catalog.CatalogSnapshot
import app.rork.sophia.data.catalog.CatalogStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.LearningCollection
import app.rork.sophia.domain.QuizQuestion
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.concurrent.ConcurrentHashMap

/**
 * L'accès au catalogue de cours de la langue active, lu dans le snapshot du catalogue en ligne
 * ([CatalogStore]) : le disque, sinon le pack de départ. L'API date des JSON embarqués par langue
 * et n'a pas changé pour ses appelants ; aucune méthode synchrone n'attend le réseau.
 *
 * Les `cached*` ne lisent rien : elles répondent de la mémoire ou null, pour la composition.
 */
object ContentCatalog {
    /**
     * Courses withheld from a language. Absent from the catalogue as if never bundled:
     * no feed card, no library row, no collection slot, no lookup by id. Switching
     * language brings them back. Le serveur les exclut aussi du catalogue de la langue ;
     * la liste locale reste pour la région du téléphone, qu'il ne connaît pas.
     */
    // Sensitive subjects, decided on 02/11/2026 after reader complaints (same lists as iOS).
    private val withheldCourseIds: Map<AppLanguage, Set<String>> = mapOf(
        AppLanguage.TURKISH to setOf(
            "course_25_le_genocide_armenien_1915_1916",
            "course_1_la_naissance_de_l_islam_622",
        ),
        AppLanguage.ARABIC to setOf(
            "course_1_la_naissance_de_l_islam_622",
            "course_201_la_naissance_du_conflit_israelo_palestin",
        ),
        AppLanguage.HEBREW to setOf("course_201_la_naissance_du_conflit_israelo_palestin"),
        AppLanguage.RUSSIAN to setOf(
            "course_209_la_russie_de_poutine",
            "course_210_la_guerre_en_ukraine_expliquee",
        ),
        AppLanguage.SERBIAN to setOf("course_270_pourquoi_la_yougoslavie_a_t_elle_eclate"),
        AppLanguage.CROATIAN to setOf("course_270_pourquoi_la_yougoslavie_a_t_elle_eclate"),
    )

    /**
     * Courses withheld by the phone's region, whatever the app language: a reader in
     * Türkiye with the app in English or French still saw the Armenian genocide course.
     */
    private val withheldCourseIdsByRegion: Map<String, Set<String>> = mapOf(
        "TR" to setOf("course_25_le_genocide_armenien_1915_1916"),
    )

    /** Everything withheld for this language on this phone. */
    private fun withheldIds(language: AppLanguage): Set<String> {
        val byLanguage = withheldCourseIds[language].orEmpty()
        val byRegion = withheldCourseIdsByRegion[java.util.Locale.getDefault().country].orEmpty()
        return if (byRegion.isEmpty()) byLanguage else byLanguage + byRegion
    }

    fun isWithheld(language: AppLanguage, courseId: String): Boolean =
        courseId in withheldIds(language)

    /**
     * Le snapshot d'une langue vu par l'app : sans les cours retenus, les collections allégées
     * d'autant. Reconstruit dès que [CatalogStore] remplace le snapshot (fichiers mis à jour).
     */
    private class LanguageView(
        val snapshot: CatalogSnapshot,
        val summaries: List<CourseSummary>,
        val collections: List<LearningCollection>,
    ) {
        val summaryById: Map<String, CourseSummary> = summaries.associateBy { it.id }
    }

    private val views = ConcurrentHashMap<String, LanguageView>()

    private fun view(language: AppLanguage): LanguageView = viewOf(language, CatalogStore.snapshot(language))

    /** La vue en mémoire, ou null tant que le snapshot n'a pas été construit : ne lit rien. */
    private fun cachedView(language: AppLanguage): LanguageView? =
        CatalogStore.cachedSnapshot(language)?.let { viewOf(language, it) }

    private fun viewOf(language: AppLanguage, snapshot: CatalogSnapshot): LanguageView {
        views[language.code]?.takeIf { it.snapshot === snapshot }?.let { return it }
        val withheld = withheldIds(language)
        val summaries = if (withheld.isEmpty()) snapshot.summaries else snapshot.summaries.filterNot { it.id in withheld }
        val collections = if (withheld.isEmpty()) {
            snapshot.collections
        } else {
            snapshot.collections.map { collection ->
                val kept = collection.courseIds.filterNot { it in withheld }
                if (kept.size == collection.courseIds.size) collection else collection.copy(courseIds = kept)
            }
        }
        return LanguageView(snapshot, summaries, collections).also { views[language.code] = it }
    }

    /** Un stub de lecteur : pas de leçons ni de questions, mais « a un quiz » d'après le catalogue. */
    private fun stub(view: LanguageView, summary: CourseSummary): Course {
        val quizCount = view.snapshot.entryById[summary.id]?.quizCount
        return summary.toStub(quizAvailable = quizCount == null || quizCount > 0)
    }

    fun cachedCourses(language: AppLanguage): List<Course>? = null

    fun cachedCollections(language: AppLanguage): List<LearningCollection>? =
        cachedView(language)?.collections

    fun cachedSummaries(language: AppLanguage): List<CourseSummary>? =
        cachedView(language)?.summaries

    fun cachedCourse(language: AppLanguage, id: String): Course? = cachedStub(language, id)

    /** In-memory stub from the catalogue already loaded. Never reads a file. */
    fun cachedStub(language: AppLanguage, id: String): Course? {
        val view = cachedView(language) ?: return null
        return view.summaryById[id]?.let { stub(view, it) }
    }

    /** Toutes les fiches de la langue. Construit le snapshot à la première demande (disque). */
    fun summaries(context: Context, language: AppLanguage): List<CourseSummary> = view(language).summaries

    suspend fun summariesAsync(context: Context, language: AppLanguage): List<CourseSummary> =
        withContext(Dispatchers.IO) { summaries(context, language) }

    /**
     * Lightweight stubs only (no lessons/quiz). Feed/library never touch quiz JSON.
     */
    fun courses(context: Context, language: AppLanguage): List<Course> {
        val view = view(language)
        return view.summaries.map { stub(view, it) }
    }

    suspend fun coursesAsync(context: Context, language: AppLanguage): List<Course> =
        withContext(Dispatchers.IO) { courses(context, language) }

    suspend fun courseAsync(context: Context, language: AppLanguage, id: String): Course? =
        withContext(Dispatchers.IO) { course(context, language, id) }

    suspend fun courseStubAsync(context: Context, language: AppLanguage, id: String): Course? =
        withContext(Dispatchers.IO) { course(context, language, id) }

    fun collections(context: Context, language: AppLanguage): List<LearningCollection> = view(language).collections

    suspend fun collectionsAsync(context: Context, language: AppLanguage): List<LearningCollection> =
        withContext(Dispatchers.IO) { collections(context, language) }

    /**
     * Reader metadata only. The quiz is loaded later via [quizQuestions].
     */
    fun course(context: Context, language: AppLanguage, id: String): Course? {
        val view = view(language)
        return view.summaryById[id]?.let { stub(view, it) }
    }

    /** Le quiz d'un cours : le fichier de la langue, sinon le paquet du cours. Lit le disque au besoin. */
    fun quizQuestions(context: Context, language: AppLanguage, id: String): List<QuizQuestion> {
        if (isWithheld(language, id)) return emptyList()
        return CatalogStore.quiz(id, language)
    }

    suspend fun quizQuestionsAsync(
        context: Context,
        language: AppLanguage,
        id: String,
    ): List<QuizQuestion> = withContext(Dispatchers.IO) { quizQuestions(context, language, id) }

    /**
     * Quizzes of [ids]. Withheld courses come back empty.
     */
    suspend fun quizQuestionsForCoursesAsync(
        context: Context,
        language: AppLanguage,
        ids: List<String>,
    ): Map<String, List<QuizQuestion>> = withContext(Dispatchers.IO) {
        val result = HashMap<String, List<QuizQuestion>>(ids.size * 2)
        for (id in ids) result[id] = quizQuestions(context, language, id)
        result
    }

    /**
     * Quiz questions across the language's catalogue (withheld courses left out), or 0.
     * Le catalogue porte le nombre de questions de chaque cours ; à défaut, le fichier des quiz.
     */
    suspend fun quizQuestionCountAsync(context: Context, language: AppLanguage): Int =
        withContext(Dispatchers.IO) {
            val view = view(language)
            view.summaries.sumOf { summary ->
                view.snapshot.entryById[summary.id]?.quizCount
                    ?: view.snapshot.quizzes[summary.id]?.size
                    ?: 0
            }
        }

    /**
     * Whether the course's structured content is on the phone (pack de départ or downloaded).
     * Lit le disque à la première demande ; `CatalogStore.ensureContent` le télécharge sinon.
     */
    fun hasStructuredContent(context: Context, language: AppLanguage, courseId: String): Boolean {
        if (isWithheld(language, courseId)) return false
        return CatalogStore.hasLocalContent(courseId, language)
    }

    /** Le JSON V2 d'un cours en texte, s'il est sur le téléphone ; les lecteurs le parcourent eux-mêmes. */
    fun structuredContentJson(context: Context, language: AppLanguage, courseId: String): String? {
        if (isWithheld(language, courseId)) return null
        return CatalogStore.localContentJson(courseId, language)
    }

    /** Oublie les vues filtrées ; le snapshot lui-même appartient à [CatalogStore]. */
    fun clearCache() {
        views.clear()
    }
}
