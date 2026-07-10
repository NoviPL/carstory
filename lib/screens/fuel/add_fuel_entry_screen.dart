import 'package:flutter/material.dart';

import '../../models/car.dart';
import '../../models/fuel_entry.dart';
import '../../repositories/fuel_entry_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../repositories/car_repository.dart';

class AddFuelEntryScreen extends StatefulWidget {
  final Car car;
  final FuelEntry? entry;

  const AddFuelEntryScreen({super.key, required this.car, this.entry});

  @override
  State<AddFuelEntryScreen> createState() => _AddFuelEntryScreenState();
}

class _AddFuelEntryScreenState extends State<AddFuelEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _mileageController = TextEditingController();
  final _litersController = TextEditingController();
  final _pricePerLiterController = TextEditingController();
  final _dateController = TextEditingController();

  final _repository = FuelEntryRepository();
  final _carRepository = CarRepository();

  bool _isFullTank = true;
  bool _isSaving = false;
  double _totalCost = 0;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _dateController.text = _formatDate(now);
    _mileageController.text = widget.car.mileage.toString();

    final entry = widget.entry;

    if (entry != null) {
      _mileageController.text = entry.mileage.toString();
      _litersController.text = entry.liters.toStringAsFixed(2);
      _pricePerLiterController.text = entry.pricePerLiter.toStringAsFixed(2);
      _dateController.text = entry.date;
      _totalCost = entry.totalCost;
      _isFullTank = entry.isFullTank;
    }

    _litersController.addListener(_calculateTotalCost);
    _pricePerLiterController.addListener(_calculateTotalCost);
  }

  @override
  void dispose() {
    _litersController.removeListener(_calculateTotalCost);
    _pricePerLiterController.removeListener(_calculateTotalCost);

    _mileageController.dispose();
    _litersController.dispose();
    _pricePerLiterController.dispose();
    _dateController.dispose();

    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  double? _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  void _calculateTotalCost() {
    final liters = _parseDouble(_litersController.text) ?? 0;
    final pricePerLiter = _parseDouble(_pricePerLiterController.text) ?? 0;

    final calculatedCost = liters * pricePerLiter;

    if (calculatedCost == _totalCost) return;

    setState(() {
      _totalCost = calculatedCost;
    });
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'To pole jest wymagane';
    }

    return null;
  }

  String? _mileageValidator(String? value) {
    final requiredError = _requiredValidator(value);

    if (requiredError != null) {
      return requiredError;
    }

    final mileage = int.tryParse(value!.trim());

    if (mileage == null || mileage < 0) {
      return 'Wpisz poprawny przebieg';
    }

    return null;
  }

  String? _positiveDoubleValidator(String? value) {
    final requiredError = _requiredValidator(value);

    if (requiredError != null) {
      return requiredError;
    }

    final number = _parseDouble(value!);

    if (number == null || number <= 0) {
      return 'Wpisz wartość większą od zera';
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

    final mileage = int.parse(_mileageController.text.trim());

    final liters = _parseDouble(_litersController.text)!;

    final pricePerLiter = _parseDouble(_pricePerLiterController.text)!;

    final totalCost = liters * pricePerLiter;

    final existingEntry = widget.entry;

    final entry = FuelEntry(
      id: existingEntry?.id,
      carId: carId,
      mileage: mileage,
      liters: liters,
      pricePerLiter: pricePerLiter,
      totalCost: totalCost,
      date: _dateController.text.trim(),
      createdAt: existingEntry?.createdAt ?? DateTime.now().toIso8601String(),
      isFullTank: _isFullTank,
    );

    if (existingEntry == null) {
      await _repository.insertEntry(entry);
    } else {
      await _repository.updateEntry(entry);
    }

    await _carRepository.updateMileageIfHigher(carId: carId, mileage: mileage);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    String? suffixText,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, suffixText: suffixText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.entry == null ? 'Nowe tankowanie' : 'Edytuj tankowanie',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(
              controller: _mileageController,
              label: 'Przebieg',
              suffixText: 'km',
              keyboardType: TextInputType.number,
              validator: _mileageValidator,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _litersController,
              label: 'Ilość paliwa',
              suffixText: 'l',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _positiveDoubleValidator,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _pricePerLiterController,
              label: 'Cena za litr',
              suffixText: 'zł',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _positiveDoubleValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              validator: _requiredValidator,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: 'Data tankowania',
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: const Text('Tankowanie do pełna'),
              subtitle: const Text(
                'Pełne tankowania są używane do obliczania średniego spalania.',
              ),
              value: _isFullTank,
              onChanged: (value) {
                setState(() {
                  _isFullTank = value;
                });
              },
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 34,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Łączny koszt',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_totalCost.toStringAsFixed(2)} zł',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: _isSaving
                  ? 'Zapisywanie...'
                  : widget.entry == null
                  ? 'Zapisz tankowanie'
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
