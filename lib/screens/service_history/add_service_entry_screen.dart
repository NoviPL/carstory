import 'package:flutter/material.dart';

import '../../models/car.dart';
import '../../models/service_entry.dart';
import '../../repositories/service_entry_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_scaffold.dart';

class AddServiceEntryScreen extends StatefulWidget {
  final Car car;

  const AddServiceEntryScreen({
    super.key,
    required this.car,
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

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _dateController.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'To pole jest wymagane';
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

    await _repository.insertEntry(entry);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: _requiredValidator,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Nowy wpis serwisowy',
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
            ),
            const SizedBox(height: 12),
            _field(
              controller: _costController,
              label: 'Koszt',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            _field(
              controller: _dateController,
              label: 'Data, np. 2026-07-08',
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: _isSaving ? 'Zapisywanie...' : 'Zapisz wpis',
              icon: Icons.save,
              onPressed: _isSaving ? null : _saveEntry,
            ),
          ],
        ),
      ),
    );
  }
}