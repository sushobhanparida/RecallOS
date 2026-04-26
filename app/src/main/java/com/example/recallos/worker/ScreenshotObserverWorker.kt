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
 * Triggered automatically by WorkManager when MediaStore images change.
 * Shows a notification with three actions:
 *   • Save      — import screenshot into RecallOS home screen
 *   • Stack     — import and assign to a Stack
 *   • Add to Task — import, extract date/time, open task creation sheet
 */
class ScreenshotObserverWorker(
    private val context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    companion object {
        const val KEY_URI = "screenshot_uri"
        const val NOTIF_ID_DETECTED = 2000
        const val CHANNEL_ID = "recall_detect_channel"

        const val ACTION_SAVE  = "com.example.recallos.ACTION_SAVE_SCREENSHOT"
        const val ACTION_STACK = "com.example.recallos.ACTION_STACK_SCREENSHOT"
        const val ACTION_TASK  = "com.example.recallos.ACTION_TASK_SCREENSHOT"
    }

    override suspend fun doWork(): Result {
        return try {
            val latestUri = queryLatestScreenshot() ?: return Result.success()
            val uriString = latestUri.toString()
            val baseCode = uriString.hashCode()

            fun makePendingIntent(action: String, requestCode: Int): PendingIntent {
                val intent = Intent(context, ScreenshotActionReceiver::class.java).apply {
                    this.action = action
                    putExtra(KEY_URI, uriString)
                }
                return PendingIntent.getBroadcast(
                    context,
                    requestCode,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            }

            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(
                NOTIF_ID_DETECTED,
                NotificationCompat.Builder(context, CHANNEL_ID)
                    .setSmallIcon(R.drawable.ic_launcher_foreground)
                    .setContentTitle("New screenshot captured")
                    .setContentText("What do you want to do with it?")
                    .setAutoCancel(true)
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .addAction(
                        R.drawable.ic_launcher_foreground,
                        "Save",
                        makePendingIntent(ACTION_SAVE, baseCode)
                    )
                    .addAction(
                        R.drawable.ic_launcher_foreground,
                        "Stack",
                        makePendingIntent(ACTION_STACK, baseCode + 1)
                    )
                    .addAction(
                        R.drawable.ic_launcher_foreground,
                        "Add to Task",
                        makePendingIntent(ACTION_TASK, baseCode + 2)
                    )
                    .build()
            )

            Result.success()
        } catch (e: Exception) {
            e.printStackTrace()
            Result.failure()
        } finally {
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
