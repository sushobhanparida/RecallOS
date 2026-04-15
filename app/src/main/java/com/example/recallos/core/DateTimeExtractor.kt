package com.example.recallos.core

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

object DateTimeExtractor {

    data class ExtractionResult(
        val category: String, // "Morning", "Afternoon", "Anytime"
        val dueDate: Long?,
        val titleHint: String
    )

    fun extract(text: String): ExtractionResult? {
        val lowerText = text.lowercase(Locale.getDefault())

        val eventKeywords = listOf("meeting", "appointment", "routine", "event", "reminder", "call", "catch up")
        val isEvent = eventKeywords.any { lowerText.contains(it) }

        var category = "Anytime"
        var dueDate: Long? = null
        var titleHint = "Task from screenshot"

        // Find potential event titles
        val lines = text.split("\n")
        for (line in lines) {
            val lowerLine = line.lowercase(Locale.getDefault())
            if (eventKeywords.any { lowerLine.contains(it) }) {
                titleHint = line.take(50)
                break
            }
        }

        // Extremely simplified heuristics for "Morning" vs "Afternoon" vs "Anytime"
        // In a real app we'd use NLP like ML Kit Entity Extraction.
        if (lowerText.contains("am ") || lowerText.contains("a.m.") || lowerText.contains("morning")) {
            category = "Morning"
            dueDate = getFutureTime(9, 0)
        } else if (lowerText.contains("pm ") || lowerText.contains("p.m.") || lowerText.contains("afternoon") || lowerText.contains("evening") || lowerText.contains("night")) {
            category = "Afternoon"
            dueDate = getFutureTime(15, 0)
        } else if (isEvent) {
            category = "Anytime"
            dueDate = getFutureTime(12, 0)
        } else if (lowerText.contains("/") || lowerText.contains("-") || containsMonth(lowerText)) {
            // Just found some date, no spec time
            category = "Anytime"
            dueDate = getFutureTime(12, 0)
        } else {
            // If no time indicators and no event keywords, it's not a Todo.
            return null
        }

        return ExtractionResult(category, dueDate, titleHint)
    }

    private fun getFutureTime(hourOfDay: Int, minute: Int): Long {
        val calendar = Calendar.getInstance()
        if (calendar.get(Calendar.HOUR_OF_DAY) >= hourOfDay) {
            calendar.add(Calendar.DAY_OF_YEAR, 1)
        }
        calendar.set(Calendar.HOUR_OF_DAY, hourOfDay)
        calendar.set(Calendar.MINUTE, minute)
        calendar.set(Calendar.SECOND, 0)
        return calendar.timeInMillis
    }

    private fun containsMonth(text: String): Boolean {
        val months = listOf("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec")
        return months.any { text.contains(it) }
    }
}
