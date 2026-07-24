package app.rork.sophia.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.FeedbackService
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.launch

private enum class AmbassadorStage { Program, Form, Success }

@Composable
fun AmbassadorScreen(
    language: AppLanguage,
    onBack: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val scope = rememberCoroutineScope()
    var stage by remember { mutableStateOf(AmbassadorStage.Program) }
    var wantsSlideshow by remember { mutableStateOf(false) }
    var wantsUgc by remember { mutableStateOf(false) }
    var email by remember { mutableStateOf("") }
    var ageText by remember { mutableStateOf("") }
    var presentation by remember { mutableStateOf("") }
    var countryConfirmed by remember { mutableStateOf(false) }
    var submitting by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) { app.analytics.trackAmbassadorOpened() }

    fun t(key: String) = StringStore.text(context, key, language)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .padding(DS.Space.l),
    ) {
        TextButton(onClick = onBack) { Text("← ${t("ambassador.title")}") }

        when (stage) {
            AmbassadorStage.Program -> {
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .verticalScroll(rememberScrollState()),
                ) {
                    Text(t("ambassador.program.heading"), style = SophiaTypography.titleLarge)
                    Spacer(Modifier.height(12.dp))
                    Text(t("ambassador.intro"), style = SophiaTypography.bodyMedium)
                    Spacer(Modifier.height(16.dp))
                    Text(t("ambassador.how.title"), style = SophiaTypography.titleMedium)
                    Spacer(Modifier.height(8.dp))
                    listOf(
                        t("ambassador.how.step1"),
                        t("ambassador.how.step2"),
                        t("ambassador.how.step3"),
                    ).forEachIndexed { i, line ->
                        Text("${i + 1}. $line", style = SophiaTypography.bodyMedium, modifier = Modifier.padding(vertical = 4.dp))
                    }
                    Spacer(Modifier.height(16.dp))
                    RoleCard(
                        title = t("ambassador.role.slideshow.title"),
                        income = t("ambassador.role.slideshow.income"),
                        time = t("ambassador.role.slideshow.time"),
                        body = t("ambassador.role.slideshow.body"),
                    )
                    Spacer(Modifier.height(10.dp))
                    RoleCard(
                        title = t("ambassador.role.ugc.title"),
                        income = t("ambassador.role.ugc.income"),
                        time = t("ambassador.role.ugc.time"),
                        body = t("ambassador.role.ugc.body"),
                    )
                    Spacer(Modifier.height(12.dp))
                    Text(t("ambassador.bonus"), style = SophiaTypography.labelLarge, color = DS.accentSoft)
                    Spacer(Modifier.height(8.dp))
                    Text(t("ambassador.cta48h"), style = SophiaTypography.bodyMedium)
                }
                Button(
                    onClick = { stage = AmbassadorStage.Form },
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    shape = DS.controlShape,
                    colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
                ) {
                    Text(
                        t("ambassador.discover.cta"),
                        color = Color.White,
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }

            AmbassadorStage.Form -> {
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .verticalScroll(rememberScrollState()),
                ) {
                    Text(t("ambassador.form.title"), style = SophiaTypography.titleLarge)
                    Spacer(Modifier.height(12.dp))
                    Text(t("ambassador.form.roles.label"), style = SophiaTypography.labelLarge)
                    RoleCheck(t("ambassador.form.role.slideshow"), wantsSlideshow) { wantsSlideshow = it }
                    RoleCheck(t("ambassador.form.role.ugc"), wantsUgc) { wantsUgc = it }
                    Spacer(Modifier.height(8.dp))
                    OutlinedTextField(
                        value = email,
                        onValueChange = { email = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text(t("ambassador.form.email.label")) },
                        placeholder = { Text(t("ambassador.form.email.placeholder")) },
                        singleLine = true,
                    )
                    Spacer(Modifier.height(8.dp))
                    OutlinedTextField(
                        value = ageText,
                        onValueChange = { ageText = it.filter { c -> c.isDigit() }.take(3) },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text(t("ambassador.form.age.label")) },
                        placeholder = { Text(t("ambassador.form.age.placeholder")) },
                        singleLine = true,
                    )
                    Spacer(Modifier.height(8.dp))
                    OutlinedTextField(
                        value = presentation,
                        onValueChange = { if (it.length <= 1500) presentation = it },
                        modifier = Modifier.fillMaxWidth().height(140.dp),
                        label = { Text(t("ambassador.form.presentation.label")) },
                        placeholder = { Text(t("ambassador.form.presentation.placeholder")) },
                    )
                    Text(
                        text = run {
                            var hint = t("ambassador.form.presentation.hint")
                            hint = hint.replaceFirst("%d", presentation.trim().length.toString())
                            hint.replaceFirst("%d", "10")
                        },
                        style = SophiaTypography.labelMedium,
                        color = DS.inkTertiary,
                        modifier = Modifier.padding(top = 4.dp),
                    )
                    Spacer(Modifier.height(8.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Checkbox(checked = countryConfirmed, onCheckedChange = { countryConfirmed = it })
                        Text(
                            t("ambassador.form.country.confirm"),
                            style = SophiaTypography.bodyMedium,
                            modifier = Modifier.clickable { countryConfirmed = !countryConfirmed },
                        )
                    }
                    if (error != null) {
                        Text(error!!, color = DS.danger, style = SophiaTypography.labelMedium)
                    } else {
                        Text(t("ambassador.form.hint"), style = SophiaTypography.labelMedium, color = DS.inkTertiary)
                    }
                }
                val age = ageText.toIntOrNull()
                val canSubmit = !submitting &&
                    email.contains("@") && email.contains(".") &&
                    age != null && age in 16..120 &&
                    presentation.trim().length >= 10 &&
                    (wantsSlideshow || wantsUgc) &&
                    countryConfirmed
                Button(
                    onClick = {
                        submitting = true
                        error = null
                        scope.launch {
                            val result = FeedbackService.submitAmbassador(
                                email = email,
                                age = age ?: 0,
                                presentation = presentation,
                                wantsSlideshow = wantsSlideshow,
                                wantsUgc = wantsUgc,
                                countryConfirmed = countryConfirmed,
                                language = language.code,
                            )
                            submitting = false
                            if (result.isSuccess) {
                                app.analytics.trackAmbassadorSubmitted()
                                stage = AmbassadorStage.Success
                            } else {
                                error = when (result.exceptionOrNull()?.message) {
                                    "age" -> t("ambassador.form.error.age")
                                    else -> t("ambassador.form.error.generic")
                                }
                            }
                        }
                    },
                    enabled = canSubmit,
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    shape = DS.controlShape,
                    colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
                ) {
                    Text(
                        if (submitting) "…" else t("ambassador.form.submit"),
                        color = Color.White,
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }

            AmbassadorStage.Success -> {
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth(),
                    verticalArrangement = Arrangement.Center,
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text(t("ambassador.success.title"), style = SophiaTypography.titleLarge)
                    Spacer(Modifier.height(12.dp))
                    Text(t("ambassador.success.body"), style = SophiaTypography.bodyMedium)
                }
                Button(
                    onClick = onBack,
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    shape = DS.controlShape,
                    colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
                ) {
                    Text(t("ambassador.success.close"), color = Color.White)
                }
            }
        }
    }
}

@Composable
private fun RoleCard(title: String, income: String, time: String, body: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(DS.cardShape)
            .background(DS.surface)
            .padding(DS.Space.m),
    ) {
        Text(title, style = SophiaTypography.titleMedium)
        Spacer(Modifier.height(4.dp))
        Text("$income · $time", style = SophiaTypography.labelMedium, color = DS.accentSoft)
        Spacer(Modifier.height(6.dp))
        Text(body, style = SophiaTypography.bodyMedium)
    }
}

@Composable
private fun RoleCheck(label: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onChange(!checked) }
            .padding(vertical = 4.dp),
    ) {
        Checkbox(checked = checked, onCheckedChange = onChange)
        Text(label, style = SophiaTypography.bodyLarge)
    }
}
