import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'water_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_readings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER,
            reading REAL,
            month TEXT,
            image_path TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveReadingOffline(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('pending_readings', data);
  }

  Future<List<Map<String, dynamic>>> getPendingReadings() async {
    final db = await database;
    return await db.query('pending_readings');
  }

  Future<void> deletePendingReading(int id) async {
    final db = await database;
    await db.delete('pending_readings', where: 'id = ?', whereArgs: [id]);
  }
}

final dbService = DatabaseService();
