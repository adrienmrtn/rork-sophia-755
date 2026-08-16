package app.rork.sophia.ui.legal

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.LegalDocumentStore
import app.rork.sophia.data.LegalSection
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.CircleIconButton
import app.rork.sophia.ui.components.ScreenTitle
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

enum class LegalDocKind { Terms, Privacy }

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
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = DS.Space.s, vertical = DS.Space.s),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            CircleIconButton(icon = Icons.AutoMirrored.Filled.ArrowBack, onClick = onBack)
        }
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = DS.Space.l)
                .padding(bottom = DS.Space.xl),
        ) {
            ScreenTitle(
                text = StringStore.text(context, titleKey, language),
                modifier = Modifier.padding(bottom = 20.dp),
            )
            sections.forEach { section ->
                LegalSectionBlock(section)
                Spacer(Modifier.height(18.dp))
            }
        }
    }
}

@Composable
private fun LegalSectionBlock(section: LegalSection) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .sophiaCard(shape = DS.controlShape, elevation = 3.dp)
            .padding(DS.Space.m),
    ) {
        Text(section.title, style = SophiaTypography.titleMedium.copy(fontSize = 16.sp))
        Spacer(Modifier.height(8.dp))
        Text(section.body, style = SophiaTypography.bodyMedium)
    }
}
