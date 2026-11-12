package app.rork.sophia.ui.profile

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Login
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.filled.ArrowOutward
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.outlined.CloudDownload
import androidx.compose.material.icons.outlined.CreditCard
import androidx.compose.material.icons.outlined.DeleteForever
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.IosShare
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.RestartAlt
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material.icons.outlined.Today
import androidx.compose.material.icons.outlined.WorkspacePremium
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.paint
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.BuildConfig
import app.rork.sophia.R
import app.rork.sophia.SophiaApplication
import app.rork.sophia.audio.CourseAudioDownloads
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.catalog.CatalogStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.domain.locale
import app.rork.sophia.ui.components.ConfirmDialog
import app.rork.sophia.ui.components.ShareSophiaSheet
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.newgen.AvatarCircle
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.text.DateFormat

/** Crème et encre de l'illustration « ambassadeur » (papier découpé du site). */
private val POSTER_CREAM = Color(0xFFFBEFC9)
private val POSTER_INK = Color(0xFF16263D)

/**
 * Les réglages dans le design « Elevate arrondi », comme le `SettingsView` iOS : le titre
 * centré et la croix, la carte d'identité du lecteur, puis les groupes en cartes bordées
 * (compte, langue, progression, abonnement, audio, aide, légal, données, à propos). Les blocs
 * arrivent en cascade ; les rangées s'enfoncent doucement sous le doigt.
 */
