package com.example.recallos.di

import android.content.Context
import androidx.room.Room
import com.example.recallos.data.AppDatabase

object AppModule {
    private var database: AppDatabase? = null

    fun getDatabase(context: Context): AppDatabase {
        if (database == null) {
            database = Room.databaseBuilder(
                context.applicationContext,
                AppDatabase::class.java,
                "recallos_db"
            )
                .fallbackToDestructiveMigration()
                .build()
        }
        return database!!
    }
}
