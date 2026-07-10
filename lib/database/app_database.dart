import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const int _databaseVersion = 8;
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
    await _createFuelEntriesTable(db);
    await _createExpenseEntriesTable(db);
    await _createRemindersTable(db);
    await _createCarPhotosTable(db);
    await _createVehicleDocumentsTable(db);
  }

  static Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createServiceEntriesTable(db);
    }
    if (oldVersion < 3) {
      await _createFuelEntriesTable(db);
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE fuel_entries '
        'ADD COLUMN isFullTank INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (oldVersion < 5) {
      await _createExpenseEntriesTable(db);
    }
    if (oldVersion < 6) {
      await _createRemindersTable(db);
    }
    if (oldVersion < 7) {
      await _createCarPhotosTable(db);
    }
    if (oldVersion < 8) {
      await _createVehicleDocumentsTable(db);
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

  static Future<void> _createFuelEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE fuel_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        carId INTEGER NOT NULL,
        mileage INTEGER NOT NULL,
        liters REAL NOT NULL,
        pricePerLiter REAL NOT NULL,
        totalCost REAL NOT NULL,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isFullTank INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  static Future<void> _createExpenseEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE expense_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        carId INTEGER NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createRemindersTable(Database db) async {
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        carId INTEGER NOT NULL,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        dueDate TEXT,
        dueMileage INTEGER,
        note TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createCarPhotosTable(Database db) async {
    await db.execute('''
      CREATE TABLE car_photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        carId INTEGER NOT NULL,
        filePath TEXT NOT NULL,
        caption TEXT NOT NULL,
        isCover INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createVehicleDocumentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE vehicle_documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        carId INTEGER NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        filePath TEXT NOT NULL,
        fileName TEXT NOT NULL,
        fileType TEXT NOT NULL,
        expiryDate TEXT,
        note TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }
}
