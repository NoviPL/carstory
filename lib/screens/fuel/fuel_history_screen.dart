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

      if (!context.mounted) return;

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