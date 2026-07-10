import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/car.dart';
import '../../models/car_photo.dart';
import '../../repositories/car_photo_repository.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_section_title.dart';
import '../add_car/add_car_screen.dart';
import '../expenses/expenses_screen.dart';
import '../fuel/fuel_history_screen.dart';
import '../gallery/car_gallery_screen.dart';
import '../reminders/reminders_screen.dart';
import '../service_history/service_history_screen.dart';
import '../documents/documents_screen.dart';

class CarDetailsScreen extends StatefulWidget {
  final Car car;

  const CarDetailsScreen({super.key, required this.car});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  final _photoRepository = CarPhotoRepository();

  late Car car;
  CarPhoto? _coverPhoto;

  @override
  void initState() {
    super.initState();

    car = widget.car;
    _loadCoverPhoto();
  }

  Future<void> _loadCoverPhoto() async {
    final carId = car.id;

    if (carId == null) return;

    final coverPhoto = await _photoRepository.getCoverPhoto(carId);

    if (!mounted) return;

    setState(() {
      _coverPhoto = coverPhoto;
    });
  }

  Future<void> _editCar() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddCarScreen(car: car)),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moduleTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: car.name,
      actions: [
        IconButton(
          tooltip: 'Edytuj samochód',
          icon: const Icon(Icons.edit_outlined),
          onPressed: _editCar,
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_coverPhoto != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.file(
                        File(_coverPhoto!.filePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Icon(
                    Icons.directions_car_filled,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  '${car.brand} ${car.model}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _infoRow('Rok', car.year.toString()),
                _infoRow('Przebieg', '${car.mileage} km'),
                _infoRow('VIN', car.vin),
                _infoRow('Rejestracja', car.plateNumber),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const AppSectionTitle(
            title: 'Moduły pojazdu',
            subtitle: 'Zarządzaj historią i kosztami auta.',
          ),
          const SizedBox(height: 16),
          _moduleTile(
            context: context,
            icon: Icons.build,
            title: 'Historia serwisowa',
            subtitle: 'Naprawy, przeglądy, części i notatki.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceHistoryScreen(car: car),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _moduleTile(
            context: context,
            icon: Icons.local_gas_station,
            title: 'Tankowania',
            subtitle: 'Spalanie, koszty paliwa i przebieg.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FuelHistoryScreen(car: car)),
              );
            },
          ),
          const SizedBox(height: 12),
          _moduleTile(
            context: context,
            icon: Icons.payments,
            title: 'Koszty',
            subtitle: 'Wydatki związane z pojazdem.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ExpensesScreen(car: car)),
              );
            },
          ),
          const SizedBox(height: 12),
          _moduleTile(
            context: context,
            icon: Icons.description,
            title: 'Dokumenty',
            subtitle: 'Polisy, faktury i ważne pliki.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DocumentsScreen(car: car)),
              );
            },
          ),
          const SizedBox(height: 12),
          _moduleTile(
            context: context,
            icon: Icons.notifications_active,
            title: 'Przypomnienia',
            subtitle: 'OC, przegląd, olej i własne terminy.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RemindersScreen(car: car)),
              );
            },
          ),
          const SizedBox(height: 12),
          _moduleTile(
            context: context,
            icon: Icons.photo_library,
            title: 'Galeria',
            subtitle: 'Zdjęcia pojazdu i dokumentacji.',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CarGalleryScreen(car: car)),
              );

              await _loadCoverPhoto();
            },
          ),
        ],
      ),
    );
  }
}
