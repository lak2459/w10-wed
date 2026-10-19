import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init() {
    // sqflite ปกติไม่รองรับ Windows โดยตรง ต้องใช้ FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('attractions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE attractions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        province TEXT NOT NULL,
        description TEXT NOT NULL,
        rating REAL NOT NULL,
        is_recommended INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertAttraction(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('attractions', row);
  }

  Future<List<Map<String, dynamic>>> getAllAttractions() async {
    final db = await database;
    return db.query('attractions', orderBy: 'id DESC');
  }

  Future<int> updateAttraction(int id, Map<String, dynamic> row) async {
    final db = await database;
    return db.update(
      'attractions',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAttraction(int id) async {
    final db = await database;
    return db.delete(
      'attractions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
