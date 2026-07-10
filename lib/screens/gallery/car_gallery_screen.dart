import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/car.dart';
import '../../models/car_photo.dart';
import '../../repositories/car_photo_repository.dart';
import '../../services/photo_storage_service.dart';
import '../../widgets/app_confirm_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_snackbar.dart';
import 'photo_viewer_screen.dart';

class CarGalleryScreen extends StatefulWidget {
  final Car car;

  const CarGalleryScreen({super.key, required this.car});

  @override
  State<CarGalleryScreen> createState() => _CarGalleryScreenState();
}

class _CarGalleryScreenState extends State<CarGalleryScreen> {
  final _repository = CarPhotoRepository();
  final _storageService = PhotoStorageService();
  final _picker = ImagePicker();

  List<CarPhoto> _photos = [];
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final carId = widget.car.id;

    if (carId == null) return;

    final photos = await _repository.getPhotosForCar(carId);

    if (!mounted) return;

    setState(() {
      _photos = photos;
      _isLoading = false;
    });
  }

  Future<String?> _askCaption() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Podpis zdjęcia'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Podpis',
              hintText: 'Opcjonalny opis zdjęcia',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text('Dodaj'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  Future<void> _addPhotos() async {
    final carId = widget.car.id;

    if (carId == null || _isAdding) return;

    final selectedImages = await _picker.pickMultiImage(imageQuality: 88);

    if (selectedImages.isEmpty) return;

    String caption = '';

    if (selectedImages.length == 1) {
      final result = await _askCaption();

      if (result == null) return;

      caption = result;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      for (final image in selectedImages) {
        final savedPath = await _storageService.savePhoto(
          carId: carId,
          sourcePath: image.path,
        );

        await _repository.insertPhoto(
          CarPhoto(
            carId: carId,
            filePath: savedPath,
            caption: selectedImages.length == 1 ? caption : '',
            isCover: false,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }

      await _loadPhotos();

      if (!mounted) return;

      showAppSnackBar(
        context: context,
        message: selectedImages.length == 1
            ? 'Zdjęcie zostało dodane.'
            : 'Dodano ${selectedImages.length} zdjęć.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  Future<void> _editCaption(CarPhoto photo) async {
    final id = photo.id;

    if (id == null) return;

    final controller = TextEditingController(text: photo.caption);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edytuj podpis'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Podpis zdjęcia'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null) return;

    await _repository.updateCaption(id: id, caption: result);

    await _loadPhotos();

    if (!mounted) return;

    showAppSnackBar(context: context, message: 'Podpis został zaktualizowany.');
  }

  Future<void> _setCover(CarPhoto photo) async {
    final carId = widget.car.id;
    final photoId = photo.id;

    if (carId == null || photoId == null) return;

    await _repository.setCoverPhoto(carId: carId, photoId: photoId);

    await _loadPhotos();

    if (!mounted) return;

    showAppSnackBar(context: context, message: 'Ustawiono zdjęcie główne.');
  }

  Future<void> _deletePhoto(CarPhoto photo) async {
    final carId = widget.car.id;
    final photoId = photo.id;

    if (carId == null || photoId == null) return;

    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Usunąć zdjęcie?',
      message: 'Zdjęcie zostanie usunięte z galerii i pamięci aplikacji.',
    );

    if (!confirmed) return;

    await _repository.deletePhoto(photoId: photoId, carId: carId);

    await _storageService.deletePhoto(photo.filePath);
    await _loadPhotos();

    if (!mounted) return;

    showAppSnackBar(context: context, message: 'Zdjęcie zostało usunięte.');
  }

  void _openViewer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoViewerScreen(photos: _photos, initialIndex: index),
      ),
    );
  }

  Future<void> _showPhotoOptions(CarPhoto photo) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edytuj podpis'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _editCaption(photo);
                },
              ),
              if (!photo.isCover)
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text('Ustaw jako główne'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _setCover(photo);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Usuń zdjęcie'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _deletePhoto(photo);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Galeria',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isAdding ? null : _addPhotos,
        icon: _isAdding
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_photo_alternate_outlined),
        label: Text(_isAdding ? 'Dodawanie...' : 'Dodaj zdjęcia'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
          ? ListView(
              padding: EdgeInsets.all(16),
              children: [
                AppEmptyState(
                  icon: Icons.photo_library_outlined,
                  title: 'Brak zdjęć',
                  message:
                      'Dodaj zdjęcia samochodu, napraw, części lub dokumentacji.',
                ),
              ],
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final photo = _photos[index];

                return GestureDetector(
                  onTap: () => _openViewer(index),
                  onLongPress: () => _showPhotoOptions(photo),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(photo.filePath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) {
                            return Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.broken_image_outlined),
                            );
                          },
                        ),
                        if (photo.isCover)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        if (photo.caption.isNotEmpty)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              color: Colors.black.withValues(alpha: 0.65),
                              child: Text(
                                photo.caption,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
