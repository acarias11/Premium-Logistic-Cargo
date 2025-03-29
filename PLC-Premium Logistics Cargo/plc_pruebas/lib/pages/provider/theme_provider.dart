import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // Notifica a todas las páginas que el valor ha cambiado
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }
}