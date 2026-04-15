package com.example.recallos.worker

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.recallos.core.OcrProcessor
import com.example.recallos.core.ScreenshotScanner
import com.example.recallos.core.TaggingEngine
import com.example.recallos.data.ScreenshotEntity
import com.example.recallos.di.AppModule

class ScreenshotWorker(
    private val context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            val database = AppModule.getDatabase(context)
            val screenshotDao = database.screenshotDao()
            val todoDao = database.todoDao()

            val latestScreenshots = ScreenshotScanner.getLatestScreenshots(context, limit = 500)
            val currentSeconds = System.currentTimeMillis() / 1000L

            for (screenshotData in latestScreenshots) {
                val uriString = screenshotData.uri.toString()
                
                // Check if already processed
                if (!screenshotDao.exists(uriString)) {
                    // Extract text
                    val extractedText = OcrProcessor.extractTextFromUri(context, screenshotData.uri)
                    
                    // Tag and save
                    val tag = TaggingEngine.generateTag(extractedText)
                    
                    val entity = ScreenshotEntity(
                        uri = uriString,
                        extractedText = extractedText,
                        tag = tag
                    )
                    val insertedId = screenshotDao.insertScreenshot(entity)

                    // Extract Todo Information only if fresh (< 24 hours)
                    val isFresh = (currentSeconds - screenshotData.dateAddedSeconds) < (24 * 3600)
                    if (isFresh) {
                        val extractionResult = com.example.recallos.core.DateTimeExtractor.extract(extractedText)
                        if (extractionResult != null) {
                            val todoEntity = com.example.recallos.data.TodoEntity(
                                screenshotId = insertedId,
                                screenshotUri = uriString,
                                title = extractionResult.titleHint,
                                category = extractionResult.category,
                                dueDate = extractionResult.dueDate
                            )
                            todoDao.insertTodo(todoEntity)
                        }
                    }
                }
            }
            Result.success()
        } catch (e: Exception) {
            e.printStackTrace()
            Result.failure()
        }
    }
}
