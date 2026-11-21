/// Severity of an official weather alert, using the international CAP scale
/// (Common Alerting Protocol) that meteorological agencies publish.
enum OfficialSeverity {
  extreme,
  severe,
  moderate,
  minor;

  String get label {
    switch (this) {
      case OfficialSeverity.extreme:
        return 'Extreme';
      case OfficialSeverity.severe:
        return 'Severe';
      case OfficialSeverity.moderate:
        return 'Moderate';
      case OfficialSeverity.minor:
        return 'Minor';
    }
  }

  /// Maps a CAP severity string. "Unknown" and anything unrecognised becomes
  /// [minor] so it is still shown, but never overstated.
  static OfficialSeverity fromCap(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'extreme':
        return OfficialSeverity.extreme;
      case 'severe':
        return OfficialSeverity.severe;
      case 'moderate':
        return OfficialSeverity.moderate;
      default:
        return OfficialSeverity.minor;
    }
  }
}

/// One official weather alert, normalised from any provider (India NDMA/IMD,
/// US NWS, Environment Canada, MeteoAlarm, GDACS) into the same shape.
class OfficialAlert {
  /// Unique across providers, e.g. `nws:urn:oid:2.49...`.
  final String id;

  /// Which feed it came from: `ndma`, `nws`, `eccc`, `meteoalarm`, `gdacs`.
  final String provider;

  /// e.g. "Heavy Rainfall Warning".
  final String title;
  final OfficialSeverity severity;

  /// Affected city, district or region.
  final String location;

  /// When the authority issued the alert.
  final DateTime issued;

  /// When the hazard is expected to start / end. Null when not published.
  final DateTime? start;
  final DateTime? end;

  /// What is expected to happen.
  final String description;

  /// What people should do.
  final String instructions;

  /// True when [instructions] is our generic guidance for this kind of hazard
  /// because the authority did not publish any (shown with a note in the UI).
  final bool instructionsAreGeneral;

  /// The official meteorological / emergency authority.
  final String source;

  /// ISO-3166 alpha-2 country code when known.
  final String? countryCode;

  /// A representative point (events published as a point, e.g. a cyclone).
  final double? lat;
  final double? lon;

  /// For point events: how far from [lat]/[lon] people are affected (km).
  final double? radiusKm;

  /// Affected-area polygons: a list of rings, each a list of `[lat, lon]`.
  /// Not persisted in the offline cache (can be very large).
  final List<List<List<double>>> polygons;

  const OfficialAlert({
    required this.id,
    required this.provider,
    required this.title,
    required this.severity,
    required this.location,
    required this.issued,
    this.start,
    this.end,
    required this.description,
    required this.instructions,
    this.instructionsAreGeneral = false,
    required this.source,
    this.countryCode,
    this.lat,
    this.lon,
    this.radiusKm,
    this.polygons = const [],
  });

  /// Not yet over.
  bool isActiveAt(DateTime now) => end == null || end!.isAfter(now);

  /// Starts no later than the end of today (the user's local day), i.e. it is
  /// happening now or later today — not an alert for next week.
  bool startsByEndOfDay(DateTime now) {
    final endOfDay = DateTime(now.year, now.month, now.day + 1);
    return start == null || start!.isBefore(endOfDay);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'provider': provider,
        'title': title,
        'severity': severity.name,
        'location': location,
        'issued': issued.toUtc().toIso8601String(),
        'start': start?.toUtc().toIso8601String(),
        'end': end?.toUtc().toIso8601String(),
        'description': description,
        'instructions': instructions,
        'instructionsAreGeneral': instructionsAreGeneral,
        'source': source,
        'countryCode': countryCode,
        'lat': lat,
        'lon': lon,
        'radiusKm': radiusKm,
      };

  factory OfficialAlert.fromJson(Map<String, dynamic> j) {
    DateTime? date(Object? v) => v == null ? null : DateTime.tryParse('$v');
    return OfficialAlert(
      id: j['id'] as String,
      provider: j['provider'] as String,
      title: j['title'] as String,
      severity: OfficialSeverity.values.firstWhere(
        (s) => s.name == j['severity'],
        orElse: () => OfficialSeverity.minor,
      ),
      location: j['location'] as String? ?? '',
      issued: date(j['issued']) ?? DateTime.now(),
      start: date(j['start']),
      end: date(j['end']),
      description: j['description'] as String? ?? '',
      instructions: j['instructions'] as String? ?? '',
      instructionsAreGeneral: j['instructionsAreGeneral'] as bool? ?? false,
      source: j['source'] as String? ?? '',
      countryCode: j['countryCode'] as String?,
      lat: (j['lat'] as num?)?.toDouble(),
      lon: (j['lon'] as num?)?.toDouble(),
      radiusKm: (j['radiusKm'] as num?)?.toDouble(),
    );
  }
}
