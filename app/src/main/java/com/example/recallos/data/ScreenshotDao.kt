package com.example.recallos.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface ScreenshotDao {
    @Query("SELECT * FROM screenshots ORDER BY createdAt DESC")
    fun getAllScreenshots(): Flow<List<ScreenshotEntity>>

    @Query("SELECT * FROM screenshots WHERE tag = :tag ORDER BY createdAt DESC")
    fun getScreenshotsByTag(tag: String): Flow<List<ScreenshotEntity>>

    @Query("SELECT * FROM screenshots WHERE extractedText LIKE '%' || :query || '%' ORDER BY createdAt DESC")
    fun searchScreenshots(query: String): Flow<List<ScreenshotEntity>>

    @Query("SELECT * FROM screenshots WHERE id = :id LIMIT 1")
    suspend fun getScreenshotById(id: Long): ScreenshotEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertScreenshot(screenshot: ScreenshotEntity): Long

    @Query("SELECT EXISTS(SELECT 1 FROM screenshots WHERE uri = :uri LIMIT 1)")
    suspend fun exists(uri: String): Boolean
}
