import 'package:bijlismart/splash/splash_screen.dart';
import 'package:bijlismart/welcome.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bijlismart/appearance/theme.dart'; // Sirf ye aik import kafi hai

import 'Drawernav/about_us.dart';
import 'dashboard.dart';
import 'firebase_options.dart';
import 'onboarding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'BijliSmart',
      debugShowCheckedModeBanner: false,

      // FIX: Yahan 'themeMode' ki jagah check lagaya hai
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1F5F2),
        primaryColor: const Color(0xFF367C5F),
        cardColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF367C5F),
          brightness: Brightness.light,
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF1E4D3B),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF367C5F),
          brightness: Brightness.dark,
        ),
      ),

      home: SplashScreen(),
    );
  }
}