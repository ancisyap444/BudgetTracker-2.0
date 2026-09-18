// lib/presentation/blocs/theme/theme_cubit.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _key = 'theme_mode';

  ThemeCubit() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_key);
    if (val == 'light') emit(ThemeMode.light);
    if (val == 'dark') emit(ThemeMode.dark);
    if (val == 'system') emit(ThemeMode.system);
  }

  Future<void> setTheme(ThemeMode mode) async {
    emit(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  void toggle(bool isDark) =>
      setTheme(isDark ? ThemeMode.dark : ThemeMode.light);
}
