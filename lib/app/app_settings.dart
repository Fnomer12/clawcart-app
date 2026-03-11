import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  String get appearanceLabel {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
    }
  }

  String get languageLabel {
    switch (_locale.languageCode) {
      case 'fr':
        return 'French';
      case 'es':
        return 'Spanish';
      case 'en':
      default:
        return 'English';
    }
  }

  void setAppearance(String value) {
    switch (value) {
      case 'Light':
        _themeMode = ThemeMode.light;
        break;
      case 'System':
        _themeMode = ThemeMode.system;
        break;
      case 'Dark':
      default:
        _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }

  void setLanguage(String value) {
    switch (value) {
      case 'French':
        _locale = const Locale('fr');
        break;
      case 'Spanish':
        _locale = const Locale('es');
        break;
      case 'English':
      default:
        _locale = const Locale('en');
    }
    notifyListeners();
  }
}