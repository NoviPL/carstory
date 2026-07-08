import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const int _databaseVersion = 2;
  static const String _databaseName = 'carstory.db';

  static Database? _database;

  static Future<Database> get database async {
    final existingDatabase = _database;

    if (existingDatabase != null) {
      return existingDatabase;
    }

    final database = await _openDatabase();
    _database = database;

    return database;
  }

  static Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  static Future<void> _createDatabase(Database db, int version) async {
    await _createCarsTable(db);
    await _createServiceEntriesTable(db);
  }

  static Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createServiceEntriesTable(db);
    }
  }

  static Future<void> _createCarsTable(Database db) async {
    await db.execute('''
      CREATE TABLE cars (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        mileage INTEGER NOT NULL,
        vin TEXT NOT NULL,
        plateNumber TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createServiceEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE service_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        carId INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        mileage INTEGER NOT NULL,
        cost REAL NOT NULL,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }
}