@Composable
fun SettingsScreen(
    language: AppLanguage,
    progress: UserProgress,
    isPremium: Boolean,
    /** The running subscription, `null` when there is none (see `StoreViewModel.SubscriptionStatus`). */
    subscription: StoreViewModel.SubscriptionStatus? = null,
    onBack: () -> Unit,
    onLanguageChange: (AppLanguage) -> Unit,
    onShowPaywall: () -> Unit,
    onOpenFeedback: () -> Unit,
    /** Ouvre la page du rôle choisi (`ugc` ou `slideshow`) du programme créateurs. */
    onOpenFeatureRequest: () -> Unit,
    onOpenAmbassador: () -> Unit,
    onOpenTerms: () -> Unit,
    onOpenPrivacy: () -> Unit,
    onRestorePurchases: () -> Unit,
    onOpenAudioDownloads: () -> Unit = {},
    /** Debug builds only: Premium forced on, to test it on an emulator where Play sells nothing. */
    debugPremium: Boolean = false,
    onDebugPremiumChange: (Boolean) -> Unit = {},
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val scope = rememberCoroutineScope()
    val haptics = rememberHaptics()
    val userId by app.authService.userId.collectAsState()
    // Le @ du lecteur, pour la carte d'identité en tête.
    val handle by app.socialService.myHandle.collectAsState()
    var showResetProgress by remember { mutableStateOf(false) }
    var showShare by remember { mutableStateOf(false) }
    if (showShare) {
        ShareSophiaSheet(language = language, onDismiss = { showShare = false })
    }
    var showLanguages by remember { mutableStateOf(false) }
    if (showLanguages) {
        LanguageSheet(
            current = language,
            title = StringStore.text(context, "language.section", language),
            onPick = {
                showLanguages = false
                onLanguageChange(it)
            },
            onDismiss = { showLanguages = false },
        )
    }
    var showDeleteAccount by remember { mutableStateOf(false) }
    var deletingAccount by remember { mutableStateOf(false) }
    var deleteError by remember { mutableStateOf<String?>(null) }
    val completedCount = progress.courseProgress.count { it.value.isCompleted }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(bottom = 32.dp),
    ) {
        // Le titre centré, la croix à droite (et son pendant vide à gauche, pour le centrage).
        ProfileCenteredTitleBar(
            title = StringStore.text(context, "settings.title", language),
            modifier = Modifier.padding(top = 8.dp, bottom = 12.dp),
            trailing = {
                ProfileRoundButton(
                    icon = Icons.Filled.Close,
                    contentDescription = StringStore.text(context, "common.close", language),
                    onClick = onBack,
                )
            },
        )

        // La carte d'identité : avatar, titre de rang, @ et ancienneté. Seulement ce que l'app
        // connaît déjà ; la ligne de détail disparaît quand il n'y a ni @ ni premier cours.
        val rankTitle = remember(language) { ProfileIdentity.rankTitle(context, language) }
        val memberSince = remember(progress.courseProgress, language) { ProfileIdentity.memberSince(progress, language) }
        val accountHandle = handle?.takeIf { userId != null && it.isNotBlank() }
        val identityDetail = listOfNotNull(
            accountHandle?.let { "@$it" },
            memberSince?.let { StringStore.text(context, "profile.member.since", language, it) },
        ).joinToString(" · ").ifEmpty { null }
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .dsStagger(0, stepMillis = 40)
                .sophiaCard()
                .padding(horizontal = 16.dp, vertical = 14.dp)
                .semantics(mergeDescendants = true) { },
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            AvatarCircle(
                avatarId = progress.avatarId,
                initial = (accountHandle ?: rankTitle).take(1).uppercase(),
                size = 56.dp,
            )
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(
                    text = rankTitle,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 17.sp,
                    lineHeight = 22.sp,
                    color = DS.ink,
                )
                if (identityDetail != null) {
                    Text(
                        text = identityDetail,
                        fontFamily = PlusJakartaSans,
                        fontSize = 13.sp,
                        lineHeight = 18.sp,
                        color = DS.inkSecondary,
                    )
                }
            }
        }

        // L'ordre d'arrivée des blocs : chacun prend le rang suivant, plafonné.
        var order = 0
        fun nextOrder(): Int {
            order += 1
            return order.coerceAtMost(10)
        }

        SettingsSection(StringStore.text(context, "account.title", language), nextOrder()) {
            SettingsGroup {
                if (userId == null) {
                    SettingsRow(
                        icon = Icons.AutoMirrored.Outlined.Login,
                        label = StringStore.text(context, "account.create.title", language),
                        subtitle = StringStore.text(context, "account.create.subtitle", language),
                        onClick = {
                            scope.launch {
                                runCatching { app.authService.signInWithGoogle(context) }
                                app.progressSyncService.pullOnLogin(app.progressManager.progress.value)
                            }
                        },
                    )
                } else {
                    SettingsRow(
                        icon = Icons.Outlined.Person,
                        label = StringStore.text(context, "account.signedIn.title", language),
                        subtitle = userId!!.take(8) + "…",
                        showChevron = false,
                        static = true,
                        onClick = {},
                    )
                    ProfileRowDivider()
                    SettingsRow(
                        icon = Icons.AutoMirrored.Outlined.Logout,
                        label = StringStore.text(context, "account.signOut.action", language),
                        destructive = true,
                        onClick = { scope.launch { app.authService.signOut() } },
                    )
                    ProfileRowDivider()
                    // Google Play requires an in-app route to delete the account, and the terms
                    // promise it lives here. Confirmation first: this is not undoable.
                    SettingsRow(
                        icon = Icons.Outlined.DeleteForever,
                        label = StringStore.text(context, "account.delete.action", language),
                        subtitle = deleteError,
                        destructive = true,
                        showChevron = false,
                        trailing = if (deletingAccount) {
                            {
                                CircularProgressIndicator(
                                    color = DS.danger,
                                    strokeWidth = 2.dp,
                                    modifier = Modifier.size(18.dp),
                                )
                            }
                        } else {
                            null
                        },
                        onClick = {
                            if (!deletingAccount) {
                                deleteError = null
                                showDeleteAccount = true
                            }
                        },
                    )
                }
            }
        }

        // La langue : une pastille qui ouvre la liste, comme le sélecteur d'iOS.
        SettingsSection(StringStore.text(context, "language.section", language), nextOrder()) {
            Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                Row(
                    modifier = Modifier
                        .pressable(onClick = { showLanguages = true })
                        .sophiaCard(shape = RoundedCornerShape(14.dp))
                        .padding(start = 16.dp, end = 10.dp, top = 11.dp, bottom = 11.dp)
                        .semantics { role = Role.Button },
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Text(text = language.flag, fontSize = 18.sp)
                    Text(
                        text = language.displayName,
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp,
                        color = DS.ink,
                    )
                    ProfileRowChevron()
                }
            }
        }

        SettingsSection(StringStore.text(context, "settings.section.progress", language), nextOrder()) {
            SettingsGroup {
                SettingsRow(
                    icon = Icons.AutoMirrored.Outlined.MenuBook,
                    label = StringStore.text(context, "settings.courses.completed", language, completedCount),
                    showChevron = false,
                    static = true,
                    onClick = {},
                )
                ProfileRowDivider()
                SettingsRow(
                    icon = Icons.Outlined.LocalFireDepartment,
                    label = StringStore.text(context, "settings.streak.title", language, progress.streak),
                    subtitle = StringStore.text(context, "settings.streak.subtitle", language),
                    showChevron = false,
                    static = true,
                    onClick = {},
                )
            }
        }

        // Subscribers used to find nothing here: no sign of Premium, no date, no way to cancel
        // (Play only lets a subscription be cancelled from its own page, linked below).
        SettingsSection(StringStore.text(context, "settings.section.subscription", language), nextOrder()) {
            SettingsGroup {
                if (isPremium) {
                    SettingsRow(
                        icon = Icons.Outlined.WorkspacePremium,
                        label = StringStore.text(context, "settings.subscription.active.title", language),
                        subtitle = subscription?.let { subscriptionSubtitle(context, it, language) },
                        showChevron = false,
                        static = true,
                        onClick = {},
                    )
                } else {
                    SettingsRow(
                        icon = Icons.Outlined.WorkspacePremium,
                        label = StringStore.text(context, "settings.premium.title", language),
                        subtitle = StringStore.text(context, "settings.premium.subtitle", language),
                        onClick = onShowPaywall,
                    )
                }
                ProfileRowDivider()
                SettingsRow(
                    icon = Icons.Outlined.CreditCard,
                    label = StringStore.text(context, "settings.subscription.manage.title", language),
                    subtitle = StringStore.text(
                        context,
                        if (subscription?.isAppStore == true) "settings.subscription.otherStore" else "settings.subscription.manage.subtitle",
                        language,
                    ),
                    onClick = { openPlaySubscriptions(context, subscription?.productId) },
                )
            }
        }

        val audioDownloads by CourseAudioDownloads.downloaded.collectAsState()
        if (isPremium || audioDownloads.isNotEmpty()) {
            SettingsSection(StringStore.text(context, "settings.section.audio", language), nextOrder()) {
                SettingsGroup {
                    SettingsRow(
                        icon = Icons.Outlined.Download,
                        label = StringStore.text(context, "audio.downloads.title", language),
                        subtitle = StringStore.text(
                            context,
                            "audio.downloads.subtitle",
                            language,
                            android.text.format.Formatter.formatShortFileSize(context, CourseAudioDownloads.totalBytes()),
                        ),
                        onClick = onOpenAudioDownloads,
                    )
                }
            }
        }

        AmbassadorBanner(
            language = language,
            onClick = onOpenAmbassador,
            modifier = Modifier.padding(top = 24.dp).dsStagger(nextOrder(), stepMillis = 40),
        )

        SettingsSection(StringStore.text(context, "settings.section.help", language), nextOrder()) {
            SettingsGroup {
                SettingsRow(
                    icon = Icons.Outlined.IosShare,
                    label = StringStore.text(context, "share.card.title", language),
                    subtitle = StringStore.text(context, "share.card.subtitle", language),
                    onClick = { showShare = true },
                )
                ProfileRowDivider()
                SettingsRow(
                    icon = Icons.Outlined.Edit,
                    label = StringStore.text(context, "settings.feedback.title", language),
                    subtitle = StringStore.text(context, "settings.feedback.subtitle", language),
                    onClick = onOpenFeedback,
                )
                ProfileRowDivider()
                SettingsRow(
                    icon = Icons.Outlined.StarBorder,
                    label = StringStore.text(context, "settings.featureRequest.title", language),
                    subtitle = StringStore.text(context, "settings.featureRequest.subtitle", language),
                    onClick = onOpenFeatureRequest,
                )
            }
        }

        SettingsSection(StringStore.text(context, "settings.section.legal", language), nextOrder()) {
            SettingsGroup {
                SettingsRow(
                    icon = null,
                    label = StringStore.text(context, "settings.terms.title", language),
                    onClick = onOpenTerms,
                )
                ProfileRowDivider()
                SettingsRow(
                    icon = null,
                    label = StringStore.text(context, "settings.privacy.title", language),
                    onClick = onOpenPrivacy,
                )
                if (!isPremium) {
                    ProfileRowDivider()
                    SettingsRow(
                        icon = null,
                        label = StringStore.text(context, "settings.restore.title", language),
                        onClick = onRestorePurchases,
                    )
                }
            }
        }

        SettingsSection(StringStore.text(context, "settings.section.data", language), nextOrder()) {
            SettingsGroup {
                SettingsRow(
                    icon = Icons.Outlined.RestartAlt,
                    label = StringStore.text(context, "settings.reset.title", language),
                    destructive = true,
                    onClick = { showResetProgress = true },
                )
                // Hands today's free course back, so the freemium gates can be re-tested.
                // Debug builds only: in release this row let any free user replay the daily
                // unlock after every course and read the whole catalogue for nothing.
                // `BuildConfig.DEBUG` is a compile-time constant, so R8 drops the branch.
                if (BuildConfig.DEBUG) {
                    ProfileRowDivider()
                    SettingsRow(
                        icon = Icons.Outlined.Today,
                        label = StringStore.text(context, "settings.debug.resetDaily", language),
                        subtitle = StringStore.text(
                            context,
                            if (app.progressManager.hasClaimedDailyFreeCourse) {
                                "settings.debug.daily.done"
                            } else {
                                "settings.debug.daily.pending"
                            },
                            language,
                        ),
                        showChevron = false,
                        onClick = { app.progressManager.resetDailyCourseFlag() },
                    )
                    ProfileRowDivider()
                    SettingsRow(
                        icon = Icons.Outlined.WorkspacePremium,
                        label = StringStore.text(context, "settings.debug.premium", language),
                        subtitle = StringStore.text(context, "settings.debug.premium.subtitle", language),
                        showChevron = false,
                        // Une bascule : la vibration « sélection », portée par la rangée et l'interrupteur.
                        haptic = false,
                        onClick = {
                            haptics.select()
                            onDebugPremiumChange(!debugPremium)
                        },
                        trailing = {
                            Switch(
                                checked = debugPremium,
                                onCheckedChange = {
                                    haptics.select()
                                    onDebugPremiumChange(it)
                                },
                                colors = SwitchDefaults.colors(
                                    checkedTrackColor = DS.accent,
                                    checkedThumbColor = Color.White,
                                    uncheckedTrackColor = DS.hairline,
                                    uncheckedThumbColor = Color.White,
                                    uncheckedBorderColor = DS.hairline,
                                ),
                            )
                        },
                    )
                    // Le catalogue en ligne : d'où il vient, combien de cours sont sur le téléphone,
                    // quand il a été relu ; un tap force le rafraîchissement (manifeste + fichiers).
                    ProfileRowDivider()
                    val catalogVersion by CatalogStore.version.collectAsState()
                    var catalogSummary by remember { mutableStateOf("") }
                    LaunchedEffect(language, catalogVersion) {
                        catalogSummary = withContext(Dispatchers.IO) { CatalogStore.debugSummary(language) }
                    }
                    SettingsRow(
                        icon = Icons.Outlined.CloudDownload,
                        label = StringStore.text(context, "settings.debug.catalog", language),
                        subtitle = catalogSummary.ifBlank {
                            StringStore.text(context, "settings.debug.catalogRefresh", language)
                        },
                        showChevron = false,
                        onClick = {
                            scope.launch {
                                CatalogStore.refresh(context.applicationContext, language, force = true)
                                catalogSummary = withContext(Dispatchers.IO) { CatalogStore.debugSummary(language) }
                            }
                        },
                    )
                }
            }
        }

        SettingsSection(StringStore.text(context, "settings.section.about", language), nextOrder()) {
            SettingsGroup {
                SettingsInfoRow(
                    label = StringStore.text(context, "settings.about.version", language),
                    value = BuildConfig.VERSION_NAME,
                )
                // Relit le catalogue en ligne sans attendre le rafraîchissement automatique.
                ProfileRowDivider()
                SettingsRow(
                    icon = null,
                    label = StringStore.text(context, "settings.debug.catalogRefresh", language),
                    onClick = {
                        scope.launch { CatalogStore.refresh(context.applicationContext, language, force = true) }
                    },
                )
            }
        }

        Text(
            text = StringStore.text(context, "settings.footer", language),
            fontFamily = PlusJakartaSans,
            fontSize = 13.sp,
            color = DS.inkSecondary,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(top = 24.dp),
        )
    }

    if (showDeleteAccount) {
        ConfirmDialog(
            title = StringStore.text(context, "account.delete.title", language),
            message = StringStore.text(context, "account.delete.message", language),
            confirm = StringStore.text(context, "account.delete.confirm", language),
            cancel = StringStore.text(context, "settings.reset.alert.cancel", language),
            onConfirm = {
                showDeleteAccount = false
                deletingAccount = true
                scope.launch {
                    val result = runCatching { app.authService.deleteAccount() }
                    deletingAccount = false
                    if (result.isSuccess) {
                        // Nothing left to show under "Account": the row list rebuilds itself
                        // from `userId`, which the sign-out inside deleteAccount cleared.
                        deleteError = null
                    } else {
                        deleteError = StringStore.text(context, "account.delete.error", language)
                    }
                }
            },
            onDismiss = { showDeleteAccount = false },
        )
    }

    if (showResetProgress) {
        ConfirmDialog(
            title = StringStore.text(context, "settings.reset.alert.title", language),
            message = StringStore.text(context, "settings.reset.alert.message", language),
            confirm = StringStore.text(context, "settings.reset.alert.confirm", language),
            cancel = StringStore.text(context, "settings.reset.alert.cancel", language),
            onConfirm = {
                showResetProgress = false
                app.progressManager.resetProgress()
            },
            onDismiss = { showResetProgress = false },
        )
    }
}

