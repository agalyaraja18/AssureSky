import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

/// Where a [LocationResult] came from.
enum LocationSource {
  /// Live device GPS fix.
  gps,

  /// A city the user picked manually (GPS is switched off for the app).
  manual,

  /// GPS was wanted but unavailable; using the last known location.
  lastKnown,

  /// Nothing available at all; using the built-in default city.
  fallback,
}

class LocationResult {
  final double lat;
  final double lon;
  final String cityName;
  final LocationSource source;

  const LocationResult({
    required this.lat,
    required this.lon,
    required this.cityName,
    this.source = LocationSource.gps,
  });

  bool get isGps => source == LocationSource.gps;

  /// True when the user wants GPS but we could not get a fix.
  bool get gpsUnavailable =>
      source == LocationSource.lastKnown || source == LocationSource.fallback;
}

class LocationService {
  /// Resolves the location to show weather for:
  ///  1. a manually chosen city (if the user turned GPS off by picking one),
  ///  2. otherwise a live GPS fix,
  ///  3. otherwise the last known location,
  ///  4. otherwise the default city.
  Future<LocationResult> getLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final useGps = prefs.getBool(AppConstants.keyUseGps) ?? true;
    final savedLat = prefs.getDouble(AppConstants.keySavedLat);
    final savedLon = prefs.getDouble(AppConstants.keySavedLon);
    final savedCity = prefs.getString(AppConstants.keySavedCityName);

    // 1. The user picked a city — keep showing it until they switch back.
    if (!useGps && savedLat != null && savedLon != null) {
      return LocationResult(
        lat: savedLat,
        lon: savedLon,
        cityName: savedCity ?? '',
        source: LocationSource.manual,
      );
    }

    // 2. Live GPS
    try {
      final permitted = await _checkPermission();
      if (permitted) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        // Remember the fix so there is a sensible fallback next time.
        await prefs.setDouble(AppConstants.keySavedLat, position.latitude);
        await prefs.setDouble(AppConstants.keySavedLon, position.longitude);
        return LocationResult(
          lat: position.latitude,
          lon: position.longitude,
          cityName: '', // resolved from the weather response
          source: LocationSource.gps,
        );
      }
    } catch (_) {
      // GPS failed — fall through to the saved location.
    }

    // 3. Last known location
    if (savedLat != null && savedLon != null) {
      return LocationResult(
        lat: savedLat,
        lon: savedLon,
        cityName: savedCity ?? '',
        source: LocationSource.lastKnown,
      );
    }

    // 4. Default
    return const LocationResult(
      lat: ApiConstants.defaultLat,
      lon: ApiConstants.defaultLon,
      cityName: ApiConstants.defaultCity,
      source: LocationSource.fallback,
    );
  }

  Future<bool> _checkPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Stores the city currently being shown (used as the offline / fallback
  /// location and by the background notification worker).
  Future<void> saveLocation(String cityName, double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keySavedCityName, cityName);
    await prefs.setDouble(AppConstants.keySavedLat, lat);
    await prefs.setDouble(AppConstants.keySavedLon, lon);
  }

  /// `true`  → follow the device GPS.
  /// `false` → stay on the manually chosen city.
  Future<void> setUseGps(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyUseGps, value);
  }
}
