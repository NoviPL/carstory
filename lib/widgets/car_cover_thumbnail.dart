import 'dart:io';

import 'package:flutter/material.dart';

import '../repositories/car_photo_repository.dart';

class CarCoverThumbnail extends StatelessWidget {
  final int? carId;
  final double size;

  const CarCoverThumbnail({super.key, required this.carId, this.size = 54});

  @override
  Widget build(BuildContext context) {
    final id = carId;

    if (id == null) {
      return _fallback(context);
    }

    return FutureBuilder(
      future: CarPhotoRepository().getCoverPhoto(id),
      builder: (context, snapshot) {
        final photo = snapshot.data;

        if (photo == null) {
          return _fallback(context);
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.file(
            File(photo.filePath),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) {
              return _fallback(context);
            },
          ),
        );
      },
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        Icons.directions_car,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
