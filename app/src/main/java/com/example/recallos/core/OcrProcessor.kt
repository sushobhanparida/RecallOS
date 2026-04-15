package com.example.recallos.core

import android.content.Context
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import kotlinx.coroutines.tasks.await
import java.io.IOException

object OcrProcessor {
    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    suspend fun extractTextFromUri(context: Context, uri: Uri): String {
        return try {
            val image = InputImage.fromFilePath(context, uri)
            val result = recognizer.process(image).await()
            result.text
        } catch (e: IOException) {
            e.printStackTrace()
            ""
        } catch (e: Exception) {
            e.printStackTrace()
            ""
        }
    }
}
