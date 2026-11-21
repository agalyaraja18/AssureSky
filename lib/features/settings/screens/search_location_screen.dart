import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/popular_cities.dart';
import '../../../core/models/place_model.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/bloc/home_bloc.dart';
import '../bloc/settings_bloc.dart';

/// Pick any place in the world, or switch back to the device's GPS location.
class SearchLocationScreen extends StatefulWidget {
  const SearchLocationScreen({super.key});

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

enum _SearchStatus { idle, loading, results, empty, error }

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  static const Duration _debounce = Duration(milliseconds: 400);

  final TextEditingController _controller = TextEditingController();
  final GeocodingService _geocoding = GeocodingService();

  Timer? _timer;
  int _requestId = 0; // lets us ignore out-of-order responses

  _SearchStatus _status = _SearchStatus.idle;
  List<PlaceModel> _results = const [];
  String _query = '';

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    final query = value.trim();
    setState(() => _query = query);

    if (query.length < GeocodingService.minQueryLength) {
      _requestId++; // invalidate any in-flight search
      setState(() => _status = _SearchStatus.idle);
      return;
    }
    setState(() => _status = _SearchStatus.loading);
    _timer = Timer(_debounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    final id = ++_requestId;
    try {
      final places = await _geocoding.search(query);
      if (!mounted || id != _requestId) return; // a newer search superseded us
      setState(() {
        _results = places;
        _status = places.isEmpty ? _SearchStatus.empty : _SearchStatus.results;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() => _status = _SearchStatus.error);
    }
  }

  void _selectPlace(PlaceModel place) {
    context
        .read<SettingsBloc>()
        .add(LocationChanged(place.name, place.lat, place.lon));
    context
        .read<HomeBloc>()
        .add(HomeCityChanged(place.name, place.lat, place.lon));
    Navigator.of(context).pop();
  }

  void _useCurrentLocation() {
    context.read<HomeBloc>().add(HomeUseCurrentLocationRequested());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose location')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search any city in the world…',
                prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      ),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    switch (_status) {
      case _SearchStatus.loading:
        return const Center(
            child: CircularProgressIndicator(color: AppColors.accent));

      case _SearchStatus.results:
        return _placeList(theme, _results);

      case _SearchStatus.empty:
        return _message(
          theme,
          icon: Icons.search_off,
          text: 'No places found for "$_query".\nCheck the spelling or try a nearby city.',
        );

      case _SearchStatus.error:
        return _message(
          theme,
          icon: Icons.cloud_off,
          text: 'Couldn\'t search right now.\nCheck your connection and try again.',
          action: TextButton.icon(
            onPressed: () => _search(_query),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        );

      case _SearchStatus.idle:
        return _idleList(theme);
    }
  }

  /// Shown before the user types: GPS shortcut + popular cities.
  Widget _idleList(ThemeData theme) {
    final homeState = context.watch<HomeBloc>().state;
    final usingGps =
        homeState is HomeLoaded && homeState.locationSource == LocationSource.gps;
    final currentLocation = context.watch<SettingsBloc>().state;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.my_location, color: AppColors.accent),
            title: Text('Use my current location',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text('Follow your phone\'s GPS',
                style: theme.textTheme.bodySmall),
            trailing: usingGps
                ? const Icon(Icons.check, color: AppColors.accent)
                : null,
            onTap: _useCurrentLocation,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
          child: Text(
            'POPULAR CITIES',
            style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: AppColors.accent),
          ),
        ),
        ..._placeTiles(
          theme,
          popularCities,
          current: usingGps ? null : currentLocation,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _placeList(ThemeData theme, List<PlaceModel> places) {
    final homeState = context.watch<HomeBloc>().state;
    final usingGps =
        homeState is HomeLoaded && homeState.locationSource == LocationSource.gps;
    final currentLocation = context.watch<SettingsBloc>().state;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        ..._placeTiles(theme, places,
            current: usingGps ? null : currentLocation),
        const SizedBox(height: 16),
      ],
    );
  }

  /// A place is "selected" when it has the same name *and* is within ~0.2° of
  /// the saved location — so "Salem, Oregon" isn't ticked for "Salem, India".
  bool _isCurrent(PlaceModel place, SettingsState? current) =>
      current != null &&
      place.name == current.cityName &&
      (place.lat - current.lat).abs() < 0.2 &&
      (place.lon - current.lon).abs() < 0.2;

  List<Widget> _placeTiles(ThemeData theme, List<PlaceModel> places,
      {SettingsState? current}) {
    final tiles = <Widget>[];
    for (int i = 0; i < places.length; i++) {
      final place = places[i];
      final selected = _isCurrent(place, current);
      tiles.add(ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          Icons.location_on_outlined,
          color: selected ? AppColors.accent : theme.textTheme.bodySmall?.color,
          size: 22,
        ),
        title: Text(
          place.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: selected ? AppColors.accent : null,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: place.subtitle.isEmpty
            ? null
            : Text(place.subtitle, style: theme.textTheme.bodySmall),
        trailing:
            selected ? const Icon(Icons.check, color: AppColors.accent) : null,
        onTap: () => _selectPlace(place),
      ));
      if (i < places.length - 1) {
        tiles.add(Divider(height: 1, color: theme.dividerColor));
      }
    }
    return tiles;
  }

  Widget _message(ThemeData theme,
      {required IconData icon, required String text, Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      ),
    );
  }
}
