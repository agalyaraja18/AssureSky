/// A searchable place (city, town, village) anywhere in the world.
class PlaceModel {
  final String name;

  /// State / province / region, e.g. "Tamil Nadu". May be empty.
  final String admin1;
  final String country;
  final String countryCode;
  final double lat;
  final double lon;

  const PlaceModel({
    required this.name,
    this.admin1 = '',
    this.country = '',
    this.countryCode = '',
    required this.lat,
    required this.lon,
  });

  /// "Salem, Tamil Nadu, India"
  String get label {
    final parts = <String>[name];
    if (admin1.isNotEmpty && admin1 != name) parts.add(admin1);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  /// "Tamil Nadu, India" (everything except the name) for list subtitles.
  String get subtitle {
    final parts = <String>[];
    if (admin1.isNotEmpty && admin1 != name) parts.add(admin1);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  factory PlaceModel.fromOpenMeteo(Map<String, dynamic> json) {
    return PlaceModel(
      name: json['name'] as String? ?? '',
      admin1: json['admin1'] as String? ?? '',
      country: json['country'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      lat: (json['latitude'] as num).toDouble(),
      lon: (json['longitude'] as num).toDouble(),
    );
  }
}
