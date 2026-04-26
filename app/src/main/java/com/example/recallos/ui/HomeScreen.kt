package com.example.recallos.ui

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddPhotoAlternate
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import com.example.recallos.data.ScreenshotEntity
import com.example.recallos.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    modifier: Modifier = Modifier,
    viewModel: ScreenshotViewModel = viewModel(),
    onScreenshotClick: (Long) -> Unit = {}
) {
    val screenshots   = viewModel.screenshots.collectAsState().value
    val currentFilter = viewModel.currentFilter.collectAsState().value
    val searchQuery   = viewModel.searchQuery.collectAsState().value
    val isImporting   = viewModel.isImporting.collectAsState().value

    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri: Uri? ->
        uri?.let { viewModel.importScreenshot(it) }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(horizontal = 20.dp)
            .padding(top = 24.dp)
    ) {
        // ── Page title ───────────────────────────────────────────────────────
        Text(
            text = "Your Screenshots",
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.onBackground,
            modifier = Modifier.padding(bottom = 20.dp)
        )

        // ── Gallery Import Banner ────────────────────────────────────────────
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RadiusCard)
                .background(MaterialTheme.colorScheme.surface)
                .border(
                    width = 1.dp,
                    color = OutlineVariant,
                    shape = RadiusCard
                )
                .clickable {
                    photoPickerLauncher.launch(
                        PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                    )
                }
                .padding(horizontal = 20.dp, vertical = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(RadiusMd)
                    .background(SecondaryContainer),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.AddPhotoAlternate,
                    contentDescription = null,
                    tint = Secondary,
                    modifier = Modifier.size(22.dp)
                )
            }
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "Import from Gallery",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground
                )
                Text(
                    text = "Choose screenshots to add to RecallOS",
                    style = MaterialTheme.typography.bodySmall,
                    color = OnSurfaceVariant
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // ── Search ───────────────────────────────────────────────────────────
        OutlinedTextField(
            value = searchQuery,
            onValueChange = { viewModel.setSearchQuery(it) },
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 12.dp),
            placeholder = {
                Text(
                    "Search screenshots…",
                    style = MaterialTheme.typography.bodyMedium,
                    color = OnSurfaceVariant
                )
            },
            leadingIcon = {
                Icon(
                    Icons.Default.Search,
                    contentDescription = "Search",
                    tint = OnSurfaceVariant
                )
            },
            shape = RadiusLg,
            singleLine = true,
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor   = Primary,
                unfocusedBorderColor = OutlineVariant,
                cursorColor          = Primary,
                focusedLeadingIconColor = Primary
            )
        )

        // ── Tag filters ──────────────────────────────────────────────────────
        val tags = listOf("All", "Shopping", "Link", "Event", "Read", "General")
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState())
                .padding(bottom = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            tags.forEach { tag ->
                FilterChip(
                    selected = currentFilter == tag,
                    onClick  = { viewModel.setFilter(tag) },
                    label    = {
                        Text(
                            tag,
                            style = MaterialTheme.typography.labelMedium
                        )
                    },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor     = PrimaryContainer,
                        selectedLabelColor         = OnPrimaryContainer,
                        containerColor             = SurfaceContainerLow,
                        labelColor                 = OnSurfaceVariant
                    ),
                    border = FilterChipDefaults.filterChipBorder(
                        borderColor         = OutlineVariant,
                        selectedBorderColor = PrimaryContainer,
                        enabled = true,
                        selected = currentFilter == tag
                    )
                )
            }
        }

        if (isImporting) {
            LinearProgressIndicator(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RadiusFull)
                    .padding(bottom = 8.dp),
                color       = Primary,
                trackColor  = SurfaceContainerHigh
            )
        }

        // ── Screenshot grid ──────────────────────────────────────────────────
        if (screenshots.isEmpty() && !isImporting) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Box(
                        modifier = Modifier
                            .size(80.dp)
                            .clip(RadiusCard)
                            .background(SurfaceContainerHigh),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Image,
                            contentDescription = null,
                            modifier = Modifier.size(40.dp),
                            tint = OutlineVariant
                        )
                    }
                    Spacer(modifier = Modifier.height(20.dp))
                    Text(
                        text = "No screenshots yet",
                        style = MaterialTheme.typography.headlineSmall,
                        color = OnSurface
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Use \"Import from Gallery\" above\nor tap Save when you take a screenshot",
                        style = MaterialTheme.typography.bodyMedium,
                        color = OnSurfaceVariant,
                        textAlign = TextAlign.Center
                    )
                }
            }
        } else {
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                modifier = Modifier.fillMaxSize(),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement   = Arrangement.spacedBy(12.dp),
                contentPadding        = PaddingValues(bottom = 80.dp)
            ) {
                items(screenshots) { item ->
                    ScreenshotCard(
                        item    = item,
                        onClick = { onScreenshotClick(item.id) }
                    )
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun ScreenshotCard(
    item: ScreenshotEntity,
    onClick: () -> Unit = {}
) {
    Card(
        shape  = RadiusCard,
        colors = CardDefaults.cardColors(containerColor = SurfaceContainerLowest),
        border = androidx.compose.foundation.BorderStroke(1.dp, OutlineVariant),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        modifier = Modifier
            .fillMaxWidth()
            .height(220.dp)
            .clickable { onClick() }
    ) {
        Column {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(148.dp)
            ) {
                AsyncImage(
                    model              = Uri.parse(item.uri),
                    contentDescription = "Screenshot Preview",
                    modifier           = Modifier
                        .fillMaxSize()
                        .clip(RadiusCardTop),
                    contentScale = ContentScale.Crop
                )
                TagBadge(
                    tag      = item.tag,
                    modifier = Modifier.padding(10.dp)
                )
            }
            Column(modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)) {
                Text(
                    text     = item.extractedText,
                    style    = MaterialTheme.typography.bodySmall,
                    color    = OnSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun TagBadge(tag: String, modifier: Modifier = Modifier) {
    val bgColor = when (tag) {
        "Shopping" -> TagShopping
        "To Do"    -> TagToDo
        "Read"     -> TagRead
        "Link"     -> TagLink
        "Event"    -> TagEvent
        else       -> TagGeneral
    }
    Box(
        modifier = modifier
            .clip(RadiusSm)
            .background(bgColor.copy(alpha = 0.88f))
            .padding(horizontal = 8.dp, vertical = 3.dp)
    ) {
        Text(
            text  = tag,
            color = OnPrimary,   // white — text on coloured tag badge
            style = MaterialTheme.typography.labelSmall,
        )
    }
}
