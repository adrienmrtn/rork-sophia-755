package app.rork.sophia.ui.social

import android.graphics.Bitmap
import android.icu.text.RelativeDateTimeFormatter
import android.icu.util.ULocale
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.filled.QrCode2
import androidx.compose.material.icons.filled.QrCodeScanner
import android.widget.Toast
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.codescanner.GmsBarcodeScannerOptions
import com.google.mlkit.vision.codescanner.GmsBarcodeScanning
import androidx.compose.material.icons.filled.WorkspacePremium
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.FeatureFlags
import app.rork.sophia.data.FriendLeaderboardEntry
import app.rork.sophia.data.FriendLinkRouter
import app.rork.sophia.data.FriendPresence
import app.rork.sophia.data.FriendRequest
import app.rork.sophia.data.FriendsLeaderboardPeriod
import app.rork.sophia.data.SendRequestOutcome
import app.rork.sophia.data.SocialService
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.SophiaLinks
import app.rork.sophia.domain.formatted
import app.rork.sophia.domain.locale
import app.rork.sophia.ui.components.DSCheckBadge
import app.rork.sophia.ui.components.DSEyebrow
import app.rork.sophia.ui.components.DSOptionState
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.dsOptionCard
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.components.dsShake
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.duels.DuelOnlineDot
import app.rork.sophia.ui.duels.DuelPalette
import app.rork.sophia.ui.newgen.AvatarCircle
import app.rork.sophia.ui.profile.ProfilePillTabs
import app.rork.sophia.ui.profile.ProfileRowChevron
import app.rork.sophia.ui.profile.ProfileRowDivider
import app.rork.sophia.ui.profile.ProfileSectionHeader
import app.rork.sophia.ui.profile.ProfileTextField
import app.rork.sophia.ui.profile.profileRowPress
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import kotlinx.coroutines.launch

/** Or, argent, bronze : les médailles des trois premiers rangs. */
internal fun friendMedalColor(rank: Int): Color = when (rank) {
    1 -> DuelPalette.saffron
    2 -> Color(0xFF9EABBD)
    else -> Color(0xFFCC804F)
}

/** « En ligne », ou « Vu il y a 5 minutes » écrit par le système dans la langue de l'app. */
fun friendPresenceText(context: android.content.Context, presence: FriendPresence?, language: AppLanguage): String? {
    presence ?: return null
    if (presence.online) return StringStore.text(context, "duel.friend.online", language)
    // Sous la minute, « il y a 1 minute » plutôt qu'un compte de secondes.
    val seconds = maxOf(presence.last_seen_seconds ?: return null, 60)
    val (count, unit) = when {
        seconds < 3_600 -> seconds / 60 to RelativeDateTimeFormatter.RelativeUnit.MINUTES
        seconds < 86_400 -> seconds / 3_600 to RelativeDateTimeFormatter.RelativeUnit.HOURS
        seconds < 30 * 86_400 -> seconds / 86_400 to RelativeDateTimeFormatter.RelativeUnit.DAYS
        seconds < 365 * 86_400 -> seconds / (30 * 86_400) to RelativeDateTimeFormatter.RelativeUnit.MONTHS
        else -> seconds / (365 * 86_400) to RelativeDateTimeFormatter.RelativeUnit.YEARS
    }
    val ago = RelativeDateTimeFormatter.getInstance(ULocale.forLocale(language.locale))
        .format(count.toDouble(), RelativeDateTimeFormatter.Direction.LAST, unit)
    return StringStore.text(context, "friends.lastSeen", language, ago)
}

/**
 * Le classement des amis, à même le profil comme sur iOS : un podium pour les trois premiers
 * (avec leurs avatars), les rangs suivants en lignes, la ligne du lecteur mise en avant, puis
 * « Ajouter un ami » et « Mon QR code ».
 */
