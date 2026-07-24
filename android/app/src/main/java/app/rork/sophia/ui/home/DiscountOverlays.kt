package app.rork.sophia.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.DiscountState
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography

@Composable
fun DiscountGiftOverlay(onOpen: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.55f))
            .clickable(onClick = onOpen),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            modifier = Modifier
                .padding(32.dp)
                .clip(DS.cardShape)
                .background(DS.surface)
                .padding(28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text("🎁", fontSize = 48.sp)
            Text("Un cadeau pour toi", style = SophiaTypography.titleLarge, textAlign = TextAlign.Center)
            Text(
                "Offre spéciale — ouvre-la maintenant.",
                style = SophiaTypography.bodyMedium,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 8.dp, bottom = 20.dp),
            )
            Button(
                onClick = onOpen,
                modifier = Modifier.fillMaxWidth(),
                shape = DS.controlShape,
                colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
            ) {
                Text("Ouvrir", color = Color.White, fontFamily = PlusJakartaSans, fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

@Composable
fun DiscountSideTab(
    state: DiscountState,
    onClick: () -> Unit,
) {
    Box(
        modifier = Modifier
            .fillMaxHeight()
            .padding(vertical = 120.dp),
        contentAlignment = Alignment.CenterEnd,
    ) {
        Column(
            modifier = Modifier
                .width(52.dp)
                .clip(RoundedCornerShape(topStart = 12.dp, bottomStart = 12.dp))
                .background(DS.accent)
                .clickable(onClick = onClick)
                .padding(vertical = 14.dp, horizontal = 6.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                "OFFRE",
                color = Color.White,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 11.sp,
            )
            Text(
                state.formattedRemaining,
                color = Color.White,
                fontFamily = PlusJakartaSans,
                fontSize = 11.sp,
                modifier = Modifier.padding(top = 6.dp),
            )
        }
    }
}
