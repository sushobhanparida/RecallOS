package com.example.recallos

import android.Manifest
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
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
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
import com.example.recallos.ui.theme.RecallOSTheme

class MainActivity : ComponentActivity() {

    private var hasPermissions by mutableStateOf(false)

    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val granted = permissions.entries.all { it.value }
        if (granted) {
            hasPermissions = true
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        
        checkPermissions()

        setContent {
            RecallOSTheme {
                if (hasPermissions) {
                    val navController = rememberNavController()
                    val navBackStackEntry by navController.currentBackStackEntryAsState()
                    val currentRoute = navBackStackEntry?.destination?.route

                    Scaffold(
                        modifier = Modifier.fillMaxSize(),
                        bottomBar = {
                            // Only show bottom bar on top level screens
                            if (currentRoute == "home" || currentRoute == "lists" || currentRoute == "todo") {
                                NavigationBar {
                                    NavigationBarItem(
                                        icon = { Icon(Icons.Default.Home, contentDescription = "Home") },
                                        label = { Text("Home") },
                                        selected = currentRoute == "home",
                                        onClick = {
                                            navController.navigate("home") {
                                                popUpTo(navController.graph.startDestinationId) { saveState = true }
                                                launchSingleTop = true
                                                restoreState = true
                                            }
                                        }
                                    )
                                    NavigationBarItem(
                                        icon = { Icon(Icons.Default.List, contentDescription = "My Lists") },
                                        label = { Text("My Lists") },
                                        selected = currentRoute == "lists",
                                        onClick = {
                                            navController.navigate("lists") {
                                                popUpTo(navController.graph.startDestinationId) { saveState = true }
                                                launchSingleTop = true
                                                restoreState = true
                                            }
                                        }
                                    )
                                    NavigationBarItem(
                                        icon = { Icon(androidx.compose.material.icons.Icons.Default.CheckCircle, contentDescription = "To-do") },
                                        label = { Text("To-do") },
                                        selected = currentRoute == "todo",
                                        onClick = {
                                            navController.navigate("todo") {
                                                popUpTo(navController.graph.startDestinationId) { saveState = true }
                                                launchSingleTop = true
                                                restoreState = true
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
                                    onScreenshotClick = { screenshotId ->
                                        navController.navigate("screenshot_detail/$screenshotId")
                                    }
                                )
                            }
                            composable("todo") {
                                com.example.recallos.ui.TodoScreen(
                                    onTodoClick = { screenshotId ->
                                        navController.navigate("screenshot_detail/$screenshotId")
                                    }
                                )
                            }
                            composable("lists") {
                                MyListsScreen(
                                    onListClick = { listId ->
                                        navController.navigate("list_detail/$listId")
                                    }
                                )
                            }
                            composable(
                                route = "list_detail/{listId}",
                                arguments = listOf(navArgument("listId") { type = NavType.LongType })
                            ) { backStackEntry ->
                                val listId = backStackEntry.arguments?.getLong("listId") ?: 0L
                                // Here we optimally should pass the name too, but we can just use "List" for now or fetch it from DB
                                ListDetailScreen(
                                    listId = listId,
                                    listName = "List Detail", // Could be enhanced to pass real name
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

    private fun checkPermissions() {
        val permissionsToRequest = mutableListOf<String>()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissionsToRequest.add(Manifest.permission.READ_MEDIA_IMAGES)
            permissionsToRequest.add(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            permissionsToRequest.add(Manifest.permission.READ_EXTERNAL_STORAGE)
        }

        val missingPermissions = permissionsToRequest.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (missingPermissions.isEmpty()) {
            hasPermissions = true
        } else {
            requestPermissionLauncher.launch(missingPermissions.toTypedArray())
        }
    }
}
