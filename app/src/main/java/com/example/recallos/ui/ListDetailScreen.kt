package com.example.recallos.ui

import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.staggeredgrid.LazyVerticalStaggeredGrid
import androidx.compose.foundation.lazy.staggeredgrid.StaggeredGridCells
import androidx.compose.foundation.lazy.staggeredgrid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import com.example.recallos.data.ScreenshotEntity

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
        modifier = modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = { Text(listName) },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { showAddSheet = true }) {
                        Icon(Icons.Default.Add, contentDescription = "Add Screenshots")
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (screenshots.isEmpty()) {
                Text(
                    text = "No screenshots here yet.\nTap + to add some.",
                    color = Color.Gray,
                    modifier = Modifier.align(Alignment.Center)
                )
            } else {
                LazyVerticalStaggeredGrid(
                    columns = StaggeredGridCells.Adaptive(150.dp),
                    modifier = Modifier.fillMaxSize().padding(horizontal = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalItemSpacing = 8.dp
                ) {
                    items(screenshots, key = { it.id }) { item ->
                        StaggeredScreenshotCard(item)
                    }
                }
            }
        }
    }

    if (showAddSheet) {
        ModalBottomSheet(
            onDismissRequest = { showAddSheet = false },
            modifier = Modifier.fillMaxHeight(0.9f)
        ) {
            AddScreenshotsSheet(
                listId = listId,
                viewModel = viewModel,
                onDismiss = { showAddSheet = false }
            )
        }
    }
}

@Composable
fun StaggeredScreenshotCard(item: ScreenshotEntity) {
    // A StaggeredGrid will adapt height based on the content's aspect ratio.
    // We don't fix the height here, just let Coil load and proportion it.
    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        modifier = Modifier.fillMaxWidth()
    ) {
        AsyncImage(
            model = Uri.parse(item.uri),
            contentDescription = "Screenshot Preview",
            modifier = Modifier.fillMaxWidth().wrapContentHeight(),
            contentScale = ContentScale.FillWidth
        )
    }
}

@Composable
fun AddScreenshotsSheet(
    listId: Long,
    viewModel: ListsViewModel,
    onDismiss: () -> Unit
) {
    val allScreenshots by viewModel.allScreenshots.collectAsState()
    val listScreenshots by viewModel.getScreenshotsForList(listId).collectAsState(initial = emptyList())
    
    val listScreenshotIds = remember(listScreenshots) { listScreenshots.map { it.id }.toSet() }

    Column(
        modifier = Modifier.fillMaxSize().padding(16.dp)
    ) {
        Text(
            text = "Add Screenshots",
            style = MaterialTheme.typography.titleLarge,
            modifier = Modifier.padding(bottom = 16.dp)
        )

        LazyVerticalGrid(
            columns = GridCells.Fixed(3),
            modifier = Modifier.weight(1f),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            items(allScreenshots, key = { it.id }) { item ->
                val isSelected = listScreenshotIds.contains(item.id)
                val isSelectPending = remember { mutableStateOf(isSelected) }

                Box(
                    modifier = Modifier
                        .aspectRatio(1f)
                        .clip(RoundedCornerShape(8.dp))
                        .clickable {
                            if (isSelected) {
                                viewModel.removeScreenshotFromList(listId, item.id)
                            } else {
                                viewModel.addScreenshotToList(listId, item.id)
                            }
                        }
                ) {
                    AsyncImage(
                        model = Uri.parse(item.uri),
                        contentDescription = null,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop,
                        alpha = if (isSelected) 0.5f else 1f
                    )
                    if (isSelected) {
                        Icon(
                            Icons.Default.CheckCircle,
                            contentDescription = "Selected",
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier
                                .align(Alignment.TopEnd)
                                .padding(4.dp)
                                .size(24.dp)
                        )
                    }
                }
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        Button(
            onClick = onDismiss,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Done")
        }
        Spacer(modifier = Modifier.height(32.dp))
    }
}
