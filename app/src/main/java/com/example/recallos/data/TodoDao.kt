package com.example.recallos.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface TodoDao {
    @Query("SELECT * FROM todos ORDER BY dueDate ASC, createdAt DESC")
    fun getAllTodos(): Flow<List<TodoEntity>>

    @Query("SELECT * FROM todos WHERE category = :category ORDER BY dueDate ASC")
    fun getTodosByCategory(category: String): Flow<List<TodoEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTodo(todo: TodoEntity): Long

    @Update
    suspend fun updateTodo(todo: TodoEntity)

    @Query("SELECT * FROM todos WHERE id = :id LIMIT 1")
    suspend fun getTodoById(id: Long): TodoEntity?

    @Query("SELECT * FROM todos WHERE screenshotId = :screenshotId LIMIT 1")
    suspend fun getTodoByScreenshotId(screenshotId: Long): TodoEntity?

    @Query("SELECT * FROM todos WHERE isEvent = 1 ORDER BY dueDate ASC")
    fun getEventTodos(): Flow<List<TodoEntity>>

    @Query("DELETE FROM todos WHERE id = :id")
    suspend fun deleteTodo(id: Long)
}
