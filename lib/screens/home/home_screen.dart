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
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_empty_state.dart';

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

      if (!mounted) return;

      showAppSnackBar(
        context: context,
        message: 'Samochód został dodany.',
      );
    }
  }

  Future<void> _deleteCar(Car car) async {
    final id = car.id;

    if (id == null) return;

    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Usunąć samochód?',
      message:
        'Samochód oraz jego historia serwisowa i tankowania zostaną trwale usunięte.',
    );

    if (!confirmed) return;

    await _repository.deleteCar(id);
    await _loadCars();
    if (!mounted) return;

    showAppSnackBar(
      context: context,
      message: 'Samochód został usunięty.',
    );
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
              AppEmptyState(
                icon: Icons.directions_car,
                title: 'Brak dodanych samochodów',
                message: 'Dodaj pierwszy pojazd i zacznij prowadzić jego historię serwisową.',
                action: AppButton(
                  text: 'Dodaj samochód',
                  icon: Icons.add,
                  onPressed: _openAddCarScreen,
                ),
              )
            else
              ..._cars.map(
                (car) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () async {
                      final currentContext = context;

                      final result = await Navigator.push<bool>(
                        currentContext,
                        MaterialPageRoute(
                          builder: (_) => CarDetailsScreen(car: car),
                        ),
                      );

                      if (result == true) {
                        await _loadCars();

                        if (!currentContext.mounted) return;

                        showAppSnackBar(
                          context: currentContext,
                          message: 'Dane samochodu zostały zaktualizowane.',
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                car.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${car.brand} ${car.model} • ${car.year}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${car.mileage} km',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteCar(car),
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