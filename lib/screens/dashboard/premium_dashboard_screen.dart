import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/car.dart';
import '../../models/car_photo.dart';
import '../../models/car_reminder.dart';
import '../../models/expense_entry.dart';
import '../../models/fuel_entry.dart';
import '../../models/service_entry.dart';
import '../../models/vehicle_document.dart';
import '../../repositories/car_photo_repository.dart';
import '../../repositories/expense_entry_repository.dart';
import '../../repositories/fuel_entry_repository.dart';
import '../../repositories/reminder_repository.dart';
import '../../repositories/service_entry_repository.dart';
import '../../repositories/vehicle_document_repository.dart';
import '../../widgets/app_scaffold.dart';
import '../add_car/add_car_screen.dart';
import '../documents/documents_screen.dart';
import '../expenses/expenses_screen.dart';
import '../fuel/add_fuel_entry_screen.dart';
import '../fuel/fuel_history_screen.dart';
import '../gallery/car_gallery_screen.dart';
import '../gallery/photo_viewer_screen.dart';
import '../reminders/reminders_screen.dart';
import '../service_history/add_service_entry_screen.dart';
import '../service_history/service_history_screen.dart';

class PremiumDashboardScreen extends StatefulWidget {
  final Car car;

  const PremiumDashboardScreen({super.key, required this.car});

  @override
  State<PremiumDashboardScreen> createState() => _PremiumDashboardScreenState();
}

class _PremiumDashboardScreenState extends State<PremiumDashboardScreen> {
  final _serviceRepository = ServiceEntryRepository();
  final _fuelRepository = FuelEntryRepository();
  final _expenseRepository = ExpenseEntryRepository();
  final _reminderRepository = ReminderRepository();
  final _documentRepository = VehicleDocumentRepository();
  final _photoRepository = CarPhotoRepository();

  late Car car;
  bool _isLoading = true;
  CarPhoto? _coverPhoto;
  List<ServiceEntry> _serviceEntries = [];
  List<FuelEntry> _fuelEntries = [];
  List<ExpenseEntry> _expenseEntries = [];
  List<CarReminder> _reminders = [];
  List<VehicleDocument> _documents = [];
  List<CarPhoto> _photos = [];

  @override
  void initState() {
    super.initState();
    car = widget.car;
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final carId = car.id;
    if (carId == null) return;

    final results = await Future.wait<dynamic>([
      _serviceRepository.getEntriesForCar(carId),
      _fuelRepository.getEntriesForCar(carId),
      _expenseRepository.getEntriesForCar(carId),
      _reminderRepository.getRemindersForCar(carId),
      _documentRepository.getDocumentsForCar(carId),
      _photoRepository.getPhotosForCar(carId),
      _photoRepository.getCoverPhoto(carId),
    ]);

    if (!mounted) return;

    setState(() {
      _serviceEntries = results[0] as List<ServiceEntry>;
      _fuelEntries = results[1] as List<FuelEntry>;
      _expenseEntries = results[2] as List<ExpenseEntry>;
      _reminders = results[3] as List<CarReminder>;
      _documents = results[4] as List<VehicleDocument>;
      _photos = results[5] as List<CarPhoto>;
      _coverPhoto = results[6] as CarPhoto?;
      _isLoading = false;
    });
  }

  double get _fuelCost =>
      _fuelEntries.fold(0, (sum, item) => sum + item.totalCost);

  double get _expenseCost =>
      _expenseEntries.fold(0, (sum, item) => sum + item.amount);

  double get _serviceCost =>
      _serviceEntries.fold(0, (sum, item) => sum + item.cost);

  double get _totalCost => _fuelCost + _expenseCost + _serviceCost;

  double get _averageFuelConsumption {
    if (_fuelEntries.length < 2) return 0;

    final sorted = [..._fuelEntries]
      ..sort((a, b) {
        final mileage = a.mileage.compareTo(b.mileage);
        if (mileage != 0) return mileage;
        return a.date.compareTo(b.date);
      });

    int? previousFullMileage;
    double litersSinceFull = 0;
    double usedLiters = 0;
    int distance = 0;

    for (final entry in sorted) {
      if (previousFullMileage == null) {
        if (entry.isFullTank) {
          previousFullMileage = entry.mileage;
          litersSinceFull = 0;
        }
        continue;
      }

      litersSinceFull += entry.liters;
      if (!entry.isFullTank) continue;

      final segmentDistance = entry.mileage - previousFullMileage;

      if (segmentDistance > 0) {
        distance += segmentDistance;
        usedLiters += litersSinceFull;
      }

      previousFullMileage = entry.mileage;
      litersSinceFull = 0;
    }

    if (distance == 0) return 0;
    return usedLiters / distance * 100;
  }

  int get _urgentReminderCount {
    return _reminders.where((item) {
      if (item.isCompleted) return false;

      final dueDate = item.dueDate == null
          ? null
          : DateTime.tryParse(item.dueDate!);

      final dateUrgent =
          dueDate != null &&
          dueDate.isBefore(DateTime.now().add(const Duration(days: 14)));

      final mileageUrgent =
          item.dueMileage != null && item.dueMileage! - car.mileage <= 1000;

      return dateUrgent || mileageUrgent;
    }).length;
  }

