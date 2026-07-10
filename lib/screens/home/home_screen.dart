import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/car.dart';
import '../../repositories/car_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_confirm_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/car_cover_thumbnail.dart';
import '../about/about_screen.dart';
import '../add_car/add_car_screen.dart';
import '../dashboard/premium_dashboard_screen.dart';

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
      MaterialPageRoute(builder: (_) => const AddCarScreen()),
    );

    if (result != true) return;

    await _loadCars();

    if (!mounted) return;

    showAppSnackBar(context: context, message: 'Samochód został dodany.');
  }

  Future<void> _openCarDashboard(Car car) async {
    final currentContext = context;

    final result = await Navigator.push<bool>(
      currentContext,
      MaterialPageRoute(builder: (_) => PremiumDashboardScreen(car: car)),
    );

    await _loadCars();

    if (!currentContext.mounted) return;

    if (result == true) {
      showAppSnackBar(
        context: currentContext,
        message: 'Dane samochodu zostały zaktualizowane.',
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
          'Samochód oraz cała jego historia, tankowania, koszty, '
          'dokumenty, przypomnienia i zdjęcia zostaną trwale usunięte.',
    );

    if (!confirmed) return;

    await _repository.deleteCar(id);
    await _loadCars();

    if (!mounted) return;

    showAppSnackBar(context: context, message: 'Samochód został usunięty.');
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF182947), Color(0xFF0B1322)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -24,
            child: Icon(
              Icons.directions_car_filled,
              size: 138,
              color: Colors.white.withValues(alpha: 0.035),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 27,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _cars.isEmpty
                    ? 'Twoja motoryzacyjna historia'
                    : 'Wszystko pod kontrolą',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _cars.isEmpty
                    ? 'Dodaj pierwszy samochód i zacznij tworzyć jego cyfrową historię.'
                    : 'Zarządzaj historią, kosztami i dokumentami swoich pojazdów.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.45,
                  color: Colors.white70,
                ),
              ),
              if (_cars.isNotEmpty) ...[
                const SizedBox(height: 22),
                Row(
                  children: [
                    _headerStat(
                      context: context,
                      icon: Icons.directions_car_outlined,
                      value: _cars.length.toString(),
                      label: _cars.length == 1 ? 'samochód' : 'samochody',
                    ),
                    const SizedBox(width: 14),
                    _headerStat(
                      context: context,
                      icon: Icons.shield_outlined,
                      value: '100%',
                      label: 'offline',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.065),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarCard(BuildContext context, Car car) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        onTap: () => _openCarDashboard(car),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CarCoverThumbnail(carId: car.id, size: 72),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${car.brand} ${car.model} • ${car.year}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.speed,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${car.mileage} km',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Opcje',
              onSelected: (value) {
                if (value == 'open') {
                  _openCarDashboard(car);
                } else if (value == 'delete') {
                  _deleteCar(car);
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem(
                    value: 'open',
                    child: Row(
                      children: [
                        Icon(Icons.dashboard_outlined),
                        SizedBox(width: 12),
                        Text('Otwórz'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline),
                        SizedBox(width: 12),
                        Text('Usuń'),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'AutoKronika',
      actions: [
        IconButton(
          tooltip: 'Informacje o aplikacji',
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            );
          },
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCarScreen,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj auto'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCars,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            _buildPremiumHeader(context),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Twoje samochody',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (_cars.isNotEmpty)
                  Text(
                    '${_cars.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Wybierz pojazd, aby otworzyć jego centrum zarządzania.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_cars.isEmpty)
              AppEmptyState(
                icon: Icons.directions_car_outlined,
                title: 'Brak dodanych samochodów',
                message:
                    'Dodaj pierwszy pojazd i zacznij prowadzić jego historię serwisową.',
                action: AppButton(
                  text: 'Dodaj samochód',
                  icon: Icons.add,
                  onPressed: _openAddCarScreen,
                ),
              )
            else
              ..._cars.map((car) => _buildCarCard(context, car)),
          ],
        ),
      ),
    );
  }
}
