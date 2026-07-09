import 'package:flutter/material.dart';

import '../../models/car.dart';
import '../../models/fuel_entry.dart';
import '../../widgets/app_scaffold.dart';

class AddFuelEntryScreen extends StatelessWidget {
  final Car car;
  final FuelEntry? entry;

  const AddFuelEntryScreen({
    super.key,
    required this.car,
    this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: entry == null ? 'Nowe tankowanie' : 'Edytuj tankowanie',
      body: const Center(
        child: Text('Formularz tankowania'),
      ),
    );
  }
}