@Composable
fun ProfileFriendsSection(
    language: AppLanguage,
    myAvatarId: String?,
    onOpenFriend: (userId: String) -> Unit,
    onEditHandle: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val social = app.socialService
    val scope = rememberCoroutineScope()
    val signedIn by app.authService.userId.collectAsState()
    val leaderboard by social.leaderboard.collectAsState()
    val pending by social.pendingRequests.collectAsState()
    val period by social.period.collectAsState()
    val handle by social.myHandle.collectAsState()
    // Avatars et présence : le classement des trophées les porte pour le même groupe.
    val duelRows by app.duelService.leaderboard.collectAsState()
    val duelById = remember(duelRows) { duelRows.associateBy { it.userId } }

    var showAdd by remember { mutableStateOf(false) }
    var showQr by remember { mutableStateOf(false) }

    LaunchedEffect(signedIn) {
        if (signedIn != null) social.refreshAll()
    }
    LaunchedEffect(signedIn, period) {
        if (signedIn != null) social.refreshLeaderboard()
    }
    LaunchedEffect(signedIn, leaderboard.size) {
        if (signedIn != null) app.duelService.refreshLeaderboard()
    }

    fun avatarOf(entry: FriendLeaderboardEntry): String? =
        if (entry.is_me && myAvatarId != null) myAvatarId else duelById[entry.user_id]?.avatarId
    fun onlineOf(entry: FriendLeaderboardEntry): Boolean = !entry.is_me && duelById[entry.user_id]?.online == true
    fun open(entry: FriendLeaderboardEntry) {
        if (entry.is_me) onEditHandle() else onOpenFriend(entry.user_id)
    }

    if (showAdd) {
        AddFriendSheet(language = language, onDismiss = { showAdd = false }, onSent = {
            scope.launch {
                social.refreshLeaderboard()
                social.refreshPendingRequests()
            }
        })
    }
    if (showQr) {
        MyFriendQrSheet(language = language, handle = handle, avatarId = myAvatarId, onDismiss = { showQr = false })
    }

    val periods = listOf(FriendsLeaderboardPeriod.WEEK, FriendsLeaderboardPeriod.ALL)
    Column(modifier = modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        ProfileSectionHeader(title = StringStore.text(context, "profile.friends.title", language))

        if (signedIn == null) {
            FriendsInfoCard(
                title = StringStore.text(context, "friends.signedOut.title", language),
                body = StringStore.text(context, "friends.signedOut.body", language),
            )
            return@Column
        }

        // Les demandes reçues : la seule chose ici qui attend une réponse.
        if (pending.isNotEmpty()) {
            FriendRequestsCard(
                requests = pending,
                language = language,
                onRespond = { request, accept ->
                    scope.launch {
                        social.respondToRequest(request.request_id, accept)
                        if (accept) social.refreshLeaderboard()
                    }
                },
            )
        }

        ProfilePillTabs(
            items = listOf(
                StringStore.text(context, "friends.period.week", language),
                StringStore.text(context, "friends.period.all", language),
            ),
            selectedIndex = periods.indexOf(period).coerceAtLeast(0),
            onSelect = { social.setPeriod(periods[it]) },
        )

        // Le classement : un podium à partir de trois, de simples lignes médaillées avant.
        if (leaderboard.none { !it.is_me }) {
            Column(
                modifier = Modifier.fillMaxWidth().sophiaCard().padding(horizontal = 16.dp, vertical = 18.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                AvatarCircle(
                    avatarId = myAvatarId,
                    initial = handle?.takeIf { it.isNotBlank() }?.take(1)?.uppercase() ?: "S",
                    size = 52.dp,
                )
                Text(
                    text = StringStore.text(context, "friends.empty.title", language),
                    fontFamily = PlusJakartaSans, fontWeight = FontWeight.Bold, fontSize = 16.sp, lineHeight = 21.sp, color = DS.ink,
                    textAlign = TextAlign.Center,
                )
                Text(
                    text = StringStore.text(context, "friends.empty.body", language),
                    fontFamily = PlusJakartaSans, fontSize = 15.sp, lineHeight = 21.sp, color = DS.inkSecondary,
                    textAlign = TextAlign.Center,
                )
            }
        } else {
            val podium = if (leaderboard.size >= 3) leaderboard.take(3) else emptyList()
            Column(modifier = Modifier.fillMaxWidth().sophiaCard()) {
                if (podium.isNotEmpty()) {
                    // Deuxième à gauche, premier au centre, troisième à droite, quelle que soit la langue.
                    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                        Row(
                            modifier = Modifier.fillMaxWidth().padding(start = 12.dp, end = 12.dp, top = 18.dp, bottom = 12.dp),
                            verticalAlignment = Alignment.Bottom,
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            listOf(2 to podium[1], 1 to podium[0], 3 to podium[2]).forEach { (rank, entry) ->
                                PodiumColumn(
                                    rank = rank,
                                    entry = entry,
                                    avatarId = avatarOf(entry),
                                    online = onlineOf(entry),
                                    language = language,
                                    onClick = { open(entry) },
                                    modifier = Modifier.weight(1f),
                                )
                            }
                        }
                    }
                }
                leaderboard.forEachIndexed { index, entry ->
                    if (index < podium.size) return@forEachIndexed
                    if (index > 0) ProfileRowDivider(inset = 0.dp)
                    LeaderRow(
                        rank = index + 1,
                        entry = entry,
                        avatarId = avatarOf(entry),
                        online = onlineOf(entry),
                        language = language,
                        onClick = { open(entry) },
                        modifier = Modifier.dsStagger(minOf(index, 8), stepMillis = 40),
                    )
                }
            }
        }

        // « Ajouter un ami » en bouton principal, puis « Mon QR code » et « Scanner » côte à côte.
        // Les vibrations viennent des boutons (CTA plein, pression élastique).
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            SophiaPrimaryButton(
                text = StringStore.text(context, "friends.add.title", language),
                leadingIcon = Icons.Outlined.Person,
                onClick = { showAdd = true },
            )
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                FriendQrActionButton(
                    icon = Icons.Filled.QrCode2,
                    title = StringStore.text(context, "profile.qr.mine", language),
                    onClick = { showQr = true },
                    modifier = Modifier.weight(1f),
                )
                // « Scanner » : le code d'un ami ouvre la même confirmation qu'un lien d'ami.
                FriendQrActionButton(
                    icon = Icons.Filled.QrCodeScanner,
                    title = StringStore.text(context, "profile.qr.scan", language),
                    onClick = {
                        fun toast(key: String) =
                            Toast.makeText(context, StringStore.text(context, key, language), Toast.LENGTH_LONG).show()
                        runCatching {
                            val options = GmsBarcodeScannerOptions.Builder().setBarcodeFormats(Barcode.FORMAT_QR_CODE).build()
                            GmsBarcodeScanning.getClient(context, options).startScan()
                                .addOnSuccessListener { code ->
                                    val friend = code.rawValue?.let { SophiaLinks.friendHandle(it) }
                                    if (friend != null) FriendLinkRouter.open(friend) else toast("profile.qr.invalid")
                                }
                                // Fermé par le lecteur : rien à dire. Sinon, l'appareil ne peut pas scanner.
                                .addOnFailureListener { toast("profile.qr.camera.unavailable") }
                        }.onFailure { toast("profile.qr.camera.unavailable") }
                    },
                    modifier = Modifier.weight(1f),
                )
            }
        }
    }
}

