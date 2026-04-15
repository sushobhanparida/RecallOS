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
 * Receives the "Add to RecallOS" action from the screenshot detection notification.
 * Dismisses the notification and enqueues the background analysis worker.
 */
class ScreenshotActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val uriString = intent.getStringExtra(ScreenshotObserverWorker.KEY_URI) ?: return

        // Dismiss the "New Screenshot" notification
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(ScreenshotObserverWorker.NOTIF_ID_DETECTED)

        // Kick off background OCR + import
        val inputData = Data.Builder()
            .putString(AnalyzeScreenshotWorker.KEY_URI, uriString)
            .build()

        val analyzeRequest = OneTimeWorkRequestBuilder<AnalyzeScreenshotWorker>()
            .setInputData(inputData)
            .build()

        WorkManager.getInstance(context).enqueue(analyzeRequest)
    }
}
