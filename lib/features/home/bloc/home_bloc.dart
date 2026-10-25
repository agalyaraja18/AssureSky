import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/air_quality_model.dart';
import '../../../core/models/current_weather_model.dart';
import '../../../core/services/asky_engine.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/weather_repository.dart';
import '../../../core/theme/theme_bloc.dart';

// Events
abstract class HomeEvent {}

class HomeLoadRequested extends HomeEvent {}

class HomeRefreshRequested extends HomeEvent {}

class HomeCityChanged extends HomeEvent {
  final String cityName;
  final double lat;
  final double lon;
  HomeCityChanged(this.cityName, this.lat, this.lon);
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

  HomeLoaded({
    required this.weather,
    required this.airQuality,
    required this.askyResult,
    required this.cityName,
    required this.lat,
    required this.lon,
  });
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

  HomeBloc({
    required WeatherRepository repository,
    required LocationService locationService,
    required ThemeBloc themeBloc,
  })  : _repository = repository,
        _locationService = locationService,
        _themeBloc = themeBloc,
        super(HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeRefreshRequested>(_onRefresh);
    on<HomeCityChanged>(_onCityChanged);
  }

  Future<void> _onLoad(
      HomeLoadRequested event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    await _fetchWeather(emit);
  }

  Future<void> _onRefresh(
      HomeRefreshRequested event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final current = state as HomeLoaded;
      await _fetchWeatherForCity(
          current.cityName, current.lat, current.lon, emit);
    } else {
      await _fetchWeather(emit);
    }
  }

  Future<void> _onCityChanged(
      HomeCityChanged event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    await _fetchWeatherForCity(event.cityName, event.lat, event.lon, emit);
  }

  Future<void> _fetchWeather(Emitter<HomeState> emit) async {
    try {
      final location = await _locationService.getLocation();
      String cityName = location.cityName;

      final data =
          await _repository.getWeatherData(location.lat, location.lon);

      if (cityName.isEmpty) {
        cityName = data.weather.cityName;
      }

      await _locationService.saveLocation(
          cityName, location.lat, location.lon);

      _themeBloc.add(
          ThemeAutoDetected(data.weather.conditionCode));

      final askyInput = AskyEngine.buildInput(
        conditionCode: data.weather.conditionCode,
        temperature: data.weather.temp,
        uvIndex: data.weather.uvIndex,
        aqi: data.airQuality.aqi500,
        humidity: data.weather.humidity,
      );
      final askyResult = AskyEngine.getTips(askyInput);

      emit(HomeLoaded(
        weather: data.weather,
        airQuality: data.airQuality,
        askyResult: askyResult,
        cityName: cityName,
        lat: location.lat,
        lon: location.lon,
      ));
    } catch (e, stack) {
      // Print the real error to the debug console for diagnosis
      print('🔴 HomeBloc error: $e');
      print('🔴 Stack: $stack');
      final msg = _friendlyError(e);
      emit(HomeError(msg));
    }
  }

  Future<void> _fetchWeatherForCity(String cityName, double lat, double lon,
      Emitter<HomeState> emit) async {
    try {
      final data = await _repository.getWeatherData(lat, lon);

      _themeBloc.add(ThemeAutoDetected(data.weather.conditionCode));

      final askyInput = AskyEngine.buildInput(
        conditionCode: data.weather.conditionCode,
        temperature: data.weather.temp,
        uvIndex: data.weather.uvIndex,
        aqi: data.airQuality.aqi500,
        humidity: data.weather.humidity,
      );
      final askyResult = AskyEngine.getTips(askyInput);

      emit(HomeLoaded(
        weather: data.weather,
        airQuality: data.airQuality,
        askyResult: askyResult,
        cityName: cityName,
        lat: lat,
        lon: lon,
      ));
    } catch (e) {
      emit(HomeError(_friendlyError(e)));
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('401')) {
      return 'Invalid API key (401). Please check your OpenWeatherMap key in api_constants.dart';
    }
    if (msg.contains('404')) {
      return 'Location not found (404). Try a different city.';
    }
    if (msg.contains('429')) {
      return 'Too many requests (429). Free plan limit reached — wait a minute.';
    }
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return 'No internet connection. Please check your network.';
    }
    if (msg.contains('TimeoutException') || msg.contains('timeout')) {
      return 'Request timed out. Check your internet connection.';
    }
    return 'Error: $msg';
  }
}
