package app.rork.sophia.ui.newgen

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.R
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans

/**
 * Les vingt avatars illustrés (design/site-art/manifest-avatars.json, la direction affiche du
 * site), dans `res/drawable-nodpi`. Un lecteur en choisit un à la place de ses initiales ; le choix
 * (`UserProgress.avatarId`) suit la progression, donc le multi-appareils. Mêmes fichiers que le
 * Studio pour les auteurs.
 */
object Avatars {
    val all: List<String> = (1..20).map { "avatar_%02d".format(it) }

    private val drawables = mapOf(
        "avatar_01" to R.drawable.avatar_01, "avatar_02" to R.drawable.avatar_02, "avatar_03" to R.drawable.avatar_03,
        "avatar_04" to R.drawable.avatar_04, "avatar_05" to R.drawable.avatar_05, "avatar_06" to R.drawable.avatar_06,
        "avatar_07" to R.drawable.avatar_07, "avatar_08" to R.drawable.avatar_08, "avatar_09" to R.drawable.avatar_09,
        "avatar_10" to R.drawable.avatar_10, "avatar_11" to R.drawable.avatar_11, "avatar_12" to R.drawable.avatar_12,
        "avatar_13" to R.drawable.avatar_13, "avatar_14" to R.drawable.avatar_14, "avatar_15" to R.drawable.avatar_15,
        "avatar_16" to R.drawable.avatar_16, "avatar_17" to R.drawable.avatar_17, "avatar_18" to R.drawable.avatar_18,
        "avatar_19" to R.drawable.avatar_19, "avatar_20" to R.drawable.avatar_20,
    )

    fun drawable(id: String?): Int? = id?.let { drawables[it] }
}

/** Le rond du profil : l'avatar choisi, sinon l'initiale sur le fond bleu. */
@Composable
fun AvatarCircle(avatarId: String?, initial: String, size: Dp, modifier: Modifier = Modifier) {
    val drawable = Avatars.drawable(avatarId)
    Box(
        modifier = modifier.size(size).clip(CircleShape).background(DS.accentSoft),
        contentAlignment = Alignment.Center,
    ) {
        if (drawable != null) {
            Image(
                painter = painterResource(drawable),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.size(size),
            )
        } else {
            Text(
                text = initial,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = (size.value * 0.38f).sp,
                color = Color.White,
            )
        }
    }
}

/** La feuille de choix : la grille des vingt, et « pas d'avatar » pour revenir aux initiales. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AvatarPickerSheet(
    language: AppLanguage,
    current: String?,
    initial: String,
    onPick: (String?) -> Unit,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState, containerColor = DS.canvas) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(
                text = StringStore.text(context, "profile.avatar.title", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 20.sp,
                color = DS.ink,
            )
            LazyVerticalGrid(
                columns = GridCells.Fixed(4),
                horizontalArrangement = Arrangement.spacedBy(14.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp),
                modifier = Modifier.height(86.dp * 5),
                userScrollEnabled = false,
            ) {
                items(Avatars.all) { id ->
                    AvatarCircle(
                        avatarId = id,
                        initial = initial,
                        size = 72.dp,
                        modifier = Modifier
                            .border(3.dp, if (current == id) DS.accent else Color.Transparent, CircleShape)
                            .softPress(onClick = { onPick(id) }),
                    )
                }
            }
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(DS.surface)
                    .border(1.dp, DS.hairline, RoundedCornerShape(16.dp))
                    .softPress(onClick = { onPick(null) })
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                AvatarCircle(avatarId = null, initial = initial, size = 40.dp)
                Text(
                    text = StringStore.text(context, "profile.avatar.none", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp,
                    color = DS.ink,
                    modifier = Modifier.weight(1f),
                )
                Spacer(Modifier.size(4.dp))
                if (current == null) {
                    Icon(Icons.Filled.Check, contentDescription = null, tint = DS.accent, modifier = Modifier.size(18.dp))
                }
            }
        }
    }
}
