import 'package:dio/dio.dart';
import '../../models/official_alert_model.dart';
import 'alert_provider.dart';

/// United States — National Weather Service (api.weather.gov). Free, no key.
class NwsAlertProvider extends AlertProvider {
  static const String baseUrl = 'https://api.weather.gov';

  final Dio _dio;

  NwsAlertProvider({Dio? dio})
      : _dio = dio ??
            AlertProvider.newDio(baseUrl: baseUrl, headers: {
              // NWS asks every client to identify itself.
              'User-Agent': 'AssureSky/2.0 (weather app)',
              'Accept': 'application/geo+json',
            });

  @override
  String get id => 'nws';

  @override
  String get name => 'USA — National Weather Service';

  @override
  Future<List<OfficialAlert>> fetchWorld() async {
    // The full US feed is several MB. Moderate-and-above keeps the worldwide
    // list useful and fast; minor advisories are still returned for the user's
    // own location by [fetchNear].
    final res = await _dio.get('/alerts/active', queryParameters: {
      'status': 'actual',
      'message_type': 'alert,update',
      'severity': 'Extreme,Severe,Moderate',
    });
    return parseFeatures(res.data);
  }

  @override
  Future<List<OfficialAlert>> fetchNear(LocationQuery query) async {
    if (!_inUnitedStates(query.lat, query.lon)) return const [];
    final res = await _dio.get('/alerts/active', queryParameters: {
      'status': 'actual',
      // NWS accepts at most 4 decimals for a point.
      'point': '${query.lat.toStringAsFixed(4)},${query.lon.toStringAsFixed(4)}',
    });
    return parseFeatures(res.data);
  }

  /// Rough bounding boxes for the 50 states, Puerto Rico and the US Pacific
  /// territories, so we don't ask NWS about points it can't answer.
  static bool _inUnitedStates(double lat, double lon) {
    final conus = lat >= 24 && lat <= 50 && lon >= -125 && lon <= -66;
    final alaska = lat >= 51 && lat <= 72 && lon >= -170 && lon <= -129;
    final hawaii = lat >= 18 && lat <= 23 && lon >= -161 && lon <= -154;
    final puertoRico = lat >= 17 && lat <= 19 && lon >= -68 && lon <= -64;
    return conus || alaska || hawaii || puertoRico;
  }

  static List<OfficialAlert> parseFeatures(dynamic data) {
    if (data is! Map) return const [];
    final features = data['features'];
    if (features is! List) return const [];

    final alerts = <OfficialAlert>[];
    for (final f in features) {
      if (f is! Map) continue;
      final p = f['properties'];
      if (p is! Map) continue;
      final alert = _parse(Map<String, dynamic>.from(p));
      if (alert != null) alerts.add(alert);
    }
    return alerts;
  }

  static OfficialAlert? _parse(Map<String, dynamic> p) {
    String s(String k) => (p[k] as String? ?? '').trim();
    DateTime? d(String k) => DateTime.tryParse(s(k));

    final event = s('event');
    if (event.isEmpty) return null;
    if (s('messageType').toLowerCase() == 'cancel') return null;

    final (instructions, general) =
        AlertProvider.instructionsFor(s('instruction'), event);
    final description = AlertProvider.tidy(s('description').isNotEmpty ? s('description') : s('headline'));

    return OfficialAlert(
      id: 'nws:${s('id')}',
      provider: 'nws',
      title: event,
      severity: OfficialSeverity.fromCap(s('severity')),
      location: s('areaDesc'),
      issued: d('sent') ?? d('effective') ?? DateTime.now(),
      start: d('onset') ?? d('effective'),
      end: d('ends') ?? d('expires'),
      description: description,
      instructions: instructions,
      instructionsAreGeneral: general,
      source: s('senderName').isNotEmpty
          ? s('senderName')
          : 'US National Weather Service',
      countryCode: 'US',
    );
  }
}
