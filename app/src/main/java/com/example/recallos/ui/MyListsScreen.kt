package com.example.recallos.ui

import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
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
                .padding(horizontal = 20.dp, vertical = 24.dp)
        ) {
            Text(
                text     = "My Stacks",
                style    = MaterialTheme.typography.headlineMedium,
                color    = OnSurface,
                modifier = Modifier.padding(bottom = 24.dp)
            )

            if (lists.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Box(
                            modifier = Modifier
                                .size(72.dp)
                                .clip(RadiusCard)
                                .background(SurfaceContainerHigh),
                            contentAlignment = Alignment.Center
                        ) {
                            Text("📚", style = MaterialTheme.typography.headlineLarge)
                        }
                        Spacer(modifier = Modifier.height(16.dp))
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
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    verticalArrangement   = Arrangement.spacedBy(28.dp),
                    contentPadding        = PaddingValues(bottom = 80.dp)
                ) {
                    items(lists) { listEntity ->
                        StackGridItem(
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
                    "Create New Stack",
                    style = MaterialTheme.typography.titleLarge,
                    color = OnSurface
                )
            },
            text = {
                OutlinedTextField(
                    value         = newListName,
                    onValueChange = { newListName = it },
                    label         = { Text("Stack Name") },
                    singleLine    = true,
                    shape         = RadiusLg,
                    colors        = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor   = Primary,
                        unfocusedBorderColor = OutlineVariant
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
                OutlinedButton(
                    onClick = { showCreateDialog = false },
                    shape   = RadiusMd,
                    border  = androidx.compose.foundation.BorderStroke(1.dp, OutlineVariant)
                ) { Text("Cancel", color = OnSurfaceVariant) }
            }
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun StackGridItem(
    listEntity: ListEntity,
    viewModel: ListsViewModel,
    onClick: () -> Unit
) {
    val coverUris by viewModel.getCoverUrisForList(listEntity.id)
        .collectAsState(initial = emptyList())
    val count by viewModel.getCountForList(listEntity.id)
        .collectAsState(initial = 0)

    Column(
        modifier            = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        LayeredCoverPreview(coverUris)
        Spacer(modifier = Modifier.height(12.dp))
        Text(
            text      = listEntity.name,
            style     = MaterialTheme.typography.titleMedium,
            color     = OnSurface,
            textAlign = TextAlign.Center
        )
        Text(
            text      = if (count == 1) "1 screenshot" else "$count screenshots",
            style     = MaterialTheme.typography.labelMedium,
            color     = OnSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier  = Modifier.padding(top = 2.dp)
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun LayeredCoverPreview(coverUris: List<String>) {
    Box(
        modifier            = Modifier
            .fillMaxWidth()
            .aspectRatio(1f)
            .padding(12.dp),
        contentAlignment = Alignment.Center
    ) {
        if (coverUris.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize(0.85f)
                    .clip(RadiusCard)
                    .background(SurfaceContainerHigh)
                    .border(1.dp, OutlineVariant, RadiusCard)
            )
        } else {
            val uris = coverUris.take(3)

            if (uris.size >= 3) {
                AsyncImage(
                    model              = Uri.parse(uris[2]),
                    contentDescription = null,
                    contentScale       = ContentScale.Crop,
                    modifier           = Modifier
                        .fillMaxSize(0.70f)
                        .offset(x = (-14).dp, y = (-10).dp)
                        .rotate(-7f)
                        .clip(RadiusCard)
                        .shadow(2.dp, RadiusCard)
                        .background(SurfaceContainerLowest)
                )
            }
            if (uris.size >= 2) {
                AsyncImage(
                    model              = Uri.parse(uris[1]),
                    contentDescription = null,
                    contentScale       = ContentScale.Crop,
                    modifier           = Modifier
                        .fillMaxSize(0.74f)
                        .offset(x = 14.dp, y = (-4).dp)
                        .rotate(9f)
                        .clip(RadiusCard)
                        .shadow(3.dp, RadiusCard)
                        .background(SurfaceContainerLowest)
                )
            }
            AsyncImage(
                model              = Uri.parse(uris[0]),
                contentDescription = null,
                contentScale       = ContentScale.Crop,
                modifier           = Modifier
                    .fillMaxSize(0.84f)
                    .offset(y = 6.dp)
                    .clip(RadiusCard)
                    .shadow(6.dp, RadiusCard)
                    .background(SurfaceContainerLowest)
            )
        }
    }
}
