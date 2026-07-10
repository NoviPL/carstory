import '../database/app_database.dart';
import '../models/car_photo.dart';

class CarPhotoRepository {
  Future<int> insertPhoto(CarPhoto photo) async {
    final db = await AppDatabase.database;

    return db.transaction((transaction) async {
      final countResult = await transaction.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM car_photos
        WHERE carId = ?
        ''',
        [photo.carId],
      );

      final photoCount = (countResult.first['count'] as int?) ?? 0;

      final shouldBeCover = photo.isCover || photoCount == 0;

      if (shouldBeCover) {
        await transaction.update(
          'car_photos',
          {'isCover': 0},
          where: 'carId = ?',
          whereArgs: [photo.carId],
        );
      }

      return transaction.insert(
        'car_photos',
        photo.copyWith(isCover: shouldBeCover).toMap(),
      );
    });
  }

  Future<List<CarPhoto>> getPhotosForCar(int carId) async {
    final db = await AppDatabase.database;

    final rows = await db.query(
      'car_photos',
      where: 'carId = ?',
      whereArgs: [carId],
      orderBy: 'isCover DESC, createdAt DESC, id DESC',
    );

    return rows.map(CarPhoto.fromMap).toList();
  }

  Future<CarPhoto?> getCoverPhoto(int carId) async {
    final db = await AppDatabase.database;

    final rows = await db.query(
      'car_photos',
      where: 'carId = ? AND isCover = 1',
      whereArgs: [carId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return CarPhoto.fromMap(rows.first);
  }

  Future<void> updateCaption({required int id, required String caption}) async {
    final db = await AppDatabase.database;

    await db.update(
      'car_photos',
      {'caption': caption},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setCoverPhoto({required int carId, required int photoId}) async {
    final db = await AppDatabase.database;

    await db.transaction((transaction) async {
      await transaction.update(
        'car_photos',
        {'isCover': 0},
        where: 'carId = ?',
        whereArgs: [carId],
      );

      await transaction.update(
        'car_photos',
        {'isCover': 1},
        where: 'id = ? AND carId = ?',
        whereArgs: [photoId, carId],
      );
    });
  }

  Future<void> deletePhoto({required int photoId, required int carId}) async {
    final db = await AppDatabase.database;

    await db.transaction((transaction) async {
      final rows = await transaction.query(
        'car_photos',
        columns: ['isCover'],
        where: 'id = ?',
        whereArgs: [photoId],
        limit: 1,
      );

      if (rows.isEmpty) return;

      final wasCover = (rows.first['isCover'] as int? ?? 0) == 1;

      await transaction.delete(
        'car_photos',
        where: 'id = ?',
        whereArgs: [photoId],
      );

      if (!wasCover) return;

      final nextPhotos = await transaction.query(
        'car_photos',
        columns: ['id'],
        where: 'carId = ?',
        whereArgs: [carId],
        orderBy: 'createdAt DESC, id DESC',
        limit: 1,
      );

      if (nextPhotos.isEmpty) return;

      await transaction.update(
        'car_photos',
        {'isCover': 1},
        where: 'id = ?',
        whereArgs: [nextPhotos.first['id']],
      );
    });
  }
}
