import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/air_quality_model.dart';
import '../../../core/models/current_weather_model.dart';
import '../../../core/models/official_alert_model.dart';
import '../../../core/services/alerts/alert_provider.dart';
import '../../../core/services/alerts/alerts_repository.dart';
import '../../../core/services/asky_engine.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_dispatcher.dart';
import '../../../core/services/weather_alert_engine.dart';
import '../../../core/services/weather_insights.dart';
import '../../../core/services/weather_repository.dart';
import '../../../core/theme/theme_bloc.dart';

// Events
abstract class HomeEvent {}

/// Load weather for the "current" location: a manually chosen city if there is
/// one, otherwise GPS.
class HomeLoadRequested extends HomeEvent {}

class HomeRefreshRequested extends HomeEvent {}

/// The user picked a city. GPS is switched off until they ask for it back.
class HomeCityChanged extends HomeEvent {
  final String cityName;
  final double lat;
  final double lon;
  HomeCityChanged(this.cityName, this.lat, this.lon);
}

/// The user asked to follow their GPS location again.
class HomeUseCurrentLocationRequested extends HomeEvent {}

/// Look up official alerts for the location now on screen. Fired by the bloc
/// itself once the weather has loaded, so alerts never delay the weather.
class HomeOfficialAlertsRequested extends HomeEvent {
  final double lat;
  final double lon;
  final String cityName;
  final String countryCode;
  HomeOfficialAlertsRequested({
    required this.lat,
    required this.lon,
    required this.cityName,
    required this.countryCode,
  });
}

// State
abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final CurrentWeatherModel weather;
  final AirQualityModel airQuality;
  final AskyResult askyResult;
  final String cityName;
  final double lat;
  final double lon;

  /// Active weather alerts, most severe first.
  final List<WeatherAlert> alerts;

  /// True when the network failed and this is the last cached data.
  final bool fromCache;
  final DateTime? cachedAt;

  /// True when the forecast shows hail (used by the Asky mascot).
  final bool hasHail;

  /// Where the location came from (GPS, a chosen city, last known…).
  final LocationSource locationSource;

  /// Official alerts (IMD, NWS, MeteoAlarm…) that apply to this location.
  final List<OfficialAlert> officialAlerts;

  /// False until the official-alert lookup has finished.
  final bool officialAlertsLoaded;

  /// Alert sources that could not be reached during the lookup.
  final List<String> officialAlertsFailed;

  HomeLoaded({
    required this.weather,
    required this.airQuality,
    required this.askyResult,
    required this.cityName,
    required this.lat,
    required this.lon,
    this.alerts = const [],
    this.fromCache = false,
    this.cachedAt,
    this.hasHail = false,
    this.locationSource = LocationSource.gps,
    this.officialAlerts = const [],
    this.officialAlertsLoaded = false,
    this.officialAlertsFailed = const [],
  });

  HomeLoaded copyWith({
    List<OfficialAlert>? officialAlerts,
    bool? officialAlertsLoaded,
    List<String>? officialAlertsFailed,
  }) =>
      HomeLoaded(
        weather: weather,
        airQuality: airQuality,
        askyResult: askyResult,
        cityName: cityName,
        lat: lat,
        lon: lon,
        alerts: alerts,
        fromCache: fromCache,
        cachedAt: cachedAt,
        hasHail: hasHail,
        locationSource: locationSource,
        officialAlerts: officialAlerts ?? this.officialAlerts,
        officialAlertsLoaded: officialAlertsLoaded ?? this.officialAlertsLoaded,
        officialAlertsFailed: officialAlertsFailed ?? this.officialAlertsFailed,
      );
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}

