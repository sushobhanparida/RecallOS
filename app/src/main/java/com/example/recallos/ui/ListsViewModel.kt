package com.example.recallos.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.recallos.data.ListEntity
import com.example.recallos.data.ListRepository
import com.example.recallos.data.ScreenshotEntity
import com.example.recallos.data.ScreenshotRepository
import com.example.recallos.di.AppModule
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class ListsViewModel(application: Application) : AndroidViewModel(application) {
    private val listRepository: ListRepository
    val screenshotRepository: ScreenshotRepository

    init {
        val db = AppModule.getDatabase(application)
        listRepository = ListRepository(db.listDao())
        screenshotRepository = ScreenshotRepository(db.screenshotDao())
    }

    val lists: StateFlow<List<ListEntity>> = listRepository.getAllLists()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Used for the "add to list" bottom sheet
    val allScreenshots: StateFlow<List<ScreenshotEntity>> = screenshotRepository.getAllScreenshots()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun createList(name: String) {
        viewModelScope.launch {
            listRepository.createList(name)
        }
    }

    fun deleteList(listId: Long) {
        viewModelScope.launch {
            listRepository.deleteList(listId)
        }
    }

    fun renameList(listId: Long, newName: String) {
        viewModelScope.launch {
            listRepository.renameList(listId, newName)
        }
    }

    fun getScreenshotsForList(listId: Long): Flow<List<ScreenshotEntity>> {
        return listRepository.getScreenshotsForList(listId)
    }

    fun getCoverUrisForList(listId: Long): Flow<List<String>> {
        return listRepository.getCoverUrisForList(listId)
    }

    fun getCountForList(listId: Long): Flow<Int> {
        return listRepository.getCountForList(listId)
    }

    fun addScreenshotToList(listId: Long, screenshotId: Long) {
        viewModelScope.launch {
            listRepository.addScreenshotToList(listId, screenshotId)
        }
    }

    fun removeScreenshotFromList(listId: Long, screenshotId: Long) {
        viewModelScope.launch {
            listRepository.removeScreenshotFromList(listId, screenshotId)
        }
    }
}
