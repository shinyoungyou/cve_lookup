import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/cve_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cve_lookup.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE saved_cves (
        id TEXT PRIMARY KEY,
        description TEXT NOT NULL,
        cvssScore REAL,
        severity TEXT,
        publishedDate TEXT
      )
    ''');
  }

  Future<void> saveCve(CveModel cve) async {
    final db = await database;
    await db.insert(
      'saved_cves',
      cve.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCve(String id) async {
    final db = await database;
    await db.delete(
      'saved_cves',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<CveModel>> getSavedCves() async {
    final db = await database;
    final maps = await db.query('saved_cves');
    return maps.map((map) => CveModel.fromMap(map)).toList();
  }

  Future<bool> isSaved(String id) async {
    final db = await database;
    final result = await db.query(
      'saved_cves',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty;
  }
}