package com.example.recallos.ui

import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.staggeredgrid.LazyVerticalStaggeredGrid
import androidx.compose.foundation.lazy.staggeredgrid.StaggeredGridCells
import androidx.compose.foundation.lazy.staggeredgrid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import com.example.recallos.data.ScreenshotEntity
import com.example.recallos.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ListDetailScreen(
    listId: Long,
    listName: String,
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: ListsViewModel = viewModel()
) {
    val screenshots by viewModel.getScreenshotsForList(listId).collectAsState(initial = emptyList())
    var showAddSheet by remember { mutableStateOf(false) }

    Scaffold(
        modifier       = modifier.fillMaxSize(),
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        listName,
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
                actions = {
                    FilledTonalIconButton(
                        onClick = { showAddSheet = true },
                        colors  = IconButtonDefaults.filledTonalIconButtonColors(
                            containerColor = PrimaryContainer,
                            contentColor   = Primary
                        )
                    ) {
                        Icon(Icons.Default.Add, contentDescription = "Add Screenshots")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (screenshots.isEmpty()) {
                Column(
                    modifier            = Modifier.align(Alignment.Center),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Box(
                        modifier = Modifier
                            .size(80.dp)
                            .clip(RadiusFull)
                            .background(SurfaceContainerHigh),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector        = Icons.Default.PhotoLibrary,
                            contentDescription = null,
                            modifier           = Modifier.size(36.dp),
                            tint               = OnSurfaceVariant
                        )
                    }
                    Spacer(modifier = Modifier.height(20.dp))
                    Text(
                        "This stack is empty",
                        style     = MaterialTheme.typography.headlineSmall,
                        color     = OnSurface,
                        textAlign = TextAlign.Center
                    )
                    Text(
                        "Tap + to add screenshots",
                        style     = MaterialTheme.typography.bodyMedium,
                        color     = OnSurfaceVariant,
                        modifier  = Modifier.padding(top = 6.dp),
                        textAlign = TextAlign.Center
                    )
                }
            } else {
                // Staggered grid — images at their natural aspect ratio
                LazyVerticalStaggeredGrid(
                    columns               = StaggeredGridCells.Fixed(2),
                    modifier              = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 12.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalItemSpacing   = 8.dp,
                    contentPadding        = PaddingValues(top = 12.dp, bottom = 80.dp)
                ) {
                    items(screenshots, key = { it.id }) { item ->
                        StackThumbnail(item)
                    }
                }
            }
        }
    }

    if (showAddSheet) {
        ModalBottomSheet(
            onDismissRequest = { showAddSheet = false },
            containerColor   = MaterialTheme.colorScheme.background,
            modifier         = Modifier.fillMaxHeight(0.92f),
            shape            = RadiusSheetTop,
            dragHandle = {
                Box(
                    modifier = Modifier
                        .padding(top = 14.dp, bottom = 8.dp)
                        .size(width = 36.dp, height = 4.dp)
                        .clip(RadiusFull)
                        .background(OutlineVariant)
                )
            }
        ) {
            AddScreenshotsSheet(
                listId    = listId,
                viewModel = viewModel,
                onDismiss = { showAddSheet = false }
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bare thumbnail — no Card wrapper, just a clipped image
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun StackThumbnail(item: ScreenshotEntity) {
    AsyncImage(
        model              = Uri.parse(item.uri),
        contentDescription = "Screenshot",
        modifier           = Modifier
            .fillMaxWidth()
            .wrapContentHeight()
            .clip(RadiusLg),
        contentScale = ContentScale.FillWidth
    )
}

// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun AddScreenshotsSheet(
    listId: Long,
    viewModel: ListsViewModel,
    onDismiss: () -> Unit
) {
    val allScreenshots  by viewModel.allScreenshots.collectAsState()
    val listScreenshots by viewModel.getScreenshotsForList(listId).collectAsState(initial = emptyList())
    val listIds = remember(listScreenshots) { listScreenshots.map { it.id }.toSet() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 20.dp)
    ) {
        Text(
            text     = "Add Screenshots",
            style    = MaterialTheme.typography.titleLarge,
            color    = OnSurface,
            modifier = Modifier.padding(bottom = 16.dp)
        )

        LazyVerticalGrid(
            columns               = GridCells.Fixed(3),
            modifier              = Modifier.weight(1f),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalArrangement   = Arrangement.spacedBy(6.dp)
        ) {
            items(allScreenshots, key = { it.id }) { item ->
                val isSelected = listIds.contains(item.id)

                Box(
                    modifier = Modifier
                        .aspectRatio(9f / 16f)
                        .clip(RadiusMd)
                        .clickable {
                            if (isSelected) viewModel.removeScreenshotFromList(listId, item.id)
                            else viewModel.addScreenshotToList(listId, item.id)
                        }
                ) {
                    AsyncImage(
                        model              = Uri.parse(item.uri),
                        contentDescription = null,
                        modifier           = Modifier.fillMaxSize(),
                        contentScale       = ContentScale.Crop,
                        alpha              = if (isSelected) 0.55f else 1f
                    )
                    if (isSelected) {
                        Box(
                            modifier = Modifier
                                .align(Alignment.TopEnd)
                                .padding(5.dp)
                                .size(22.dp)
                                .clip(RadiusFull)
                                .background(Primary),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                Icons.Default.CheckCircle,
                                contentDescription = "Selected",
                                tint     = OnPrimary,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))
        Button(
            onClick  = onDismiss,
            modifier = Modifier.fillMaxWidth(),
            colors   = ButtonDefaults.buttonColors(containerColor = Primary),
            shape    = RadiusMd
        ) { Text("Done") }
        Spacer(modifier = Modifier.height(32.dp))
    }
}
