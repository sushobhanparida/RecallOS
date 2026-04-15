package com.example.recallos.ui

import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
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
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import com.example.recallos.data.ListEntity
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.flowOf

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MyListsScreen(
    onListClick: (Long) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: ListsViewModel = viewModel()
) {
    val lists by viewModel.lists.collectAsState()
    var showCreateDialog by remember { mutableStateOf(false) }
    var newListName by remember { mutableStateOf("") }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        containerColor = MaterialTheme.colorScheme.background,
        floatingActionButton = {
            FloatingActionButton(onClick = { showCreateDialog = true }) {
                Icon(Icons.Default.Add, contentDescription = "Create List")
            }
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp)
        ) {
            Text(
                text = "My Lists",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 16.dp),
                color = MaterialTheme.colorScheme.onBackground
            )

            if (lists.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("No lists created yet. Tap + to create one.", color = Color.Gray)
                }
            } else {
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    modifier = Modifier.fillMaxSize(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    verticalArrangement = Arrangement.spacedBy(32.dp)
                ) {
                    items(lists) { listEntity ->
                        ListGridItem(
                            listEntity = listEntity,
                            viewModel = viewModel,
                            onClick = { onListClick(listEntity.id) }
                        )
                    }
                }
            }
        }
    }

    if (showCreateDialog) {
        AlertDialog(
            onDismissRequest = { showCreateDialog = false },
            title = { Text("Create New List") },
            text = {
                OutlinedTextField(
                    value = newListName,
                    onValueChange = { newListName = it },
                    label = { Text("List Name") },
                    singleLine = true
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    if (newListName.isNotBlank()) {
                        viewModel.createList(newListName.trim())
                    }
                    showCreateDialog = false
                    newListName = ""
                }) {
                    Text("Create")
                }
            },
            dismissButton = {
                TextButton(onClick = { showCreateDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
fun ListGridItem(
    listEntity: ListEntity,
    viewModel: ListsViewModel,
    onClick: () -> Unit
) {
    // Collect cover URIs dynamically
    val coverUris by viewModel.getCoverUrisForList(listEntity.id)
        .collectAsState(initial = emptyList())
        
    val count by viewModel.getCountForList(listEntity.id)
        .collectAsState(initial = 0)

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        LayeredCoverPreview(coverUris)
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = listEntity.name,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.Medium,
            textAlign = TextAlign.Center
        )
        Text(
            text = "$count screenshots",
            style = MaterialTheme.typography.bodySmall,
            color = Color.Gray,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
fun LayeredCoverPreview(coverUris: List<String>) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(1f)
            .padding(16.dp),
        contentAlignment = Alignment.Center
    ) {
        if (coverUris.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize(0.8f)
                    .clip(RoundedCornerShape(12.dp))
                    .background(Color.LightGray.copy(alpha = 0.5f))
            )
        } else {
            // Show up to 3 layers to recreate the effect from the reference
            val urisToDisplay = coverUris.take(3)
            
            // Background Layer (Index 2 if available, else 1, else 0)
            if (urisToDisplay.size >= 3) {
                AsyncImage(
                    model = Uri.parse(urisToDisplay[2]),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier
                        .fillMaxSize(0.7f)
                        .offset(x = (-16).dp, y = (-12).dp)
                        .rotate(-8f)
                        .clip(RoundedCornerShape(12.dp))
                        .shadow(4.dp, RoundedCornerShape(12.dp))
                        .background(Color.White)
                )
            }
            
            // Middle Layer (Index 1)
            if (urisToDisplay.size >= 2) {
                AsyncImage(
                    model = Uri.parse(urisToDisplay[1]),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier
                        .fillMaxSize(0.75f)
                        .offset(x = 16.dp, y = (-4).dp)
                        .rotate(10f)
                        .clip(RoundedCornerShape(12.dp))
                        .shadow(4.dp, RoundedCornerShape(12.dp))
                        .background(Color.White)
                )
            }
            
            // Front Layer (Index 0)
            AsyncImage(
                model = Uri.parse(urisToDisplay[0]),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .fillMaxSize(0.85f)
                    .offset(y = 8.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .shadow(8.dp, RoundedCornerShape(12.dp))
                    .background(Color.White)
            )
        }
    }
}
