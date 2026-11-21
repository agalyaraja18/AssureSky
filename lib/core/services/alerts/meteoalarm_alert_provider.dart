import 'dart:async';
import 'package:dio/dio.dart';
import '../../models/official_alert_model.dart';
import 'alert_provider.dart';
import 'geo_utils.dart';

/// Europe — MeteoAlarm, the joint warning service of the national
/// meteorological services of ~37 European countries. Free, no key.
class MeteoAlarmAlertProvider extends AlertProvider {
  static const String baseUrl = 'https://feeds.meteoalarm.org';

  /// Feed slug → ISO-3166 alpha-2 country code.
  static const Map<String, String> countries = {
    'austria': 'AT',
    'belgium': 'BE',
    'bosnia-herzegovina': 'BA',
    'bulgaria': 'BG',
    'croatia': 'HR',
    'cyprus': 'CY',
    'czechia': 'CZ',
    'denmark': 'DK',
    'estonia': 'EE',
    'finland': 'FI',
    'france': 'FR',
    'germany': 'DE',
    'greece': 'GR',
    'hungary': 'HU',
    'iceland': 'IS',
    'ireland': 'IE',
    'israel': 'IL',
    'italy': 'IT',
    'latvia': 'LV',
    'lithuania': 'LT',
    'luxembourg': 'LU',
    'malta': 'MT',
    'moldova': 'MD',
    'montenegro': 'ME',
    'netherlands': 'NL',
    'north-macedonia': 'MK',
    'norway': 'NO',
    'poland': 'PL',
    'portugal': 'PT',
    'romania': 'RO',
    'serbia': 'RS',
    'slovakia': 'SK',
    'slovenia': 'SI',
    'spain': 'ES',
    'sweden': 'SE',
    'switzerland': 'CH',
    'ukraine': 'UA',
    'united-kingdom': 'GB',
  };

  /// The MeteoAlarm server is slow (13–55 s per country at times) and drops
  /// connections when hit hard, so keep parallelism low.
  static const int concurrency = 2;

  /// Hard limit for the worldwide download. Country feeds are huge (Germany's
  /// is ~10 MB at ~70 KB/s), so whatever finished by then is returned and the
  /// rest is cancelled. Small countries are fetched first.
  static const Duration worldBudget = Duration(seconds: 30);

  /// Countries with very large feeds, fetched last.
  static const Set<String> _heavy = {
    'germany', 'france', 'italy', 'spain', 'united-kingdom', 'poland',
    'romania', 'netherlands', 'sweden', 'norway', 'austria', 'switzerland',
    'greece', 'portugal', 'czechia', 'hungary', 'belgium', 'finland',
  };

  @override
  bool get isSlow => true;

  final _dio = AlertProvider.newDio(baseUrl: baseUrl);

  @override
  String get id => 'meteoalarm';

  @override
  String get name => 'Europe — MeteoAlarm';

  @override
  Future<List<OfficialAlert>> fetchWorld() async {
    final slugs = countries.keys.toList()
      ..sort((a, b) =>
          (_heavy.contains(a) ? 1 : 0).compareTo(_heavy.contains(b) ? 1 : 0));
    final alerts = <OfficialAlert>[];
    final cancel = CancelToken();
    var succeeded = 0;
    var next = 0;
    var stopped = false;

    Future<void> worker() async {
      while (!stopped && next < slugs.length) {
        final slug = slugs[next++];
        try {
          final found =
              await _fetchCountry(slug, keepPolygons: false, cancel: cancel);
          if (stopped) return;
          alerts.addAll(found);
          succeeded++;
        } catch (_) {
          // A single country being unavailable must not hide the others.
        }
      }
    }

    final all = Future.wait(List.generate(concurrency, (_) => worker()));
    await Future.any([all, Future<void>.delayed(worldBudget)]);
    stopped = true;
    cancel.cancel('MeteoAlarm time budget reached');

    if (succeeded == 0) {
      throw Exception('MeteoAlarm: no country feed could be loaded');
    }
    return List.of(alerts);
  }

  @override
  Future<List<OfficialAlert>> fetchNear(LocationQuery query) async {
    final slug = countries.entries
        .where((e) => e.value == query.countryCode.toUpperCase())
        .map((e) => e.key)
        .firstOrNull;
    if (slug == null) return const []; // not a MeteoAlarm country

    final all = await _fetchCountry(slug, keepPolygons: true);
    return all.where((a) => AlertProvider.affects(a, query)).toList();
  }

