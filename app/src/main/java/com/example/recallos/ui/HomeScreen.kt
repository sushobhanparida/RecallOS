package com.example.recallos.ui

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
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
import androidx.compose.ui.text.style.TextAlign
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
    ) {
        // ── Header: title + import icon button ───────────────────────────────
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 20.dp, end = 4.dp, top = 24.dp, bottom = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text     = "Screenshots",
                style    = MaterialTheme.typography.headlineMedium,
                color    = OnSurface,
                modifier = Modifier.weight(1f)
            )
            IconButton(
                onClick = {
                    photoPickerLauncher.launch(
                        PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                    )
                }
            ) {
                Icon(
                    imageVector        = Icons.Default.AddPhotoAlternate,
                    contentDescription = "Import from Gallery",
                    tint               = Primary,
                    modifier           = Modifier.size(26.dp)
                )
            }
        }

        // ── Filled pill search bar ───────────────────────────────────────────
        TextField(
            value         = searchQuery,
            onValueChange = { viewModel.setSearchQuery(it) },
            modifier      = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .padding(bottom = 10.dp),
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
                    contentDescription = null,
                    tint     = OnSurfaceVariant,
                    modifier = Modifier.size(20.dp)
                )
            },
            shape      = RadiusFull,
            singleLine = true,
            colors     = TextFieldDefaults.colors(
                focusedContainerColor     = SurfaceContainerLow,
                unfocusedContainerColor   = SurfaceContainerLow,
                focusedIndicatorColor     = Color.Transparent,
                unfocusedIndicatorColor   = Color.Transparent,
                disabledIndicatorColor    = Color.Transparent,
                cursorColor               = Primary,
                focusedLeadingIconColor   = Primary,
                unfocusedLeadingIconColor = OnSurfaceVariant
            )
        )

        // ── Category filter chips ────────────────────────────────────────────
        val tags = listOf("All", "Shopping", "Link", "Event", "Read", "General")
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState())
                .padding(start = 16.dp, end = 16.dp, bottom = 10.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            tags.forEach { tag ->
                FilterChip(
                    selected = currentFilter == tag,
                    onClick  = { viewModel.setFilter(tag) },
                    label    = { Text(tag, style = MaterialTheme.typography.labelMedium) },
                    colors   = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = Primary,
                        selectedLabelColor     = OnPrimary,
                        containerColor         = SurfaceContainerLow,
                        labelColor             = OnSurfaceVariant
                    ),
                    border = FilterChipDefaults.filterChipBorder(
                        borderColor         = Color.Transparent,
                        selectedBorderColor = Color.Transparent,
                        enabled             = true,
                        selected            = currentFilter == tag
                    )
                )
            }
        }

        // ── Import progress bar ──────────────────────────────────────────────
        if (isImporting) {
            LinearProgressIndicator(
                modifier   = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .clip(RadiusFull)
                    .padding(bottom = 8.dp),
                color      = Primary,
                trackColor = SurfaceContainerHigh
            )
        }

        // ── Screenshot grid ──────────────────────────────────────────────────
        if (screenshots.isEmpty() && !isImporting) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Box(
                        modifier = Modifier
                            .size(80.dp)
                            .clip(RadiusFull)
                            .background(SurfaceContainerHigh),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector        = Icons.Default.Image,
                            contentDescription = null,
                            modifier           = Modifier.size(36.dp),
                            tint               = OnSurfaceVariant
                        )
                    }
                    Spacer(modifier = Modifier.height(20.dp))
                    Text(
                        "No screenshots yet",
                        style = MaterialTheme.typography.headlineSmall,
                        color = OnSurface
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        "Tap ⊕ above to import from gallery",
                        style     = MaterialTheme.typography.bodyMedium,
                        color     = OnSurfaceVariant,
                        textAlign = TextAlign.Center
                    )
                }
            }
        } else {
            LazyVerticalGrid(
                columns               = GridCells.Fixed(2),
                modifier              = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement   = Arrangement.spacedBy(8.dp),
                contentPadding        = PaddingValues(bottom = 80.dp)
            ) {
                items(screenshots) { item ->
                    ScreenshotThumbnail(
                        item    = item,
                        onClick = { onScreenshotClick(item.id) }
                    )
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pure image thumbnail — no card chrome, just clipped image + tag pill overlay
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun ScreenshotThumbnail(
    item: ScreenshotEntity,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(9f / 16f)
            .clip(RadiusCard)
            .clickable { onClick() }
    ) {
        AsyncImage(
            model              = Uri.parse(item.uri),
            contentDescription = "Screenshot",
            modifier           = Modifier.fillMaxSize(),
            contentScale       = ContentScale.Crop
        )
        TagBadge(
            tag      = item.tag,
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(8.dp)
        )
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
            .clip(RadiusFull)
            .background(bgColor.copy(alpha = 0.92f))
            .padding(horizontal = 10.dp, vertical = 4.dp)
    ) {
        Text(
            text  = tag,
            color = OnPrimary,
            style = MaterialTheme.typography.labelSmall
        )
    }
}
