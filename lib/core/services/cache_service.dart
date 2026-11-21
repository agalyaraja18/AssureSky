import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A cached JSON payload and when it was saved.
class CachedEntry {
  final dynamic data;
  final DateTime savedAt;
  const CachedEntry({required this.data, required this.savedAt});
}

/// Tiny JSON cache on top of SharedPreferences, used so the app can still show
/// the last weather / forecast / news when the network is unavailable.
///
/// Raw API JSON is cached (not model objects) and re-parsed on read, so the
/// models stay free of serialization code.
class CacheService {
  /// Max cached locations per key prefix. Oldest entries are evicted first.
  static const int maxEntriesPerPrefix = 10;

  /// Builds a per-location cache key. Coordinates are rounded to 1 decimal
  /// (≈ 11 km) so tiny GPS jitter still hits the same cache entry.
  static String coordKey(String prefix, double lat, double lon) =>
      '$prefix${lat.toStringAsFixed(1)}_${lon.toStringAsFixed(1)}';

  Future<void> save(String key, Object? data, {String? prunePrefix}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode({
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }),
    );
    if (prunePrefix != null) await _prune(prefs, prunePrefix);
  }

  Future<CachedEntry?> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CachedEntry(
        data: map['data'],
        savedAt: DateTime.fromMillisecondsSinceEpoch(
            (map['savedAt'] as num).toInt()),
      );
    } catch (_) {
      return null; // corrupt entry — behave as a cache miss
    }
  }

  Future<void> _prune(SharedPreferences prefs, String prefix) async {
    final keys = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    if (keys.length <= maxEntriesPerPrefix) return;

    final saved = <String, int>{};
    for (final k in keys) {
      try {
        final map = jsonDecode(prefs.getString(k) ?? '') as Map<String, dynamic>;
        saved[k] = (map['savedAt'] as num).toInt();
      } catch (_) {
        saved[k] = 0; // corrupt → evict first
      }
    }
    keys.sort((a, b) => saved[a]!.compareTo(saved[b]!));
    for (final k in keys.take(keys.length - maxEntriesPerPrefix)) {
      await prefs.remove(k);
    }
  }
}
