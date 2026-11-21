import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/world_map_cities.dart';
import '../../../core/models/map_weather_model.dart';
import '../../../core/models/place_model.dart';
import '../../../core/services/map_weather_service.dart';
import '../../home/bloc/home_bloc.dart';
import '../../settings/bloc/settings_bloc.dart';
import '../marker_culling.dart';
import '../widgets/place_detail_card.dart';
import '../widgets/weather_marker.dart';

/// Zoomable world map. Every marker shows the place name, current temperature,
/// weather icon and the place's own local time. Tap a marker or any spot on the
/// map for details.
class WorldMapScreen extends StatefulWidget {
  final String currentCity;
  final double currentLat;
  final double currentLon;

  const WorldMapScreen({
    super.key,
    required this.currentCity,
    required this.currentLat,
    required this.currentLon,
  });

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  static const String _esri =
      'https://server.arcgisonline.com/ArcGIS/rest/services';
  static const double _minZoom = 2;
  static const double _maxZoom = 18;
  static final LatLngBounds _worldBounds =
      LatLngBounds(const LatLng(-85, -180), const LatLng(85, 180));

  final MapController _controller = MapController();
  final MapWeatherService _service = MapWeatherService();
  final Map<String, MapWeather> _weather = {};

  MapCamera? _camera;
  Timer? _debounce;
  Timer? _clock;
  bool _satellite = false;

  PlaceModel? _selected;
  MapWeather? _selectedWeather;
  bool _selectedLoading = false;
  bool _selectedIsCity = false;

  late final PlaceModel _current = PlaceModel(
    name: widget.currentCity,
    lat: widget.currentLat,
    lon: widget.currentLon,
  );