/**
 * Les demandes d'amis reçues, sur une carte : le sur-titre et leur nombre, puis une rangée par
 * demande. Refuser, accepter : deux pastilles qui rebondissent franchement sous le doigt.
 */
@Composable
internal fun FriendRequestsCard(
    requests: List<FriendRequest>,
    language: AppLanguage,
    onRespond: (FriendRequest, Boolean) -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    Column(modifier = modifier.fillMaxWidth().sophiaCard()) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = 14.dp, bottom = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            DSEyebrow(
                text = StringStore.text(context, "friends.requests.title", language),
                modifier = Modifier.weight(1f).semantics { heading() },
            )
            Text(
                text = "${requests.size}",
                fontFamily = PlusJakartaSans, fontWeight = FontWeight.ExtraBold, fontSize = 11.sp, color = Color.White,
                maxLines = 1,
                modifier = Modifier.clip(CircleShape).background(DS.accent).padding(horizontal = 7.dp, vertical = 2.dp),
            )
        }
        requests.forEachIndexed { index, request ->
            if (index > 0) ProfileRowDivider()
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                AvatarCircle(avatarId = null, initial = request.handle.take(1).uppercase(), size = 38.dp)
                Text(
                    text = "@${request.handle}",
                    fontFamily = PlusJakartaSans, fontWeight = FontWeight.Bold, fontSize = 15.sp, color = DS.ink,
                    maxLines = 1, overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f),
                )
                // Un refus : un simple toucher sourd ; un nouvel ami : la vibration du succès.
                RequestRoundButton(
                    icon = Icons.Filled.Close,
                    label = StringStore.text(context, "friends.requests.decline", language),
                    filled = false,
                    onClick = {
                        haptics.soft()
                        onRespond(request, false)
                    },
                )
                RequestRoundButton(
                    icon = Icons.Filled.Check,
                    label = StringStore.text(context, "friends.requests.accept", language),
                    filled = true,
                    onClick = {
                        haptics.success()
                        onRespond(request, true)
                    },
                )
            }
        }
        Spacer(Modifier.height(6.dp))
    }
}

