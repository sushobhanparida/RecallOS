import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/screenshot_model.dart';
import '../models/task_model.dart';
import '../models/stack_model.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'recall_os.db');
    return openDatabase(
      path,
      version: 7,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, _) => _ensureSchema(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        // v7: rename todos → tasks. Must run BEFORE _ensureSchema so the
        // new 'tasks' table isn't created fresh (which would lack isEvent).
        if (oldVersion < 7) {
          final existing = await db.rawQuery(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='todos'");
          if (existing.isNotEmpty) {
            await db.execute('ALTER TABLE todos RENAME TO tasks');
            await _addColumnIfMissing(
              db,
              table: 'tasks',
              column: 'intent',
              definition: "TEXT NOT NULL DEFAULT 'task'",
            );
            // isEvent column exists in the renamed table — safe to query.
            await db.execute(
                "UPDATE tasks SET intent = 'event' WHERE isEvent = 1");
            await db.execute('DROP INDEX IF EXISTS idx_todos_category');
            await db.execute('DROP INDEX IF EXISTS idx_todos_completed');
          }
        }

        // Idempotent schema — creates any tables/indexes that are still missing.
        await _ensureSchema(db);

        await _addColumnIfMissing(
          db,
          table: 'screenshots',
          column: 'entities',
          definition: "TEXT NOT NULL DEFAULT '[]'",
        );
        await _addColumnIfMissing(
          db,
          table: 'screenshots',
          column: 'entitiesExtracted',
          definition: 'INTEGER NOT NULL DEFAULT 0',
        );
        await _addColumnIfMissing(
          db,
          table: 'screenshots',
          column: 'noteText',
          definition: 'TEXT',
        );
        await _migrateLegacyTags(db);
      },
    );
  }

  /// Maps legacy tag strings (General, Read, Link, Event) to the new five-tag
  /// scheme. Existing screenshots will get re-tagged on the next backfill pass
  /// using the entity-aware autoTag — this is just a placeholder so they
  /// don't show up as "General" in the meantime.
  Future<void> _migrateLegacyTags(Database db) async {
    await db.update('screenshots', {'tag': 'Notes'},
        where: "tag IN ('General', 'Read', 'general', 'read')");
    await db.update('screenshots', {'tag': 'Links'},
        where: "tag IN ('Link', 'link')");
    await db.update('screenshots', {'tag': 'Events'},
        where: "tag IN ('Event', 'event')");
    // Force a re-tag pass: clear entitiesExtracted for everything so the
    // backfill runs autoTag with full entity data.
    await db.update('screenshots', {'entitiesExtracted': 0});
  }

  Future<void> _addColumnIfMissing(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final cols = await db.rawQuery("PRAGMA table_info('$table')");
    final exists = cols.any((c) => c['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  // Idempotent schema setup. Safe on fresh installs and on upgrades from any
  // earlier version where some tables may already exist.
  Future<void> _ensureSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS screenshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uri TEXT NOT NULL,
        extractedText TEXT NOT NULL DEFAULT '',
        tag TEXT NOT NULL DEFAULT 'Notes',
        createdAt INTEGER NOT NULL,
        entities TEXT NOT NULL DEFAULT '[]',
        entitiesExtracted INTEGER NOT NULL DEFAULT 0,
        noteText TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        screenshotId INTEGER NOT NULL,
        screenshotUri TEXT NOT NULL,
        title TEXT NOT NULL,
        intent TEXT NOT NULL DEFAULT 'task',
        dueDate INTEGER,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        isReminded INTEGER NOT NULL DEFAULT 0,
        notifyOption TEXT NOT NULL DEFAULT 'None',
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS stacks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS stack_screenshots (
        stackId INTEGER NOT NULL,
        screenshotId INTEGER NOT NULL,
        PRIMARY KEY (stackId, screenshotId),
        FOREIGN KEY (stackId) REFERENCES stacks(id) ON DELETE CASCADE,
        FOREIGN KEY (screenshotId) REFERENCES screenshots(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS dismissed_suggestions (
        dismissKey TEXT PRIMARY KEY,
        dismissedAt INTEGER NOT NULL
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_screenshots_tag ON screenshots (tag)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tasks_intent ON tasks (intent)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tasks_completed ON tasks (isCompleted)');
  }

  // ── Screenshots ───────────────────────────────────────────────────────────

  Future<int> insertScreenshot(Screenshot s) async {
    final db = await database;
    final map = s.toMap()..remove('id');
    map['entitiesExtracted'] = 1;
    return db.insert('screenshots', map);
  }

  Future<List<Screenshot>> getScreenshots({
    String? tagFilter,
    String? query,
  }) async {
    final db = await database;
    String where = '';
    final args = <Object>[];

    if (tagFilter != null && tagFilter != 'All') {
      where = 'tag = ?';
      args.add(tagFilter);
    }
    if (query != null && query.isNotEmpty) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'extractedText LIKE ?';
      args.add('%$query%');
    }

    final rows = await db.query(
      'screenshots',
      where: where.isNotEmpty ? where : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'createdAt DESC',
    );
    return rows.map(Screenshot.fromMap).toList();
  }

  Future<Screenshot?> getScreenshotById(int id) async {
    final db = await database;
    final rows = await db.query(
      'screenshots',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Screenshot.fromMap(rows.first);
  }

  Future<void> deleteScreenshot(int id) async {
    final db = await database;
    await db.delete('screenshots', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateScreenshot(Screenshot s) async {
    final db = await database;
    final map = s.toMap()..remove('id');
    map['entitiesExtracted'] = 1;
    await db.update(
      'screenshots',
      map,
      where: 'id = ?',
      whereArgs: [s.id],
    );
  }

  /// Returns rows that still need entity extraction (legacy data inserted
  /// before the entity pipeline existed).
  Future<List<Screenshot>> getScreenshotsNeedingEntityBackfill(
      {int limit = 25}) async {
    final db = await database;
    final rows = await db.query(
      'screenshots',
      where: "entitiesExtracted = 0 AND extractedText != ''",
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return rows.map(Screenshot.fromMap).toList();
  }

  /// Saved notes — screenshots the user has explicitly converted to a note
  /// (noteText is non-null). Surfaces in the Notes tab's Pinterest grid.
  Future<List<Screenshot>> getSavedNotes() async {
    final db = await database;
    final rows = await db.query(
      'screenshots',
      where: 'noteText IS NOT NULL',
      orderBy: 'createdAt DESC',
    );
    return rows.map(Screenshot.fromMap).toList();
  }

  Future<int> getEntityBackfillRemaining() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM screenshots "
      "WHERE entitiesExtracted = 0 AND extractedText != ''",
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  Future<int> insertTask(Task t) async {
    final db = await database;
    return db.insert('tasks', t.toMap()..remove('id'));
  }

  Future<List<Task>> getTasks({bool includeCompleted = false}) async {
    final db = await database;
    final rows = await db.query(
      'tasks',
      where: includeCompleted ? null : 'isCompleted = 0',
      orderBy: 'createdAt ASC',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<void> updateTask(Task t) async {
    final db = await database;
    await db.update('tasks', t.toMap(),
        where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ── Stacks ────────────────────────────────────────────────────────────────

  Future<int> insertStack(Stack s) async {
    final db = await database;
    return db.insert('stacks', s.toMap()..remove('id'));
  }

  Future<List<Stack>> getStacks() async {
    final db = await database;
    final stackRows = await db.query('stacks', orderBy: 'createdAt DESC');
    final stacks = <Stack>[];
    for (final row in stackRows) {
      final id = row['id'] as int;
      final screenshots = await _getScreenshotsForStack(id);
      stacks.add(Stack.fromMap(row, screenshots: screenshots));
    }
    return stacks;
  }

  Future<Stack?> getStackById(int id) async {
    final db = await database;
    final rows = await db.query('stacks',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final screenshots = await _getScreenshotsForStack(id);
    return Stack.fromMap(rows.first, screenshots: screenshots);
  }

  Future<List<Screenshot>> _getScreenshotsForStack(int stackId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT s.* FROM screenshots s
      INNER JOIN stack_screenshots ss ON s.id = ss.screenshotId
      WHERE ss.stackId = ?
      ORDER BY s.createdAt DESC
    ''', [stackId]);
    return rows.map(Screenshot.fromMap).toList();
  }

  Future<void> addScreenshotToStack(int stackId, int screenshotId) async {
    final db = await database;
    await db.insert(
      'stack_screenshots',
      {'stackId': stackId, 'screenshotId': screenshotId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeScreenshotFromStack(
      int stackId, int screenshotId) async {
    final db = await database;
    await db.delete(
      'stack_screenshots',
      where: 'stackId = ? AND screenshotId = ?',
      whereArgs: [stackId, screenshotId],
    );
  }

  Future<void> deleteStack(int id) async {
    final db = await database;
    await db.delete('stacks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> renameStack(int id, String name) async {
    final db = await database;
    await db.update('stacks', {'name': name},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> createStackWithScreenshots(
      String name, List<int> screenshotIds) async {
    final db = await database;
    return db.transaction((txn) async {
      final stackId = await txn.insert('stacks', {
        'name': name,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      for (final sid in screenshotIds) {
        await txn.insert(
          'stack_screenshots',
          {'stackId': stackId, 'screenshotId': sid},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      return stackId;
    });
  }

  // ── Suggestion dismissals ─────────────────────────────────────────────────

  Future<Set<String>> getDismissedSuggestionKeys() async {
    final db = await database;
    final rows = await db.query('dismissed_suggestions',
        columns: ['dismissKey']);
    return rows.map((r) => r['dismissKey'] as String).toSet();
  }

  Future<void> dismissSuggestion(String key) async {
    final db = await database;
    await db.insert(
      'dismissed_suggestions',
      {
        'dismissKey': key,
        'dismissedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
