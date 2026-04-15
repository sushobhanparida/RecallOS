package com.example.recallos.data

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index

@Entity(
    tableName = "list_screenshot_cross_ref",
    primaryKeys = ["listId", "screenshotId"],
    foreignKeys = [
        ForeignKey(
            entity = ListEntity::class,
            parentColumns = ["id"],
            childColumns = ["listId"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = ScreenshotEntity::class,
            parentColumns = ["id"],
            childColumns = ["screenshotId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("listId"), Index("screenshotId")]
)
data class ListScreenshotCrossRef(
    val listId: Long,
    val screenshotId: Long,
    val addedAt: Long = System.currentTimeMillis()
)