/** « Essai gratuit jusqu'au… », « Renouvellement le… » or « Se termine le… », with the store's date. */
private fun subscriptionSubtitle(
    context: android.content.Context,
    subscription: StoreViewModel.SubscriptionStatus,
    language: AppLanguage,
): String? {
    val date = subscription.expirationDate ?: return null
    val formatted = DateFormat.getDateInstance(DateFormat.LONG, language.locale).format(date)
    val key = when {
        subscription.isTrial && subscription.willRenew -> "settings.subscription.trialUntil"
        subscription.willRenew -> "settings.subscription.renewsOn"
        else -> "settings.subscription.endsOn"
    }
    return StringStore.text(context, key, language, formatted)
}

/**
 * Play's own subscriptions page, where a subscription is changed or cancelled. With the
 * product id it opens straight on Sophia's; without one, on the list.
 */
private fun openPlaySubscriptions(context: android.content.Context, productId: String?) {
    val url = if (productId.isNullOrBlank()) {
        "https://play.google.com/store/account/subscriptions"
    } else {
        "https://play.google.com/store/account/subscriptions?sku=$productId&package=${context.packageName}"
    }
    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    runCatching { context.startActivity(intent) }
}

/** Un groupe des réglages : son sur-titre en petites capitales, puis son contenu, révélés ensemble. */
@Composable
private fun SettingsSection(title: String, order: Int, content: @Composable ColumnScope.() -> Unit) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(top = 24.dp).dsStagger(order, stepMillis = 40),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        ProfileGroupLabel(text = title)
        content()
    }
}

