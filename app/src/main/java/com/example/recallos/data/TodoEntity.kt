package com.example.recallos.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "todos")
data class TodoEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val screenshotId: Long,
    val screenshotUri: String,
    val title: String,
    val category: String, // "Anytime", "Morning", "Afternoon"
    val dueDate: Long? = null,
    val duration: String = "5m",
    val isCompleted: Boolean = false,
    val isReminded: Boolean = false,
    val createdAt: Long = System.currentTimeMillis()
)
