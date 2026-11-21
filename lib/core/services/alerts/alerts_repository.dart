import 'dart:async';
import '../../constants/app_constants.dart';
import '../../models/official_alert_model.dart';
import '../cache_service.dart';
import 'alert_provider.dart';
import 'eccc_alert_provider.dart';
import 'gdacs_alert_provider.dart';
import 'meteoalarm_alert_provider.dart';
import 'ndma_alert_provider.dart';
import 'nws_alert_provider.dart';

/// The worldwide list of today's official alerts.
class AlertsResult {
  final List<OfficialAlert> alerts;

  /// Names of sources that loaded.
  final List<String> okSources;

  /// Names of sources that could not be loaded right now.
  final List<String> failedSources;

  /// Names of sources still loading (non-empty only for partial results).
  final List<String> pendingSources;

  /// True when every source failed and this is the last saved copy.
  final bool fromCache;
  final DateTime? cachedAt;

  const AlertsResult({
    required this.alerts,
    this.okSources = const [],
    this.failedSources = const [],
    this.pendingSources = const [],
    this.fromCache = false,
    this.cachedAt,
  });

  bool get isComplete => pendingSources.isEmpty;
}

/// Alerts affecting one location (for the home dashboard).
class NearbyAlerts {
  final List<OfficialAlert> alerts;
  final List<String> failedSources;
  const NearbyAlerts(this.alerts, {this.failedSources = const []});
}

/// Collects official alerts from every provider. Providers are independent —
/// a failing or blocked one only shows up in [AlertsResult.failedSources].
class AlertsRepository {
  static const Duration _memoTtl = Duration(minutes: 5);
  static const Duration _providerTimeout = Duration(seconds: 40);

  /// Shared between instances (each screen makes its own repository).
  static AlertsResult? _memo;
  static DateTime? _memoAt;

  final List<AlertProvider> providers;
  final CacheService _cache;

  AlertsRepository({List<AlertProvider>? providers, CacheService? cache})
      : providers = providers ??
            [
              NdmaAlertProvider(),
              NwsAlertProvider(),
              EcccAlertProvider(),
              MeteoAlarmAlertProvider(),
              GdacsAlertProvider(),
            ],
        _cache = cache ?? CacheService();

  /// Today's active official alerts from all sources, most severe first.
  /// Waits for every source; see [streamWorldAlerts] for progressive loading.
  Future<AlertsResult> getWorldAlerts({bool force = false, DateTime? now}) =>
      streamWorldAlerts(force: force, now: now).last;

  /// Same as [getWorldAlerts] but emits a partial result each time a source
  /// finishes, so fast sources (India, USA, Canada…) show up immediately while
  /// slow ones (MeteoAlarm) are still loading. The final event has
  /// [AlertsResult.isComplete] == true.
  Stream<AlertsResult> streamWorldAlerts(
      {bool force = false, DateTime? now}) async* {
    final clock = now ?? DateTime.now();

    final memo = _memo;
    final memoAt = _memoAt;
    if (!force &&
        memo != null &&
        memoAt != null &&
        clock.difference(memoAt) < _memoTtl) {
      yield memo;
      return;
    }

    // Start the fast providers at once; slow ones (huge downloads) wait until
    // those are done so they cannot starve them of bandwidth.
    final controller = StreamController<_Outcome>();
    var remaining = providers.length;
    Future<void> start(AlertProvider p) =>
        _run(p, force: force).then((outcome) {
          controller.add(outcome);
          if (--remaining == 0) controller.close();
        });
    final fast = providers.where((p) => !p.isSlow).map(start).toList();
    Future.wait(fast).whenComplete(() {
      for (final p in providers.where((p) => p.isSlow)) {
        start(p);
      }
    });

    final ok = <_Outcome>[];
    final failed = <_Outcome>[];
    await for (final outcome in controller.stream) {
      (outcome.alerts != null ? ok : failed).add(outcome);
      final done = ok.length + failed.length;
      // Partial result (the last one is emitted below, after caching).
      if (ok.isNotEmpty && done < providers.length) {
        yield _build(ok, failed, clock);
      }
    }

    if (ok.isEmpty) {
      // Nothing loaded at all (offline?) — show the last saved list.
      final cached = await _cache.load(AppConstants.cacheOfficialAlerts);
      if (cached != null) {
        try {
          final list = (cached.data as List)
              .map((e) => OfficialAlert.fromJson(Map<String, dynamic>.from(e as Map)))
              .where((a) => a.isActiveAt(clock))
              .toList();
          yield AlertsResult(
            alerts: _sorted(list),
            failedSources: failed.map((o) => o.provider.name).toList(),
            fromCache: true,
            cachedAt: cached.savedAt,
          );
          return;
        } catch (_) {
          // corrupt cache → fall through to the error
        }
      }
      throw Exception('No alert source could be reached');
    }

    final result = _build(ok, failed, clock);
    try {
      await _cache.save(AppConstants.cacheOfficialAlerts,
          result.alerts.map((a) => a.toJson()).toList());
    } catch (_) {
      // The offline copy is a bonus; never let a storage error hide alerts.
    }
    _memo = result;
    _memoAt = clock;
    yield result;
  }

