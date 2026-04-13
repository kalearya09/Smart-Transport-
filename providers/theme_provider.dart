import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get themeMode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  ThemeProvider() {
    final box = Hive.box('settings');
    final saved = box.get('theme', defaultValue: 'light');
    _mode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    Hive.box('settings').put('theme', isDark ? 'dark' : 'light');
    notifyListeners();
  }
}