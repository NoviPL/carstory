import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/car.dart';
import '../../models/car_reminder.dart';
import '../../repositories/reminder_repository.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_confirm_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_section_title.dart';
import '../../widgets/app_snackbar.dart';
import 'add_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  final Car car;

  const RemindersScreen({super.key, required this.car});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _repository = ReminderRepository();

  List<CarReminder> _reminders = [];
  bool _isLoading = true;

  int get _activeCount {
    return _reminders.where((item) => !item.isCompleted).length;
  }

  int get _completedCount {
    return _reminders.where((item) => item.isCompleted).length;
  }

  int get _urgentCount {
    return _reminders.where((item) {
      if (item.isCompleted) return false;

      return _statusFor(item).level == _ReminderLevel.urgent;
    }).length;
  }

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final carId = widget.car.id;

    if (carId == null) return;

    final reminders = await _repository.getRemindersForCar(carId);

    if (!mounted) return;

    setState(() {
      _reminders = reminders;
      _isLoading = false;
    });
  }

  Future<void> _openForm({CarReminder? reminder}) async {
    final currentContext = context;

    final result = await Navigator.push<bool>(
      currentContext,
      MaterialPageRoute(
        builder: (_) => AddReminderScreen(car: widget.car, reminder: reminder),
      ),
    );

    if (result != true) return;

    await _loadReminders();

    if (!currentContext.mounted) return;

    showAppSnackBar(
      context: currentContext,
      message: reminder == null
          ? 'Przypomnienie zostało dodane.'
          : 'Przypomnienie zostało zaktualizowane.',
    );
  }

  Future<void> _toggleCompleted(CarReminder reminder) async {
    final id = reminder.id;
    if (id == null) return;

    await _repository.setCompleted(id: id, isCompleted: !reminder.isCompleted);

    await _loadReminders();

    if (!mounted) return;

    showAppSnackBar(
      context: context,
      message: reminder.isCompleted
          ? 'Przypomnienie zostało przywrócone.'
          : 'Przypomnienie oznaczono jako wykonane.',
    );
  }

  Future<void> _deleteReminder(CarReminder reminder) async {
    final id = reminder.id;
    if (id == null) return;

    final currentContext = context;

    final confirmed = await showAppConfirmDialog(
      context: currentContext,
      title: 'Usunąć przypomnienie?',
      message: 'Ta operacja trwale usunie przypomnienie.',
    );

    if (!confirmed) return;

    await _repository.deleteReminder(id);
    await _loadReminders();

    if (!currentContext.mounted) return;

    showAppSnackBar(
      context: currentContext,
      message: 'Przypomnienie zostało usunięte.',
    );
  }

  _ReminderStatus _statusFor(CarReminder reminder) {
    if (reminder.isCompleted) {
      return const _ReminderStatus(
        label: 'Wykonane',
        level: _ReminderLevel.completed,
      );
    }

    var urgent = false;
    var warning = false;

    final dueDateText = reminder.dueDate;

    if (dueDateText != null) {
      final dueDate = DateTime.tryParse(dueDateText);

      if (dueDate != null) {
        final today = DateTime.now();
        final currentDay = DateTime(today.year, today.month, today.day);

        final difference = dueDate.difference(currentDay).inDays;

        if (difference < 0) {
          urgent = true;
        } else if (difference <= 30) {
          warning = true;
        }
      }
    }

    final dueMileage = reminder.dueMileage;

    if (dueMileage != null) {
      final remaining = dueMileage - widget.car.mileage;

      if (remaining < 0) {
        urgent = true;
      } else if (remaining <= 1000) {
        warning = true;
      }
    }

    if (urgent) {
      return const _ReminderStatus(
        label: 'Po terminie',
        level: _ReminderLevel.urgent,
      );
    }

    if (warning) {
      return const _ReminderStatus(
        label: 'Wkrótce',
        level: _ReminderLevel.warning,
      );
    }

    return const _ReminderStatus(label: 'Aktualne', level: _ReminderLevel.ok);
  }

  Color _statusColor(_ReminderLevel level) {
    switch (level) {
      case _ReminderLevel.urgent:
        return AppColors.danger;
      case _ReminderLevel.warning:
        return AppColors.warning;
      case _ReminderLevel.completed:
        return AppColors.muted;
      case _ReminderLevel.ok:
        return AppColors.success;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'OC':
      case 'AC':
        return Icons.verified_user_outlined;
      case 'Przegląd':
        return Icons.fact_check_outlined;
      case 'Olej':
        return Icons.oil_barrel_outlined;
      case 'Opony':
        return Icons.tire_repair_outlined;
      case 'Rozrząd':
        return Icons.settings_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Widget _summaryItem({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
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
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
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
      title: 'Przypomnienia',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_alert),
        label: const Text('Przypomnienie'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReminders,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppSectionTitle(
              title: widget.car.name,
              subtitle: 'Terminy według daty i przebiegu pojazdu.',
            ),
            const SizedBox(height: 20),
            if (!_isLoading && _reminders.isNotEmpty) ...[
              AppCard(
                child: Row(
                  children: [
                    _summaryItem(
                      context: context,
                      label: 'Aktywne',
                      value: _activeCount.toString(),
                      icon: Icons.notifications_active_outlined,
                    ),
                    const SizedBox(width: 16),
                    _summaryItem(
                      context: context,
                      label: 'Pilne',
                      value: _urgentCount.toString(),
                      icon: Icons.warning_amber_outlined,
                    ),
                    const SizedBox(width: 16),
                    _summaryItem(
                      context: context,
                      label: 'Wykonane',
                      value: _completedCount.toString(),
                      icon: Icons.check_circle_outline,
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
            else if (_reminders.isEmpty)
              const AppEmptyState(
                icon: Icons.notifications_active_outlined,
                title: 'Brak przypomnień',
                message:
                    'Dodaj termin OC, przeglądu, wymiany oleju lub inne zdarzenie.',
              )
            else
              ..._reminders.map((reminder) {
                final status = _statusFor(reminder);
                final statusColor = _statusColor(status.level);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () => _openForm(reminder: reminder),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            _typeIcon(reminder.type),
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reminder.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      decoration: reminder.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reminder.type,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (reminder.dueDate != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Termin: ${reminder.dueDate}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              if (reminder.dueMileage != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Przebieg: ${reminder.dueMileage} km',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                status.label,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              tooltip: reminder.isCompleted
                                  ? 'Przywróć'
                                  : 'Oznacz jako wykonane',
                              icon: Icon(
                                reminder.isCompleted
                                    ? Icons.undo
                                    : Icons.check_circle_outline,
                              ),
                              onPressed: () => _toggleCompleted(reminder),
                            ),
                            IconButton(
                              tooltip: 'Usuń',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteReminder(reminder),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

enum _ReminderLevel { urgent, warning, ok, completed }

class _ReminderStatus {
  final String label;
  final _ReminderLevel level;

  const _ReminderStatus({required this.label, required this.level});
}
