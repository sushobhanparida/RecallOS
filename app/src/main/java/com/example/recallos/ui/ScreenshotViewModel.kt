package com.example.recallos.ui

import android.app.Application
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.recallos.core.ImportScreenshotManager
import com.example.recallos.data.ScreenshotEntity
import com.example.recallos.data.ScreenshotRepository
import com.example.recallos.di.AppModule
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class ScreenshotViewModel(application: Application) : AndroidViewModel(application) {
    private val repository: ScreenshotRepository

    init {
        val dao = AppModule.getDatabase(application).screenshotDao()
        repository = ScreenshotRepository(dao)
    }

    private val _isImporting = MutableStateFlow(false)
    val isImporting = _isImporting.asStateFlow()

    fun importScreenshot(uri: Uri) {
        viewModelScope.launch {
            _isImporting.value = true
            try {
                ImportScreenshotManager.importFromUri(getApplication(), uri)
            } finally {
                _isImporting.value = false
            }
        }
    }

    private val _currentFilter = MutableStateFlow("All")
    val currentFilter = _currentFilter.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery = _searchQuery.asStateFlow()

    @OptIn(ExperimentalCoroutinesApi::class)
    val screenshots: StateFlow<List<ScreenshotEntity>> = combine(_currentFilter, _searchQuery) { filter, query ->
        Pair(filter, query)
    }.flatMapLatest { (filter, query) ->
        if (query.isNotEmpty()) {
            repository.searchScreenshots(query)
        } else if (filter == "All") {
            repository.getAllScreenshots()
        } else {
            repository.getScreenshotsByTag(filter)
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun setFilter(tag: String) {
        _currentFilter.value = tag
        _searchQuery.value = ""
    }

    fun setSearchQuery(query: String) {
        _searchQuery.value = query
        if (query.isNotEmpty()) {
            _currentFilter.value = "All"
        }
    }
}

