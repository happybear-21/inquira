import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/theme_model.dart';

class ThemeProvider with ChangeNotifier {
  static const String _boxName = 'themeBox';
  late Box<ThemeModel> _themeBox;
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _initTheme();
  }

  Future<void> _initTheme() async {
    _themeBox = await Hive.openBox<ThemeModel>(_boxName);
    if (_themeBox.isEmpty) {
      await _themeBox.put('theme', ThemeModel(isDarkMode: false));
    }
    _isDarkMode = _themeBox.get('theme')?.isDarkMode ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _themeBox.put('theme', ThemeModel(isDarkMode: _isDarkMode));
    notifyListeners();
  }
} 