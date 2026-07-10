import 'package:flutter/material.dart';

import '../../models/car.dart';
import '../../models/service_entry.dart';
import '../../repositories/service_entry_repository.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_confirm_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_section_title.dart';
import '../../widgets/app_snackbar.dart';
import 'add_service_entry_screen.dart';

class ServiceHistoryScreen extends StatefulWidget {
  final Car car;

  const ServiceHistoryScreen({super.key, required this.car});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  final _repository = ServiceEntryRepository();

  List<ServiceEntry> _entries = [];
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

  Future<void> _openEntryForm({ServiceEntry? entry}) async {
    final currentContext = context;

    final result = await Navigator.push<bool>(
      currentContext,
      MaterialPageRoute(
        builder: (_) => AddServiceEntryScreen(car: widget.car, entry: entry),
      ),
    );

    if (result == true) {
      await _loadEntries();

      if (!currentContext.mounted) return;

      showAppSnackBar(
        context: currentContext,
        message: entry == null
            ? 'Wpis serwisowy został dodany.'
            : 'Wpis został zaktualizowany.',
      );
    }
  }

  Future<void> _deleteEntry(ServiceEntry entry) async {
    final id = entry.id;
    if (id == null) return;

    final currentContext = context;

    final confirmed = await showAppConfirmDialog(
      context: currentContext,
      title: 'Usunąć wpis?',
      message: 'Ta operacja usunie wpis z historii serwisowej.',
    );

    if (!confirmed) return;

    await _repository.deleteEntry(id);
    await _loadEntries();

    if (!currentContext.mounted) return;

    showAppSnackBar(context: currentContext, message: 'Wpis został usunięty.');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Historia serwisowa',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEntryForm(),
        icon: const Icon(Icons.add),
        label: const Text('Wpis'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppSectionTitle(
              title: widget.car.name,
              subtitle: 'Naprawy, przeglądy, części i koszty.',
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
                icon: Icons.build,
                title: 'Brak wpisów serwisowych',
                message:
                    'Dodaj pierwszy wpis, np. wymianę oleju, przegląd lub naprawę.',
              )
            else
              ..._entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () => _openEntryForm(entry: entry),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.build,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.date,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${entry.mileage} km • ${entry.cost.toStringAsFixed(2)} zł',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
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
