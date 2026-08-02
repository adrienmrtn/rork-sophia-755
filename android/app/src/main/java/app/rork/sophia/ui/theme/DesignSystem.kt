package app.rork.sophia.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Typography
import androidx.compose.runtime.Immutable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.R

val PlusJakartaSans = FontFamily(
    Font(R.font.plus_jakarta_sans, FontWeight.Normal),
)

@Immutable
object DS {
    val canvas = Color(0xFFF7F8FA)
    val surface = Color.White
    val surfaceMuted = Color(0xFFE9EFF8)

    val ink = Color(0xFF16263D)
    val inkSecondary = Color(0xFF55637A)
    val inkTertiary = Color(0xFF9AA4B2)

    val accent = Color(0xFF1A3A6B)
    val accentSoft = Color(0xFF2E62C4)
    val accentTint = Color(0xFFE9EFF8)

    val hairline = Color(0xFFE4E7EC)

    val success = Color(0xFF387D5A)
    val successTint = Color(0xFFE0EDED)
    val danger = Color(0xFFB14F42)
    val dangerTint = Color(0xFFF6E7E4)
    val warm = Color(0xFFE6B233)

    object Radius {
        val card = 22.dp
        val control = 16.dp
        val small = 12.dp
    }

    object Space {
        val xs = 6.dp
        val s = 12.dp
        val m = 16.dp
        val l = 20.dp
        val xl = 28.dp
    }

    val cardShape = RoundedCornerShape(Radius.card)
    val controlShape = RoundedCornerShape(Radius.control)
}

val SophiaTypography = Typography(
    displayLarge = TextStyle(
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 34.sp,
        color = DS.ink,
    ),
    titleLarge = TextStyle(
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 22.sp,
        color = DS.ink,
    ),
    titleMedium = TextStyle(
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.Bold,
        fontSize = 18.sp,
        color = DS.ink,
    ),
    bodyLarge = TextStyle(
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.Normal,
        fontSize = 17.sp,
        color = DS.ink,
        lineHeight = 24.sp,
    ),
    bodyMedium = TextStyle(
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.Normal,
        fontSize = 15.sp,
        color = DS.inkSecondary,
        lineHeight = 22.sp,
    ),
    labelLarge = TextStyle(
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.SemiBold,
        fontSize = 16.sp,
        color = DS.ink,
    ),
    labelMedium = TextStyle(
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.Medium,
        fontSize = 13.sp,
        color = DS.inkSecondary,
    ),
)
