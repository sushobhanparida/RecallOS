package com.example.recall_os_flutter

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "com.example.recall_os_flutter/screenshot"
    }

    private var channel: MethodChannel? = null
    private var pendingAction: Map<String, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    ScreenshotDetectionService.start(this)
                    result.success(null)
                }
                "stopService" -> {
                    ScreenshotDetectionService.stop(this)
                    result.success(null)
                }
                "getPendingAction" -> {
                    result.success(pendingAction)
                    pendingAction = null
                }
                "requestMediaPermission" -> {
                    val perm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        Manifest.permission.READ_MEDIA_IMAGES
                    } else {
                        Manifest.permission.READ_EXTERNAL_STORAGE
                    }
                    val granted = ContextCompat.checkSelfPermission(this, perm) ==
                            PackageManager.PERMISSION_GRANTED
                    if (!granted) {
                        ActivityCompat.requestPermissions(this, arrayOf(perm), 1001)
                    }
                    result.success(granted)
                }
                "resolveContentUri" -> {
                    val uriStr = call.argument<String>("uri")
                    if (uriStr == null) { result.error("NO_URI", null, null); return@setMethodCallHandler }
                    try {
                        val uri = Uri.parse(uriStr)
                        val ext = MimeTypeMap.getSingleton()
                            .getExtensionFromMimeType(contentResolver.getType(uri)) ?: "jpg"
                        val tmp = File(cacheDir, "screenshot_${System.currentTimeMillis()}.$ext")
                        contentResolver.openInputStream(uri)?.use { input ->
                            tmp.outputStream().use { output -> input.copyTo(output) }
                        }
                        result.success(tmp.absolutePath)
                    } catch (e: Exception) {
                        result.error("RESOLVE_FAILED", e.message, null)
                    }
                }
                "countDeviceScreenshots" -> {
                    try {
                        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
                        } else {
                            MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                        }
                        val col = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
                            MediaStore.Images.Media.RELATIVE_PATH
                        else
                            MediaStore.Images.Media.DATA
                        val cursor = contentResolver.query(
                            collection,
                            arrayOf(MediaStore.Images.Media._ID),
                            "$col LIKE ?",
                            arrayOf("%Screenshots%"),
                            null
                        )
                        val count = cursor?.use { it.count } ?: 0
                        result.success(count)
                    } catch (e: Exception) {
                        result.success(0)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // App was cold-started from a notification action — store for Flutter to pick up
        pendingAction = extractAction(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val action = extractAction(intent) ?: return
        // Flutter engine is live — deliver immediately via channel
        if (channel != null) {
            channel!!.invokeMethod("onScreenshotAction", action)
        } else {
            pendingAction = action
        }
    }

    private fun extractAction(intent: Intent?): Map<String, String>? {
        val path = intent?.getStringExtra(ScreenshotDetectionService.EXTRA_URI) ?: return null
        val mapped = when (intent.action) {
            ScreenshotDetectionService.ACTION_SAVE  -> "save"
            ScreenshotDetectionService.ACTION_STACK -> "stack"
            ScreenshotDetectionService.ACTION_TASK  -> "addtask"
            else -> return null
        }
        return mapOf("action" to mapped, "uri" to path)
    }
}