  int get _expiredDocumentCount {
    final today = DateTime.now();

    return _documents.where((item) {
      final expiry = item.expiryDate == null
          ? null
          : DateTime.tryParse(item.expiryDate!);

      return expiry != null && expiry.isBefore(today);
    }).length;
  }

  int get _healthScore {
    var score = 100;
    score -= _urgentReminderCount * 12;
    score -= _expiredDocumentCount * 14;
    if (_serviceEntries.isEmpty) score -= 8;
    if (_documents.isEmpty) score -= 5;
    return score.clamp(0, 100);
  }

  String get _healthLabel {
    if (_healthScore >= 90) return 'Doskonały stan';
    if (_healthScore >= 75) return 'Bardzo dobry stan';
    if (_healthScore >= 55) return 'Wymaga uwagi';
    return 'Pilna kontrola';
  }

  CarReminder? get _nearestReminder {
    final active = _reminders.where((item) => !item.isCompleted).toList();
    if (active.isEmpty) return null;

    active.sort((a, b) {
      final aDate = a.dueDate == null
          ? DateTime(9999)
          : DateTime.tryParse(a.dueDate!) ?? DateTime(9999);
      final bDate = b.dueDate == null
          ? DateTime(9999)
          : DateTime.tryParse(b.dueDate!) ?? DateTime(9999);

      final dateCompare = aDate.compareTo(bDate);
      if (dateCompare != 0) return dateCompare;

      return (a.dueMileage ?? 999999999).compareTo(b.dueMileage ?? 999999999);
    });

    return active.first;
  }

  List<_ActivityItem> get _recentActivities {
    final items = <_ActivityItem>[];

    for (final entry in _serviceEntries.take(4)) {
      items.add(
        _ActivityItem(
          title: entry.title,
          subtitle: '${entry.date} • ${entry.mileage} km',
          icon: Icons.build_outlined,
          sortDate: entry.createdAt,
        ),
      );
    }

    for (final entry in _fuelEntries.take(4)) {
      items.add(
        _ActivityItem(
          title: 'Tankowanie',
          subtitle: '${entry.date} • ${entry.totalCost.toStringAsFixed(2)} zł',
          icon: Icons.local_gas_station_outlined,
          sortDate: entry.createdAt,
        ),
      );
    }

    for (final entry in _expenseEntries.take(4)) {
      items.add(
        _ActivityItem(
          title: entry.title,
          subtitle: '${entry.category} • ${entry.amount.toStringAsFixed(2)} zł',
          icon: Icons.payments_outlined,
          sortDate: entry.createdAt,
        ),
      );
    }

    for (final entry in _documents.take(4)) {
      items.add(
        _ActivityItem(
          title: entry.title,
          subtitle: entry.category,
          icon: Icons.description_outlined,
          sortDate: entry.createdAt,
        ),
      );
    }

    items.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return items.take(5).toList();
  }

