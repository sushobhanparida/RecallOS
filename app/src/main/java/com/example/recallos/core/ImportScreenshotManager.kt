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
        val screenshotId: Long,
        val screenshotUri: String,
        // Pre-filled data for task creation UI (populated when autoCreateTodo = false)
        val titleHint: String? = null,
        val extractedDueDate: Long? = null,
        val extractedIsEvent: Boolean = false
    )

    /**
     * Processes a URI: runs OCR, tags it, saves to DB, and optionally auto-creates a Todo.
     *
     * @param autoCreateTodo  When false, the OCR extraction result is returned but no Todo
     *                        is written to the database — the caller will present the
     *                        task-creation sheet to the user instead.
     * @return null if the screenshot was already imported (duplicate).
     */
    suspend fun importFromUri(
        context: Context,
        uri: Uri,
        autoCreateTodo: Boolean = true
    ): AnalysisResult? {
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

        val lowerText = extractedText.lowercase()
        val hasLink = lowerText.contains("http://") || lowerText.contains("https://")

        // Run extraction regardless — we need the result for both auto-create and UI pre-fill
        val extractionResult = DateTimeExtractor.extract(extractedText)
        var hasTodo = false

        if (extractionResult != null) {
            if (autoCreateTodo) {
                todoDao.insertTodo(
                    TodoEntity(
                        screenshotId = insertedId,
                        screenshotUri = uriString,
                        title = extractionResult.titleHint,
                        category = extractionResult.category,
                        dueDate = extractionResult.dueDate,
                        isEvent = extractionResult.isEvent,
                        notifyOption = if (extractionResult.isEvent) "None" else "On the day"
                    )
                )
                hasTodo = true
            }
        }

        val hasEvent = tag == "Event" || extractionResult?.isEvent == true

        return AnalysisResult(
            tag = tag,
            hasTodo = hasTodo,
            hasLink = hasLink,
            hasEvent = hasEvent,
            extractedText = extractedText,
            screenshotId = insertedId,
            screenshotUri = uriString,
            titleHint = extractionResult?.titleHint,
            extractedDueDate = extractionResult?.dueDate,
            extractedIsEvent = extractionResult?.isEvent ?: false
        )
    }
}
