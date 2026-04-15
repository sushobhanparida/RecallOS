package com.example.recallos.core

import android.content.Context
import android.net.Uri
import com.example.recallos.data.ScreenshotEntity
import com.example.recallos.data.TodoEntity
import com.example.recallos.di.AppModule

object ImportScreenshotManager {

    data class AnalysisResult(
        val tag: String,
        val hasTodo: Boolean,
        val hasLink: Boolean,
        val hasEvent: Boolean,
        val extractedText: String,
        val screenshotId: Long
    )

    /**
     * Processes a user-selected image URI: runs OCR, tags it, saves it to the DB,
     * and optionally creates a Todo if datetime information is detected.
     * Returns null if the screenshot already existed (duplicate), or an AnalysisResult.
     */
    suspend fun importFromUri(context: Context, uri: Uri): AnalysisResult? {
        val db = AppModule.getDatabase(context)
        val screenshotDao = db.screenshotDao()
        val todoDao = db.todoDao()

        val uriString = uri.toString()

        // Don't re-import the same URI
        if (screenshotDao.exists(uriString)) return null

        val extractedText = OcrProcessor.extractTextFromUri(context, uri)
        val tag = TaggingEngine.generateTag(extractedText)

        val entity = ScreenshotEntity(
            uri = uriString,
            extractedText = extractedText,
            tag = tag
        )
        val insertedId = screenshotDao.insertScreenshot(entity)

        // Attempt Todo extraction for user-imported screenshots
        var hasTodo = false
        val extractionResult = DateTimeExtractor.extract(extractedText)
        if (extractionResult != null) {
            todoDao.insertTodo(
                TodoEntity(
                    screenshotId = insertedId,
                    screenshotUri = uriString,
                    title = extractionResult.titleHint,
                    category = extractionResult.category,
                    dueDate = extractionResult.dueDate
                )
            )
            hasTodo = true
        }

        val lowerText = extractedText.lowercase()
        val hasLink = lowerText.contains("http://") || lowerText.contains("https://")
        val hasEvent = tag == "Event" || hasTodo

        return AnalysisResult(
            tag = tag,
            hasTodo = hasTodo,
            hasLink = hasLink,
            hasEvent = hasEvent,
            extractedText = extractedText,
            screenshotId = insertedId
        )
    }
}
