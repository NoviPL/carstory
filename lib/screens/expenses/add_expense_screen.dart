import 'package:flutter/material.dart';

import '../../models/car.dart';
import '../../models/expense_entry.dart';
import '../../repositories/expense_entry_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_scaffold.dart';

class AddExpenseScreen extends StatefulWidget {
  final Car car;
  final ExpenseEntry? entry;

  const AddExpenseScreen({
    super.key,
    required this.car,
    this.entry,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  static const List<String> _categories = [
    'Ubezpieczenie',
    'Przegląd',
    'Myjnia',
    'Opony',
    'Parking',
    'Opłaty',
    'Akcesoria',
    'Inne',
  ];

  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();

  final _repository = ExpenseEntryRepository();

  String _selectedCategory = _categories.first;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _dateController.text = _formatDate(now);

    final entry = widget.entry;

    if (entry != null) {
      _titleController.text = entry.title;
      _amountController.text = entry.amount.toStringAsFixed(2);
      _dateController.text = entry.date;
      _noteController.text = entry.note;

      if (_categories.contains(entry.category)) {
        _selectedCategory = entry.category;
      } else {
        _selectedCategory = 'Inne';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  double? _parseAmount(String value) {
    return double.tryParse(
      value.trim().replaceAll(',', '.'),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'To pole jest wymagane';
    }

    return null;
  }

  String? _amountValidator(String? value) {
    final requiredError = _requiredValidator(value);

    if (requiredError != null) {
      return requiredError;
    }

    final amount = _parseAmount(value!);

    if (amount == null || amount <= 0) {
      return 'Wpisz poprawną kwotę';
    }

    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = DateTime.tryParse(_dateController.text) ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null) return;

    _dateController.text = _formatDate(pickedDate);
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final carId = widget.car.id;

    if (carId == null) return;

    setState(() {
      _isSaving = true;
    });

    final existingEntry = widget.entry;

    final entry = ExpenseEntry(
      id: existingEntry?.id,
      carId: carId,
      title: _titleController.text.trim(),
      category: _selectedCategory,
      amount: _parseAmount(_amountController.text)!,
      date: _dateController.text.trim(),
      note: _noteController.text.trim(),
      createdAt:
          existingEntry?.createdAt ?? DateTime.now().toIso8601String(),
    );

    if (existingEntry == null) {
      await _repository.insertEntry(entry);
    } else {
      await _repository.updateEntry(entry);
    }

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.entry == null ? 'Nowy koszt' : 'Edytuj koszt',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              validator: _requiredValidator,
              decoration: const InputDecoration(
                labelText: 'Nazwa kosztu',
                hintText: 'Np. ubezpieczenie OC',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategoria',
              ),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              validator: _amountValidator,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Kwota',
                suffixText: 'zł',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dateController,
              validator: _requiredValidator,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: 'Data',
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notatka',
                hintText: 'Opcjonalne dodatkowe informacje',
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: _isSaving
                  ? 'Zapisywanie...'
                  : widget.entry == null
                      ? 'Zapisz koszt'
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