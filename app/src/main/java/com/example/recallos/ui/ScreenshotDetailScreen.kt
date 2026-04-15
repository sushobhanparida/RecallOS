package com.example.recallos.ui

import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
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
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
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
    val todo by viewModel.todoState.collectAsState()

    val dateFormat = SimpleDateFormat("MMMM d'th', yyyy 'at' h:mm a", Locale.getDefault())

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Details", fontWeight = FontWeight.SemiBold) },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color(0xFFFAFAFA)
                )
            )
        },
        containerColor = Color(0xFFFAFAFA)
    ) { innerPadding ->
        if (screenshot != null) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .verticalScroll(rememberScrollState())
            ) {
                // Hero Image
                AsyncImage(
                    model = Uri.parse(screenshot!!.uri),
                    contentDescription = "Full Screenshot",
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(max = 400.dp)
                        .background(Color.Black),
                    contentScale = ContentScale.Fit
                )

                Spacer(modifier = Modifier.height(24.dp))

                Column(modifier = Modifier.padding(horizontal = 16.dp)) {

                    // Associated Task
                    if (todo != null) {
                        MetadataCard(
                            icon = Icons.Default.Assignment,
                            title = "Associated Task",
                            content = todo!!.title,
                            iconTint = Color(0xFFC3C5F1)
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                    }

                    // Classification & Timing
                    MetadataCard(
                        icon = Icons.Default.Label,
                        title = "Tag Classification",
                        content = screenshot!!.tag,
                        iconTint = Color(0xFFE5B5B5)
                    )
                    Spacer(modifier = Modifier.height(16.dp))

                    MetadataCard(
                        icon = Icons.Default.Schedule,
                        title = "Captured On",
                        content = dateFormat.format(Date(screenshot!!.createdAt)),
                        iconTint = Color.Gray
                    )
                    Spacer(modifier = Modifier.height(16.dp))

                    // Extracted Text
                    if (screenshot!!.extractedText.isNotEmpty()) {
                        MetadataCard(
                            icon = Icons.Default.Description,
                            title = "Extracted Text (OCR)",
                            content = screenshot!!.extractedText,
                            iconTint = Color(0xFF86EFAC)
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(32.dp))
                }
            }
        } else {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        }
    }
}

@Composable
fun MetadataCard(
    icon: ImageVector,
    title: String,
    content: String,
    iconTint: Color
) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp), // flat modern look
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = icon,
                    contentDescription = title,
                    tint = iconTint,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = title,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.DarkGray
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = content,
                fontSize = 16.sp,
                color = Color.Black,
                lineHeight = 22.sp
            )
        }
    }
}
