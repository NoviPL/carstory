import '../database/app_database.dart';
import '../models/service_entry.dart';

class ServiceEntryRepository {
  Future<int> insertEntry(ServiceEntry entry) async {
    final db = await AppDatabase.database;

    return db.insert(
      'service_entries',
      entry.toMap(),
    );
  }

  Future<List<ServiceEntry>> getEntriesForCar(int carId) async {
    final db = await AppDatabase.database;

    final rows = await db.query(
      'service_entries',
      where: 'carId = ?',
      whereArgs: [carId],
      orderBy: 'date DESC, id DESC',
    );

    return rows.map(ServiceEntry.fromMap).toList();
  }

  Future<void> deleteEntry(int id) async {
    final db = await AppDatabase.database;

    await db.delete(
      'service_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}