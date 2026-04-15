package com.example.recallos.data

import kotlinx.coroutines.flow.Flow

class ScreenshotRepository(private val dao: ScreenshotDao) {

    fun getAllScreenshots(): Flow<List<ScreenshotEntity>> {
        return dao.getAllScreenshots()
    }

    fun getScreenshotsByTag(tag: String): Flow<List<ScreenshotEntity>> {
        return dao.getScreenshotsByTag(tag)
    }

    fun searchScreenshots(query: String): Flow<List<ScreenshotEntity>> {
        return dao.searchScreenshots(query)
    }
}
