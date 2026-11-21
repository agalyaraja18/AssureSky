import '../../models/official_alert_model.dart';
import 'alert_provider.dart';

/// Canada — Environment and Climate Change Canada (MSC GeoMet-OGC-API).
/// Free, no key. One record is published per affected *area*, so records of
/// the same alert are merged into one entry listing every area.
class EcccAlertProvider extends AlertProvider {
  static const String baseUrl = 'https://api.weather.gc.ca';
  static const String _items = '/collections/weather-alerts/items';

  final _dio = AlertProvider.newDio(baseUrl: baseUrl);

  @override
  String get id => 'eccc';

  @override
  String get name => 'Canada — Environment Canada';

  @override
  Future<List<OfficialAlert>> fetchWorld() async {
    final res = await _dio.get(_items, queryParameters: {
      'f': 'json',
      'limit': 500,
    });
    return parseFeatures(res.data);
  }

  @override
  Future<List<OfficialAlert>> fetchNear(LocationQuery query) async {
    if (!_inCanada(query.lat, query.lon)) return const [];
    const pad = 0.05; // ≈ 5 km box around the point
    final res = await _dio.get(_items, queryParameters: {
      'f': 'json',
      'limit': 100,
      'bbox': '${query.lon - pad},${query.lat - pad},${query.lon + pad},${query.lat + pad}',
    });
    return parseFeatures(res.data);
  }

  static bool _inCanada(double lat, double lon) =>
      lat >= 41.5 && lat <= 84 && lon >= -141.5 && lon <= -52;

  static List<OfficialAlert> parseFeatures(dynamic data) {
    if (data is! Map) return const [];
    final features = data['features'];
    if (features is! List) return const [];

    // Group the per-area records that belong to one alert.
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final f in features) {
      if (f is! Map) continue;
      final p = f['properties'];
      if (p is! Map) continue;
      final props = Map<String, dynamic>.from(p);
      final status = (props['status_en'] as String? ?? '').toLowerCase();
      if (status.contains('ended') || status.contains('cancel')) continue;

      final key = [
        props['alert_name_en'],
        props['publication_datetime'],
        (props['alert_text_en'] as String? ?? '').hashCode,
      ].join('|');
      groups.putIfAbsent(key, () => []).add(props);
    }

    final alerts = <OfficialAlert>[];
    for (final records in groups.values) {
      final alert = _merge(records);
      if (alert != null) alerts.add(alert);
    }
    return alerts;
  }

  static OfficialAlert? _merge(List<Map<String, dynamic>> records) {
    final p = records.first;
    String s(String k) => (p[k] as String? ?? '').trim();
    DateTime? d(String k) => DateTime.tryParse(s(k));

    final rawName = s('alert_name_en');
    if (rawName.isEmpty) return null;
    final title = rawName[0].toUpperCase() + rawName.substring(1);

    final areas = records
        .map((r) => (r['feature_name_en'] as String? ?? '').trim())
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList();
    final province = s('province');
    final shown = areas.take(4).join(', ');
    final extra = areas.length > 4 ? ' (+${areas.length - 4} more)' : '';
    final location = [
      if (shown.isNotEmpty) '$shown$extra',
      if (province.isNotEmpty) province,
    ].join(' — ');

    final text = s('alert_text_en');
    final (instructions, general) = AlertProvider.instructionsFor(null, '$rawName $text');

    return OfficialAlert(
      id: 'eccc:${s('feature_id').isEmpty ? '$rawName${s('publication_datetime')}' : s('feature_id')}',
      provider: 'eccc',
      title: title,
      severity: _severity(s('risk_colour_en'), s('alert_type')),
      location: location.isEmpty ? 'Canada' : location,
      issued: d('publication_datetime') ?? DateTime.now(),
      start: d('validity_datetime'),
      end: d('event_end_datetime') ?? d('expiration_datetime'),
      description: AlertProvider.tidy(text),
      instructions: instructions,
      instructionsAreGeneral: general,
      source: 'Environment and Climate Change Canada',
      countryCode: 'CA',
    );
  }

  /// Environment Canada colour levels: yellow = be aware, orange = be
  /// prepared, red = take action. Alerts without a colour fall back to type.
  static OfficialSeverity _severity(String colour, String type) {
    switch (colour.toLowerCase()) {
      case 'red':
        return OfficialSeverity.extreme;
      case 'orange':
        return OfficialSeverity.severe;
      case 'yellow':
        return OfficialSeverity.moderate;
    }
    switch (type.toLowerCase()) {
      case 'warning':
        return OfficialSeverity.severe;
      case 'watch':
        return OfficialSeverity.moderate;
      default:
        return OfficialSeverity.minor;
    }
  }
}
