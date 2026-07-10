import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class PhotoStorageService {
  Future<Directory> _getCarDirectory(int carId) async {
    final appDirectory = await getApplicationDocumentsDirectory();

    final directory = Directory(
      path.join(appDirectory.path, 'car_photos', carId.toString()),
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<String> savePhoto({
    required int carId,
    required String sourcePath,
  }) async {
    final targetDirectory = await _getCarDirectory(carId);

    final extension = path.extension(sourcePath).isEmpty
        ? '.jpg'
        : path.extension(sourcePath);

    final fileName = '${DateTime.now().microsecondsSinceEpoch}$extension';

    final targetPath = path.join(targetDirectory.path, fileName);

    final sourceFile = File(sourcePath);

    final copiedFile = await sourceFile.copy(targetPath);

    return copiedFile.path;
  }

  Future<void> deletePhoto(String filePath) async {
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteCarPhotos(int carId) async {
    final appDirectory = await getApplicationDocumentsDirectory();

    final directory = Directory(
      path.join(appDirectory.path, 'car_photos', carId.toString()),
    );

    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
