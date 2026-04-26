package com.example.recallos.data

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface ListDao {

    // ── Stacks CRUD ─────────────────────────────────────────────────────────

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertList(list: ListEntity): Long

    @Query("DELETE FROM stacks WHERE id = :listId")
    suspend fun deleteList(listId: Long)

    @Query("UPDATE stacks SET name = :name WHERE id = :listId")
    suspend fun renameList(listId: Long, name: String)

    @Query("SELECT * FROM stacks ORDER BY createdAt DESC")
    fun getAllLists(): Flow<List<ListEntity>>

    // ── Cross-ref (add / remove screenshots) ────────────────────────────────

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun addScreenshotToList(crossRef: ListScreenshotCrossRef)

    @Query("DELETE FROM stack_screenshot_cross_ref WHERE stackId = :listId AND screenshotId = :screenshotId")
    suspend fun removeScreenshotFromList(listId: Long, screenshotId: Long)

    // ── Screenshots for a stack ──────────────────────────────────────────────

    @Query("""
        SELECT s.* FROM screenshots s
        INNER JOIN stack_screenshot_cross_ref r ON s.id = r.screenshotId
        WHERE r.stackId = :listId
        ORDER BY r.addedAt DESC
    """)
    fun getScreenshotsForList(listId: Long): Flow<List<ScreenshotEntity>>

    // ── Cover images (first 4 screenshots) for mosaic ───────────────────────

    @Query("""
        SELECT s.uri FROM screenshots s
        INNER JOIN stack_screenshot_cross_ref r ON s.id = r.screenshotId
        WHERE r.stackId = :listId
        ORDER BY r.addedAt DESC
        LIMIT 4
    """)
    fun getCoverUrisForList(listId: Long): Flow<List<String>>

    // ── Screenshot count per stack ───────────────────────────────────────────

    @Query("""
        SELECT COUNT(*) FROM stack_screenshot_cross_ref WHERE stackId = :listId
    """)
    fun getCountForList(listId: Long): Flow<Int>

    // ── Check membership ─────────────────────────────────────────────────────

    @Query("""
        SELECT EXISTS(
            SELECT 1 FROM stack_screenshot_cross_ref
            WHERE stackId = :listId AND screenshotId = :screenshotId
            LIMIT 1
        )
    """)
    suspend fun isScreenshotInList(listId: Long, screenshotId: Long): Boolean
}
