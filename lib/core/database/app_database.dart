import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/screenshot_model.dart';
import '../models/todo_model.dart';
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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE screenshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uri TEXT NOT NULL,
        extractedText TEXT NOT NULL DEFAULT '',
        tag TEXT NOT NULL DEFAULT 'General',
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        screenshotId INTEGER NOT NULL,
        screenshotUri TEXT NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'Anytime',
        dueDate INTEGER,
        duration TEXT NOT NULL DEFAULT '15m',
        isCompleted INTEGER NOT NULL DEFAULT 0,
        isReminded INTEGER NOT NULL DEFAULT 0,
        isEvent INTEGER NOT NULL DEFAULT 0,
        notifyOption TEXT NOT NULL DEFAULT 'None',
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE stacks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE stack_screenshots (
        stackId INTEGER NOT NULL,
        screenshotId INTEGER NOT NULL,
        PRIMARY KEY (stackId, screenshotId),
        FOREIGN KEY (stackId) REFERENCES stacks(id) ON DELETE CASCADE,
        FOREIGN KEY (screenshotId) REFERENCES screenshots(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_screenshots_tag ON screenshots (tag)');
    await db.execute(
        'CREATE INDEX idx_todos_category ON todos (category)');
    await db.execute(
        'CREATE INDEX idx_todos_completed ON todos (isCompleted)');
  }

  // ── Screenshots ───────────────────────────────────────────────────────────

  Future<int> insertScreenshot(Screenshot s) async {
    final db = await database;
    return db.insert('screenshots', s.toMap()..remove('id'));
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

  // ── Todos ─────────────────────────────────────────────────────────────────

  Future<int> insertTodo(Todo t) async {
    final db = await database;
    return db.insert('todos', t.toMap()..remove('id'));
  }

  Future<List<Todo>> getTodos({bool includeCompleted = false}) async {
    final db = await database;
    final rows = await db.query(
      'todos',
      where: includeCompleted ? null : 'isCompleted = 0',
      orderBy: 'createdAt ASC',
    );
    return rows.map(Todo.fromMap).toList();
  }

  Future<void> updateTodo(Todo t) async {
    final db = await database;
    await db.update('todos', t.toMap(),
        where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> deleteTodo(int id) async {
    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
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
}
