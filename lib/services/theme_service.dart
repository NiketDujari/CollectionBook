import 'package:flutter/material.dart';
import 'storage_service.dart';

class ThemeService {
  static final ThemeService instance = ThemeService._internal();
  ThemeService._internal();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  void initialize() {
    final String? savedTheme = StorageService.get('cb-dark-mode');
    if (savedTheme == 'true') {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.light;
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    await StorageService.set('cb-dark-mode', isDark ? 'true' : 'false');
  }
}