/** Rows sit inside one bordered card, separated by hairlines: the iOS grouped list. */
@Composable
private fun SettingsGroup(content: @Composable ColumnScope.() -> Unit) {
    Column(modifier = Modifier.fillMaxWidth().sophiaCard(), content = content)
}

/**
 * Une rangée des réglages : pictogramme au trait (bleu, rouge pour une action destructrice),
 * titre, ligne de détail, chevron. Elle s'enfonce doucement sous le doigt ; une rangée
 * [static] ne fait qu'informer et ne réagit pas.
 */
@Composable
private fun SettingsRow(
    icon: ImageVector?,
    label: String,
    onClick: () -> Unit,
    subtitle: String? = null,
    destructive: Boolean = false,
    showChevron: Boolean = true,
    static: Boolean = false,
    haptic: Boolean = true,
    trailing: (@Composable () -> Unit)? = null,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .then(
                if (static) {
                    Modifier.semantics(mergeDescendants = true) { }
                } else {
                    Modifier.profileRowPress(onClick = onClick, haptic = haptic)
                },
            )
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        if (icon != null) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = if (destructive) DS.danger else DS.accent,
                modifier = Modifier.size(22.dp),
            )
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                text = label,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 15.sp,
                lineHeight = 20.sp,
                color = if (destructive) DS.danger else DS.ink,
            )
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    fontFamily = PlusJakartaSans,
                    fontSize = 13.sp,
                    lineHeight = 18.sp,
                    color = if (destructive) DS.danger else DS.inkSecondary,
                )
            }
        }
        when {
            trailing != null -> trailing()
            showChevron && !destructive -> ProfileRowChevron()
        }
    }
}

