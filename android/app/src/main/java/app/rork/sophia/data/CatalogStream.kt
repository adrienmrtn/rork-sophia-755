package app.rork.sophia.data

import android.util.JsonReader
import android.util.JsonToken
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.QuizQuestion
import app.rork.sophia.domain.QuizQuestionType
import java.io.InputStream
import java.io.InputStreamReader

/**
 * Streaming catalog reader.
 *
 * Home/library use `course_index.{lang}.json` (~70KB, no quiz/lessons).
 * Opening a course streams `courses.{lang}.json` (quiz only, lessons already stripped)
 * and keeps a single Course in memory.
 */
object CatalogStream {
    fun readSummaries(input: InputStream): List<CourseSummary> {
        val out = ArrayList<CourseSummary>(256)
        JsonReader(InputStreamReader(input, Charsets.UTF_8)).use { reader ->
            reader.beginArray()
            while (reader.hasNext()) {
                readSummary(reader)?.let { out += it }
            }
            reader.endArray()
        }
        return out
    }

    fun readOneCourse(input: InputStream, courseId: String): Course? {
        JsonReader(InputStreamReader(input, Charsets.UTF_8)).use { reader ->
            reader.beginArray()
            while (reader.hasNext()) {
                val course = readCourse(reader, courseId)
                if (course != null) {
                    while (reader.hasNext()) reader.skipValue()
                    reader.endArray()
                    return course
                }
            }
            reader.endArray()
        }
        return null
    }

    private fun readSummary(reader: JsonReader): CourseSummary? {
        reader.beginObject()
        var id = ""
        var title = ""
        var description = ""
        var subject = ""
        var subcategory = ""
        while (reader.hasNext()) {
            when (reader.nextName()) {
                "id" -> id = reader.nextString()
                "title" -> title = reader.nextString()
                "description" -> description = reader.nextString()
                "subject" -> subject = reader.nextString()
                "subcategory" -> subcategory = reader.nextString()
                else -> reader.skipValue()
            }
        }
        reader.endObject()
        if (id.isEmpty()) return null
        return CourseSummary(id, title, description, subject, subcategory)
    }

    private fun readCourse(reader: JsonReader, targetId: String): Course? {
        reader.beginObject()
        var id = ""
        var title = ""
        var description = ""
        var subject = ""
        var subcategory = ""
        var quiz = emptyList<QuizQuestion>()
        var pendingQuiz: List<QuizQuestion>? = null
        while (reader.hasNext()) {
            when (reader.nextName()) {
                "id" -> id = reader.nextString()
                "title" -> title = reader.nextString()
                "description" -> description = reader.nextString()
                "subject" -> subject = reader.nextString()
                "subcategory" -> subcategory = reader.nextString()
                "quiz" -> {
                    if (id.isEmpty()) {
                        pendingQuiz = readQuizArray(reader)
                    } else if (id == targetId) {
                        quiz = readQuizArray(reader)
                    } else {
                        reader.skipValue()
                    }
                }
                else -> reader.skipValue()
            }
        }
        reader.endObject()
        if (id != targetId) return null
        if (pendingQuiz != null) quiz = pendingQuiz
        return Course(id, title, description, subject, subcategory, emptyList(), quiz)
    }

    private fun readQuizArray(reader: JsonReader): List<QuizQuestion> {
        val out = ArrayList<QuizQuestion>()
        reader.beginArray()
        while (reader.hasNext()) {
            out += readQuizQuestion(reader)
        }
        reader.endArray()
        return out
    }

    private fun readQuizQuestion(reader: JsonReader): QuizQuestion {
        reader.beginObject()
        var id = ""
        var type = QuizQuestionType.MCQ
        var question = ""
        var explanation = ""
        var options: List<String>? = null
        var correctIndex: Int? = null
        var items: List<String>? = null
        var correctValue: Double? = null
        var sliderMin: Double? = null
        var sliderMax: Double? = null
        var tolerance: Double? = null
        var unit: String? = null
        while (reader.hasNext()) {
            when (reader.nextName()) {
                "id" -> id = reader.nextString()
                "type" -> type = quizType(reader.nextString())
                "question" -> question = reader.nextString()
                "explanation" -> explanation = reader.nextString()
                "options" -> options = readStringArray(reader)
                "correctIndex" -> correctIndex = reader.nextInt()
                "items" -> items = readStringArray(reader)
                "correctValue" -> correctValue = reader.nextDouble()
                "sliderMin" -> sliderMin = reader.nextDouble()
                "sliderMax" -> sliderMax = reader.nextDouble()
                "tolerance" -> tolerance = reader.nextDouble()
                "unit" -> unit = reader.nextString()
                else -> reader.skipValue()
            }
        }
        reader.endObject()
        return QuizQuestion(
            id = id,
            type = type,
            question = question,
            explanation = explanation,
            options = options,
            correctIndex = correctIndex,
            items = items,
            correctValue = correctValue,
            sliderMin = sliderMin,
            sliderMax = sliderMax,
            tolerance = tolerance,
            unit = unit,
        )
    }

    private fun readStringArray(reader: JsonReader): List<String> {
        val out = ArrayList<String>()
        reader.beginArray()
        while (reader.hasNext()) {
            if (reader.peek() == JsonToken.NULL) {
                reader.skipValue()
            } else {
                out += reader.nextString()
            }
        }
        reader.endArray()
        return out
    }

    private fun quizType(raw: String): QuizQuestionType = when (raw) {
        "trueFalse" -> QuizQuestionType.TRUE_FALSE
        "chronological" -> QuizQuestionType.CHRONOLOGICAL
        "numericSlider" -> QuizQuestionType.NUMERIC_SLIDER
        "percentageSlider" -> QuizQuestionType.PERCENTAGE_SLIDER
        else -> QuizQuestionType.MCQ
    }
}
