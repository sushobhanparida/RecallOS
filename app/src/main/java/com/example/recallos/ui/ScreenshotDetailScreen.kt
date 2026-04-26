package com.example.recallos.ui

import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.ui.text.font.FontWeight
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

    val dateFormat = SimpleDateFormat("MMMM d'th', yyyy 'at' h:mm a", Locale.getDefault())

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        "Details",
                        style = MaterialTheme.typography.titleLarge,
                        color = OnSurface
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back",
                            tint = OnSurface
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        },
        containerColor = MaterialTheme.colorScheme.background
    ) { innerPadding ->
        if (screenshot != null) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .verticalScroll(rememberScrollState())
            ) {
                // ── Hero Image ───────────────────────────────────────────────
                Box(
                    modifier = Modifier
                        .padding(horizontal = 20.dp)
                        .fillMaxWidth()
                        .clip(RadiusCard)
                        .border(1.dp, OutlineVariant, RadiusCard)
                ) {
                    AsyncImage(
                        model              = Uri.parse(screenshot!!.uri),
                        contentDescription = "Full Screenshot",
                        modifier           = Modifier
                            .fillMaxWidth()
                            .heightIn(max = 400.dp),
                        contentScale = ContentScale.Fit
                    )
                }

                Spacer(modifier = Modifier.height(24.dp))

                Column(modifier = Modifier.padding(horizontal = 20.dp)) {

                    // ── Associated Task card ─────────────────────────────────
                    if (todo != null) {
                        DetailCard(
                            icon      = Icons.Default.Assignment,
                            title     = if (todo!!.isEvent) "Associated Event" else "Associated Task",
                            content   = todo!!.title,
                            iconColor = if (todo!!.isEvent) Secondary else Primary
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                    }

                    // ── Tag ──────────────────────────────────────────────────
                    DetailCard(
                        icon      = Icons.Default.Label,
                        title     = "Category",
                        content   = screenshot!!.tag,
                        iconColor = Secondary
                    )
                    Spacer(modifier = Modifier.height(12.dp))

                    // ── Captured on ──────────────────────────────────────────
                    DetailCard(
                        icon      = Icons.Default.Schedule,
                        title     = "Captured On",
                        content   = dateFormat.format(Date(screenshot!!.createdAt)),
                        iconColor = Tertiary
                    )

                    // ── Extracted text ───────────────────────────────────────
                    if (screenshot!!.extractedText.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(12.dp))
                        DetailCard(
                            icon      = Icons.Default.Description,
                            title     = "Extracted Text (OCR)",
                            content   = screenshot!!.extractedText,
                            iconColor = Outline
                        )
                    }

                    Spacer(modifier = Modifier.height(32.dp))
                }
            }
        } else {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = Primary)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun DetailCard(
    icon: ImageVector,
    title: String,
    content: String,
    iconColor: Color
) {
    Card(
        shape     = RadiusCard,
        colors    = CardDefaults.cardColors(containerColor = SurfaceContainerLowest),
        border    = androidx.compose.foundation.BorderStroke(1.dp, OutlineVariant),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        modifier  = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .clip(RadiusMd)
                        .background(iconColor.copy(alpha = 0.12f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector        = icon,
                        contentDescription = title,
                        tint               = iconColor,
                        modifier           = Modifier.size(18.dp)
                    )
                }
                Spacer(modifier = Modifier.width(10.dp))
                Text(
                    text  = title,
                    style = MaterialTheme.typography.labelLarge,
                    color = OnSurfaceVariant
                )
            }
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text  = content,
                style = MaterialTheme.typography.bodyMedium,
                color = OnSurface
            )
        }
    }
}
