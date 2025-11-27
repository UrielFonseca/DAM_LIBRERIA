import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> getDatabase() async {
    if (_db != null) return _db!;
    String path = join(await getDatabasesPath(), 'test.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, version) {
      db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT
        )
      ''');
    });
    return _db!;
  }

  static Future<int> insertUser(String name) async {
    final db = await getDatabase();

    return db.insert('users', {'name': name});

  }

  static Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await getDatabase();
    return db.query('users');
  }
}
