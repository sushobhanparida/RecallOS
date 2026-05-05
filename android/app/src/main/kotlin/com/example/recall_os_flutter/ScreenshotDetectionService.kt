package com.example.recall_os_flutter

import android.app.*
import android.content.*
import android.database.ContentObserver
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import android.net.Uri
import android.os.*
import android.provider.MediaStore
import androidx.core.app.NotificationCompat
import android.content.ContentUris

class ScreenshotDetectionService : Service() {

    companion object {
        const val CHANNEL_FG   = "recall_os_fg"
        const val CHANNEL_SHOT = "recall_os_screenshot"
        const val NOTIF_FG     = 2001
        const val NOTIF_SHOT   = 2002

        const val ACTION_SAVE  = "com.example.recall_os_flutter.SAVE"
        const val ACTION_STACK = "com.example.recall_os_flutter.STACK"
        const val ACTION_TASK  = "com.example.recall_os_flutter.ADD_TASK"
        const val EXTRA_URI    = "screenshot_uri"

        fun start(ctx: Context) =
            ctx.startForegroundService(Intent(ctx, ScreenshotDetectionService::class.java))

        fun stop(ctx: Context) =
            ctx.stopService(Intent(ctx, ScreenshotDetectionService::class.java))
    }

    private val handler = Handler(Looper.getMainLooper())
    private var observer: ContentObserver? = null
    private var lastPath: String? = null

    override fun onCreate() {
        super.onCreate()
        createChannels()
        startForeground(NOTIF_FG, buildFgNotif())
        registerObserver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIF_FG, buildFgNotif())
        return START_STICKY
    }

    override fun onDestroy() {
        observer?.let { contentResolver.unregisterContentObserver(it) }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createChannels() {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_FG, "RecallOS Service", NotificationManager.IMPORTANCE_MIN)
                .apply { setShowBadge(false) }
        )
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_SHOT, "Screenshot Capture", NotificationManager.IMPORTANCE_HIGH)
                .apply { description = "Actions when you take a screenshot" }
        )
    }

    private fun buildFgNotif(): Notification =
        NotificationCompat.Builder(this, CHANNEL_FG)
            .setContentTitle("RecallOS")
            .setContentText("Watching for screenshots")
            .setSmallIcon(R.drawable.logo)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setOngoing(true)
            .build()

    private fun registerObserver() {
        observer = object : ContentObserver(handler) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                uri ?: return
                // Wait for the file to be fully committed to MediaStore
                handler.postDelayed({ processUri(uri) }, 1500)
            }
        }
        // Register on the legacy "external" authority (pre-Q devices and some OEMs)
        contentResolver.registerContentObserver(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI, true, observer!!
        )
        // Android 10+ uses "external_primary" for primary internal storage;
        // Samsung in particular broadcasts only to this URI, not the legacy one.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            contentResolver.registerContentObserver(
                MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY),
                true, observer!!
            )
        }
    }

    private fun processUri(uri: Uri) {
        try {
            val isQ = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

            val proj = if (isQ) {
                arrayOf(
                    MediaStore.Images.Media._ID,
                    MediaStore.Images.Media.DISPLAY_NAME,
                    MediaStore.Images.Media.RELATIVE_PATH,
                )
            } else {
                arrayOf(
                    MediaStore.Images.Media._ID,
                    MediaStore.Images.Media.DATA,
                )
            }

            // Samsung (and some other OEMs) may emit the base collection URI without
            // a specific item ID. In that case, sort by DATE_ADDED DESC to get the newest.
            val isItemUri = uri.lastPathSegment?.toLongOrNull() != null
            val queryUri = if (isItemUri) uri else MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            val sortOrder = if (isItemUri) null else "${MediaStore.Images.Media.DATE_ADDED} DESC"

            contentResolver.query(queryUri, proj, null, null, sortOrder)?.use { c ->
                if (!c.moveToFirst()) return

                val checkPath: String = if (isQ) {
                    val rel = c.getString(c.getColumnIndexOrThrow(MediaStore.Images.Media.RELATIVE_PATH)) ?: return
                    val name = c.getString(c.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)) ?: return
                    "$rel$name"
                } else {
                    c.getString(c.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)) ?: return
                }

                if (!checkPath.lowercase().contains("screenshot")) return

                val id = c.getLong(c.getColumnIndexOrThrow(MediaStore.Images.Media._ID))
                val itemUri = ContentUris.withAppendedId(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id
                ).toString()

                if (itemUri == lastPath) return
                lastPath = itemUri
                postNotification(itemUri)
            }
        } catch (_: Exception) {}
    }

    private fun postNotification(path: String) {
        val piFlags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

        fun pi(action: String) = PendingIntent.getActivity(
            this,
            action.hashCode(),
            Intent(this, MainActivity::class.java).apply {
                this.action = action
                putExtra(EXTRA_URI, path)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            },
            piFlags
        )

        val bitmap = loadScreenshotBitmap(Uri.parse(path))

        val builder = NotificationCompat.Builder(this, CHANNEL_SHOT)
            .setContentTitle("Save to RecallOS?")
            .setContentText("Screenshot captured")
            .setSmallIcon(R.drawable.logo)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .addAction(0, "Save",     pi(ACTION_SAVE))
            .addAction(0, "Stack",    pi(ACTION_STACK))
            .addAction(0, "Add Task", pi(ACTION_TASK))

        if (bitmap != null) {
            builder
                .setLargeIcon(bitmap)
                .setStyle(
                    NotificationCompat.BigPictureStyle()
                        .bigPicture(bitmap)
                        .bigLargeIcon(null as Bitmap?)
                )
        }

        getSystemService(NotificationManager::class.java).notify(NOTIF_SHOT, builder.build())
    }

    private fun loadScreenshotBitmap(uri: Uri): Bitmap? = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val src = ImageDecoder.createSource(contentResolver, uri)
            ImageDecoder.decodeBitmap(src) { decoder, info, _ ->
                val w = info.size.width
                val h = info.size.height
                if (w > 1024 || h > 1024) {
                    val scale = 1024f / maxOf(w, h)
                    decoder.setTargetSize((w * scale).toInt(), (h * scale).toInt())
                }
            }
        } else {
            @Suppress("DEPRECATION")
            BitmapFactory.decodeStream(contentResolver.openInputStream(uri))
        }
    } catch (_: Exception) { null }
}
