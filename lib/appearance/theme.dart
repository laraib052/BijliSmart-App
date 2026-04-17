import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme(bool isOn) {
    _isDarkMode = isOn;
    notifyListeners();
  }

  // Light Theme
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF367C5F),
    scaffoldBackgroundColor: const Color(0xFFF1F5F2),
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, iconTheme: IconThemeData(color: Color(0xFF1E4D3B))),
  );

  // Dark Theme
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF367C5F),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, iconTheme: IconThemeData(color: Colors.white)),
  );
}