/** Une ligne d'information : le libellé à gauche, sa valeur à droite. */
@Composable
private fun SettingsInfoRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .semantics(mergeDescendants = true) { }
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = label,
            modifier = Modifier.weight(1f),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 15.sp,
            color = DS.ink,
        )
        Text(
            text = value,
            fontFamily = PlusJakartaSans,
            fontSize = 15.sp,
            color = DS.inkSecondary,
            maxLines = 1,
        )
    }
}

/**
 * La liste des langues, en feuille : la langue de l'app sur fond teinté avec sa coche ; en
 * choisir une autre la change aussitôt et referme la feuille.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun LanguageSheet(
    current: AppLanguage,
    title: String,
    onPick: (AppLanguage) -> Unit,
    onDismiss: () -> Unit,
) {
    val haptics = rememberHaptics()
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = DS.canvas,
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().navigationBarsPadding().padding(start = 20.dp, end = 20.dp, bottom = 20.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Text(
                text = title,
                modifier = Modifier.semantics { heading() },
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 20.sp,
                color = DS.ink,
            )
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f, fill = false)
                    .sophiaCard()
                    .verticalScroll(rememberScrollState()),
            ) {
                AppLanguage.entries.forEachIndexed { index, lang ->
                    val isCurrent = lang == current
                    if (index > 0) ProfileRowDivider()
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .profileRowPress(
                                onClick = {
                                    if (!isCurrent) haptics.select()
                                    onPick(lang)
                                },
                                haptic = false,
                            )
                            .background(if (isCurrent) DS.accentTint else Color.Transparent)
                            .semantics { selected = isCurrent }
                            .padding(horizontal = 16.dp, vertical = 13.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        Text(text = lang.flag, fontSize = 20.sp)
                        Text(
                            text = lang.displayName,
                            modifier = Modifier.weight(1f),
                            fontFamily = PlusJakartaSans,
                            fontWeight = if (isCurrent) FontWeight.Bold else FontWeight.Medium,
                            fontSize = 16.sp,
                            color = DS.ink,
                        )
                        if (isCurrent) {
                            Icon(Icons.Filled.Check, contentDescription = null, tint = DS.accent, modifier = Modifier.size(18.dp))
                        }
                    }
                }
            }
        }
    }
}

/**
 * Le bandeau « Deviens ambassadeur » dans le style papier du site, comme sur iOS :
 * l'illustration à gauche, la promesse, et la sortie vers le site des créateurs dans la langue
 * de l'app.
 */
