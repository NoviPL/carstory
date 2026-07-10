import 'package:flutter/material.dart';

import '../../models/car.dart';
import '../../models/expense_entry.dart';
import '../../repositories/expense_entry_repository.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_confirm_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_section_title.dart';
import '../../widgets/app_snackbar.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  final Car car;

  const ExpensesScreen({super.key, required this.car});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _repository = ExpenseEntryRepository();

  List<ExpenseEntry> _entries = [];
  bool _isLoading = true;

  double get _totalAmount {
    return _entries.fold(0, (sum, entry) => sum + entry.amount);
  }

  Map<String, double> get _amountByCategory {
    final result = <String, double>{};

    for (final entry in _entries) {
      result[entry.category] = (result[entry.category] ?? 0) + entry.amount;
    }

    return result;
  }

  String get _largestCategory {
    if (_amountByCategory.isEmpty) return 'Brak';

    final sorted = _amountByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

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

  Future<void> _openEntryForm({ExpenseEntry? entry}) async {
    final currentContext = context;

    final result = await Navigator.push<bool>(
      currentContext,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(car: widget.car, entry: entry),
      ),
    );

    if (result != true) return;

    await _loadEntries();

    if (!currentContext.mounted) return;

    showAppSnackBar(
      context: currentContext,
      message: entry == null
          ? 'Koszt został dodany.'
          : 'Koszt został zaktualizowany.',
    );
  }

  Future<void> _deleteEntry(ExpenseEntry entry) async {
    final id = entry.id;

    if (id == null) return;

    final currentContext = context;

    final confirmed = await showAppConfirmDialog(
      context: currentContext,
      title: 'Usunąć koszt?',
      message: 'Ta operacja trwale usunie wybrany koszt.',
    );

    if (!confirmed) return;

    await _repository.deleteEntry(id);
    await _loadEntries();

    if (!currentContext.mounted) return;

    showAppSnackBar(context: currentContext, message: 'Koszt został usunięty.');
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Ubezpieczenie':
        return Icons.verified_user_outlined;
      case 'Przegląd':
        return Icons.fact_check_outlined;
      case 'Myjnia':
        return Icons.local_car_wash_outlined;
      case 'Opony':
        return Icons.tire_repair_outlined;
      case 'Parking':
        return Icons.local_parking_outlined;
      case 'Opłaty':
        return Icons.receipt_long_outlined;
      case 'Akcesoria':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.payments_outlined;
    }
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
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
      title: 'Koszty',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEntryForm(),
        icon: const Icon(Icons.add),
        label: const Text('Koszt'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppSectionTitle(
              title: widget.car.name,
              subtitle: 'Wydatki niezwiązane bezpośrednio z tankowaniem.',
            ),
            const SizedBox(height: 20),
            if (!_isLoading && _entries.isNotEmpty) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Podsumowanie kosztów',
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
                          label: 'Łącznie',
                          value: '${_totalAmount.toStringAsFixed(2)} zł',
                        ),
                        const SizedBox(width: 16),
                        _statItem(
                          context: context,
                          icon: Icons.receipt_long_outlined,
                          label: 'Liczba wpisów',
                          value: _entries.length.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _statItem(
                          context: context,
                          icon: Icons.category_outlined,
                          label: 'Największa kategoria',
                          value: _largestCategory,
                        ),
                        const SizedBox(width: 16),
                        _statItem(
                          context: context,
                          icon: Icons.calculate_outlined,
                          label: 'Średni koszt',
                          value:
                              '${(_totalAmount / _entries.length).toStringAsFixed(2)} zł',
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
                icon: Icons.payments_outlined,
                title: 'Brak dodatkowych kosztów',
                message:
                    'Dodaj ubezpieczenie, opłatę, parking, opony lub inny wydatek.',
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
                            _categoryIcon(entry.category),
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
                                '${entry.category} • ${entry.date}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${entry.amount.toStringAsFixed(2)} zł',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              if (entry.note.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  entry.note,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
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
