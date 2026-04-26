package com.example.recallos.core

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.Data
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.example.recallos.worker.AnalyzeScreenshotWorker
import com.example.recallos.worker.ScreenshotObserverWorker

/**
 * Receives one of three actions from the screenshot detection notification:
 *   • ACTION_SAVE  — import screenshot, show in Home
 *   • ACTION_STACK — import screenshot, open Stacks tab
 *   • ACTION_TASK  — import screenshot (no auto-todo), open task creation sheet
 */
class ScreenshotActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val uriString = intent.getStringExtra(ScreenshotObserverWorker.KEY_URI) ?: return

        // Dismiss the detection notification
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(ScreenshotObserverWorker.NOTIF_ID_DETECTED)

        val mode = when (intent.action) {
            ScreenshotObserverWorker.ACTION_SAVE  -> AnalyzeScreenshotWorker.MODE_SAVE
            ScreenshotObserverWorker.ACTION_STACK -> AnalyzeScreenshotWorker.MODE_STACK
            ScreenshotObserverWorker.ACTION_TASK  -> AnalyzeScreenshotWorker.MODE_TASK
            else -> AnalyzeScreenshotWorker.MODE_SAVE
        }

        val inputData = Data.Builder()
            .putString(AnalyzeScreenshotWorker.KEY_URI, uriString)
            .putString(AnalyzeScreenshotWorker.KEY_MODE, mode)
            .build()

        val analyzeRequest = OneTimeWorkRequestBuilder<AnalyzeScreenshotWorker>()
            .setInputData(inputData)
            .build()

        WorkManager.getInstance(context).enqueue(analyzeRequest)
    }
}
