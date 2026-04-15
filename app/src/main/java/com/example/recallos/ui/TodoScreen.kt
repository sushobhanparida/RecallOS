package com.example.recallos.ui

import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Alarm
import androidx.compose.material.icons.filled.CheckCircle
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import com.example.recallos.data.TodoEntity
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TodoScreen(
    viewModel: TodoViewModel = viewModel(),
    onTodoClick: (Long) -> Unit = {}
) {
    val morningTodos by viewModel.morningTodos.collectAsState()
    val afternoonTodos by viewModel.afternoonTodos.collectAsState()
    val anytimeTodos by viewModel.anytimeTodos.collectAsState()

    var showDialog by remember { mutableStateOf(false) }
    var editingTodo by remember { mutableStateOf<TodoEntity?>(null) }

    val currentDate = Date()
    val dayFormat = SimpleDateFormat("EEEE", Locale.getDefault())
    val dateFormat = SimpleDateFormat("MMMM d'th', yyyy", Locale.getDefault())

    val isAllEmpty = morningTodos.isEmpty() && afternoonTodos.isEmpty() && anytimeTodos.isEmpty()

    if (showDialog) {
        AddEditTodoDialog(
            todo = editingTodo,
            onDismiss = { showDialog = false },
            onSave = { updatedTodo ->
                viewModel.saveTodo(updatedTodo)
                showDialog = false
            }
        )
    }

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(
                onClick = {
                    editingTodo = null
                    showDialog = true
                },
                containerColor = Color(0xFF1E1E1E),
                contentColor = Color.White
            ) {
                Icon(Icons.Default.Add, contentDescription = "Add Todo")
            }
        },
        containerColor = Color(0xFFFAFAFA)
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(top = 48.dp, start = 16.dp, end = 16.dp)
        ) {
            // Header
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = dayFormat.format(currentDate),
                    fontSize = 32.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF1E1E1E)
                )
                Text(
                    text = dateFormat.format(currentDate),
                    fontSize = 16.sp,
                    color = Color.Gray,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }

            Spacer(modifier = Modifier.height(32.dp))

            if (isAllEmpty) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = "Empty",
                            modifier = Modifier.size(64.dp),
                            tint = Color.LightGray
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "You're all caught up!",
                            fontSize = 20.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = Color.DarkGray
                        )
                        Text(
                            text = "Tap + to add a manual task.",
                            fontSize = 14.sp,
                            color = Color.Gray,
                            modifier = Modifier.padding(top = 8.dp)
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(bottom = 80.dp)
                ) {
                    item {
                        TodoSection(
                            title = "ANYTIME",
                            todos = anytimeTodos,
                            iconTint = Color.Gray,
                            onToggleComplete = { viewModel.toggleComplete(it) },
                            onSetReminder = { viewModel.setReminder(it) },
                            onTodoClick = onTodoClick,
                            onEdit = { todo ->
                                editingTodo = todo
                                showDialog = true
                            },
                            onDelete = { viewModel.deleteTodo(it) }
                        )
                    }
                    item { Spacer(modifier = Modifier.height(16.dp)) }
                    item {
                        TodoSection(
                            title = "MORNING",
                            todos = morningTodos,
                            iconTint = Color(0xFFE5B5B5),
                            onToggleComplete = { viewModel.toggleComplete(it) },
                            onSetReminder = { viewModel.setReminder(it) },
                            onTodoClick = onTodoClick,
                            onEdit = { todo ->
                                editingTodo = todo
                                showDialog = true
                            },
                            onDelete = { viewModel.deleteTodo(it) }
                        )
                    }
                    item { Spacer(modifier = Modifier.height(16.dp)) }
                    item {
                        TodoSection(
                            title = "AFTERNOON",
                            todos = afternoonTodos,
                            iconTint = Color(0xFFC3C5F1),
                            onToggleComplete = { viewModel.toggleComplete(it) },
                            onSetReminder = { viewModel.setReminder(it) },
                            onTodoClick = onTodoClick,
                            onEdit = { todo ->
                                editingTodo = todo
                                showDialog = true
                            },
                            onDelete = { viewModel.deleteTodo(it) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun TodoSection(
    title: String,
    todos: List<TodoEntity>,
    iconTint: Color,
    onToggleComplete: (TodoEntity) -> Unit,
    onSetReminder: (TodoEntity) -> Unit,
    onTodoClick: (Long) -> Unit,
    onEdit: (TodoEntity) -> Unit,
    onDelete: (TodoEntity) -> Unit
) {
    if (todos.isNotEmpty()) {
        Column {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .wrapContentWidth()
                    .background(Color.White, RoundedCornerShape(16.dp))
                    .padding(horizontal = 12.dp, vertical = 6.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.KeyboardArrowDown,
                    contentDescription = null,
                    tint = iconTint,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "$title (${todos.size})",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.DarkGray
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            todos.forEach { todo ->
                TodoItemRow(
                    todo = todo,
                    onToggleComplete = { onToggleComplete(todo) },
                    onSetReminder = { onSetReminder(todo) },
                    onClick = { onTodoClick(todo.screenshotId) },
                    onEdit = { onEdit(todo) },
                    onDelete = { onDelete(todo) }
                )
            }
        }
    }
}

@Composable
fun TodoItemRow(
    todo: TodoEntity,
    onToggleComplete: () -> Unit,
    onSetReminder: () -> Unit,
    onClick: () -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit
) {
    var expanded by remember { mutableStateOf(false) }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
            .background(Color.White, RoundedCornerShape(16.dp))
            .clickable { onClick() }
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Thumbnail Image
        if (todo.screenshotUri.isNotEmpty()) {
            AsyncImage(
                model = Uri.parse(todo.screenshotUri),
                contentDescription = "Thumbnail",
                modifier = Modifier
                    .size(40.dp)
                    .clip(RoundedCornerShape(8.dp)),
                contentScale = ContentScale.Crop
            )
            Spacer(modifier = Modifier.width(16.dp))
        }

        // Title and Duration
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = todo.title,
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color.Black
            )
            Text(
                text = todo.duration,
                fontSize = 12.sp,
                color = Color.Gray
            )
        }

        // Action Buttons
        if (todo.dueDate != null && !todo.isReminded && !todo.isCompleted) {
            IconButton(onClick = onSetReminder) {
                Icon(
                    imageVector = Icons.Default.Alarm,
                    contentDescription = "Set Reminder",
                    tint = Color(0xFFC3C5F1)
                )
            }
        }

        IconButton(onClick = onToggleComplete) {
            Icon(
                imageVector = if (todo.isCompleted) Icons.Default.CheckCircle else Icons.Outlined.Circle,
                contentDescription = "Toggle Complete",
                tint = if (todo.isCompleted) Color(0xFF86EFAC) else Color.Gray,
                modifier = Modifier.size(28.dp)
            )
        }

        // Dropdown Menu
        Box {
            IconButton(onClick = { expanded = true }) {
                Icon(Icons.Default.MoreVert, contentDescription = "More options", tint = Color.Gray)
            }
            DropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false }
            ) {
                DropdownMenuItem(
                    text = { Text("Edit") },
                    onClick = {
                        expanded = false
                        onEdit()
                    }
                )
                DropdownMenuItem(
                    text = { Text("Delete") },
                    onClick = {
                        expanded = false
                        onDelete()
                    }
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditTodoDialog(
    todo: TodoEntity?,
    onDismiss: () -> Unit,
    onSave: (TodoEntity) -> Unit
) {
    var title by remember { mutableStateOf(todo?.title ?: "") }
    var duration by remember { mutableStateOf(todo?.duration ?: "15m") }
    
    // Simplistic category dropdown selection omitted for brevity, using Morning if null.
    var category by remember { mutableStateOf(todo?.category ?: "Anytime") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(text = if (todo == null) "New Task" else "Edit Task") },
        text = {
            Column {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Task Title") },
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = duration,
                    onValueChange = { duration = it },
                    label = { Text("Duration (e.g. 15m or 1h)") },
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(8.dp))
                // Quick Category Selector
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    listOf("Morning", "Afternoon", "Anytime").forEach { cat ->
                        FilterChip(
                            selected = category == cat,
                            onClick = { category = cat },
                            label = { Text(cat) }
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    if (title.isNotEmpty()) {
                        val newEntity = todo?.copy(
                            title = title,
                            duration = duration,
                            category = category
                        ) ?: TodoEntity(
                            screenshotId = -1,
                            screenshotUri = "", // Manual Todo
                            title = title,
                            category = category,
                            duration = duration
                        )
                        onSave(newEntity)
                    }
                }
            ) {
                Text("Save")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
