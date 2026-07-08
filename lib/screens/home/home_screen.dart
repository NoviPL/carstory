import 'package:flutter/material.dart';

import '../../models/car.dart';
import '../../repositories/car_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_section_title.dart';
import '../add_car/add_car_screen.dart';
import '../car_details/car_details_screen.dart';
import '../../widgets/app_confirm_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repository = CarRepository();

  List<Car> _cars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    final cars = await _repository.getCars();

    if (!mounted) return;

    setState(() {
      _cars = cars;
      _isLoading = false;
    });
  }

  Future<void> _openAddCarScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddCarScreen(),
      ),
    );

    if (result == true) {
      await _loadCars();
    }
  }

  Future<void> _deleteCar(Car car) async {
    final id = car.id;

    if (id == null) return;

    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Usunąć samochód?',
      message: 'Ta operacja usunie samochód z aplikacji.',
    );

    if (!confirmed) return;

    await _repository.deleteCar(id);
    await _loadCars();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'CarStory',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCarScreen,
        icon: const Icon(Icons.add),
        label: const Text('Auto'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCars,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const AppSectionTitle(
              title: 'Twoje samochody',
              subtitle: 'Cyfrowa historia pojazdów w jednym miejscu.',
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_cars.isEmpty)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 42,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Brak dodanych samochodów',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dodaj pierwszy pojazd i zacznij prowadzić jego historię serwisową.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Dodaj samochód',
                      icon: Icons.add,
                      onPressed: _openAddCarScreen,
                    ),
                  ],
                ),
              )
            else
              ..._cars.map(
                (car) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CarDetailsScreen(car: car),
                        ),
                      );
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.directions_car,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(car.name),
                      subtitle: Text(
                        '${car.brand} ${car.model} • ${car.year} • ${car.mileage} km',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteCar(car),
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