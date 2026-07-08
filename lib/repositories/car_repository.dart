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

    await db.delete(
      'cars',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}