import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isPinned INTEGER NOT NULL DEFAULT 0,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        backgroundColor INTEGER NOT NULL DEFAULT 4294967295
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE notes ADD COLUMN isPinned INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE notes ADD COLUMN isDeleted INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE notes ADD COLUMN backgroundColor INTEGER NOT NULL DEFAULT 4294967295',
      );
    }
  }

  Future<Note> createNote(Note note) async {
    try {
      final db = await database;
      final id = await db.insert('notes', note.toMap());
      return note.copyWith(id: id);
    } catch (e) {
      throw Exception('Lỗi khi tạo ghi chú: $e');
    }
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: 'isDeleted = 0',
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return result.map((m) => Note.fromMap(m)).toList();
  }

  Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: 'isDeleted = 0 AND (title LIKE ? OR content LIKE ?)',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return result.map((m) => Note.fromMap(m)).toList();
  }

  Future<Note?> getNote(int id) async {
    final db = await database;
    final maps = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    // Xóa mềm: chuyển vào thùng rác
    return db.update(
      'notes',
      {'isDeleted': 1, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteNotePermanently(int id) async {
    final db = await database;
    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteMany(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final idPlaceholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'notes',
      {'isDeleted': 1, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id IN ($idPlaceholders)',
      whereArgs: ids,
    );
  }

  Future<List<Note>> getDeletedNotes() async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: 'isDeleted = 1',
      orderBy: 'updatedAt DESC',
    );
    return result.map((m) => Note.fromMap(m)).toList();
  }

  Future<int> restoreNote(int id) async {
    final db = await database;
    return db.update(
      'notes',
      {'isDeleted': 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreMany(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final idPlaceholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'notes',
      {'isDeleted': 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id IN ($idPlaceholders)',
      whereArgs: ids,
    );
  }

  Future<int> togglePin(Note note) async {
    final db = await database;
    final updated = note.copyWith(
      isPinned: !note.isPinned,
      updatedAt: DateTime.now(),
    );
    return db.update(
      'notes',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;
    final allNotes = await db.query('notes', where: 'isDeleted = 0');

    int totalNotes = allNotes.length;
    int totalWords = 0;
    int totalCharacters = 0;
    int pinnedNotes = 0;

    for (final noteMap in allNotes) {
      final content = noteMap['content'] as String? ?? '';
      final title = noteMap['title'] as String? ?? '';
      final fullText = '$title $content';

      totalCharacters += fullText.length;
      totalWords += fullText.trim().isEmpty
          ? 0
          : fullText.trim().split(RegExp(r'\s+')).length;

      if ((noteMap['isPinned'] ?? 0) == 1) {
        pinnedNotes++;
      }
    }

    return {
      'totalNotes': totalNotes,
      'totalWords': totalWords,
      'totalCharacters': totalCharacters,
      'pinnedNotes': pinnedNotes,
    };
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