/** Une pastille ronde de réponse (accepter en bleu plein, refuser en blanc bordé), au rebond franc. */
@Composable
private fun RequestRoundButton(icon: ImageVector, label: String, filled: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(40.dp)
            .pressable(onClick = onClick, scaleDown = 0.84f, haptic = false)
            .clip(CircleShape)
            .background(if (filled) DS.accent else DS.surface)
            .then(if (filled) Modifier else Modifier.border(1.5.dp, DS.hairline, CircleShape)),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, contentDescription = label, tint = if (filled) Color.White else DS.inkSecondary, modifier = Modifier.size(17.dp))
    }
}

/** « Mon QR code », « Scanner » : un bouton secondaire (carte blanche bordée) avec son pictogramme. */
@Composable
private fun FriendQrActionButton(icon: ImageVector, title: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .height(50.dp)
            .pressable(onClick = onClick)
            .dsOptionCard(DSOptionState.Idle)
            .padding(horizontal = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
    ) {
        Icon(icon, contentDescription = null, tint = DS.ink, modifier = Modifier.size(19.dp))
        Spacer(Modifier.width(8.dp))
        Text(
            text = title,
            fontFamily = PlusJakartaSans, fontWeight = FontWeight.Bold, fontSize = 14.sp, color = DS.ink,
            maxLines = 1, overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f, fill = false),
        )
    }
}

/** L'avatar d'un ami (ses initiales s'il n'en a pas choisi), avec la pastille « en ligne ». */
@Composable
private fun FriendAvatar(handle: String, avatarId: String?, online: Boolean, size: Dp, ring: Color? = null) {
    Box {
        AvatarCircle(
            avatarId = avatarId,
            initial = handle.take(1).uppercase(),
            size = size,
            modifier = if (ring != null) Modifier.border(maxOf(2.5f, size.value * 0.05f).dp, ring, CircleShape) else Modifier,
        )
        if (online) DuelOnlineDot(size = maxOf(11f, size.value * 0.22f).dp, modifier = Modifier.align(Alignment.BottomEnd))
    }
}