  Future<List<OfficialAlert>> _fetchCountry(String slug,
      {required bool keepPolygons, CancelToken? cancel}) async {
    final path = '/api/v1/warnings/feeds-$slug';
    Response<dynamic> res;
    try {
      res = await _dio.get(path, cancelToken: cancel);
    } on DioException catch (e) {
      // The server sometimes resets the connection under load; one retry
      // after a short pause usually succeeds.
      if (e.type != DioExceptionType.connectionError) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 800));
      res = await _dio.get(path, cancelToken: cancel);
    }
    return parseFeed(res.data,
        countryCode: countries[slug], keepPolygons: keepPolygons);
  }

  static List<OfficialAlert> parseFeed(dynamic data,
      {String? countryCode, bool keepPolygons = false, DateTime? now}) {
    if (data is! Map) return const [];
    final warnings = data['warnings'];
    if (warnings is! List) return const [];
    final clock = now ?? DateTime.now();

    final alerts = <OfficialAlert>[];
    for (final w in warnings) {
      if (w is! Map || w['alert'] is! Map) continue;
      final alert = Map<String, dynamic>.from(w['alert'] as Map);

      if ((alert['msgType'] as String? ?? '').toLowerCase() == 'cancel') continue;
      final status = alert['status'] as String? ?? 'Actual';
      if (status.toLowerCase() != 'actual') continue;

      final infos = alert['info'];
      if (infos is! List || infos.isEmpty) continue;
      final infoList = infos.whereType<Map>().map((i) => Map<String, dynamic>.from(i)).toList();
      if (infoList.isEmpty) continue;

      // Prefer English; warnings are published in the local language too.
      final info = infoList.firstWhere(
        (i) => (i['language'] as String? ?? '').toLowerCase().startsWith('en'),
        orElse: () => infoList.first,
      );

      final parsed = _parseInfo(alert, info,
          countryCode: countryCode, keepPolygons: keepPolygons);
      if (parsed != null && parsed.isActiveAt(clock)) alerts.add(parsed);
    }
    return alerts;
  }

  static OfficialAlert? _parseInfo(
    Map<String, dynamic> alert,
    Map<String, dynamic> info, {
    String? countryCode,
    required bool keepPolygons,
  }) {
    String s(Map<String, dynamic> m, String k) => (m[k] as String? ?? '').trim();

    // awareness_level "1; green; Minor" means "no warning" — skip those.
    final level = _parameter(info, 'awareness_level');
    if (level != null && level.trim().startsWith('1')) return null;

    final event = s(info, 'event');
    final headline = s(info, 'headline');
    final title = event.isNotEmpty ? event : headline;
    if (title.isEmpty) return null;

    final areas = <String>[];
    final polygons = <List<List<double>>>[];
    final rawAreas = info['area'];
    if (rawAreas is List) {
      for (final a in rawAreas.whereType<Map>()) {
        final desc = (a['areaDesc'] as String? ?? '').trim();
        if (desc.isNotEmpty) areas.add(desc.replaceAll(' | ', ', '));
        if (keepPolygons && a['polygon'] is List) {
          for (final p in (a['polygon'] as List).whereType<String>()) {
            final ring = GeoUtils.parsePolygon(p);
            if (ring.isNotEmpty) polygons.add(ring);
          }
        }
      }
    }

    final description = s(info, 'description');
    final (instructions, general) =
        AlertProvider.instructionsFor(s(info, 'instruction'), '$event $headline');

    final sender = s(info, 'senderName');
    final identifier = alert['identifier'] as String? ?? title;

    return OfficialAlert(
      id: 'meteoalarm:$identifier:${s(info, 'event')}:${areas.isEmpty ? '' : areas.first}',
      provider: 'meteoalarm',
      title: title,
      severity: OfficialSeverity.fromCap(s(info, 'severity')),
      location: areas.isEmpty ? (countryCode ?? 'Europe') : areas.join(', '),
      issued: DateTime.tryParse(s(alert.cast<String, dynamic>(), 'sent')) ?? DateTime.now(),
      start: DateTime.tryParse(s(info, 'onset')) ?? DateTime.tryParse(s(info, 'effective')),
      end: DateTime.tryParse(s(info, 'expires')),
      description: AlertProvider.tidy(description.isNotEmpty ? description : headline),
      instructions: instructions,
      instructionsAreGeneral: general,
      source: sender.isEmpty ? 'MeteoAlarm' : '$sender via MeteoAlarm',
      countryCode: countryCode,
      polygons: polygons,
    );
  }

  static String? _parameter(Map<String, dynamic> info, String name) {
    final params = info['parameter'];
    if (params is! List) return null;
    for (final p in params.whereType<Map>()) {
      if (p['valueName'] == name) return p['value'] as String?;
    }
    return null;
  }
}
