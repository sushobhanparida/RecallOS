package com.example.recallos.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.recallos.data.ScreenshotEntity
import com.example.recallos.data.TodoEntity
import com.example.recallos.di.AppModule
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class ScreenshotDetailViewModel(application: Application) : AndroidViewModel(application) {
    private val screenshotDao = AppModule.getDatabase(application).screenshotDao()
    private val todoDao = AppModule.getDatabase(application).todoDao()

    private val _screenshotState = MutableStateFlow<ScreenshotEntity?>(null)
    val screenshotState: StateFlow<ScreenshotEntity?> = _screenshotState.asStateFlow()

    private val _todoState = MutableStateFlow<TodoEntity?>(null)
    val todoState: StateFlow<TodoEntity?> = _todoState.asStateFlow()

    fun loadDetails(screenshotId: Long) {
        viewModelScope.launch {
            val screenshot = screenshotDao.getScreenshotById(screenshotId)
            _screenshotState.value = screenshot

            if (screenshot != null) {
                val todo = todoDao.getTodoByScreenshotId(screenshotId)
                _todoState.value = todo
            }
        }
    }
}
