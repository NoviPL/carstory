import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import 'theme.dart';

class AutoKronikaApp extends StatelessWidget {
  const AutoKronikaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoKronika',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const HomeScreen(),
    );
  }
}