  /// Merges the outcomes received so far into one sorted "today" list.
  AlertsResult _build(List<_Outcome> ok, List<_Outcome> failed, DateTime clock) {
    final merged = <String, OfficialAlert>{};
    for (final o in ok) {
      for (final a in o.alerts!) {
        merged[a.id] = a;
      }
    }
    final today = _sorted(merged.values
        .where((a) => a.isActiveAt(clock) && a.startsByEndOfDay(clock))
        .toList());

    final finished = {...ok, ...failed}.map((o) => o.provider).toSet();
    return AlertsResult(
      alerts: today,
      okSources: ok.map((o) => o.provider.name).toList(),
      failedSources: failed.map((o) => o.provider.name).toList(),
      pendingSources: providers
          .where((p) => !finished.contains(p))
          .map((p) => p.name)
          .toList(),
    );
  }

  /// Alerts that apply to [query] — used by the home dashboard.
  Future<NearbyAlerts> getAlertsNear(LocationQuery query, {DateTime? now}) async {
    final clock = now ?? DateTime.now();

    final outcomes = await Future.wait(providers.map((p) => _run(p, near: query)));
    final failed = outcomes
        .where((o) => o.alerts == null)
        .map((o) => o.provider.name)
        .toList();

    final merged = <String, OfficialAlert>{};
    for (final o in outcomes) {
      for (final a in o.alerts ?? const <OfficialAlert>[]) {
        if (a.isActiveAt(clock) && a.startsByEndOfDay(clock)) merged[a.id] = a;
      }
    }
    return NearbyAlerts(_sorted(merged.values.toList()), failedSources: failed);
  }

  Future<_Outcome> _run(AlertProvider provider,
      {LocationQuery? near, bool force = false}) async {
    Future<List<OfficialAlert>> attempt() => (near == null
            ? provider.fetchWorldCached(force: force)
            : provider.fetchNear(near))
        .timeout(_providerTimeout);

    try {
      return _Outcome(provider, await attempt());
    } on TimeoutException {
      return _Outcome(provider, null); // already waited long enough
    } catch (_) {
      if (provider.isSlow) return _Outcome(provider, null); // don't wait twice
      // One quick retry covers transient resets / 5xx blips.
      try {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        return _Outcome(provider, await attempt());
      } catch (_) {
        return _Outcome(provider, null);
      }
    }
  }

  /// Most severe first; within a severity, newest first.
  static List<OfficialAlert> _sorted(List<OfficialAlert> alerts) {
    return alerts
      ..sort((a, b) {
        final bySeverity = a.severity.index.compareTo(b.severity.index);
        return bySeverity != 0 ? bySeverity : b.issued.compareTo(a.issued);
      });
  }
}

class _Outcome {
  final AlertProvider provider;

  /// Null when the provider failed.
  final List<OfficialAlert>? alerts;
  _Outcome(this.provider, this.alerts);
}
