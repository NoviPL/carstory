import 'package:flutter/material.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_section_title.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'CarStory',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppSectionTitle(
            title: 'Twoje samochody',
            subtitle: 'Cyfrowa historia pojazdów w jednym miejscu.',
          ),
          const SizedBox(height: 20),
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
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}