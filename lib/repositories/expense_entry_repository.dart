import '../database/app_database.dart';
import '../models/expense_entry.dart';

class ExpenseEntryRepository {
  Future<int> insertEntry(ExpenseEntry entry) async {
    final db = await AppDatabase.database;

    return db.insert(
      'expense_entries',
      entry.toMap(),
    );
  }

  Future<void> updateEntry(ExpenseEntry entry) async {
    final db = await AppDatabase.database;

    await db.update(
      'expense_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<List<ExpenseEntry>> getEntriesForCar(int carId) async {
    final db = await AppDatabase.database;

    final rows = await db.query(
      'expense_entries',
      where: 'carId = ?',
      whereArgs: [carId],
      orderBy: 'date DESC, id DESC',
    );

    return rows.map(ExpenseEntry.fromMap).toList();
  }

  Future<void> deleteEntry(int id) async {
    final db = await AppDatabase.database;

    await db.delete(
      'expense_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}