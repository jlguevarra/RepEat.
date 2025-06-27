import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'main_nav_screen.dart'; // ✅ Import MainNavScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RepEat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(), // ✅ still starts with Splash
    );
  }
}
