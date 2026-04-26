package com.example.recallos.core

import java.util.Calendar
import java.util.Locale

object DateTimeExtractor {

    data class ExtractionResult(
        val category: String,    // "Morning", "Afternoon", "Anytime", "Event"
        val dueDate: Long?,
        val titleHint: String,
        val isEvent: Boolean     // true = calendar event (flight, movie, etc.)
    )

    // Calendar-style events: show with calendar icon, no notify-later, fire at event time
    private val calendarEventKeywords = listOf(
        "flight", "movie", "cinema", "concert", "show", "match", "game",
        "dinner reservation", "reservation", "booking", "ticket", "check-in",
        "checkin", "boarding", "departs", "arrives", "arrival", "departure",
        "screening", "performance", "gig"
    )

    // Task-style reminders: show with checkbox, notify-later options available
    private val taskKeywords = listOf(
        "meeting", "appointment", "reminder", "call", "catch up", "sync",
        "routine", "deadline", "due", "submit", "send", "buy", "pick up",
        "drop off", "pay", "book", "schedule", "follow up"
    )

    fun extract(text: String): ExtractionResult? {
        val lowerText = text.lowercase(Locale.getDefault())

        val isCalendarEvent = calendarEventKeywords.any { lowerText.contains(it) }
        val isTask = taskKeywords.any { lowerText.contains(it) }
        val hasTimeExpr = lowerText.contains("am ") || lowerText.contains("pm ") ||
                lowerText.contains("a.m.") || lowerText.contains("p.m.") ||
                lowerText.contains("morning") || lowerText.contains("afternoon") ||
                lowerText.contains("evening") || lowerText.contains("night")
        val hasDateExpr = lowerText.contains("/") || containsMonth(lowerText)

        // If nothing actionable is found, skip
        if (!isCalendarEvent && !isTask && !hasTimeExpr && !hasDateExpr) return null

        // Find a good title hint from the most relevant line
        val titleHint = findTitleHint(text, isCalendarEvent)

        // Determine time bucket
        val category: String
        val dueDate: Long?
        when {
            lowerText.contains("am ") || lowerText.contains("a.m.") || lowerText.contains("morning") -> {
                category = if (isCalendarEvent) "Event" else "Morning"
                dueDate = getFutureTime(9, 0)
            }
            lowerText.contains("pm ") || lowerText.contains("p.m.") ||
            lowerText.contains("afternoon") || lowerText.contains("evening") ||
            lowerText.contains("night") -> {
                category = if (isCalendarEvent) "Event" else "Afternoon"
                dueDate = getFutureTime(15, 0)
            }
            isCalendarEvent -> {
                category = "Event"
                dueDate = getFutureTime(12, 0)
            }
            else -> {
                category = "Anytime"
                dueDate = if (hasDateExpr || isTask) getFutureTime(12, 0) else null
            }
        }

        return ExtractionResult(
            category = category,
            dueDate = dueDate,
            titleHint = titleHint,
            isEvent = isCalendarEvent
        )
    }

    private fun findTitleHint(text: String, isCalendarEvent: Boolean): String {
        val keywords = if (isCalendarEvent) calendarEventKeywords else taskKeywords
        val lines = text.split("\n")
        for (line in lines) {
            val lower = line.lowercase(Locale.getDefault())
            if (keywords.any { lower.contains(it) }) {
                return line.trim().take(60)
            }
        }
        // Fall back to first non-empty line
        return lines.firstOrNull { it.isNotBlank() }?.trim()?.take(60) ?: "Task from screenshot"
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
        val months = listOf(
            "jan", "feb", "mar", "apr", "may", "jun",
            "jul", "aug", "sep", "oct", "nov", "dec"
        )
        return months.any { text.contains(it) }
    }
}
