package com.example.recallos.data

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [
        ScreenshotEntity::class,
        ListEntity::class,
        ListScreenshotCrossRef::class,
        TodoEntity::class
    ],
    version = 3,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun screenshotDao(): ScreenshotDao
    abstract fun listDao(): ListDao
    abstract fun todoDao(): TodoDao
}
