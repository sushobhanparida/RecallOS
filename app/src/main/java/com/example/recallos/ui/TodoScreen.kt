package com.example.recallos.ui

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Alarm
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import com.example.recallos.data.TodoEntity
import com.example.recallos.ui.theme.*
import java.text.SimpleDateFormat
import java.util.*

// ─────────────────────────────────────────────────────────────────────────────
// Data passed from notification "Add to Task" tap
// ─────────────────────────────────────────────────────────────────────────────
data class PendingTaskData(
    val screenshotId: Long,
    val screenshotUri: String,
    val titleHint: String,
    val dueDate: Long?,
    val isEvent: Boolean
)

// ─────────────────────────────────────────────────────────────────────────────
// Main To-Do Screen
// ─────────────────────────────────────────────────────────────────────────────
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TodoScreen(
    viewModel: TodoViewModel = viewModel(),
    onTodoClick: (Long) -> Unit = {},
    pendingTask: PendingTaskData? = null,
    onPendingTaskConsumed: () -> Unit = {}
) {
    val morningTodos   by viewModel.morningTodos.collectAsState()
    val afternoonTodos by viewModel.afternoonTodos.collectAsState()
    val anytimeTodos   by viewModel.anytimeTodos.collectAsState()
    val eventTodos     by viewModel.eventTodos.collectAsState()

    var showDialog         by remember { mutableStateOf(false) }
    var editingTodo        by remember { mutableStateOf<TodoEntity?>(null) }
    var showAddToTaskSheet by remember { mutableStateOf(false) }
    var sheetData          by remember { mutableStateOf<PendingTaskData?>(null) }

    LaunchedEffect(pendingTask) {
        if (pendingTask != null) {
            sheetData = pendingTask
            showAddToTaskSheet = true
            onPendingTaskConsumed()
        }
    }

    val currentDate = Date()
    val dayFormat   = SimpleDateFormat("EEEE", Locale.getDefault())
    val dateFormat  = SimpleDateFormat("MMMM d, yyyy", Locale.getDefault())
    val isAllEmpty  = morningTodos.isEmpty() && afternoonTodos.isEmpty() &&
                      anytimeTodos.isEmpty() && eventTodos.isEmpty()

    if (showDialog) {
        AddEditTodoDialog(
            todo      = editingTodo,
            onDismiss = { showDialog = false },
            onSave    = { viewModel.saveTodo(it); showDialog = false }
        )
    }
    if (showAddToTaskSheet && sheetData != null) {
        AddToTaskSheet(
            data      = sheetData!!,
            onDismiss = { showAddToTaskSheet = false; sheetData = null },
            onSave    = { viewModel.saveTodo(it); showAddToTaskSheet = false; sheetData = null }
        )
    }

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(
                onClick        = { editingTodo = null; showDialog = true },
                containerColor = Primary,
                contentColor   = OnPrimary,
                shape          = RadiusFull
            ) {
                Icon(Icons.Default.Add, contentDescription = "Add Task")
            }
        },
        containerColor = MaterialTheme.colorScheme.background
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(top = 32.dp, start = 20.dp, end = 20.dp)
        ) {
            // ── Date header ─────────────────────────────────────────────────
            Text(
                text  = dayFormat.format(currentDate),
                style = MaterialTheme.typography.headlineLarge,
                color = OnSurface
            )
            Text(
                text     = dateFormat.format(currentDate),
                style    = MaterialTheme.typography.bodyMedium,
                color    = OnSurfaceVariant,
                modifier = Modifier.padding(top = 2.dp, bottom = 28.dp)
            )

            if (isAllEmpty) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Box(
                            modifier = Modifier
                                .size(72.dp)
                                .clip(RadiusFull)
                                .background(SurfaceContainerHigh),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                Icons.Default.CheckCircle,
                                contentDescription = null,
                                modifier = Modifier.size(32.dp),
                                tint     = Primary.copy(alpha = 0.6f)
                            )
                        }
                        Spacer(modifier = Modifier.height(20.dp))
                        Text(
                            "You're all caught up!",
                            style = MaterialTheme.typography.headlineSmall,
                            color = OnSurface
                        )
                        Text(
                            "Tap + to add a task",
                            style    = MaterialTheme.typography.bodyMedium,
                            color    = OnSurfaceVariant,
                            modifier = Modifier.padding(top = 8.dp)
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier       = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(bottom = 80.dp)
                ) {
                    item {
                        TodoSection(
                            title            = "Events",
                            todos            = eventTodos,
                            sectionColor     = Primary,
                            isEventSection   = true,
                            onToggleComplete = { viewModel.toggleComplete(it) },
                            onSetReminder    = { viewModel.setReminder(it) },
                            onTodoClick      = onTodoClick,
                            onEdit           = { editingTodo = it; showDialog = true },
                            onDelete         = { viewModel.deleteTodo(it) }
                        )
                    }
                    item { if (eventTodos.isNotEmpty()) Spacer(Modifier.height(20.dp)) }
                    item {
                        TodoSection(
                            title            = "Anytime",
                            todos            = anytimeTodos,
                            sectionColor     = Tertiary,
                            onToggleComplete = { viewModel.toggleComplete(it) },
                            onSetReminder    = { viewModel.setReminder(it) },
                            onTodoClick      = onTodoClick,
                            onEdit           = { editingTodo = it; showDialog = true },
                            onDelete         = { viewModel.deleteTodo(it) }
                        )
                    }
                    item { Spacer(Modifier.height(20.dp)) }
                    item {
                        TodoSection(
                            title            = "Morning",
                            todos            = morningTodos,
                            sectionColor     = Secondary,
                            onToggleComplete = { viewModel.toggleComplete(it) },
                            onSetReminder    = { viewModel.setReminder(it) },
                            onTodoClick      = onTodoClick,
                            onEdit           = { editingTodo = it; showDialog = true },
                            onDelete         = { viewModel.deleteTodo(it) }
                        )
                    }
                    item { Spacer(Modifier.height(20.dp)) }
                    item {
                        TodoSection(
                            title            = "Afternoon",
                            todos            = afternoonTodos,
                            sectionColor     = Primary,
                            onToggleComplete = { viewModel.toggleComplete(it) },
                            onSetReminder    = { viewModel.setReminder(it) },
                            onTodoClick      = onTodoClick,
                            onEdit           = { editingTodo = it; showDialog = true },
                            onDelete         = { viewModel.deleteTodo(it) }
                        )
                    }
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section — simple text label + thin divider (no pill badge)
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun TodoSection(
    title: String,
    todos: List<TodoEntity>,
    sectionColor: Color,
    isEventSection: Boolean = false,
    onToggleComplete: (TodoEntity) -> Unit,
    onSetReminder: (TodoEntity) -> Unit,
    onTodoClick: (Long) -> Unit,
    onEdit: (TodoEntity) -> Unit,
    onDelete: (TodoEntity) -> Unit
) {
    if (todos.isEmpty()) return

    Column {
        // ── Section header ───────────────────────────────────────────────────
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier          = Modifier
                .fillMaxWidth()
                .padding(bottom = 8.dp)
        ) {
            if (isEventSection) {
                Icon(
                    imageVector        = Icons.Default.CalendarMonth,
                    contentDescription = null,
                    tint               = sectionColor,
                    modifier           = Modifier.size(15.dp)
                )
                Spacer(modifier = Modifier.width(6.dp))
            }
            Text(
                text  = title.uppercase(),
                style = MaterialTheme.typography.labelMedium,
                color = sectionColor
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text  = "${todos.size}",
                style = MaterialTheme.typography.labelMedium,
                color = sectionColor.copy(alpha = 0.55f)
            )
            Spacer(modifier = Modifier.weight(1f))
        }
        HorizontalDivider(
            modifier  = Modifier.padding(bottom = 10.dp),
            color     = OutlineVariant.copy(alpha = 0.6f),
            thickness = 0.5.dp
        )

        // ── Task rows ────────────────────────────────────────────────────────
        todos.forEach { todo ->
            TodoItemRow(
                todo             = todo,
                isEventSection   = isEventSection,
                onToggleComplete = { onToggleComplete(todo) },
                onSetReminder    = { onSetReminder(todo) },
                onClick          = { onTodoClick(todo.screenshotId) },
                onEdit           = { onEdit(todo) },
                onDelete         = { onDelete(todo) }
            )
            Spacer(modifier = Modifier.height(8.dp))
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual row — elevated Card (no visible border)
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun TodoItemRow(
    todo: TodoEntity,
    isEventSection: Boolean = false,
    onToggleComplete: () -> Unit,
    onSetReminder: () -> Unit,
    onClick: () -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    val dueDateStr = todo.dueDate?.let {
        SimpleDateFormat("MMM d, h:mm a", Locale.getDefault()).format(Date(it))
    }

    Card(
        shape     = RadiusXl,
        colors    = CardDefaults.cardColors(containerColor = SurfaceContainerLowest),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        modifier  = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
    ) {
        Row(
            modifier          = Modifier.padding(horizontal = 14.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Screenshot thumbnail
            if (todo.screenshotUri.isNotEmpty()) {
                AsyncImage(
                    model              = Uri.parse(todo.screenshotUri),
                    contentDescription = "Thumbnail",
                    modifier           = Modifier
                        .size(44.dp)
                        .clip(RadiusMd),
                    contentScale = ContentScale.Crop
                )
                Spacer(modifier = Modifier.width(12.dp))
            }

            // Title + subtitle
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text  = todo.title,
                    style = MaterialTheme.typography.titleSmall,
                    color = if (todo.isCompleted) OnSurfaceVariant else OnSurface
                )
                Spacer(modifier = Modifier.height(2.dp))
                if (isEventSection && dueDateStr != null) {
                    Text(
                        text  = dueDateStr,
                        style = MaterialTheme.typography.labelSmall,
                        color = Primary
                    )
                } else if (!isEventSection) {
                    Text(
                        text  = todo.duration,
                        style = MaterialTheme.typography.labelSmall,
                        color = OnSurfaceVariant
                    )
                }
            }

            // Event badge OR task actions
            if (isEventSection) {
                Box(
                    modifier = Modifier
                        .clip(RadiusMd)
                        .background(PrimaryContainer)
                        .padding(horizontal = 8.dp, vertical = 6.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Default.CalendarMonth,
                        contentDescription = "Event",
                        tint     = Primary,
                        modifier = Modifier.size(16.dp)
                    )
                }
            } else {
                if (todo.dueDate != null && !todo.isReminded && !todo.isCompleted) {
                    IconButton(onClick = onSetReminder, modifier = Modifier.size(36.dp)) {
                        Icon(
                            Icons.Default.Alarm,
                            contentDescription = "Set Reminder",
                            tint     = Secondary,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
                IconButton(onClick = onToggleComplete, modifier = Modifier.size(36.dp)) {
                    Icon(
                        imageVector        = if (todo.isCompleted) Icons.Default.CheckCircle
                                            else Icons.Outlined.Circle,
                        contentDescription = "Toggle Complete",
                        tint               = if (todo.isCompleted) Primary else OutlineVariant,
                        modifier           = Modifier.size(24.dp)
                    )
                }
            }

            // Overflow menu
            Box {
                IconButton(onClick = { expanded = true }, modifier = Modifier.size(36.dp)) {
                    Icon(
                        Icons.Default.MoreVert,
                        contentDescription = "More",
                        tint     = OnSurfaceVariant,
                        modifier = Modifier.size(18.dp)
                    )
                }
                DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                    DropdownMenuItem(text = { Text("Edit") },   onClick = { expanded = false; onEdit() })
                    DropdownMenuItem(text = { Text("Delete") }, onClick = { expanded = false; onDelete() })
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Manual add / edit dialog
// ─────────────────────────────────────────────────────────────────────────────
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditTodoDialog(
    todo: TodoEntity?,
    onDismiss: () -> Unit,
    onSave: (TodoEntity) -> Unit
) {
    var title    by remember { mutableStateOf(todo?.title ?: "") }
    var duration by remember { mutableStateOf(todo?.duration ?: "15m") }
    var category by remember { mutableStateOf(todo?.category ?: "Anytime") }

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor   = SurfaceContainerLowest,
        shape            = RadiusCard,
        title = {
            Text(
                if (todo == null) "New Task" else "Edit Task",
                style = MaterialTheme.typography.titleLarge,
                color = OnSurface
            )
        },
        text = {
            Column {
                TextField(
                    value         = title,
                    onValueChange = { title = it },
                    placeholder   = { Text("Task title") },
                    modifier      = Modifier.fillMaxWidth(),
                    shape         = RadiusLg,
                    singleLine    = true,
                    colors        = TextFieldDefaults.colors(
                        focusedContainerColor   = SurfaceContainerLow,
                        unfocusedContainerColor = SurfaceContainerLow,
                        focusedIndicatorColor   = Color.Transparent,
                        unfocusedIndicatorColor = Color.Transparent,
                        cursorColor             = Primary
                    )
                )
                Spacer(modifier = Modifier.height(12.dp))
                TextField(
                    value         = duration,
                    onValueChange = { duration = it },
                    placeholder   = { Text("Duration, e.g. 15m") },
                    modifier      = Modifier.fillMaxWidth(),
                    shape         = RadiusLg,
                    singleLine    = true,
                    colors        = TextFieldDefaults.colors(
                        focusedContainerColor   = SurfaceContainerLow,
                        unfocusedContainerColor = SurfaceContainerLow,
                        focusedIndicatorColor   = Color.Transparent,
                        unfocusedIndicatorColor = Color.Transparent,
                        cursorColor             = Primary
                    )
                )
                Spacer(modifier = Modifier.height(12.dp))
                Row(
                    modifier              = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("Morning", "Afternoon", "Anytime").forEach { cat ->
                        FilterChip(
                            selected = category == cat,
                            onClick  = { category = cat },
                            label    = { Text(cat, style = MaterialTheme.typography.labelMedium) },
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
                                selected            = category == cat
                            )
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (title.isNotEmpty()) {
                        val entity = todo?.copy(title = title, duration = duration, category = category)
                            ?: TodoEntity(
                                screenshotId  = -1,
                                screenshotUri = "",
                                title         = title,
                                category      = category,
                                duration      = duration
                            )
                        onSave(entity)
                    }
                },
                colors = ButtonDefaults.buttonColors(containerColor = Primary),
                shape  = RadiusMd
            ) { Text("Save") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel", color = OnSurfaceVariant)
            }
        }
    )
}

// ─────────────────────────────────────────────────────────────────────────────
// "Add to Task" bottom sheet — launched from notification
// ─────────────────────────────────────────────────────────────────────────────
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddToTaskSheet(
    data: PendingTaskData,
    onDismiss: () -> Unit,
    onSave: (TodoEntity) -> Unit
) {
    val context = LocalContext.current

    var title     by remember { mutableStateOf(data.titleHint.ifBlank { "" }) }
    var isEvent   by remember { mutableStateOf(data.isEvent) }
    var category  by remember { mutableStateOf(if (data.isEvent) "Event" else "Anytime") }
    var duration  by remember { mutableStateOf("15m") }
    var notifyOpt by remember { mutableStateOf("On the day") }

    val initial = Calendar.getInstance().apply {
        if (data.dueDate != null) timeInMillis = data.dueDate
    }
    var selectedCal by remember { mutableStateOf(initial) }

    val dateLabel = SimpleDateFormat("MMM d, yyyy", Locale.getDefault()).format(selectedCal.time)
    val timeLabel = SimpleDateFormat("h:mm a",      Locale.getDefault()).format(selectedCal.time)

    val notifyOptions   = listOf("None", "On the day", "Night before", "1 hour before", "30 min before")
    val durationOptions = listOf("5m", "15m", "30m", "1h", "2h")

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor   = MaterialTheme.colorScheme.background,
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
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 40.dp)
        ) {
            // Header
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier          = Modifier.padding(bottom = 20.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(RadiusMd)
                        .background(if (isEvent) SecondaryContainer else PrimaryContainer),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        if (isEvent) Icons.Default.CalendarMonth else Icons.Default.CheckCircle,
                        contentDescription = null,
                        tint     = if (isEvent) Secondary else Primary,
                        modifier = Modifier.size(20.dp)
                    )
                }
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text  = if (isEvent) "New Event" else "New Task",
                    style = MaterialTheme.typography.titleLarge,
                    color = OnSurface
                )
            }

            // Title field
            TextField(
                value         = title,
                onValueChange = { title = it },
                placeholder   = { Text(if (isEvent) "Event name" else "Task name") },
                modifier      = Modifier.fillMaxWidth(),
                singleLine    = true,
                shape         = RadiusLg,
                colors        = TextFieldDefaults.colors(
                    focusedContainerColor   = SurfaceContainerLow,
                    unfocusedContainerColor = SurfaceContainerLow,
                    focusedIndicatorColor   = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent,
                    cursorColor             = Primary
                )
            )

            Spacer(modifier = Modifier.height(14.dp))

            // Date + Time row
            Row(
                modifier              = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                OutlinedButton(
                    onClick = {
                        DatePickerDialog(
                            context,
                            { _, year, month, day ->
                                selectedCal = (selectedCal.clone() as Calendar).also {
                                    it.set(Calendar.YEAR, year)
                                    it.set(Calendar.MONTH, month)
                                    it.set(Calendar.DAY_OF_MONTH, day)
                                }
                            },
                            selectedCal.get(Calendar.YEAR),
                            selectedCal.get(Calendar.MONTH),
                            selectedCal.get(Calendar.DAY_OF_MONTH)
                        ).show()
                    },
                    modifier = Modifier.weight(1f),
                    shape    = RadiusLg,
                    border   = androidx.compose.foundation.BorderStroke(1.dp, OutlineVariant),
                    colors   = ButtonDefaults.outlinedButtonColors(contentColor = OnSurface)
                ) {
                    Icon(
                        Icons.Default.DateRange,
                        contentDescription = null,
                        modifier = Modifier.size(15.dp),
                        tint     = Primary
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(dateLabel, style = MaterialTheme.typography.labelLarge)
                }

                OutlinedButton(
                    onClick = {
                        TimePickerDialog(
                            context,
                            { _, hour, minute ->
                                selectedCal = (selectedCal.clone() as Calendar).also {
                                    it.set(Calendar.HOUR_OF_DAY, hour)
                                    it.set(Calendar.MINUTE, minute)
                                }
                            },
                            selectedCal.get(Calendar.HOUR_OF_DAY),
                            selectedCal.get(Calendar.MINUTE),
                            false
                        ).show()
                    },
                    modifier = Modifier.weight(1f),
                    shape    = RadiusLg,
                    border   = androidx.compose.foundation.BorderStroke(1.dp, OutlineVariant),
                    colors   = ButtonDefaults.outlinedButtonColors(contentColor = OnSurface)
                ) {
                    Text(timeLabel, style = MaterialTheme.typography.labelLarge)
                }
            }

            // Task-only fields
            if (!isEvent) {
                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    "Category",
                    style    = MaterialTheme.typography.labelMedium,
                    color    = OnSurfaceVariant,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("Morning", "Afternoon", "Anytime").forEach { cat ->
                        FilterChip(
                            selected = category == cat,
                            onClick  = { category = cat },
                            label    = { Text(cat, style = MaterialTheme.typography.labelMedium) },
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
                                selected            = category == cat
                            )
                        )
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                Text(
                    "Duration",
                    style    = MaterialTheme.typography.labelMedium,
                    color    = OnSurfaceVariant,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    durationOptions.forEach { d ->
                        FilterChip(
                            selected = duration == d,
                            onClick  = { duration = d },
                            label    = { Text(d, style = MaterialTheme.typography.labelMedium) },
                            colors   = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = SecondaryContainer,
                                selectedLabelColor     = OnSecondaryContainer,
                                containerColor         = SurfaceContainerLow,
                                labelColor             = OnSurfaceVariant
                            )
                        )
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                Text(
                    "Notify me",
                    style    = MaterialTheme.typography.labelMedium,
                    color    = OnSurfaceVariant,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                var notifyExpanded by remember { mutableStateOf(false) }
                ExposedDropdownMenuBox(
                    expanded         = notifyExpanded,
                    onExpandedChange = { notifyExpanded = it }
                ) {
                    OutlinedTextField(
                        value         = notifyOpt,
                        onValueChange = {},
                        readOnly      = true,
                        modifier      = Modifier.menuAnchor().fillMaxWidth(),
                        shape         = RadiusLg,
                        colors        = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor   = Primary,
                            unfocusedBorderColor = OutlineVariant
                        ),
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = notifyExpanded) }
                    )
                    ExposedDropdownMenu(
                        expanded         = notifyExpanded,
                        onDismissRequest = { notifyExpanded = false }
                    ) {
                        notifyOptions.forEach { opt ->
                            DropdownMenuItem(
                                text    = { Text(opt) },
                                onClick = { notifyOpt = opt; notifyExpanded = false }
                            )
                        }
                    }
                }
            }

            // Source screenshot thumbnail
            if (data.screenshotUri.isNotEmpty()) {
                Spacer(modifier = Modifier.height(18.dp))
                Text(
                    "From screenshot",
                    style    = MaterialTheme.typography.labelMedium,
                    color    = OnSurfaceVariant,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                AsyncImage(
                    model              = Uri.parse(data.screenshotUri),
                    contentDescription = "Source screenshot",
                    modifier           = Modifier
                        .fillMaxWidth()
                        .height(110.dp)
                        .clip(RadiusLg),
                    contentScale = ContentScale.Crop
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Actions
            Row(
                modifier              = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                TextButton(
                    onClick  = onDismiss,
                    modifier = Modifier.weight(1f)
                ) { Text("Cancel", color = OnSurfaceVariant) }

                Button(
                    onClick = {
                        if (title.isNotBlank()) {
                            onSave(
                                TodoEntity(
                                    screenshotId  = data.screenshotId,
                                    screenshotUri = data.screenshotUri,
                                    title         = title.trim(),
                                    category      = if (isEvent) "Event" else category,
                                    dueDate       = selectedCal.timeInMillis,
                                    duration      = duration,
                                    isEvent       = isEvent,
                                    notifyOption  = if (isEvent) "None" else notifyOpt
                                )
                            )
                        }
                    },
                    modifier = Modifier.weight(1f),
                    colors   = ButtonDefaults.buttonColors(containerColor = Primary),
                    shape    = RadiusMd
                ) { Text(if (isEvent) "Save Event" else "Save Task") }
            }
        }
    }
}
