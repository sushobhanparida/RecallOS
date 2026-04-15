package com.example.recallos

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.work.Constraints
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.example.recallos.worker.AnalyzeScreenshotWorker
import com.example.recallos.worker.ScreenshotObserverWorker

class RecallApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
        setupScreenshotObserver()
    }

    /**
     * Create two channels:
     * 1. "recall_detect_channel" — heads-up prompt when a new screenshot is taken
     * 2. "recall_results_channel" — silent summary after analysis completes
     */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java)

            val detectChannel = NotificationChannel(
                ScreenshotObserverWorker.CHANNEL_ID,
                "Screenshot Detected",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Prompt to add a fresh screenshot to RecallOS"
            }

            val resultsChannel = NotificationChannel(
                AnalyzeScreenshotWorker.CHANNEL_ID,
                "Analysis Results",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Summary of what RecallOS found in an imported screenshot"
            }

            nm.createNotificationChannels(listOf(detectChannel, resultsChannel))
        }
    }

    /**
     * Register a ContentUri trigger so WorkManager wakes up ScreenshotObserverWorker
     * whenever the MediaStore images table changes — no polling, no battery drain.
     */
    private fun setupScreenshotObserver() {
        val constraints = Constraints.Builder()
            .addContentUriTrigger(
                Uri.parse(MediaStore.Images.Media.EXTERNAL_CONTENT_URI.toString()),
                true
            )
            .build()

        val observerRequest = OneTimeWorkRequestBuilder<ScreenshotObserverWorker>()
            .setConstraints(constraints)
            .build()

        // REPLACE ensures only one is ever waiting at a time; after it fires it re-queues itself
        WorkManager.getInstance(this).enqueueUniqueWork(
            "ScreenshotObserverWork",
            ExistingWorkPolicy.REPLACE,
            observerRequest
        )
    }
}

