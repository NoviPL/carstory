import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import 'theme.dart';

class CarStoryApp extends StatelessWidget {
  const CarStoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarStory',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const HomeScreen(),
    );
  }
}