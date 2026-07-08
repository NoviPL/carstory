import 'package:flutter/material.dart';

import '../../models/car.dart';
import '../../repositories/car_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_scaffold.dart';

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _vinController = TextEditingController();
  final _plateController = TextEditingController();

  final _repository = CarRepository();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _vinController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final car = Car(
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: _yearController.text.trim(),
      mileage: _mileageController.text.trim(),
      vin: _vinController.text.trim(),
      plateNumber: _plateController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    await _repository.insertCar(car);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'To pole jest wymagane';
    }

    return null;
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: _requiredValidator,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dodaj samochód',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(
              controller: _nameController,
              label: 'Nazwa auta, np. Moje BMW',
            ),
            const SizedBox(height: 12),
            _field(
              controller: _brandController,
              label: 'Marka',
            ),
            const SizedBox(height: 12),
            _field(
              controller: _modelController,
              label: 'Model',
            ),
            const SizedBox(height: 12),
            _field(
              controller: _yearController,
              label: 'Rok produkcji',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _mileageController,
              label: 'Przebieg',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _vinController,
              label: 'VIN',
            ),
            const SizedBox(height: 12),
            _field(
              controller: _plateController,
              label: 'Numer rejestracyjny',
            ),
            const SizedBox(height: 24),
            AppButton(
              text: _isSaving ? 'Zapisywanie...' : 'Zapisz samochód',
              icon: Icons.save,
              onPressed: _isSaving ? null : _saveCar,
            ),
          ],
        ),
      ),
    );
  }
}