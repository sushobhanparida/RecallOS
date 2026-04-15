package com.example.recallos.data

import kotlinx.coroutines.flow.Flow

class ListRepository(private val listDao: ListDao) {

    fun getAllLists(): Flow<List<ListEntity>> = listDao.getAllLists()

    fun getScreenshotsForList(listId: Long): Flow<List<ScreenshotEntity>> = listDao.getScreenshotsForList(listId)

    fun getCoverUrisForList(listId: Long): Flow<List<String>> = listDao.getCoverUrisForList(listId)

    fun getCountForList(listId: Long): Flow<Int> = listDao.getCountForList(listId)

    suspend fun createList(name: String): Long {
        val listEntity = ListEntity(name = name)
        return listDao.insertList(listEntity)
    }

    suspend fun deleteList(listId: Long) {
        listDao.deleteList(listId)
    }

    suspend fun renameList(listId: Long, newName: String) {
        listDao.renameList(listId, newName)
    }

    suspend fun addScreenshotToList(listId: Long, screenshotId: Long) {
        val crossRef = ListScreenshotCrossRef(listId, screenshotId)
        listDao.addScreenshotToList(crossRef)
    }

    suspend fun removeScreenshotFromList(listId: Long, screenshotId: Long) {
        listDao.removeScreenshotFromList(listId, screenshotId)
    }

    suspend fun isScreenshotInList(listId: Long, screenshotId: Long): Boolean {
        return listDao.isScreenshotInList(listId, screenshotId)
    }
}
