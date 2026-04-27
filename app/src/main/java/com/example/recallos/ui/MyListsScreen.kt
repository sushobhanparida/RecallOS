package com.example.recallos.ui

import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import com.example.recallos.data.ListEntity
import com.example.recallos.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MyListsScreen(
    onListClick: (Long) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: ListsViewModel = viewModel()
) {
    val lists by viewModel.lists.collectAsState()
    var showCreateDialog by remember { mutableStateOf(false) }
    var newListName      by remember { mutableStateOf("") }

    Scaffold(
        modifier       = modifier.fillMaxSize(),
        containerColor = MaterialTheme.colorScheme.background,
        floatingActionButton = {
            FloatingActionButton(
                onClick        = { showCreateDialog = true },
                containerColor = Primary,
                contentColor   = OnPrimary,
                shape          = RadiusFull
            ) {
                Icon(Icons.Default.Add, contentDescription = "Create Stack")
            }
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 16.dp, vertical = 24.dp)
        ) {
            Text(
                text     = "Stacks",
                style    = MaterialTheme.typography.headlineMedium,
                color    = OnSurface,
                modifier = Modifier.padding(start = 4.dp, bottom = 20.dp)
            )

            if (lists.isEmpty()) {
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
                                imageVector        = Icons.Default.PhotoLibrary,
                                contentDescription = null,
                                modifier           = Modifier.size(36.dp),
                                tint               = OnSurfaceVariant
                            )
                        }
                        Spacer(modifier = Modifier.height(20.dp))
                        Text(
                            "No stacks yet",
                            style = MaterialTheme.typography.headlineSmall,
                            color = OnSurface
                        )
                        Text(
                            "Tap + to create your first stack",
                            style    = MaterialTheme.typography.bodyMedium,
                            color    = OnSurfaceVariant,
                            modifier = Modifier.padding(top = 6.dp)
                        )
                    }
                }
            } else {
                LazyVerticalGrid(
                    columns               = GridCells.Fixed(2),
                    modifier              = Modifier.fillMaxSize(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement   = Arrangement.spacedBy(16.dp),
                    contentPadding        = PaddingValues(bottom = 80.dp)
                ) {
                    items(lists) { listEntity ->
                        StackAlbumItem(
                            listEntity = listEntity,
                            viewModel  = viewModel,
                            onClick    = { onListClick(listEntity.id) }
                        )
                    }
                }
            }
        }
    }

    // ── Create Stack dialog ──────────────────────────────────────────────────
    if (showCreateDialog) {
        AlertDialog(
            onDismissRequest = { showCreateDialog = false },
            containerColor   = SurfaceContainerLowest,
            shape            = RadiusCard,
            title = {
                Text(
                    "New Stack",
                    style = MaterialTheme.typography.titleLarge,
                    color = OnSurface
                )
            },
            text = {
                TextField(
                    value         = newListName,
                    onValueChange = { newListName = it },
                    placeholder   = { Text("Stack name") },
                    singleLine    = true,
                    shape         = RadiusLg,
                    modifier      = Modifier.fillMaxWidth(),
                    colors        = TextFieldDefaults.colors(
                        focusedContainerColor   = SurfaceContainerLow,
                        unfocusedContainerColor = SurfaceContainerLow,
                        focusedIndicatorColor   = Color.Transparent,
                        unfocusedIndicatorColor = Color.Transparent,
                        cursorColor             = Primary
                    )
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (newListName.isNotBlank()) viewModel.createList(newListName.trim())
                        showCreateDialog = false
                        newListName = ""
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Primary),
                    shape  = RadiusMd
                ) { Text("Create") }
            },
            dismissButton = {
                TextButton(onClick = { showCreateDialog = false }) {
                    Text("Cancel", color = OnSurfaceVariant)
                }
            }
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google Photos–style album card: full-cover image + gradient + name below
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun StackAlbumItem(
    listEntity: ListEntity,
    viewModel: ListsViewModel,
    onClick: () -> Unit
) {
    val coverUris by viewModel.getCoverUrisForList(listEntity.id)
        .collectAsState(initial = emptyList())
    val count by viewModel.getCountForList(listEntity.id)
        .collectAsState(initial = 0)

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
    ) {
        // ── Cover thumbnail ──────────────────────────────────────────────────
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(1f)
                .clip(RadiusCard)
        ) {
            if (coverUris.isEmpty()) {
                Box(
                    modifier         = Modifier
                        .fillMaxSize()
                        .background(SurfaceContainerHigh),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector        = Icons.Default.PhotoLibrary,
                        contentDescription = null,
                        modifier           = Modifier.size(36.dp),
                        tint               = OutlineVariant
                    )
                }
            } else {
                AsyncImage(
                    model              = Uri.parse(coverUris[0]),
                    contentDescription = null,
                    modifier           = Modifier.fillMaxSize(),
                    contentScale       = ContentScale.Crop
                )
                // Bottom gradient scrim
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(64.dp)
                        .align(Alignment.BottomCenter)
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.52f))
                            )
                        )
                )
                // Photo count badge
                if (count > 0) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.BottomEnd)
                            .padding(8.dp)
                            .clip(RadiusFull)
                            .background(Color.Black.copy(alpha = 0.52f))
                            .padding(horizontal = 8.dp, vertical = 3.dp)
                    ) {
                        Text(
                            text  = "$count",
                            style = MaterialTheme.typography.labelSmall,
                            color = OnPrimary
                        )
                    }
                }
            }
        }

        // ── Name + count ─────────────────────────────────────────────────────
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text     = listEntity.name,
            style    = MaterialTheme.typography.titleSmall,
            color    = OnSurface,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
        Text(
            text  = if (count == 1) "1 screenshot" else "$count screenshots",
            style = MaterialTheme.typography.labelSmall,
            color = OnSurfaceVariant
        )
    }
}
