package com.example.recallos.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "screenshots")
data class ScreenshotEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val uri: String,
    val extractedText: String,
    val tag: String,
    val createdAt: Long = System.currentTimeMillis()
)
