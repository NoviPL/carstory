import '../database/app_database.dart';
import '../models/car_reminder.dart';

class ReminderRepository {
  Future<int> insertReminder(CarReminder reminder) async {
    final db = await AppDatabase.database;

    return db.insert('reminders', reminder.toMap());
  }

  Future<void> updateReminder(CarReminder reminder) async {
    final db = await AppDatabase.database;

    await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<List<CarReminder>> getRemindersForCar(int carId) async {
    final db = await AppDatabase.database;

    final rows = await db.query(
      'reminders',
      where: 'carId = ?',
      whereArgs: [carId],
      orderBy: 'isCompleted ASC, dueDate ASC, dueMileage ASC, id DESC',
    );

    return rows.map(CarReminder.fromMap).toList();
  }

  Future<void> setCompleted({
    required int id,
    required bool isCompleted,
  }) async {
    final db = await AppDatabase.database;

    await db.update(
      'reminders',
      {'isCompleted': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteReminder(int id) async {
    final db = await AppDatabase.database;

    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }
}