@Composable
private fun PodiumColumn(
    rank: Int,
    entry: FriendLeaderboardEntry,
    avatarId: String?,
    online: Boolean,
    language: AppLanguage,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val medal = friendMedalColor(rank)
    Column(
        modifier = modifier.pressable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        if (rank == 1) Icon(Icons.Filled.WorkspacePremium, contentDescription = null, tint = medal, modifier = Modifier.size(22.dp))
        // Les avatars arrivent en rebondissant, le troisième d'abord, le premier en dernier.
        Box(modifier = Modifier.dsPopIn(delayMillis = 100 + (3 - rank) * 90)) {
            FriendAvatar(entry.handle, avatarId, online, size = if (rank == 1) 72.dp else 56.dp, ring = medal)
        }
        Text(
            text = "@${entry.handle}",
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 13.sp,
            color = if (entry.is_me) DS.accent else DS.ink,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = if (entry.is_me) {
                Modifier.clip(CircleShape).background(DS.accentTint).padding(horizontal = 8.dp, vertical = 2.dp)
            } else {
                Modifier
            },
        )
        Text(
            text = "${entry.xp.formatted(language)} XP",
            fontFamily = PlusJakartaSans, fontWeight = FontWeight.Bold, fontSize = 12.sp, color = DS.inkSecondary,
            maxLines = 1,
        )
        // La marche du podium, à la couleur de la médaille.
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(if (rank == 1) 62.dp else if (rank == 2) 44.dp else 32.dp)
                .clip(RoundedCornerShape(topStart = 14.dp, topEnd = 14.dp, bottomStart = 4.dp, bottomEnd = 4.dp))
                .background(medal.copy(alpha = 0.2f)),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = "$rank",
                fontFamily = PlusJakartaSans, fontWeight = FontWeight.ExtraBold,
                fontSize = if (rank == 1) 22.sp else 20.sp, color = medal,
            )
        }
    }
}

@Composable
private fun LeaderRow(
    rank: Int,
    entry: FriendLeaderboardEntry,
    avatarId: String?,
    online: Boolean,
    language: AppLanguage,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    Row(
        modifier = modifier
            .fillMaxWidth()
            .profileRowPress(onClick = onClick)
            // La ligne du lecteur ressort sur un fond teinté.
            .background(if (entry.is_me) DS.accentTint else Color.Transparent)
            .padding(horizontal = 16.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        // Une médaille pleine pour les trois premiers, un simple nombre ensuite.
        FriendRankBadge(rank)
        FriendAvatar(entry.handle, avatarId, online, size = 42.dp)
        Row(
            modifier = Modifier.weight(1f),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(
                text = "@${entry.handle}",
                fontFamily = PlusJakartaSans, fontWeight = FontWeight.Bold, fontSize = 15.sp, color = DS.ink,
                maxLines = 1, overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f, fill = false),
            )
            if (entry.is_me) FriendYouPill(StringStore.text(context, "friends.you", language))
        }
        Text(
            text = "${entry.xp.formatted(language)} XP",
            fontFamily = PlusJakartaSans, fontWeight = FontWeight.Bold, fontSize = 15.sp,
            color = if (entry.is_me) DS.ink else DS.inkSecondary,
            maxLines = 1,
        )
        if (!entry.is_me) ProfileRowChevron()
    }
}

/** Le message d'une demande d'ami, déjà traduit : envoyée, déjà amis, ou l'erreur. */
private suspend fun sendFriendRequest(
    context: android.content.Context,
    social: SocialService,
    handle: String,
    language: AppLanguage,
): Pair<Boolean, String> {
    val result = social.sendFriendRequest(handle)
    val outcome = result.getOrNull()
    return when {
        outcome == SendRequestOutcome.AUTO_ACCEPTED -> true to StringStore.text(context, "friends.request.autoAccepted", language)
        outcome != null -> true to StringStore.text(context, "friends.request.sent", language)
        else -> false to StringStore.text(context, SocialService.errorKeyFor(result.exceptionOrNull()?.message), language)
    }
}

