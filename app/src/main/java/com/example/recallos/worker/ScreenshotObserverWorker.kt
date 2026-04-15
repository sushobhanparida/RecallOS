package com.example.recallos.worker

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.provider.MediaStore
import androidx.core.app.NotificationCompat
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.recallos.R
import com.example.recallos.core.ScreenshotActionReceiver

/**
 * Triggered automatically by WorkManager when MediaStore images change
 * (via ContentUriTrigger set up in RecallApplication).
 * Checks if the newest image is a screenshot and shows a notification with
 * an "Add to RecallOS" action button.
 */
class ScreenshotObserverWorker(
    private val context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    companion object {
        const val KEY_URI = "screenshot_uri"
        const val NOTIF_ID_DETECTED = 2000
        const val CHANNEL_ID = "recall_detect_channel"
    }

    override suspend fun doWork(): Result {
        return try {
            val latestUri = queryLatestScreenshot() ?: return Result.success()

            val uriString = latestUri.toString()

            // Build the "Add to RecallOS" action PendingIntent
            val addIntent = Intent(context, ScreenshotActionReceiver::class.java).apply {
                action = "com.example.recallos.ACTION_ADD_SCREENSHOT"
                putExtra(KEY_URI, uriString)
            }
            val addPendingIntent = PendingIntent.getBroadcast(
                context,
                uriString.hashCode(),
                addIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(
                NOTIF_ID_DETECTED,
                NotificationCompat.Builder(context, CHANNEL_ID)
                    .setSmallIcon(R.drawable.ic_launcher_foreground)
                    .setContentTitle("New Screenshot Captured")
                    .setContentText("Tap to add it to RecallOS")
                    .setAutoCancel(true)
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .addAction(
                        R.drawable.ic_launcher_foreground,
                        "Add to RecallOS",
                        addPendingIntent
                    )
                    .build()
            )

            Result.success()
        } catch (e: Exception) {
            e.printStackTrace()
            Result.failure()
        } finally {
            // Re-register ourselves so we keep watching for future screenshots
            reEnqueue()
        }
    }

    private fun reEnqueue() {
        val constraints = Constraints.Builder()
            .addContentUriTrigger(
                android.net.Uri.parse(MediaStore.Images.Media.EXTERNAL_CONTENT_URI.toString()),
                true
            )
            .build()

        val nextRequest = androidx.work.OneTimeWorkRequestBuilder<ScreenshotObserverWorker>()
            .setConstraints(constraints)
            .build()

        androidx.work.WorkManager.getInstance(context).enqueueUniqueWork(
            "ScreenshotObserverWork",
            androidx.work.ExistingWorkPolicy.REPLACE,
            nextRequest
        )
    }

    private fun queryLatestScreenshot(): android.net.Uri? {
        val projection = arrayOf(
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DATA,
            MediaStore.Images.Media.DATE_ADDED
        )
        val selection = "${MediaStore.Images.Media.DATA} LIKE ?"
        val selectionArgs = arrayOf("%/Screenshots/%")
        val sortOrder = "${MediaStore.Images.Media.DATE_ADDED} DESC"

        context.contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            sortOrder
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID))
                val dateAdded = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_ADDED))
                // Only surface if taken in the last 30 seconds (very fresh = just taken)
                val nowSeconds = System.currentTimeMillis() / 1000L
                if (nowSeconds - dateAdded <= 30) {
                    return ContentUris.withAppendedId(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id
                    )
                }
            }
        }
        return null
    }
}