  @override
  void initState() {
    super.initState();
    // Local times on the markers move forward while the map is open.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _clock?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // --- camera / data -------------------------------------------------------

  void _onCamera(MapCamera camera) {
    _camera = camera;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else if (mounted) {
      setState(() {});
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _loadVisibleWeather);
  }

  /// Indexes into [worldMapCities] to draw, plus the current city marker
  /// (index -1) which is always shown.
  List<int> _visibleIndexes(MapCamera camera) {
    final candidates = <MarkerCandidate>[
      MarkerCandidate(-1, camera.latLngToScreenOffset(_current.latLng)),
      for (var i = 0; i < worldMapCities.length; i++)
        MarkerCandidate(
            i, camera.latLngToScreenOffset(worldMapCities[i].latLng)),
    ];
    return cullMarkers(
      candidates: candidates,
      markerSize: weatherMarkerSize,
      viewport: camera.size,
      forceShow: const {-1},
    );
  }

  Future<void> _loadVisibleWeather() async {
    final camera = _camera;
    if (camera == null || !mounted) return;
    final places = [
      for (final i in _visibleIndexes(camera))
        if (i == -1) _current else worldMapCities[i],
    ];
    final result = await _service.fetchFor(places);
    if (!mounted || result.isEmpty) return;
    setState(() => _weather.addAll(result));
  }

  MapWeather? _weatherFor(PlaceModel p) =>
      _weather[MapWeatherService.keyFor(p.lat, p.lon)];

  // --- selection -----------------------------------------------------------

  Future<void> _selectCity(PlaceModel city) async {
    final known = _weatherFor(city);
    setState(() {
      _selected = city;
      _selectedWeather = known;
      _selectedLoading = known == null;
      _selectedIsCity = true;
    });
    if (known != null) return;
    final w = await _service.fetchPoint(city.lat, city.lon);
    if (!mounted || _selected != city) return;
    setState(() {
      _selectedWeather = w;
      _selectedLoading = false;
    });
  }

  Future<void> _selectPoint(LatLng point) async {
    final pin = PlaceModel(
      name: _coordinateLabel(point),
      lat: point.latitude,
      lon: point.longitude,
    );
    setState(() {
      _selected = pin;
      _selectedWeather = null;
      _selectedLoading = true;
      _selectedIsCity = false;
    });
    final results = await Future.wait([
      _service.fetchPoint(point.latitude, point.longitude),
      _service.reverseGeocode(point.latitude, point.longitude),
    ]);
    if (!mounted || _selected != pin) return;
    final named = results[1] as PlaceModel?;
    setState(() {
      _selectedWeather = results[0] as MapWeather?;
      _selectedLoading = false;
      if (named != null) {
        _selected = PlaceModel(
          name: named.name,
          admin1: named.admin1,
          country: named.country,
          countryCode: named.countryCode,
          lat: point.latitude,
          lon: point.longitude,
        );
      }
    });
  }

  static String _coordinateLabel(LatLng p) {
    final ns = p.latitude >= 0 ? 'N' : 'S';
    final ew = p.longitude >= 0 ? 'E' : 'W';
    return '${p.latitude.abs().toStringAsFixed(2)}°$ns, '
        '${p.longitude.abs().toStringAsFixed(2)}°$ew';
  }

  void _clearSelection() => setState(() => _selected = null);

  void _setAsMyLocation() {
    final p = _selected;
    if (p == null) return;
    context
        .read<SettingsBloc>()
        .add(LocationChanged(p.name, p.lat, p.lon));
    context.read<HomeBloc>().add(HomeCityChanged(p.name, p.lat, p.lon));
    Navigator.of(context).pop();
  }

  // --- map controls --------------------------------------------------------

  void _zoomBy(double delta) {
    final cam = _controller.camera;
    _controller.move(cam.center, (cam.zoom + delta).clamp(_minZoom, _maxZoom));
  }

  void _zoomToSelected() {
    final p = _selected;
    if (p == null) return;
    _controller.move(p.latLng, math.max(_controller.camera.zoom, 11));
  }

  void _goToCurrent() {
    _controller.move(_current.latLng, 8);
  }

  // --- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final tempUnit =
        context.select<SettingsBloc, String>((b) => b.state.tempUnit);
    final selected = _selected;

    final markers = <Marker>[];
    final camera = _camera;
    if (camera != null) {
      for (final i in _visibleIndexes(camera)) {
        final place = i == -1 ? _current : worldMapCities[i];
        final isCurrent = i == -1;
        // The current city may also be in the list; skip the duplicate.
        if (!isCurrent && _isSameSpot(place, _current)) continue;
        markers.add(Marker(
          point: place.latLng,
          width: weatherMarkerSize.width,
          height: weatherMarkerSize.height,
          child: WeatherMarker(
            name: place.name,
            weather: _weatherFor(place),
            tempUnit: tempUnit,
            isCurrent: isCurrent,
            isSelected: selected != null && _isSameSpot(place, selected),
            onTap: () => _selectCity(place),
          ),
        ));
      }
      if (selected != null && !_selectedIsCity) {
        markers.add(Marker(
          point: selected.latLng,
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('World Weather Map')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _current.latLng,
              initialZoom: 4,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              backgroundColor:
                  dark ? const Color(0xFF0E1621) : const Color(0xFFAADAFF),
              cameraConstraint: CameraConstraint.contain(bounds: _worldBounds),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () => _onCamera(_controller.camera),
              onPositionChanged: (camera, _) => _onCamera(camera),
              onTap: (_, point) => _selectPoint(point),
            ),
            children: [
              TileLayer(
                urlTemplate: _satellite
                    ? '$_esri/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : dark
                        ? '$_esri/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}'
                        : '$_esri/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                maxNativeZoom: _satellite ? 17 : (dark ? 16 : 18),
                userAgentPackageName: 'com.assuresky.assuresky',
              ),
              MarkerLayer(markers: markers, rotate: false),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                showFlutterMapAttribution: false,
                attributions: [
                  const TextSourceAttribution(
                      'Map © Esri, HERE, Garmin, OpenStreetMap contributors'),
                  const TextSourceAttribution(
                      'Weather data by Open-Meteo.com'),
                ],
              ),
            ],
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Column(
              children: [
                _MapButton(
                  icon: _satellite ? Icons.map : Icons.satellite_alt,
                  tooltip: _satellite ? 'Street map' : 'Satellite',
                  onPressed: () => setState(() => _satellite = !_satellite),
                ),
                const SizedBox(height: 8),
                _MapButton(
                    icon: Icons.add,
                    tooltip: 'Zoom in',
                    onPressed: () => _zoomBy(1)),
                const SizedBox(height: 8),
                _MapButton(
                    icon: Icons.remove,
                    tooltip: 'Zoom out',
                    onPressed: () => _zoomBy(-1)),
                const SizedBox(height: 8),
                _MapButton(
                    icon: Icons.my_location,
                    tooltip: 'My location',
                    onPressed: _goToCurrent),
              ],
            ),
          ),
          if (selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 36,
              child: SafeArea(
                top: false,
                child: PlaceDetailCard(
                  place: selected,
                  weather: _selectedWeather,
                  loading: _selectedLoading,
                  tempUnit: tempUnit,
                  onClose: _clearSelection,
                  onZoom: _zoomToSelected,
                  onSetLocation: _setAsMyLocation,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static bool _isSameSpot(PlaceModel a, PlaceModel b) =>
      (a.lat - b.lat).abs() < 0.05 && (a.lon - b.lon).abs() < 0.05;
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _MapButton(
      {required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      elevation: 3,
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

extension on PlaceModel {
  LatLng get latLng => LatLng(lat, lon);
}