/** « Ajouter un ami » : le @ à saisir, la demande part, le message s'affiche sous le champ. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddFriendSheet(language: AppLanguage, onDismiss: () -> Unit, onSent: () -> Unit) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val scope = rememberCoroutineScope()
    val haptics = rememberHaptics()
    var input by remember { mutableStateOf("") }
    var sending by remember { mutableStateOf(false) }
    var feedback by remember { mutableStateOf<Pair<Boolean, String>?>(null) }
    // Secousse du champ à chaque demande refusée.
    var errorShake by remember { mutableIntStateOf(0) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = DS.canvas,
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().imePadding().navigationBarsPadding().padding(start = 20.dp, end = 20.dp, bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Text(
                text = StringStore.text(context, "friends.add.title", language),
                fontFamily = PlusJakartaSans, fontWeight = FontWeight.SemiBold, fontSize = 22.sp, color = DS.ink,
                modifier = Modifier.semantics { heading() },
            )
            Text(
                text = StringStore.text(context, "friends.add.requestSubtitle", language),
                fontFamily = PlusJakartaSans, fontSize = 15.sp, lineHeight = 21.sp, color = DS.inkSecondary,
            )
            // Le champ : neutre, vert une fois la demande partie, rouge si elle est refusée.
            ProfileTextField(
                value = input,
                onValueChange = {
                    input = it.trim().removePrefix("@").take(20)
                    feedback = null
                },
                placeholder = StringStore.text(context, "friends.handle.placeholder", language),
                prefix = "@",
                keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.None, autoCorrectEnabled = false, imeAction = ImeAction.Done),
                borderOverride = feedback?.let { if (it.first) DS.success else DS.danger },
                fillOverride = feedback?.let { if (it.first) DS.successTint else DS.dangerTint },
                modifier = Modifier.dsShake(trigger = errorShake),
            )
            feedback?.let { (success, message) ->
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    // Demande partie : la coche se dessine, avec rebond.
                    if (success) DSCheckBadge(size = 22.dp)
                    Text(
                        text = message,
                        fontFamily = PlusJakartaSans, fontWeight = FontWeight.Bold, fontSize = 14.sp, lineHeight = 19.sp,
                        color = if (success) DS.success else DS.danger,
                    )
                }
            }
            SophiaPrimaryButton(
                text = StringStore.text(context, "friends.request.send", language),
                onClick = {
                    if (sending || input.isBlank()) return@SophiaPrimaryButton
                    sending = true
                    scope.launch {
                        val outcome = sendFriendRequest(context, app.socialService, input, language)
                        feedback = outcome
                        sending = false
                        if (outcome.first) {
                            haptics.success()
                            input = ""
                            onSent()
                        } else {
                            haptics.error()
                            errorShake += 1
                        }
                    }
                },
            )
        }
    }
}

/** Le QR code d'un texte : bleu marine sur crème, un pixel par module (affiché sans lissage). */
internal fun friendQrBitmap(text: String): Bitmap? = runCatching {
    val hints = mapOf(EncodeHintType.ERROR_CORRECTION to ErrorCorrectionLevel.M, EncodeHintType.MARGIN to 1)
    val matrix = QRCodeWriter().encode(text, BarcodeFormat.QR_CODE, 0, 0, hints)
    val ink = DuelPalette.navy.toArgb()
    val paper = DuelPalette.cream.toArgb()
    val pixels = IntArray(matrix.width * matrix.height) { i ->
        if (matrix.get(i % matrix.width, i / matrix.width)) ink else paper
    }
    Bitmap.createBitmap(pixels, matrix.width, matrix.height, Bitmap.Config.ARGB_8888)
}.getOrNull()

