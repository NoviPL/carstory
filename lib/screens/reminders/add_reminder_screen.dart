import 'package:flutter/material.dart';

import '../../models/car.dart';
import '../../models/car_reminder.dart';
import '../../repositories/reminder_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_scaffold.dart';

class AddReminderScreen extends StatefulWidget {
  final Car car;
  final CarReminder? reminder;

  const AddReminderScreen({
    super.key,
    required this.car,
    this.reminder,
  });

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  static const _types = [
    'OC',
    'AC',
    'Przegląd',
    'Olej',
    'Opony',
    'Rozrząd',
    'Inne',
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _mileageController = TextEditingController();
  final _noteController = TextEditingController();

  final _repository = ReminderRepository();

  String _selectedType = _types.first;
  bool _useDate = true;
  bool _useMileage = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final reminder = widget.reminder;

    if (reminder != null) {
      _titleController.text = reminder.title;
      _dateController.text = reminder.dueDate ?? '';
      _mileageController.text = reminder.dueMileage?.toString() ?? '';
      _noteController.text = reminder.note;
      _selectedType =
          _types.contains(reminder.type) ? reminder.type : 'Inne';
      _useDate = reminder.dueDate != null;
      _useMileage = reminder.dueMileage != null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _mileageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'To pole jest wymagane';
    }

    return null;
  }

  String? _mileageValidator(String? value) {
    if (!_useMileage) return null;

    if (value == null || value.trim().isEmpty) {
      return 'Podaj przebieg';
    }

    final mileage = int.tryParse(value.trim());

    if (mileage == null || mileage < 0) {
      return 'Wpisz poprawny przebieg';
    }

    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final initialDate =
        DateTime.tryParse(_dateController.text) ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );

    if (pickedDate == null) return;

    _dateController.text = _formatDate(pickedDate);
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_useDate && !_useMileage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Wybierz termin według daty, przebiegu albo obu.',
          ),
        ),
      );
      return;
    }

    if (_useDate && _dateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wybierz datę przypomnienia.'),
        ),
      );
      return;
    }

    final carId = widget.car.id;
    if (carId == null) return;

    setState(() {
      _isSaving = true;
    });

    final existing = widget.reminder;

    final reminder = CarReminder(
      id: existing?.id,
      carId: carId,
      title: _titleController.text.trim(),
      type: _selectedType,
      dueDate: _useDate ? _dateController.text.trim() : null,
      dueMileage: _useMileage
          ? int.parse(_mileageController.text.trim())
          : null,
      note: _noteController.text.trim(),
      isCompleted: existing?.isCompleted ?? false,
      createdAt:
          existing?.createdAt ?? DateTime.now().toIso8601String(),
    );

    if (existing == null) {
      await _repository.insertReminder(reminder);
    } else {
      await _repository.updateReminder(reminder);
    }

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.reminder == null
          ? 'Nowe przypomnienie'
          : 'Edytuj przypomnienie',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Typ przypomnienia',
              ),
              items: _types
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedType = value;

                  if (_titleController.text.trim().isEmpty &&
                      value != 'Inne') {
                    _titleController.text = value;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              validator: _requiredValidator,
              decoration: const InputDecoration(
                labelText: 'Nazwa przypomnienia',
                hintText: 'Np. wymiana oleju',
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Termin według daty'),
              value: _useDate,
              onChanged: (value) {
                setState(() {
                  _useDate = value;
                });
              },
            ),
            if (_useDate) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Termin',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Termin według przebiegu'),
              value: _useMileage,
              onChanged: (value) {
                setState(() {
                  _useMileage = value;
                });
              },
            ),
            if (_useMileage) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _mileageController,
                validator: _mileageValidator,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Przebieg docelowy',
                  suffixText: 'km',
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notatka',
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: _isSaving
                  ? 'Zapisywanie...'
                  : widget.reminder == null
                      ? 'Zapisz przypomnienie'
                      : 'Zapisz zmiany',
              icon: Icons.save,
              onPressed: _isSaving ? null : _saveReminder,
            ),
          ],
        ),
      ),
    );
  }
}