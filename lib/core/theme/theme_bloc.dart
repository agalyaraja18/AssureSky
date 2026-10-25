import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'app_theme.dart';
import 'package:flutter/material.dart';

// Events
abstract class ThemeEvent {}

class ThemeChanged extends ThemeEvent {
  final String themeName;
  ThemeChanged(this.themeName);
}

class ThemeAutoDetected extends ThemeEvent {
  final int weatherCode;
  ThemeAutoDetected(this.weatherCode);
}

class ThemeLoaded extends ThemeEvent {}

// State
class ThemeState {
  final ThemeData themeData;
  final String themeName;

  const ThemeState({required this.themeData, required this.themeName});
}

// Bloc
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc()
      : super(ThemeState(
            themeData: AppTheme.light,
            themeName: AppConstants.themeLight)) {
    on<ThemeLoaded>(_onLoaded);
    on<ThemeChanged>(_onChanged);
    on<ThemeAutoDetected>(_onAutoDetected);
  }

  Future<void> _onLoaded(
      ThemeLoaded event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final savedName =
        prefs.getString(AppConstants.keyThemeName) ?? AppConstants.themeLight;
    emit(ThemeState(
        themeData: AppTheme.fromName(savedName), themeName: savedName));
  }

  Future<void> _onChanged(
      ThemeChanged event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyThemeName, event.themeName);
    await prefs.setBool(AppConstants.keyThemeManualOverride, true);
    emit(ThemeState(
        themeData: AppTheme.fromName(event.themeName),
        themeName: event.themeName));
  }

  Future<void> _onAutoDetected(
      ThemeAutoDetected event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final isManual =
        prefs.getBool(AppConstants.keyThemeManualOverride) ?? false;
    if (isManual) return; // Respect manual override

    final themeName = AppTheme.themeFromConditionCode(event.weatherCode);
    await prefs.setString(AppConstants.keyThemeName, themeName);
    emit(ThemeState(
        themeData: AppTheme.fromName(themeName), themeName: themeName));
  }
}