/** Mon QR code, sur une carte « papier » : avatar, @, le code. Un ami le vise avec son appareil photo. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MyFriendQrSheet(language: AppLanguage, handle: String?, avatarId: String?, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val name = handle?.takeIf { it.isNotBlank() }
    val qr = remember(name) { name?.let { friendQrBitmap(SophiaLinks.friendUrl(it)) } }
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = DS.canvas,
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().navigationBarsPadding().padding(start = 20.dp, end = 20.dp, bottom = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(22.dp),
        ) {
            Text(
                text = StringStore.text(context, "profile.qr.mine", language),
                fontFamily = PlusJakartaSans, fontWeight = FontWeight.SemiBold, fontSize = 22.sp, color = DS.ink,
                modifier = Modifier.fillMaxWidth().semantics { heading() },
            )
            // La carte crème au liseré marine, posée sur un aplat safran décalé (papier découpé).
            Box(modifier = Modifier.padding(top = 30.dp).fillMaxWidth(0.82f)) {
                Box(
                    modifier = Modifier
                        .matchParentSize()
                        .offset(x = 7.dp, y = 8.dp)
                        .clip(RoundedCornerShape(28.dp))
                        .background(DuelPalette.saffron),
                )
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(28.dp))
                        .background(DuelPalette.cream)
                        .border(2.dp, DuelPalette.navy, RoundedCornerShape(28.dp))
                        .padding(start = 22.dp, end = 22.dp, top = 40.dp, bottom = 22.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    Text(
                        text = "@${name.orEmpty()}",
                        fontFamily = PlusJakartaSans, fontWeight = FontWeight.ExtraBold, fontSize = 20.sp, color = DuelPalette.navy,
                        maxLines = 1, overflow = TextOverflow.Ellipsis,
                    )
                    if (qr != null) {
                        Image(
                            bitmap = qr.asImageBitmap(),
                            contentDescription = StringStore.text(context, "profile.qr.mine", language),
                            filterQuality = FilterQuality.None,
                            modifier = Modifier.fillMaxWidth().aspectRatio(1f),
                        )
                    } else {
                        Box(modifier = Modifier.fillMaxWidth().aspectRatio(1f))
                    }
                }
                AvatarCircle(
                    avatarId = avatarId,
                    initial = name.orEmpty().take(1).uppercase(),
                    size = 60.dp,
                    modifier = Modifier
                        .align(Alignment.TopCenter)
                        .offset(y = (-30).dp)
                        .border(3.dp, DuelPalette.cream, CircleShape),
                )
            }
            Text(
                text = StringStore.text(context, "profile.qr.mine.hint", language),
                fontFamily = PlusJakartaSans, fontSize = 15.sp, lineHeight = 21.sp,
                color = DS.inkSecondary, textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 8.dp),
            )
        }
    }
}

/**
 * La feuille d'un lien d'ami ouvert de l'extérieur (un QR code scanné) : « Ajouter @x en ami ? ».
 * Posée une fois au-dessus des onglets ; elle lit [app.rork.sophia.data.FriendLinkRouter].
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FriendLinkHost(language: AppLanguage) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val scope = rememberCoroutineScope()
    val handle by FriendLinkRouter.pendingHandle.collectAsState()
    val signedIn by app.authService.userId.collectAsState()
    val haptics = rememberHaptics()
    var sending by remember { mutableStateOf(false) }
    var feedback by remember(handle) { mutableStateOf<Pair<Boolean, String>?>(null) }
    val target = handle ?: return
    val dismiss = { FriendLinkRouter.consume() }

    ModalBottomSheet(onDismissRequest = dismiss, containerColor = DS.canvas) {
        Column(
            modifier = Modifier.fillMaxWidth().navigationBarsPadding().padding(start = 20.dp, end = 20.dp, bottom = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            AvatarCircle(
                avatarId = null,
                initial = target.take(1).uppercase(),
                size = 72.dp,
                modifier = Modifier.dsPopIn(delayMillis = 100),
            )
            Text(
                text = StringStore.text(context, "profile.friendLink.title", language, target),
                fontFamily = PlusJakartaSans, fontWeight = FontWeight.SemiBold, fontSize = 22.sp, lineHeight = 28.sp,
                color = DS.ink, textAlign = TextAlign.Center,
            )
            val message = feedback?.second
                ?: if (signedIn == null) StringStore.text(context, "friends.signedOut.body", language) else null
            message?.let {
                Text(
                    text = it,
                    fontFamily = PlusJakartaSans, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, lineHeight = 21.sp,
                    color = when (feedback?.first) {
                        false -> DS.danger
                        true -> DS.success
                        null -> DS.inkSecondary
                    },
                    textAlign = TextAlign.Center,
                )
            }
            if (feedback?.first == true || signedIn == null) {
                SophiaPrimaryButton(text = StringStore.text(context, "common.close", language), onClick = dismiss)
            } else {
                SophiaPrimaryButton(
                    text = StringStore.text(context, "friends.request.send", language),
                    onClick = {
                        if (sending) return@SophiaPrimaryButton
                        sending = true
                        scope.launch {
                            feedback = sendFriendRequest(context, app.socialService, target, language)
                            sending = false
                            if (feedback?.first == true) {
                                haptics.success()
                                app.socialService.refreshLeaderboard()
                                app.socialService.refreshPendingRequests()
                            } else {
                                haptics.error()
                            }
                        }
                    },
                )
            }
        }
    }
}
