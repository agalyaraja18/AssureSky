import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/forecast_model.dart';
import '../../../core/services/weather_repository.dart';

// Events
abstract class ForecastEvent {}

class ForecastLoadRequested extends ForecastEvent {
  final double lat;
  final double lon;
  ForecastLoadRequested(this.lat, this.lon);
}

// State
abstract class ForecastState {}

class ForecastInitial extends ForecastState {}

class ForecastLoading extends ForecastState {}

class ForecastLoaded extends ForecastState {
  final ForecastModel forecast;
  ForecastLoaded(this.forecast);
}

class ForecastError extends ForecastState {
  final String message;
  ForecastError(this.message);
}

// Bloc
class ForecastBloc extends Bloc<ForecastEvent, ForecastState> {
  final WeatherRepository _repository;

  ForecastBloc({required WeatherRepository repository})
      : _repository = repository,
        super(ForecastInitial()) {
    on<ForecastLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
      ForecastLoadRequested event, Emitter<ForecastState> emit) async {
    emit(ForecastLoading());
    try {
      final forecast = await _repository.getForecast(event.lat, event.lon);
      emit(ForecastLoaded(forecast));
    } catch (e) {
      emit(ForecastError('Failed to load forecast data.'));
    }
  }
}
