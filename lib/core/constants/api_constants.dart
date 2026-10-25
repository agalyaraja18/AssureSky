class ApiConstants {
  // OpenWeatherMap — injected at build time via --dart-define=OWM_API_KEY=...
  static const String owmBaseUrl = 'https://api.openweathermap.org';
  static const String owmApiKey = String.fromEnvironment(
    'OWM_API_KEY',
    defaultValue: '', // set via --dart-define or GitHub Actions secret
  );

  // NewsAPI — injected at build time via --dart-define=NEWS_API_KEY=...
  static const String newsBaseUrl = 'https://newsapi.org/v2';
  static const String newsApiKey = String.fromEnvironment(
    'NEWS_API_KEY',
    defaultValue: '', // set via --dart-define or GitHub Actions secret
  );

  // Endpoints
  static const String currentWeather = '/data/2.5/weather';
  static const String forecast = '/data/2.5/forecast';
  static const String airPollution = '/data/2.5/air_pollution';
  static const String uvIndex = '/data/2.5/uvi';
  static const String geocoding = '/geo/1.0/direct';
  static const String reverseGeocoding = '/geo/1.0/reverse';

  // Default location (Chennai)
  static const double defaultLat = 13.0827;
  static const double defaultLon = 80.2707;
  static const String defaultCity = 'Chennai';

  // Indian cities list for location search
  static const List<String> indianCities = [
    'Chennai',
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Hyderabad',
    'Kolkata',
    'Pune',
    'Ahmedabad',
    'Jaipur',
    'Surat',
    'Coimbatore',
    'Madurai',
    'Visakhapatnam',
    'Kochi',
    'Nagpur',
    'Bhopal',
    'Lucknow',
    'Chandigarh',
    'Guwahati',
    'Patna',
    'Indore',
    'Thane',
    'Agra',
    'Varanasi',
    'Mysuru',
  ];
}
