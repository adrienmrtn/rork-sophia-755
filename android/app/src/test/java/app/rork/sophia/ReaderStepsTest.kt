package app.rork.sophia

import app.rork.sophia.ui.course.ReaderBlock
import app.rork.sophia.ui.course.ReaderPage
import app.rork.sophia.ui.course.ReaderStep
import app.rork.sophia.ui.course.buildReaderSteps
import app.rork.sophia.ui.course.revealedThroughSection
import app.rork.sophia.ui.course.sectionFill
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ReaderStepsTest {
    private val pages = listOf(
        ReaderPage("Intro", listOf(ReaderBlock.Paragraph("a"), ReaderBlock.Image("img", null, null))),
        ReaderPage(
            "Part 1",
            listOf(
                ReaderBlock.Heading("H1"),
                ReaderBlock.Paragraph("b"),
                ReaderBlock.Heading("H2"),
                ReaderBlock.Heading("H3"),
                ReaderBlock.Quote("q", null),
                ReaderBlock.Heading("tail"),
            ),
        ),
        ReaderPage("Part 2", listOf(ReaderBlock.Takeaway("t"))),
    )

    @Test
    fun aBlockIsAStepAndAHeadingRidesWithTheNextBlock() {
        val steps = buildReaderSteps(pages, isLocked = { false }, hasFooter = true)
        assertEquals(
            listOf("Header", "Block", "Block", "Header", "Block", "Block", "Block", "Block", "Header", "Block", "Footer"),
            steps.map { it::class.simpleName },
        )
        val part1 = steps.filterIsInstance<ReaderStep.Block>().filter { it.sectionIndex == 1 }
        // « H1 » accompagne le paragraphe ; « H2 », suivi d'un autre intertitre, passe seul ;
        // « H3 » accompagne la citation ; l'intertitre de fin passe seul.
        assertEquals(listOf("H1", null, "H3", null), part1.map { it.heading })
        assertEquals(ReaderBlock.Heading("H2"), part1[1].block)
        assertEquals(ReaderBlock.Heading("tail"), part1[3].block)
        assertTrue(steps[2].showsPicture)
        assertEquals(steps.size, steps.map { it.id }.toSet().size)
    }

    @Test
    fun aLockedSectionIsASingleStepAndTheFooterIsOptional() {
        val steps = buildReaderSteps(pages, isLocked = { it >= 1 }, hasFooter = false)
        assertEquals(listOf("Header", "Block", "Block", "Locked", "Locked"), steps.map { it::class.simpleName })
    }

    @Test
    fun revealAndFillFollowTheSections() {
        val steps = buildReaderSteps(pages, isLocked = { false }, hasFooter = true)
        assertEquals(1, revealedThroughSection(steps, 0))
        assertEquals(4, revealedThroughSection(steps, 1))
        assertEquals(steps.size, revealedThroughSection(steps, 9))
        assertEquals(1f, sectionFill(steps, 4, 0), 0.001f)
        assertEquals(0.2f, sectionFill(steps, 4, 1), 0.001f)
        assertEquals(0f, sectionFill(steps, 4, 2), 0.001f)
    }
}
