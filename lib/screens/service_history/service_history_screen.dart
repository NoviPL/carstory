import 'package:flutter/material.dart';

import '../../models/car.dart';
import '../../models/service_entry.dart';
import '../../repositories/service_entry_repository.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_section_title.dart';
import 'add_service_entry_screen.dart';
import '../../widgets/app_confirm_dialog.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_empty_state.dart';

class ServiceHistoryScreen extends StatefulWidget {
  final Car car;

  const ServiceHistoryScreen({
    super.key,
    required this.car,
  });

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

  Future<void> _deleteEntry(ServiceEntry entry) async {
    final id = entry.id;

    if (id == null) return;

    final confirmed = await showAppConfirmDialog(
        context: context,
        title: 'Usunąć wpis?',
        message: 'Ta operacja usunie wpis z historii serwisowej.',
    );

    if (!confirmed) return;

    await _repository.deleteEntry(id);
    await _loadEntries();
    if (!mounted) return;

    showAppSnackBar(
    context: context,
    message: 'Wpis został usunięty.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Historia serwisowa',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
            final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                builder: (_) => AddServiceEntryScreen(car: widget.car),
                ),
            );

            if (result == true) {
                await _loadEntries();

                if (!mounted) return;

                showAppSnackBar(
                    context: context,
                    message: 'Wpis serwisowy został dodany.',
                );
                }
            },
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
                message: 'Dodaj pierwszy wpis, np. wymianę oleju, przegląd lub naprawę.',
              )
            else
              ..._entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.build_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(entry.title),
                      subtitle: Text(
                        '${entry.date} • ${entry.mileage} km • ${entry.cost.toStringAsFixed(2)} zł',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteEntry(entry),
                      ),
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