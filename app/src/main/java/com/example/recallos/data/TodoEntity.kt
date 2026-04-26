package com.example.recallos.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "todos")
data class TodoEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val screenshotId: Long,
    val screenshotUri: String,
    val title: String,
    val category: String, // "Anytime", "Morning", "Afternoon", "Event"
    val dueDate: Long? = null,
    val duration: String = "5m",
    val isCompleted: Boolean = false,
    val isReminded: Boolean = false,
    // true = calendar-style event (flight, movie, etc.) — no notify-later, fires at event time
    val isEvent: Boolean = false,
    // "None" | "On the day" | "Night before" | "1 hour before" | "30 min before" (tasks only)
    val notifyOption: String = "None",
    val createdAt: Long = System.currentTimeMillis()
)
