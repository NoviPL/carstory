import '../database/app_database.dart';
import '../models/fuel_entry.dart';

class FuelEntryRepository {
  Future<int> insertEntry(FuelEntry entry) async {
    final db = await AppDatabase.database;

    return db.insert(
      'fuel_entries',
      entry.toMap(),
    );
  }

  Future<void> updateEntry(FuelEntry entry) async {
    final db = await AppDatabase.database;

    await db.update(
      'fuel_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<List<FuelEntry>> getEntriesForCar(int carId) async {
    final db = await AppDatabase.database;

    final rows = await db.query(
      'fuel_entries',
      where: 'carId = ?',
      whereArgs: [carId],
      orderBy: 'date DESC, id DESC',
    );

    return rows.map(FuelEntry.fromMap).toList();
  }

  Future<void> deleteEntry(int id) async {
    final db = await AppDatabase.database;

    await db.delete(
      'fuel_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}