@Composable
private fun AmbassadorBanner(language: AppLanguage, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    Row(
        modifier = modifier
            .fillMaxWidth()
            .pressable(onClick = onClick)
            .clip(DS.cardShape)
            .background(POSTER_CREAM)
            .height(IntrinsicSize.Min)
            .semantics(mergeDescendants = true) { role = Role.Button },
    ) {
        // Peinte en fond d'une boîte, sans imposer sa taille : c'est le texte qui donne la hauteur.
        Box(
            modifier = Modifier
                .width(110.dp)
                .fillMaxHeight()
                .clipToBounds()
                .paint(
                    painter = painterResource(R.drawable.ambassador_poster),
                    sizeToIntrinsics = false,
                    contentScale = ContentScale.Crop,
                ),
        )
        Column(
            modifier = Modifier.weight(1f).padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text(
                text = StringStore.text(context, "settings.ambassador.banner.title", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 16.sp,
                lineHeight = 21.sp,
                color = POSTER_INK,
            )
            Text(
                text = StringStore.text(context, "settings.ambassador.banner.subtitle", language),
                fontFamily = PlusJakartaSans,
                fontSize = 13.sp,
                lineHeight = 18.sp,
                color = POSTER_INK,
            )
            Row(
                modifier = Modifier
                    .padding(top = 2.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(POSTER_INK)
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Text(
                    text = StringStore.text(context, "settings.ambassador.cta", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp,
                    color = Color.White,
                    modifier = Modifier.weight(1f, fill = false),
                )
                Icon(Icons.Filled.ArrowOutward, contentDescription = null, tint = Color.White, modifier = Modifier.size(13.dp))
            }
        }
    }
}
