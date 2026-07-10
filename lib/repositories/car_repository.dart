import '../database/app_database.dart';
import '../models/car.dart';

class CarRepository {
  Future<int> insertCar(Car car) async {
    final db = await AppDatabase.database;

    return db.insert(
      'cars',
      car.toMap(),
    );
  }

  Future<void> updateCar(Car car) async {
    final db = await AppDatabase.database;

    await db.update(
      'cars',
      car.toMap(),
      where: 'id = ?',
      whereArgs: [car.id],
    );
  }

  Future<List<Car>> getCars() async {
    final db = await AppDatabase.database;

    final rows = await db.query(
      'cars',
      orderBy: 'id DESC',
    );

    return rows.map(Car.fromMap).toList();
  }

  Future<void> deleteCar(int id) async {
    final db = await AppDatabase.database;

    await db.transaction((transaction) async {
      await transaction.delete(
        'service_entries',
        where: 'carId = ?',
        whereArgs: [id],
      );

      await transaction.delete(
        'fuel_entries',
        where: 'carId = ?',
        whereArgs: [id],
      );

      await transaction.delete(
        'cars',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> updateMileageIfHigher({
    required int carId,
    required int mileage,
  }) async {
    final db = await AppDatabase.database;

    await db.rawUpdate(
      '''
      UPDATE cars
      SET mileage = ?
      WHERE id = ? AND mileage < ?
      ''',
      [mileage, carId, mileage],
    );
  }
}