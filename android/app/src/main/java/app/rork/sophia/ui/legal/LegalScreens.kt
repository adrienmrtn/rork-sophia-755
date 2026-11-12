package app.rork.sophia.ui.legal

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.LegalDocumentStore
import app.rork.sophia.data.LegalSection
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.profile.ProfileSheetHeader
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

enum class LegalDocKind { Terms, Privacy }

/**
 * Les conditions et la politique de confidentialité dans le design « Elevate arrondi », comme
 * les pages iOS : l'en-tête calme (titre en graisse moyenne, croix ronde) reste en haut, le
 * texte défile dessous, section par section, sans carte.
 */
@Composable
fun LegalDocumentScreen(
    kind: LegalDocKind,
    language: AppLanguage,
    onBack: () -> Unit,
) {
    val context = LocalContext.current
    val sections by produceState(initialValue = emptyList<LegalSection>(), kind, language) {
        value = withContext(Dispatchers.IO) {
            when (kind) {
                LegalDocKind.Terms -> LegalDocumentStore.terms(context.applicationContext, language)
                LegalDocKind.Privacy -> LegalDocumentStore.privacy(context.applicationContext, language)
            }
        }
    }
    val titleKey = when (kind) {
        LegalDocKind.Terms -> "legal.terms.title"
        LegalDocKind.Privacy -> "legal.privacy.title"
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas),
    ) {
        ProfileSheetHeader(
            title = StringStore.text(context, titleKey, language),
            closeIcon = Icons.Filled.Close,
            closeLabel = StringStore.text(context, "common.close", language),
            onClose = onBack,
            modifier = Modifier.padding(start = 20.dp, end = 20.dp, top = 16.dp, bottom = 14.dp),
        )
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(start = 20.dp, end = 20.dp, top = 4.dp, bottom = 48.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp),
        ) {
            sections.forEachIndexed { index, section ->
                // Seules les premières sections arrivent en cascade : le reste est sous l'écran.
                LegalSectionBlock(section, modifier = if (index < 6) Modifier.dsStagger(index, stepMillis = 40) else Modifier)
            }
        }
    }
}

@Composable
private fun LegalSectionBlock(section: LegalSection, modifier: Modifier = Modifier) {
    Column(modifier = modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            text = section.title,
            modifier = Modifier.semantics { heading() },
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 20.sp,
            lineHeight = 26.sp,
            color = DS.ink,
        )
        Text(
            text = section.body,
            fontFamily = PlusJakartaSans,
            fontSize = 15.sp,
            lineHeight = 23.sp,
            color = DS.inkSecondary,
        )
    }
}
