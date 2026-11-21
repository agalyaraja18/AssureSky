import '../../models/official_alert_model.dart';
import 'alert_provider.dart';
import 'safety_advice.dart';

/// Worldwide — GDACS, the Global Disaster Alert and Coordination System of the
/// United Nations (OCHA) and the European Commission (JRC). Covers tropical
/// cyclones, floods and droughts anywhere on Earth. Free, no key.
class GdacsAlertProvider extends AlertProvider {
  static const String url =
      'https://www.gdacs.org/gdacsapi/api/events/geteventlist/SEARCH'
      '?eventlist=TC;FL;DR&alertlevel=Green;Orange;Red';

  final _dio = AlertProvider.newDio();

  @override
  String get id => 'gdacs';

  @override
  String get name => 'Worldwide — GDACS (UN / EU)';

  @override
  Future<List<OfficialAlert>> fetchWorld() async {
    final res = await _dio.get(url);
    return parseFeatures(res.data);
  }

  static List<OfficialAlert> parseFeatures(dynamic data) {
    if (data is! Map) return const [];
    final features = data['features'];
    if (features is! List) return const [];

    final alerts = <OfficialAlert>[];
    for (final f in features) {
      if (f is! Map || f['properties'] is! Map) continue;
      final alert = _parse(
        Map<String, dynamic>.from(f['properties'] as Map),
        f['geometry'] is Map ? Map<String, dynamic>.from(f['geometry'] as Map) : null,
      );
      if (alert != null) alerts.add(alert);
    }
    return alerts;
  }

  static OfficialAlert? _parse(Map<String, dynamic> p, Map<String, dynamic>? geometry) {
    String s(String k) => (p[k] as String? ?? '').trim();

    // Only events that are happening now.
    if (s('iscurrent').toLowerCase() != 'true') return null;

    final type = s('eventtype'); // TC / FL / DR
    final level = s('alertlevel').toLowerCase(); // green / orange / red

    // Weather-related hazards only (never earthquakes, volcanoes, wildfires…),
    // regardless of what the feed returns.
    if (type != 'TC' && type != 'FL' && type != 'DR') return null;

    // Green floods and droughts are routine low-impact events and would bury
    // the alerts that matter. Tropical cyclones are always worth showing.
    if (level == 'green' && type != 'TC') return null;

    final severity = switch (level) {
      'red' => OfficialSeverity.extreme,
      'orange' => OfficialSeverity.severe,
      _ => OfficialSeverity.minor,
    };

    final (kindName, radiusKm) = switch (type) {
      'TC' => ('Tropical cyclone', 500.0),
      'FL' => ('Flood', 120.0),
      'DR' => ('Drought', 250.0),
      _ => ('Weather event', 100.0),
    };

    final name = s('name').isNotEmpty ? s('name') : kindName;
    final eventName = s('eventname');
    final title = eventName.isNotEmpty && !name.contains(eventName)
        ? '$name ($eventName)'
        : name;

    final severityData = p['severitydata'];
    final severityText = severityData is Map
        ? (severityData['severitytext'] as String? ?? '').trim()
        : '';
    final description = [
      '${_cap(level)} alert level for ${kindName.toLowerCase()} in ${s('country').isEmpty ? 'the affected area' : s('country')}.',
      if (severityText.isNotEmpty) severityText,
    ].join(' ');

    double? lat, lon;
    final coords = geometry?['coordinates'];
    if (geometry?['type'] == 'Point' && coords is List && coords.length >= 2) {
      lon = (coords[0] as num).toDouble();
      lat = (coords[1] as num).toDouble();
    }

    // GDACS publishes no per-event instructions, so use hazard guidance.
    final instructions = SafetyAdvice.forHazard(switch (type) {
      'TC' => 'cyclone',
      'FL' => 'flood',
      'DR' => 'drought',
      _ => title,
    });

    return OfficialAlert(
      id: 'gdacs:${s('eventtype')}${p['eventid']}-${p['episodeid']}',
      provider: 'gdacs',
      title: title,
      severity: severity,
      location: s('country').isEmpty ? 'Multiple areas' : s('country'),
      issued: _utc(s('datemodified')) ?? _utc(s('fromdate')) ?? DateTime.now(),
      start: _utc(s('fromdate')),
      // GDACS keeps flagging an event "current" for a while after its last
      // forecast `todate`. A past end date would wrongly drop a live event, so
      // treat it as ongoing (end not published) instead.
      end: _futureOrNull(_utc(s('todate'))),
      description: description,
      instructions: instructions,
      instructionsAreGeneral: true,
      source: 'Global Disaster Alert and Coordination System (GDACS) — UN OCHA & European Commission JRC',
      lat: lat,
      lon: lon,
      radiusKm: lat == null ? null : radiusKm,
    );
  }

  /// GDACS timestamps carry no zone but are UTC.
  static DateTime? _utc(String v) => v.isEmpty ? null : DateTime.tryParse('${v}Z');

  static DateTime? _futureOrNull(DateTime? t) =>
      (t != null && t.isAfter(DateTime.now())) ? t : null;

  static String _cap(String v) => v.isEmpty ? v : v[0].toUpperCase() + v.substring(1);
}
