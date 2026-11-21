import 'package:dio/dio.dart';
import '../../models/official_alert_model.dart';
import 'geo_utils.dart';
import 'safety_advice.dart';

/// Where the user is, for finding the alerts that affect them.
class LocationQuery {
  final double lat;
  final double lon;
  final String cityName;

  /// ISO-3166 alpha-2 (e.g. `IN`, `US`), as returned by OpenWeatherMap.
  final String countryCode;

  const LocationQuery({
    required this.lat,
    required this.lon,
    this.cityName = '',
    this.countryCode = '',
  });
}

/// A source of official alerts (a national meteorological service or an
/// international body). Providers are independent: if one is down or blocked,
/// the others still work.
abstract class AlertProvider {
  /// Short stable id, e.g. `nws`.
  String get id;

  /// Human-readable name for "some sources unavailable" messages.
  String get name;

  /// Every currently-active alert this provider publishes (for the worldwide
  /// Alerts tab).
  Future<List<OfficialAlert>> fetchWorld();

  /// True for sources whose downloads are very large or slow. They start only
  /// after the fast sources finish, so they cannot starve them of bandwidth.
  bool get isSlow => false;

  static const Duration _worldMemoTtl = Duration(minutes: 5);

  /// Latest [fetchWorld] result per provider id. Static because every screen
  /// creates its own repository (and so its own provider instances), yet the
  /// Alerts tab and the Home dashboard should share one download.
  static final Map<String, (DateTime, List<OfficialAlert>)> _worldMemo = {};

  /// [fetchWorld] with a 5-minute memo.
  Future<List<OfficialAlert>> fetchWorldCached({bool force = false}) async {
    final memo = _worldMemo[id];
    if (!force &&
        memo != null &&
        DateTime.now().difference(memo.$1) < _worldMemoTtl) {
      return memo.$2;
    }
    final fresh = await fetchWorld();
    _worldMemo[id] = (DateTime.now(), fresh);
    return fresh;
  }

  /// Alerts that affect [query]. The default filters the (memoised) world
  /// list; providers that can ask their API about a single point override this
  /// (cheaper).
  Future<List<OfficialAlert>> fetchNear(LocationQuery query) async {
    final all = await fetchWorldCached();
    return all.where((a) => affects(a, query)).toList();
  }

  /// Whether [alert] applies to [query]: polygon match, then point-radius
  /// match, then a conservative place-name match.
  static bool affects(OfficialAlert alert, LocationQuery query) {
    if (alert.polygons.isNotEmpty) {
      return alert.polygons
          .any((ring) => GeoUtils.pointInRing(query.lat, query.lon, ring));
    }
    if (alert.lat != null && alert.lon != null && alert.radiusKm != null) {
      return GeoUtils.distanceKm(
              query.lat, query.lon, alert.lat!, alert.lon!) <=
          alert.radiusKm!;
    }
    final city = query.cityName.trim().toLowerCase();
    if (city.length < 3) return false;
    // Whole-word match so "Salem" doesn't match "Salemi".
    final pattern = RegExp('(^|[^a-z])${RegExp.escape(city)}([^a-z]|\$)');
    return pattern.hasMatch(alert.location.toLowerCase());
  }

  /// Picks the instructions to show: the authority's own if they say something
  /// real, otherwise generic guidance for the hazard. Returns (text, isGeneral).
  static (String, bool) instructionsFor(String? official, String hazardText) {
    final cleaned = tidy(official);
    if (SafetyAdvice.isUseful(cleaned)) return (cleaned, false);
    return (SafetyAdvice.forHazard(hazardText), true);
  }

  /// Cleans free text from an alert for display.
  ///
  /// Many agencies (notably the US NWS) hard-wrap text at ~70 columns, leaving
  /// a newline in the middle of sentences. A single newline is just a wrap, so
  /// it becomes a space; blank lines (real paragraph breaks) are kept.
  static String tidy(String? text) {
    if (text == null) return '';
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAllMapped(RegExp(r'(?<!\n)\n(?!\n)'), (_) => ' ')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  /// Shared HTTP client settings.
  static Dio newDio({String? baseUrl, Map<String, dynamic>? headers}) => Dio(
        BaseOptions(
          baseUrl: baseUrl ?? '',
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 25),
          headers: headers,
        ),
      );
}
