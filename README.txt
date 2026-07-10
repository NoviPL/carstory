1. Skopiuj katalog lib/screens/dashboard do projektu.
2. W home_screen.dart usuń import car_details_screen.dart.
3. Dodaj import:
   import '../dashboard/premium_dashboard_screen.dart';
4. Zamień CarDetailsScreen(car: car) na PremiumDashboardScreen(car: car).
5. Uruchom:
   dart format lib
   flutter analyze
