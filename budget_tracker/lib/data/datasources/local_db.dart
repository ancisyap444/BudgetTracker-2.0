// lib/data/datasources/local_db.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDb {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'budget_tracker.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profiles (
            id TEXT PRIMARY KEY,
            full_name TEXT,
            monthly_budget REAL DEFAULT 0,
            created_at TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            name TEXT,
            icon TEXT,
            color TEXT,
            budget_limit REAL DEFAULT 0,
            created_at TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            category_id TEXT,
            title TEXT,
            amount REAL,
            type TEXT,
            note TEXT,
            date TEXT,
            created_at TEXT
          );
        ''');
      },
    );
    return _db!;
  }
}
