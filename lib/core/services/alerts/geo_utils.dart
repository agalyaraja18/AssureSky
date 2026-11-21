import 'dart:math';

/// Small geometry helpers for matching alerts to a user's location.
class GeoUtils {
  GeoUtils._();

  /// Parses a CAP polygon string `"lat,lon lat,lon …"` into `[lat, lon]` pairs.
  /// Returns an empty list when the string is malformed.
  static List<List<double>> parsePolygon(String s) {
    final ring = <List<double>>[];
    for (final pair in s.trim().split(RegExp(r'\s+'))) {
      final parts = pair.split(',');
      if (parts.length < 2) continue;
      final lat = double.tryParse(parts[0]);
      final lon = double.tryParse(parts[1]);
      if (lat == null || lon == null) continue;
      ring.add([lat, lon]);
    }
    return ring.length >= 3 ? ring : const [];
  }

  /// Ray-casting point-in-polygon test. [ring] is a list of `[lat, lon]`.
  static bool pointInRing(double lat, double lon, List<List<double>> ring) {
    if (ring.length < 3) return false;
    var inside = false;
    for (int i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final yi = ring[i][0], xi = ring[i][1];
      final yj = ring[j][0], xj = ring[j][1];
      final crosses = ((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (crosses) inside = !inside;
    }
    return inside;
  }

  /// Great-circle distance in kilometres (haversine).
  static double distanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    double rad(double d) => d * pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) +
        cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLon / 2), 2);
    return 2 * earthRadiusKm * asin(min(1.0, sqrt(a.toDouble())));
  }
}