// Bloc
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final WeatherRepository _repository;
  final LocationService _locationService;
  final ThemeBloc _themeBloc;
  final AlertsRepository _alertsRepository;

  HomeBloc({
    required WeatherRepository repository,
    required LocationService locationService,
    required ThemeBloc themeBloc,
    AlertsRepository? alertsRepository,
  })  : _repository = repository,
        _locationService = locationService,
        _themeBloc = themeBloc,
        _alertsRepository = alertsRepository ?? AlertsRepository(),
        super(HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeRefreshRequested>(_onRefresh);
    on<HomeCityChanged>(_onCityChanged);
    on<HomeUseCurrentLocationRequested>(_onUseCurrentLocation);
    on<HomeOfficialAlertsRequested>(_onOfficialAlerts);
  }

  Future<void> _onOfficialAlerts(
      HomeOfficialAlertsRequested event, Emitter<HomeState> emit) async {
    final NearbyAlerts nearby;
    try {
      nearby = await _alertsRepository.getAlertsNear(LocationQuery(
        lat: event.lat,
        lon: event.lon,
        cityName: event.cityName,
        countryCode: event.countryCode,
      ));
    } catch (_) {
      return; // alerts are a bonus; leave the dashboard as it is
    }

    // The user may have switched city while we were looking — drop stale
    // results rather than showing another city's alerts.
    final current = state;
    if (current is! HomeLoaded ||
        current.lat != event.lat ||
        current.lon != event.lon) {
      return;
    }
    emit(current.copyWith(
      officialAlerts: nearby.alerts,
      officialAlertsLoaded: true,
      officialAlertsFailed: nearby.failedSources,
    ));
  }

  Future<void> _onLoad(
      HomeLoadRequested event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    await _resolveAndLoad(emit);
  }

  Future<void> _onRefresh(
      HomeRefreshRequested event, Emitter<HomeState> emit) async {
    final current = state;
    if (current is! HomeLoaded) {
      await _resolveAndLoad(emit);
      return;
    }
    try {
      if (current.locationSource == LocationSource.gps) {
        // Following GPS: the user may have moved, so re-check the location.
        await _resolveAndLoad(emit, rethrowErrors: true);
      } else {
        await _loadFor(emit,
            lat: current.lat,
            lon: current.lon,
            cityName: current.cityName,
            source: current.locationSource);
      }
    } catch (_) {
      // A failed pull-to-refresh must not wipe the weather already on screen.
    }
  }

  Future<void> _onCityChanged(
      HomeCityChanged event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    await _locationService.setUseGps(false);
    try {
      await _loadFor(emit,
          lat: event.lat,
          lon: event.lon,
          cityName: event.cityName,
          source: LocationSource.manual);
    } catch (e) {
      emit(HomeError(_friendlyError(e)));
    }
  }

  Future<void> _onUseCurrentLocation(
      HomeUseCurrentLocationRequested event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    await _locationService.setUseGps(true);
    await _resolveAndLoad(emit);
  }

  /// Works out *where* to show weather for (manual city / GPS / fallback) and
  /// loads it.
  Future<void> _resolveAndLoad(Emitter<HomeState> emit,
      {bool rethrowErrors = false}) async {
    try {
      final location = await _locationService.getLocation();
      await _loadFor(emit,
          lat: location.lat,
          lon: location.lon,
          cityName: location.cityName,
          source: location.source);
    } catch (e, stack) {
      debugPrint('HomeBloc error: $e');
      debugPrint('$stack');
      if (rethrowErrors) rethrow;
      emit(HomeError(_friendlyError(e)));
    }
  }

  Future<void> _loadFor(
    Emitter<HomeState> emit, {
    required double lat,
    required double lon,
    required String cityName,
    required LocationSource source,
  }) async {
    final data = await _repository.getWeatherData(lat, lon);
    final name = cityName.isEmpty ? data.weather.cityName : cityName;

    await _locationService.saveLocation(name, lat, lon);

    final w = data.weather;
    _themeBloc.add(ThemeAutoDetected(
      w.conditionCode,
      windKmh: w.windSpeed,
      visibilityMeters: w.visibility,
      isHail: data.hasHail,
      tempC: w.temp,
      humidity: w.humidity,
    ));

    // On a refresh at the same place, keep showing the official alerts we
    // already have until the new lookup finishes (avoids a flicker).
    final previous = state;
    final samePlace =
        previous is HomeLoaded && previous.lat == lat && previous.lon == lon;

    emit(HomeLoaded(
      weather: w,
      airQuality: data.airQuality,
      askyResult: WeatherInsights.asky(data),
      alerts: WeatherInsights.alerts(data),
      cityName: name,
      lat: lat,
      lon: lon,
      fromCache: data.fromCache,
      cachedAt: data.cachedAt,
      hasHail: data.hasHail,
      locationSource: source,
      officialAlerts: samePlace ? previous.officialAlerts : const [],
      officialAlertsLoaded: samePlace && previous.officialAlertsLoaded,
      officialAlertsFailed: samePlace ? previous.officialAlertsFailed : const [],
    ));

    // Look up official alerts for this place in the background.
    add(HomeOfficialAlertsRequested(
      lat: lat,
      lon: lon,
      cityName: name,
      countryCode: w.country,
    ));

    // Send any notifications that are due. Best effort and never blocks the UI.
    unawaited(NotificationDispatcher.process(data, cityName: name)
        .catchError((Object e) => debugPrint('Notification error: $e')));
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Request timed out. Check your internet connection.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        case DioExceptionType.badResponse:
          switch (e.response?.statusCode) {
            case 401:
              return 'Invalid API key (401). Please check your OpenWeatherMap key.';
            case 404:
              return 'Location not found (404). Try a different city.';
            case 429:
              return 'Too many requests (429). Free plan limit reached — wait a minute.';
          }
          break;
        default:
          break;
      }
    }
    return 'Something went wrong while loading the weather. Please try again.';
  }
}
