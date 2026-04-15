package com.example.recallos.core

import android.content.ContentUris
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore

object ScreenshotScanner {

    data class ScreenshotData(
        val uri: Uri,
        val dateAddedSeconds: Long
    )

    fun getLatestScreenshots(context: Context, limit: Int = 500): List<ScreenshotData> {
        val screenshots = mutableListOf<ScreenshotData>()

        val projection = arrayOf(
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DISPLAY_NAME,
            MediaStore.Images.Media.DATA,
            MediaStore.Images.Media.DATE_ADDED
        )

        // Query all images that are in a "Screenshots" directory
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
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
            val dateAddedColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_ADDED)
            
            var count = 0
            while (cursor.moveToNext() && count < limit) {
                val id = cursor.getLong(idColumn)
                val dateAdded = cursor.getLong(dateAddedColumn)
                val contentUri: Uri = ContentUris.withAppendedId(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                    id
                )
                screenshots.add(ScreenshotData(contentUri, dateAdded))
                count++
            }
        }

        return screenshots
    }
}
