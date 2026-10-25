import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

class LocationResult {
  final double lat;
  final double lon;
  final String cityName;

  const LocationResult({
    required this.lat,
    required this.lon,
    required this.cityName,
  });
}

class LocationService {
  Future<LocationResult> getLocation() async {
    // 1. Try GPS
    try {
      final permission = await _checkPermission();
      if (permission) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        // Save to prefs for fallback
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(AppConstants.keySavedLat, position.latitude);
        await prefs.setDouble(AppConstants.keySavedLon, position.longitude);
        return LocationResult(
          lat: position.latitude,
          lon: position.longitude,
          cityName: '', // will be resolved after weather fetch
        );
      }
    } catch (_) {
      // GPS failed, fall through to saved location
    }

    // 2. Try saved location
    final prefs = await SharedPreferences.getInstance();
    final savedLat = prefs.getDouble(AppConstants.keySavedLat);
    final savedLon = prefs.getDouble(AppConstants.keySavedLon);
    final savedCity = prefs.getString(AppConstants.keySavedCityName);

    if (savedLat != null && savedLon != null) {
      return LocationResult(
        lat: savedLat,
        lon: savedLon,
        cityName: savedCity ?? '',
      );
    }

    // 3. Default to Chennai
    return const LocationResult(
      lat: ApiConstants.defaultLat,
      lon: ApiConstants.defaultLon,
      cityName: ApiConstants.defaultCity,
    );
  }

  Future<bool> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<void> saveLocation(
      String cityName, double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keySavedCityName, cityName);
    await prefs.setDouble(AppConstants.keySavedLat, lat);
    await prefs.setDouble(AppConstants.keySavedLon, lon);
  }
}
