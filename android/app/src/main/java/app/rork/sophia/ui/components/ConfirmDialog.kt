package app.rork.sophia.ui.components

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.SophiaTypography

/** Destructive confirmation, styled like the iOS alerts: settings resets, removing a friend. */
@Composable
fun ConfirmDialog(
    title: String,
    message: String,
    confirm: String,
    cancel: String,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = DS.surface,
        shape = DS.cardShape,
        title = { Text(title, style = SophiaTypography.titleMedium) },
        text = { Text(message, style = SophiaTypography.bodyMedium) },
        confirmButton = {
            TextButton(onClick = onConfirm) { Text(confirm, color = DS.danger) }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(cancel, color = DS.inkSecondary) }
        },
    )
}
