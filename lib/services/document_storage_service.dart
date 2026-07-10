import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class DocumentStorageService {
  Future<Directory> _getCarDocumentsDirectory(int carId) async {
    final appDirectory = await getApplicationDocumentsDirectory();

    final directory = Directory(
      path.join(appDirectory.path, 'vehicle_documents', carId.toString()),
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<String> saveDocument({
    required int carId,
    required String sourcePath,
    required String originalFileName,
  }) async {
    final targetDirectory = await _getCarDocumentsDirectory(carId);

    final extension = path.extension(originalFileName);

    final safeBaseName = path
        .basenameWithoutExtension(originalFileName)
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    final targetFileName =
        '${DateTime.now().microsecondsSinceEpoch}_'
        '$safeBaseName$extension';

    final targetPath = path.join(targetDirectory.path, targetFileName);

    final copiedFile = await File(sourcePath).copy(targetPath);

    return copiedFile.path;
  }

  Future<void> deleteDocument(String filePath) async {
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteCarDocuments(int carId) async {
    final appDirectory = await getApplicationDocumentsDirectory();

    final directory = Directory(
      path.join(appDirectory.path, 'vehicle_documents', carId.toString()),
    );

    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
