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
        const val KEY_URI = "screenshot_uri"
        const val CHANNEL_ID = "recall_results_channel"
        const val NOTIF_ID_BASE = 3000
    }

    override suspend fun doWork(): Result {
        val uriString = inputData.getString(KEY_URI) ?: return Result.failure()
        val uri = Uri.parse(uriString)

        return try {
            val result = ImportScreenshotManager.importFromUri(context, uri)

            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Open app on tap
            val openIntent = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            if (result == null) {
                // Already imported
                nm.notify(
                    NOTIF_ID_BASE,
                    NotificationCompat.Builder(context, CHANNEL_ID)
                        .setSmallIcon(R.drawable.ic_launcher_foreground)
                        .setContentTitle("Already in RecallOS")
                        .setContentText("This screenshot was previously imported.")
                        .setAutoCancel(true)
                        .setContentIntent(openIntent)
                        .build()
                )
                return Result.success()
            }

            // Build a human-readable summary
            val findings = mutableListOf<String>()
            if (result.hasTodo)  findings.add("📋 Task detected")
            if (result.hasLink)  findings.add("🔗 Link found")
            if (result.hasEvent) findings.add("📅 Event found")
            if (result.tag == "Shopping") findings.add("🛒 Shopping item")

            val summary = if (findings.isNotEmpty())
                findings.joinToString("  ·  ")
            else
                "Saved as ${result.tag}"

            nm.notify(
                NOTIF_ID_BASE + result.screenshotId.toInt(),
                NotificationCompat.Builder(context, CHANNEL_ID)
                    .setSmallIcon(R.drawable.ic_launcher_foreground)
                    .setContentTitle("Added to RecallOS ✓")
                    .setContentText(summary)
                    .setStyle(NotificationCompat.BigTextStyle().bigText(summary))
                    .setAutoCancel(true)
                    .setContentIntent(openIntent)
                    .build()
            )

            Result.success()
        } catch (e: Exception) {
            e.printStackTrace()
            Result.failure()
        }
    }
}
