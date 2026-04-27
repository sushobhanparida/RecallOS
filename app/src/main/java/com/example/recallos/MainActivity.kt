package com.example.recallos

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Layers
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import com.example.recallos.ui.theme.OnSurface
import com.example.recallos.ui.theme.OnSurfaceVariant
import com.example.recallos.ui.theme.Primary
import com.example.recallos.ui.theme.PrimaryContainer
import androidx.core.content.ContextCompat
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.recallos.ui.HomeScreen
import com.example.recallos.ui.ListDetailScreen
import com.example.recallos.ui.MyListsScreen
import com.example.recallos.ui.PendingTaskData
import com.example.recallos.ui.TodoScreen
import com.example.recallos.ui.theme.RecallOSTheme
import com.example.recallos.worker.AnalyzeScreenshotWorker

class MainActivity : ComponentActivity() {

    private var hasPermissions by mutableStateOf(false)

    // Holds task-creation data coming from a notification "Add to Task" tap
    private var pendingTask by mutableStateOf<PendingTaskData?>(null)
    // Holds "open_stacks" request from notification "Stack" tap
    private var pendingNavAction by mutableStateOf<String?>(null)

    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        if (permissions.entries.all { it.value }) hasPermissions = true
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        checkPermissions()
        handleIntent(intent)

        setContent {
            RecallOSTheme {
                if (hasPermissions) {
                    AppNavigation(
                        pendingTask = pendingTask,
                        pendingNavAction = pendingNavAction,
                        onPendingTaskConsumed = { pendingTask = null },
                        onPendingNavConsumed  = { pendingNavAction = null }
                    )
                } else {
                    Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                        Text(
                            text = "Please grant media permissions to view screenshots.",
                            modifier = Modifier.padding(innerPadding)
                        )
                    }
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        when (intent?.getStringExtra(AnalyzeScreenshotWorker.EXTRA_ACTION)) {
            AnalyzeScreenshotWorker.ACTION_CREATE_TASK -> {
                val screenshotId  = intent.getLongExtra(AnalyzeScreenshotWorker.EXTRA_SCREENSHOT_ID, -1L)
                val screenshotUri = intent.getStringExtra(AnalyzeScreenshotWorker.EXTRA_SCREENSHOT_URI) ?: ""
                val titleHint     = intent.getStringExtra(AnalyzeScreenshotWorker.EXTRA_TITLE_HINT) ?: ""
                val dueDate       = if (intent.hasExtra(AnalyzeScreenshotWorker.EXTRA_DUE_DATE))
                                        intent.getLongExtra(AnalyzeScreenshotWorker.EXTRA_DUE_DATE, 0L)
                                    else null
                val isEvent       = intent.getBooleanExtra(AnalyzeScreenshotWorker.EXTRA_IS_EVENT, false)

                if (screenshotId >= 0) {
                    pendingTask = PendingTaskData(
                        screenshotId  = screenshotId,
                        screenshotUri = screenshotUri,
                        titleHint     = titleHint,
                        dueDate       = dueDate,
                        isEvent       = isEvent
                    )
                }
            }
            AnalyzeScreenshotWorker.ACTION_OPEN_STACKS -> {
                pendingNavAction = "stacks"
            }
        }
    }

    private fun checkPermissions() {
        val permissionsToRequest = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissionsToRequest.add(Manifest.permission.READ_MEDIA_IMAGES)
            permissionsToRequest.add(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            permissionsToRequest.add(Manifest.permission.READ_EXTERNAL_STORAGE)
        }
        val missing = permissionsToRequest.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isEmpty()) hasPermissions = true
        else requestPermissionLauncher.launch(missing.toTypedArray())
    }
}

@Composable
private fun AppNavigation(
    pendingTask: PendingTaskData?,
    pendingNavAction: String?,
    onPendingTaskConsumed: () -> Unit,
    onPendingNavConsumed: () -> Unit
) {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    // Navigate to stacks tab when triggered by notification
    androidx.compose.runtime.LaunchedEffect(pendingNavAction) {
        if (pendingNavAction == "stacks") {
            navController.navigate("stacks") {
                popUpTo(navController.graph.startDestinationId) { saveState = true }
                launchSingleTop = true
                restoreState = true
            }
            onPendingNavConsumed()
        }
    }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        bottomBar = {
            if (currentRoute in listOf("home", "stacks", "todo")) {
                val navItemColors = NavigationBarItemDefaults.colors(
                    selectedIconColor   = Primary,
                    selectedTextColor   = Primary,
                    indicatorColor      = PrimaryContainer,
                    unselectedIconColor = OnSurfaceVariant,
                    unselectedTextColor = OnSurfaceVariant
                )
                NavigationBar(
                    containerColor = androidx.compose.material3.MaterialTheme.colorScheme.surface,
                    tonalElevation = 0.dp
                ) {
                    NavigationBarItem(
                        icon     = { Icon(Icons.Default.Home, contentDescription = "Home") },
                        label    = { Text("Home") },
                        selected = currentRoute == "home",
                        colors   = navItemColors,
                        onClick  = {
                            navController.navigate("home") {
                                popUpTo(navController.graph.startDestinationId) { saveState = true }
                                launchSingleTop = true; restoreState = true
                            }
                        }
                    )
                    NavigationBarItem(
                        icon     = { Icon(Icons.Default.Layers, contentDescription = "Stacks") },
                        label    = { Text("Stacks") },
                        selected = currentRoute == "stacks",
                        colors   = navItemColors,
                        onClick  = {
                            navController.navigate("stacks") {
                                popUpTo(navController.graph.startDestinationId) { saveState = true }
                                launchSingleTop = true; restoreState = true
                            }
                        }
                    )
                    NavigationBarItem(
                        icon     = { Icon(Icons.Default.CheckCircle, contentDescription = "To-do") },
                        label    = { Text("To-do") },
                        selected = currentRoute == "todo",
                        colors   = navItemColors,
                        onClick  = {
                            navController.navigate("todo") {
                                popUpTo(navController.graph.startDestinationId) { saveState = true }
                                launchSingleTop = true; restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = "home",
            modifier = Modifier.padding(innerPadding)
        ) {
            composable("home") {
                HomeScreen(
                    onScreenshotClick = { navController.navigate("screenshot_detail/$it") }
                )
            }
            composable("todo") {
                TodoScreen(
                    onTodoClick = { navController.navigate("screenshot_detail/$it") },
                    pendingTask = pendingTask,
                    onPendingTaskConsumed = onPendingTaskConsumed
                )
            }
            composable("stacks") {
                MyListsScreen(
                    onListClick = { listId ->
                        navController.navigate("stack_detail/$listId")
                    }
                )
            }
            composable(
                route = "stack_detail/{listId}",
                arguments = listOf(navArgument("listId") { type = NavType.LongType })
            ) { backStackEntry ->
                val listId = backStackEntry.arguments?.getLong("listId") ?: 0L
                ListDetailScreen(
                    listId = listId,
                    listName = "Stack",
                    onBackClick = { navController.popBackStack() }
                )
            }
            composable(
                route = "screenshot_detail/{id}",
                arguments = listOf(navArgument("id") { type = NavType.LongType })
            ) { backStackEntry ->
                val screenshotId = backStackEntry.arguments?.getLong("id") ?: 0L
                com.example.recallos.ui.ScreenshotDetailScreen(
                    screenshotId = screenshotId,
                    onBackClick = { navController.popBackStack() }
                )
            }
        }
    }
}