  Future<void> _openAndReload(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    await _loadDashboard();
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

  Future<void> _showQuickAddMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Szybkie dodawanie',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                _quickAddTile(
                  icon: Icons.build_outlined,
                  title: 'Wpis serwisowy',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openAndReload(AddServiceEntryScreen(car: car));
                  },
                ),
                _quickAddTile(
                  icon: Icons.local_gas_station_outlined,
                  title: 'Tankowanie',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openAndReload(AddFuelEntryScreen(car: car));
                  },
                ),
                _quickAddTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Zdjęcie',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openAndReload(CarGalleryScreen(car: car));
                  },
                ),
                _quickAddTile(
                  icon: Icons.description_outlined,
                  title: 'Dokument',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openAndReload(DocumentsScreen(car: car));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _quickAddTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '',
      actions: [
        IconButton(
          tooltip: 'Edytuj samochód',
          onPressed: _editCar,
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickAddMenu,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                children: [
                  _HeroCard(
                    car: car,
                    coverPhoto: _coverPhoto,
                    healthScore: _healthScore,
                    healthLabel: _healthLabel,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.speed_outlined,
                          label: 'Przebieg',
                          value: '${car.mileage}',
                          suffix: 'km',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.local_gas_station_outlined,
                          label: 'Średnie spalanie',
                          value: _averageFuelConsumption == 0
                              ? '—'
                              : _averageFuelConsumption.toStringAsFixed(1),
                          suffix: 'l/100',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.payments_outlined,
                          label: 'Łączne koszty',
                          value: _totalCost.toStringAsFixed(0),
                          suffix: 'zł',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.build_outlined,
                          label: 'Serwisy',
                          value: _serviceEntries.length.toString(),
                          suffix: 'wpisów',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle(
                    title: 'Centrum pojazdu',
                    subtitle: 'Wszystko, czego potrzebujesz w jednym miejscu.',
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.22,
                    children: [
                      _ModuleTile(
                        icon: Icons.build_outlined,
                        title: 'Serwis',
                        value: '${_serviceEntries.length}',
                        onTap: () =>
                            _openAndReload(ServiceHistoryScreen(car: car)),
                      ),
                      _ModuleTile(
                        icon: Icons.local_gas_station_outlined,
                        title: 'Tankowania',
                        value: '${_fuelEntries.length}',
                        onTap: () =>
                            _openAndReload(FuelHistoryScreen(car: car)),
                      ),
                      _ModuleTile(
                        icon: Icons.payments_outlined,
                        title: 'Koszty',
                        value: '${_expenseEntries.length}',
                        onTap: () => _openAndReload(ExpensesScreen(car: car)),
                      ),
                      _ModuleTile(
                        icon: Icons.description_outlined,
                        title: 'Dokumenty',
                        value: '${_documents.length}',
                        onTap: () => _openAndReload(DocumentsScreen(car: car)),
                      ),
                      _ModuleTile(
                        icon: Icons.notifications_active_outlined,
                        title: 'Przypomnienia',
                        value: '${_reminders.length}',
                        onTap: () => _openAndReload(RemindersScreen(car: car)),
                      ),
                      _ModuleTile(
                        icon: Icons.photo_library_outlined,
                        title: 'Galeria',
                        value: '${_photos.length}',
                        onTap: () => _openAndReload(CarGalleryScreen(car: car)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _HealthScore(
                    score: _healthScore,
                    label: _healthLabel,
                    urgentReminders: _urgentReminderCount,
                    expiredDocuments: _expiredDocumentCount,
                  ),
                  const SizedBox(height: 22),
                  if (_nearestReminder != null) ...[
                    const _SectionTitle(
                      title: 'Najbliższy termin',
                      subtitle: 'To zdarzenie wymaga Twojej uwagi.',
                    ),
                    const SizedBox(height: 12),
                    _GlassCard(
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nearestReminder!.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _nearestReminder!.dueDate != null
                                      ? 'Termin: ${_nearestReminder!.dueDate}'
                                      : 'Przebieg: ${_nearestReminder!.dueMileage} km',
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  if (_recentActivities.isNotEmpty) ...[
                    const _SectionTitle(
                      title: 'Ostatnia aktywność',
                      subtitle: 'Najnowsze zdarzenia związane z autem.',
                    ),
                    const SizedBox(height: 12),
                    _GlassCard(
                      child: Column(
                        children: [
                          for (
                            var i = 0;
                            i < _recentActivities.length;
                            i++
                          ) ...[
                            _ActivityRow(item: _recentActivities[i]),
                            if (i != _recentActivities.length - 1)
                              const Divider(height: 24),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  if (_photos.isNotEmpty) ...[
                    const _SectionTitle(
                      title: 'Ostatnie zdjęcia',
                      subtitle: 'Szybki podgląd galerii pojazdu.',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 142,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: math.min(_photos.length, 6),
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final photo = _photos[index];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PhotoViewerScreen(
                                    photos: _photos,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.file(
                                File(photo.filePath),
                                width: 178,
                                height: 142,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Car car;
  final CarPhoto? coverPhoto;
  final int healthScore;
  final String healthLabel;

  const _HeroCard({
    required this.car,
    required this.coverPhoto,
    required this.healthScore,
    required this.healthLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 330,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverPhoto != null)
            Image.file(File(coverPhoto!.filePath), fit: BoxFit.cover)
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF17233A), Color(0xFF07101E)],
                ),
              ),
              child: const Icon(
                Icons.directions_car_filled,
                size: 110,
                color: Colors.white12,
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xD9000000)],
                stops: [0.28, 1],
              ),
            ),
          ),
          Positioned(
            top: 18,
            left: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    healthLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 22,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        car.name,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${car.brand} ${car.model} • ${car.year}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Text(
                          '${car.mileage} km',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.46),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$healthScore',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'HEALTH',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 9,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String suffix;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 21),
          ),
          const SizedBox(height: 18),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    suffix,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.surfaceLight, AppColors.surface],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const Spacer(),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthScore extends StatelessWidget {
  final int score;
  final String label;
  final int urgentReminders;
  final int expiredDocuments;

  const _HealthScore({
    required this.score,
    required this.label,
    required this.urgentReminders,
    required this.expiredDocuments,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          SizedBox(
            width: 108,
            height: 108,
            child: CustomPaint(
              painter: _HealthRingPainter(progress: score / 100),
              child: Center(
                child: Text(
                  '$score',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stan pojazdu',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Text(
                  urgentReminders == 0
                      ? 'Brak pilnych przypomnień'
                      : 'Pilne przypomnienia: $urgentReminders',
                ),
                const SizedBox(height: 4),
                Text(
                  expiredDocuments == 0
                      ? 'Dokumenty są aktualne'
                      : 'Dokumenty po terminie: $expiredDocuments',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthRingPainter extends CustomPainter {
  final double progress;

  _HealthRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - 12) / 2;

    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.08);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [AppColors.primary, AppColors.success],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, backgroundPaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HealthRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String sortDate;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.sortDate,
  });
}

class _ActivityRow extends StatelessWidget {
  final _ActivityItem item;

  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(item.icon, color: AppColors.primary, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
