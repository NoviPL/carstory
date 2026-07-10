import '../database/app_database.dart';
import '../models/vehicle_document.dart';

class VehicleDocumentRepository {
  Future<int> insertDocument(VehicleDocument document) async {
    final db = await AppDatabase.database;

    return db.insert('vehicle_documents', document.toMap());
  }

  Future<void> updateDocument(VehicleDocument document) async {
    final db = await AppDatabase.database;

    await db.update(
      'vehicle_documents',
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<List<VehicleDocument>> getDocumentsForCar(int carId) async {
    final db = await AppDatabase.database;

    final rows = await db.query(
      'vehicle_documents',
      where: 'carId = ?',
      whereArgs: [carId],
      orderBy: '''
        CASE WHEN expiryDate IS NULL THEN 1 ELSE 0 END,
        expiryDate ASC,
        createdAt DESC,
        id DESC
      ''',
    );

    return rows.map(VehicleDocument.fromMap).toList();
  }

  Future<void> deleteDocument(int id) async {
    final db = await AppDatabase.database;

    await db.delete('vehicle_documents', where: 'id = ?', whereArgs: [id]);
  }
}
