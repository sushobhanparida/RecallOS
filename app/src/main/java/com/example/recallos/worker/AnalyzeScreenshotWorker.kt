package com.example.recallos.worker

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.recallos.MainActivity
import com.example.recallos.R
import com.example.recallos.core.ImportScreenshotManager

class AnalyzeScreenshotWorker(
    private val context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    companion object {
        const val KEY_URI  = "screenshot_uri"
        const val KEY_MODE = "import_mode"
        const val CHANNEL_ID = "recall_results_channel"
        const val NOTIF_ID_BASE = 3000

        // Modes
        const val MODE_SAVE  = "save"   // import only, show in Home
        const val MODE_STACK = "stack"  // import + open Stacks tab
        const val MODE_TASK  = "task"   // import (no auto-todo) + open task creation sheet

        // Intent extras used by MainActivity to react to notification taps
        const val EXTRA_ACTION         = "recallos_action"
        const val EXTRA_SCREENSHOT_ID  = "screenshot_id"
        const val EXTRA_SCREENSHOT_URI = "screenshot_uri"
        const val EXTRA_TITLE_HINT     = "title_hint"
        const val EXTRA_DUE_DATE       = "due_date"
        const val EXTRA_IS_EVENT       = "is_event"

        const val ACTION_OPEN_STACKS      = "open_stacks"
        const val ACTION_CREATE_TASK      = "create_task"
    }

    override suspend fun doWork(): Result {
        val uriString = inputData.getString(KEY_URI) ?: return Result.failure()
        val mode = inputData.getString(KEY_MODE) ?: MODE_SAVE
        val uri = Uri.parse(uriString)

        return try {
            // For task mode we skip auto-creating a todo so the user fills the sheet
            val autoCreateTodo = (mode != MODE_TASK)
            val result = ImportScreenshotManager.importFromUri(context, uri, autoCreateTodo)

            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            if (result == null) {
                // Already imported — silently ignore for stack/task, show note for save
                if (mode == MODE_SAVE) {
                    nm.notify(
                        NOTIF_ID_BASE,
                        NotificationCompat.Builder(context, CHANNEL_ID)
                            .setSmallIcon(R.drawable.ic_launcher_foreground)
                            .setContentTitle("Already in RecallOS")
                            .setContentText("This screenshot was previously imported.")
                            .setAutoCancel(true)
                            .setContentIntent(openAppIntent(null))
                            .build()
                    )
                }
                return Result.success()
            }

            when (mode) {
                MODE_STACK -> {
                    // Open MainActivity on the Stacks tab
                    val intent = Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra(EXTRA_ACTION, ACTION_OPEN_STACKS)
                    }
                    context.startActivity(intent)
                    showImportedNotification(nm, result, "Saved to RecallOS — open Stacks to assign")
                }

                MODE_TASK -> {
                    // Open MainActivity and trigger the task-creation sheet
                    val intent = Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra(EXTRA_ACTION, ACTION_CREATE_TASK)
                        putExtra(EXTRA_SCREENSHOT_ID,  result.screenshotId)
                        putExtra(EXTRA_SCREENSHOT_URI, result.screenshotUri)
                        putExtra(EXTRA_TITLE_HINT,     result.titleHint ?: "")
                        if (result.extractedDueDate != null) {
                            putExtra(EXTRA_DUE_DATE, result.extractedDueDate)
                        }
                        putExtra(EXTRA_IS_EVENT, result.extractedIsEvent)
                    }
                    context.startActivity(intent)
                    // No persistent notification needed — the sheet is opening
                }

                else -> {
                    // MODE_SAVE — show summary notification
                    val findings = mutableListOf<String>()
                    if (result.hasTodo)  findings.add("📋 Task detected")
                    if (result.hasLink)  findings.add("🔗 Link found")
                    if (result.hasEvent) findings.add("📅 Event found")
                    if (result.tag == "Shopping") findings.add("🛒 Shopping item")
                    val summary = if (findings.isNotEmpty()) findings.joinToString("  ·  ")
                                  else "Saved as ${result.tag}"

                    nm.notify(
                        NOTIF_ID_BASE + result.screenshotId.toInt(),
                        NotificationCompat.Builder(context, CHANNEL_ID)
                            .setSmallIcon(R.drawable.ic_launcher_foreground)
                            .setContentTitle("Added to RecallOS ✓")
                            .setContentText(summary)
                            .setStyle(NotificationCompat.BigTextStyle().bigText(summary))
                            .setAutoCancel(true)
                            .setContentIntent(openAppIntent(null))
                            .build()
                    )
                }
            }

            Result.success()
        } catch (e: Exception) {
            e.printStackTrace()
            Result.failure()
        }
    }

    private fun showImportedNotification(
        nm: NotificationManager,
        result: ImportScreenshotManager.AnalysisResult,
        subtitle: String
    ) {
        nm.notify(
            NOTIF_ID_BASE + result.screenshotId.toInt(),
            NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_launcher_foreground)
                .setContentTitle("Added to RecallOS ✓")
                .setContentText(subtitle)
                .setAutoCancel(true)
                .setContentIntent(openAppIntent(null))
                .build()
        )
    }

    private fun openAppIntent(extras: Intent?): PendingIntent {
        val intent = extras ?: Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
