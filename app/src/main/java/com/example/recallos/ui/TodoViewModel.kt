package com.example.recallos.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.recallos.core.ReminderManager
import com.example.recallos.data.TodoEntity
import com.example.recallos.di.AppModule
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.collectLatest

class TodoViewModel(application: Application) : AndroidViewModel(application) {
    private val todoDao = AppModule.getDatabase(application).todoDao()

    private val _morningTodos = MutableStateFlow<List<TodoEntity>>(emptyList())
    val morningTodos: StateFlow<List<TodoEntity>> = _morningTodos.asStateFlow()

    private val _afternoonTodos = MutableStateFlow<List<TodoEntity>>(emptyList())
    val afternoonTodos: StateFlow<List<TodoEntity>> = _afternoonTodos.asStateFlow()

    private val _anytimeTodos = MutableStateFlow<List<TodoEntity>>(emptyList())
    val anytimeTodos: StateFlow<List<TodoEntity>> = _anytimeTodos.asStateFlow()

    init {
        viewModelScope.launch {
            todoDao.getTodosByCategory("Morning").collectLatest { _morningTodos.value = it }
        }
        viewModelScope.launch {
            todoDao.getTodosByCategory("Afternoon").collectLatest { _afternoonTodos.value = it }
        }
        viewModelScope.launch {
            todoDao.getTodosByCategory("Anytime").collectLatest { _anytimeTodos.value = it }
        }
    }

    fun toggleComplete(todo: TodoEntity) {
        viewModelScope.launch {
            todoDao.updateTodo(todo.copy(isCompleted = !todo.isCompleted))
        }
    }

    fun saveTodo(todo: TodoEntity) {
        viewModelScope.launch {
            if (todo.id == 0L) {
                todoDao.insertTodo(todo)
            } else {
                todoDao.updateTodo(todo)
            }
        }
    }

    fun deleteTodo(todo: TodoEntity) {
        viewModelScope.launch {
            if (todo.isReminded) {
                ReminderManager.cancelReminder(getApplication(), todo.id)
            }
            todoDao.deleteTodo(todo.id)
        }
    }

    fun setReminder(todo: TodoEntity) {
        val application = getApplication<Application>()
        if (todo.dueDate != null) {
            ReminderManager.scheduleReminder(application, todo.id, todo.dueDate, todo.title)
            viewModelScope.launch {
                todoDao.updateTodo(todo.copy(isReminded = true))
            }
        }
    }
}
