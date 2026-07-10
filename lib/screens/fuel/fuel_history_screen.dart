import 'package:flutter/material.dart';

import '../../models/car.dart';
import '../../models/fuel_entry.dart';
import '../../repositories/fuel_entry_repository.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_confirm_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_section_title.dart';
import '../../widgets/app_snackbar.dart';
import 'add_fuel_entry_screen.dart';

class FuelHistoryScreen extends StatefulWidget {
  final Car car;

  const FuelHistoryScreen({
    super.key,
    required this.car,
  });

  @override
  State<FuelHistoryScreen> createState() => _FuelHistoryScreenState();
}

class _FuelHistoryScreenState extends State<FuelHistoryScreen> {
  final _repository = FuelEntryRepository();

  List<FuelEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final carId = widget.car.id;

    if (carId == null) return;

    final entries = await _repository.getEntriesForCar(carId);

    if (!mounted) return;

    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  double get _totalFuelCost {
    return _entries.fold(
      0,
      (sum, entry) => sum + entry.totalCost,
    );
  }

  double get _totalLiters {
    return _entries.fold(
      0,
      (sum, entry) => sum + entry.liters,
    );
  }

  double get _averagePricePerLiter {
    if (_totalLiters == 0) return 0;

    return _totalFuelCost / _totalLiters;
  }

  double get _averageFuelConsumption {
    if (_entries.length < 2) return 0;

    final sortedEntries = [..._entries]
      ..sort((a, b) {
        final mileageComparison = a.mileage.compareTo(b.mileage);

        if (mileageComparison != 0) {
          return mileageComparison;
        }

        return a.date.compareTo(b.date);
      });

    int? previousFullTankMileage;
    double litersSinceFullTank = 0;
    double calculatedLiters = 0;
    int calculatedDistance = 0;

    for (final entry in sortedEntries) {
      if (previousFullTankMileage == null) {
        if (entry.isFullTank) {
          previousFullTankMileage = entry.mileage;
          litersSinceFullTank = 0;
        }

        continue;
      }

      litersSinceFullTank += entry.liters;

      if (!entry.isFullTank) {
        continue;
      }

      final distance = entry.mileage - previousFullTankMileage;

      if (distance > 0) {
        calculatedDistance += distance;
        calculatedLiters += litersSinceFullTank;
      }

      previousFullTankMileage = entry.mileage;
      litersSinceFullTank = 0;
    }

    if (calculatedDistance == 0) return 0;

    return calculatedLiters / calculatedDistance * 100;
  }

  Future<void> _openAddFuelEntryScreen({FuelEntry? entry}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddFuelEntryScreen(
          car: widget.car,
          entry: entry,
        ),
      ),
    );

    if (result == true) {
      await _loadEntries();

      if (!mounted) return;

      showAppSnackBar(
        context: context,
        message: entry == null
            ? 'Tankowanie zostało dodane.'
            : 'Tankowanie zostało zaktualizowane.',
      );
    }
  }

  Future<void> _deleteEntry(FuelEntry entry) async {
    final id = entry.id;

    if (id == null) return;

    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Usunąć tankowanie?',
      message: 'Ta operacja usunie wpis tankowania.',
    );

    if (!confirmed) return;

    await _repository.deleteEntry(id);
    await _loadEntries();

    if (!mounted) return;

    showAppSnackBar(
      context: context,
      message: 'Tankowanie zostało usunięte.',
    );
  }

  Widget _statItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tankowania',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddFuelEntryScreen(),
        icon: const Icon(Icons.add),
        label: const Text('Tankowanie'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppSectionTitle(
              title: widget.car.name,
              subtitle: 'Historia tankowań i kosztów paliwa.',
            ),
            const SizedBox(height: 20),
            if (!_isLoading && _entries.isNotEmpty) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Podsumowanie',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _statItem(
                          context: context,
                          icon: Icons.payments_outlined,
                          label: 'Łączny koszt',
                          value: '${_totalFuelCost.toStringAsFixed(2)} zł',
                        ),
                        const SizedBox(width: 16),
                        _statItem(
                          context: context,
                          icon: Icons.local_gas_station_outlined,
                          label: 'Łącznie paliwa',
                          value: '${_totalLiters.toStringAsFixed(2)} l',
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _statItem(
                          context: context,
                          icon: Icons.show_chart,
                          label: 'Średnia cena',
                          value:
                              '${_averagePricePerLiter.toStringAsFixed(2)} zł/l',
                        ),
                        const SizedBox(width: 16),
                        _statItem(
                          context: context,
                          icon: Icons.receipt_long_outlined,
                          label: 'Tankowania',
                          value: _entries.length.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _statItem(
                          context: context,
                          icon: Icons.speed,
                          label: 'Średnie spalanie',
                          value: _averageFuelConsumption == 0
                              ? 'Brak danych'
                              : '${_averageFuelConsumption.toStringAsFixed(2)} l/100 km',
                        ),
                        const SizedBox(width: 16),
                        _statItem(
                          context: context,
                          icon: Icons.check_circle_outline,
                          label: 'Pełne tankowania',
                          value: _entries
                              .where((entry) => entry.isFullTank)
                              .length
                              .toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_entries.isEmpty)
              const AppEmptyState(
                icon: Icons.local_gas_station,
                title: 'Brak tankowań',
                message: 'Dodaj pierwsze tankowanie, aby śledzić koszty paliwa.',
              )
            else
              ..._entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () => _openAddFuelEntryScreen(entry: entry),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.local_gas_station,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.totalCost.toStringAsFixed(2)} zł',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.date,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${entry.liters.toStringAsFixed(2)} l • ${entry.pricePerLiter.toStringAsFixed(2)} zł/l • ${entry.mileage} km',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              if (entry.isFullTank) ...[
                                const SizedBox(height: 5),
                                Text(
                                  'Tankowanie do pełna',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteEntry(entry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}