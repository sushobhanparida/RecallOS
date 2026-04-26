package com.example.recallos.data

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index

@Entity(
    tableName = "stack_screenshot_cross_ref",
    primaryKeys = ["stackId", "screenshotId"],
    foreignKeys = [
        ForeignKey(
            entity = ListEntity::class,
            parentColumns = ["id"],
            childColumns = ["stackId"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = ScreenshotEntity::class,
            parentColumns = ["id"],
            childColumns = ["screenshotId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("stackId"), Index("screenshotId")]
)
data class ListScreenshotCrossRef(
    val stackId: Long,
    val screenshotId: Long,
    val addedAt: Long = System.currentTimeMillis()
)
