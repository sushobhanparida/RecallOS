package com.example.recallos.core

object TaggingEngine {
    fun generateTag(extractedText: String): String {
        val lowerText = extractedText.lowercase()
        return when {
            lowerText.contains("₹") || lowerText.contains("$") -> "Shopping"
            lowerText.contains("http://") || lowerText.contains("https://") -> "Link"
            containsDate(lowerText) -> "Event"
            extractedText.length > 100 -> "Read"
            else -> "General"
        }
    }

    private fun containsDate(text: String): Boolean {
        // Simple heuristic for dates like mm/dd/yyyy, dd-mm-yyyy, or 202x
        val pattern = Regex("(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})|(202[0-9])")
        return pattern.containsMatchIn(text)
    }
}
