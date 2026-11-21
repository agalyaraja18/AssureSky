import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/alerts/alerts_repository.dart';

// Events
abstract class AlertsEvent {}

class AlertsLoadRequested extends AlertsEvent {
  /// Bypass the 5-minute memo (pull-to-refresh / retry).
  final bool force;
  AlertsLoadRequested({this.force = false});
}

// State
abstract class AlertsState {}

class AlertsInitial extends AlertsState {}

class AlertsLoading extends AlertsState {}

/// Alerts loaded. While some sources are still downloading
/// ([AlertsResult.isComplete] is false) this is a *partial* result that grows
/// as more sources finish.
class AlertsLoaded extends AlertsState {
  final AlertsResult result;
  AlertsLoaded(this.result);
}

class AlertsError extends AlertsState {
  final String message;
  AlertsError(this.message);
}

class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  final AlertsRepository _repository;

  AlertsBloc({AlertsRepository? repository})
      : _repository = repository ?? AlertsRepository(),
        super(AlertsInitial()) {
    on<AlertsLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
      AlertsLoadRequested event, Emitter<AlertsState> emit) async {
    // Keep what is on screen during a refresh; only show the full-screen
    // spinner for the very first load.
    if (state is! AlertsLoaded) emit(AlertsLoading());

    await emit.forEach<AlertsResult>(
      _repository.streamWorldAlerts(force: event.force),
      onData: AlertsLoaded.new,
      onError: (error, stack) {
        // A failed refresh must not wipe alerts that are already showing.
        if (state is AlertsLoaded) return state;
        return AlertsError(
            'Couldn\'t load weather alerts. Check your internet connection and try again.');
      },
    );
  }
}
