import 'package:flutter/material.dart';

import '../../models/car.dart';
import '../../models/service_entry.dart';
import '../../repositories/service_entry_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_scaffold.dart';
import '../../repositories/car_repository.dart';

class AddServiceEntryScreen extends StatefulWidget {
  final Car car;
  final ServiceEntry? entry;

  const AddServiceEntryScreen({
    super.key,
    required this.car,
    this.entry,
  });

  @override
  State<AddServiceEntryScreen> createState() => _AddServiceEntryScreenState();
}

class _AddServiceEntryScreenState extends State<AddServiceEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mileageController = TextEditingController();
  final _costController = TextEditingController();
  final _dateController = TextEditingController();

  final _repository = ServiceEntryRepository();
  final _carRepository = CarRepository();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _dateController.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final entry = widget.entry;

    if (entry != null) {
      _titleController.text = entry.title;
      _descriptionController.text = entry.description;
      _mileageController.text = entry.mileage.toString();
      _costController.text = entry.cost.toStringAsFixed(2);
      _dateController.text = entry.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _mileageController.dispose();
    _costController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null) return;

    _dateController.text =
        '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'To pole jest wymagane';
    }

    return null;
  }

  String? _intValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) return requiredError;

    final parsed = int.tryParse(value!.trim());

    if (parsed == null || parsed < 0) {
      return 'Wpisz poprawną liczbę';
    }

    return null;
  }

  String? _doubleValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) return requiredError;

    final parsed = double.tryParse(value!.trim().replaceAll(',', '.'));

    if (parsed == null || parsed < 0) {
      return 'Wpisz poprawną kwotę';
    }

    return null;
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final carId = widget.car.id;
    if (carId == null) return;

    setState(() {
      _isSaving = true;
    });

    final entry = ServiceEntry(
      carId: carId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      mileage: int.parse(_mileageController.text.trim()),
      cost: double.parse(_costController.text.trim().replaceAll(',', '.')),
      date: _dateController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    if (widget.entry == null) {
      await _repository.insertEntry(entry);
    } else {
      await _repository.updateEntry(
        ServiceEntry(
          id: widget.entry!.id,
          carId: entry.carId,
          title: entry.title,
          description: entry.description,
          mileage: entry.mileage,
          cost: entry.cost,
          date: entry.date,
          createdAt: widget.entry!.createdAt,
        ),
      );
    }

    await _carRepository.updateMileageIfHigher(
      carId: carId,
      mileage: entry.mileage,
    );

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Widget _field({
  required TextEditingController controller,
  required String label,
  TextInputType? keyboardType,
  int maxLines = 1,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    validator: validator ?? _requiredValidator,
    decoration: InputDecoration(
      labelText: label,
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.entry == null ? 'Nowy wpis serwisowy' : 'Edytuj wpis',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(
              controller: _titleController,
              label: 'Tytuł, np. Wymiana oleju',
            ),
            const SizedBox(height: 12),
            _field(
              controller: _descriptionController,
              label: 'Opis',
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _mileageController,
              label: 'Przebieg',
              keyboardType: TextInputType.number,
              validator: _intValidator,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _costController,
              label: 'Koszt',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,              
              ),
              validator: _doubleValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              validator: _requiredValidator,
              decoration: const InputDecoration(
                labelText: 'Data',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: _isSaving
                ? 'Zapisywanie...'
                : widget.entry == null
                    ? 'Zapisz wpis'
                    : 'Zapisz zmiany',
              icon: Icons.save,
              onPressed: _isSaving ? null : _saveEntry,
            ),
          ],
        ),
      ),
    );
  }
}