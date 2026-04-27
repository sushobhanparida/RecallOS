package com.example.recallos.ui

import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Assignment
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Label
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import com.example.recallos.ui.theme.*
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScreenshotDetailScreen(
    screenshotId: Long,
    onBackClick: () -> Unit,
    viewModel: ScreenshotDetailViewModel = viewModel()
) {
    LaunchedEffect(screenshotId) {
        viewModel.loadDetails(screenshotId)
    }

    val screenshot by viewModel.screenshotState.collectAsState()
    val todo       by viewModel.todoState.collectAsState()

    val dateFormat = SimpleDateFormat("MMMM d, yyyy 'at' h:mm a", Locale.getDefault())

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        if (screenshot != null) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
            ) {
                // ── Full-width hero image — no padding, no border ─────────────
                AsyncImage(
                    model              = Uri.parse(screenshot!!.uri),
                    contentDescription = "Screenshot",
                    modifier           = Modifier
                        .fillMaxWidth()
                        .wrapContentHeight(),
                    contentScale = ContentScale.FillWidth
                )

                Spacer(modifier = Modifier.height(24.dp))

                // ── Detail rows ───────────────────────────────────────────────
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp)
                ) {
                    if (todo != null) {
                        DetailInfoRow(
                            icon      = Icons.Default.Assignment,
                            title     = if (todo!!.isEvent) "Event" else "Task",
                            content   = todo!!.title,
                            iconColor = if (todo!!.isEvent) Secondary else Primary
                        )
                        HorizontalDivider(
                            modifier  = Modifier.padding(vertical = 4.dp),
                            color     = OutlineVariant.copy(alpha = 0.5f),
                            thickness = 0.5.dp
                        )
                    }

                    DetailInfoRow(
                        icon      = Icons.Default.Label,
                        title     = "Category",
                        content   = screenshot!!.tag,
                        iconColor = Secondary
                    )
                    HorizontalDivider(
                        modifier  = Modifier.padding(vertical = 4.dp),
                        color     = OutlineVariant.copy(alpha = 0.5f),
                        thickness = 0.5.dp
                    )

                    DetailInfoRow(
                        icon      = Icons.Default.Schedule,
                        title     = "Captured",
                        content   = dateFormat.format(Date(screenshot!!.createdAt)),
                        iconColor = Tertiary
                    )

                    if (screenshot!!.extractedText.isNotEmpty()) {
                        HorizontalDivider(
                            modifier  = Modifier.padding(vertical = 4.dp),
                            color     = OutlineVariant.copy(alpha = 0.5f),
                            thickness = 0.5.dp
                        )
                        DetailInfoRow(
                            icon      = Icons.Default.Description,
                            title     = "Extracted text",
                            content   = screenshot!!.extractedText,
                            iconColor = Outline
                        )
                    }

                    Spacer(modifier = Modifier.height(40.dp))
                }
            }

            // ── Floating back button overlaid on the image ────────────────────
            Box(
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .padding(top = 12.dp, start = 12.dp)
                    .size(40.dp)
                    .clip(RadiusFull)
                    .background(Color.Black.copy(alpha = 0.45f))
                    .clickable { onBackClick() },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector        = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Back",
                    tint               = OnPrimary,
                    modifier           = Modifier.size(20.dp)
                )
            }
        } else {
            CircularProgressIndicator(
                modifier = Modifier.align(Alignment.Center),
                color    = Primary
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Clean detail row — icon + label + content, no card chrome
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun DetailInfoRow(
    icon: ImageVector,
    title: String,
    content: String,
    iconColor: Color
) {
    Row(
        modifier          = Modifier
            .fillMaxWidth()
            .padding(vertical = 14.dp),
        verticalAlignment = Alignment.Top
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(RadiusMd)
                .background(iconColor.copy(alpha = 0.10f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector        = icon,
                contentDescription = title,
                tint               = iconColor,
                modifier           = Modifier.size(18.dp)
            )
        }
        Spacer(modifier = Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text  = title,
                style = MaterialTheme.typography.labelMedium,
                color = OnSurfaceVariant
            )
            Spacer(modifier = Modifier.height(3.dp))
            Text(
                text  = content,
                style = MaterialTheme.typography.bodyMedium,
                color = OnSurface
            )
        }
    }
}

// Keep the old name as an alias so existing call-sites compile
@Composable
fun DetailCard(
    icon: ImageVector,
    title: String,
    content: String,
    iconColor: Color
) = DetailInfoRow(icon = icon, title = title, content = content, iconColor = iconColor)
