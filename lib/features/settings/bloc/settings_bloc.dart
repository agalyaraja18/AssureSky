import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

// Events
abstract class SettingsEvent {}

class SettingsLoaded extends SettingsEvent {}

class TempUnitChanged extends SettingsEvent {
  final String unit;
  TempUnitChanged(this.unit);
}

class WindUnitChanged extends SettingsEvent {
  final String unit;
  WindUnitChanged(this.unit);
}

class PressureUnitChanged extends SettingsEvent {
  final String unit;
  PressureUnitChanged(this.unit);
}

class LocationChanged extends SettingsEvent {
  final String cityName;
  final double lat;
  final double lon;
  LocationChanged(this.cityName, this.lat, this.lon);
}

class NotificationToggled extends SettingsEvent {
  final String key;
  final bool value;
  NotificationToggled(this.key, this.value);
}

// State
class SettingsState {
  final String tempUnit;
  final String windUnit;
  final String pressureUnit;
  final String cityName;
  final double lat;
  final double lon;
  final bool notifWeatherAlerts;
  final bool notifAskyAdvice;
  final bool notifTrendingNews;
  final bool notifDailyForecast;

  const SettingsState({
    this.tempUnit = AppConstants.tempCelsius,
    this.windUnit = AppConstants.windKmh,
    this.pressureUnit = AppConstants.pressureMb,
    this.cityName = 'Chennai',
    this.lat = 13.0827,
    this.lon = 80.2707,
    this.notifWeatherAlerts = true,
    this.notifAskyAdvice = true,
    this.notifTrendingNews = false,
    this.notifDailyForecast = true,
  });

  SettingsState copyWith({
    String? tempUnit,
    String? windUnit,
    String? pressureUnit,
    String? cityName,
    double? lat,
    double? lon,
    bool? notifWeatherAlerts,
    bool? notifAskyAdvice,
    bool? notifTrendingNews,
    bool? notifDailyForecast,
  }) {
    return SettingsState(
      tempUnit: tempUnit ?? this.tempUnit,
      windUnit: windUnit ?? this.windUnit,
      pressureUnit: pressureUnit ?? this.pressureUnit,
      cityName: cityName ?? this.cityName,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      notifWeatherAlerts: notifWeatherAlerts ?? this.notifWeatherAlerts,
      notifAskyAdvice: notifAskyAdvice ?? this.notifAskyAdvice,
      notifTrendingNews: notifTrendingNews ?? this.notifTrendingNews,
      notifDailyForecast: notifDailyForecast ?? this.notifDailyForecast,
    );
  }
}

// Bloc
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<SettingsLoaded>(_onLoaded);
    on<TempUnitChanged>(_onTempUnit);
    on<WindUnitChanged>(_onWindUnit);
    on<PressureUnitChanged>(_onPressureUnit);
    on<LocationChanged>(_onLocation);
    on<NotificationToggled>(_onNotification);
  }

  Future<void> _onLoaded(
      SettingsLoaded event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    emit(SettingsState(
      tempUnit: prefs.getString(AppConstants.keyTempUnit) ??
          AppConstants.tempCelsius,
      windUnit: prefs.getString(AppConstants.keyWindUnit) ??
          AppConstants.windKmh,
      pressureUnit: prefs.getString(AppConstants.keyPressureUnit) ??
          AppConstants.pressureMb,
      cityName: prefs.getString(AppConstants.keySavedCityName) ?? 'Chennai',
      lat: prefs.getDouble(AppConstants.keySavedLat) ?? 13.0827,
      lon: prefs.getDouble(AppConstants.keySavedLon) ?? 80.2707,
      notifWeatherAlerts:
          prefs.getBool(AppConstants.keyNotifWeatherAlerts) ?? true,
      notifAskyAdvice:
          prefs.getBool(AppConstants.keyNotifAskyAdvice) ?? true,
      notifTrendingNews:
          prefs.getBool(AppConstants.keyNotifTrendingNews) ?? false,
      notifDailyForecast:
          prefs.getBool(AppConstants.keyNotifDailyForecast) ?? true,
    ));
  }

  Future<void> _onTempUnit(
      TempUnitChanged event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyTempUnit, event.unit);
    emit(state.copyWith(tempUnit: event.unit));
  }

  Future<void> _onWindUnit(
      WindUnitChanged event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyWindUnit, event.unit);
    emit(state.copyWith(windUnit: event.unit));
  }

  Future<void> _onPressureUnit(
      PressureUnitChanged event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyPressureUnit, event.unit);
    emit(state.copyWith(pressureUnit: event.unit));
  }

  Future<void> _onLocation(
      LocationChanged event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keySavedCityName, event.cityName);
    await prefs.setDouble(AppConstants.keySavedLat, event.lat);
    await prefs.setDouble(AppConstants.keySavedLon, event.lon);
    emit(state.copyWith(
        cityName: event.cityName, lat: event.lat, lon: event.lon));
  }

  Future<void> _onNotification(
      NotificationToggled event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(event.key, event.value);
    switch (event.key) {
      case AppConstants.keyNotifWeatherAlerts:
        emit(state.copyWith(notifWeatherAlerts: event.value));
        break;
      case AppConstants.keyNotifAskyAdvice:
        emit(state.copyWith(notifAskyAdvice: event.value));
        break;
      case AppConstants.keyNotifTrendingNews:
        emit(state.copyWith(notifTrendingNews: event.value));
        break;
      case AppConstants.keyNotifDailyForecast:
        emit(state.copyWith(notifDailyForecast: event.value));
        break;
    }
  }
}
