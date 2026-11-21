import '../models/place_model.dart';

/// Major cities shown before the user starts typing. Any other place in the
/// world is reachable through live search (see GeocodingService).
const List<PlaceModel> popularCities = [
  // North America
  PlaceModel(name: 'New York', admin1: 'New York', country: 'United States', countryCode: 'US', lat: 40.7128, lon: -74.0060),
  PlaceModel(name: 'Los Angeles', admin1: 'California', country: 'United States', countryCode: 'US', lat: 34.0522, lon: -118.2437),
  PlaceModel(name: 'Chicago', admin1: 'Illinois', country: 'United States', countryCode: 'US', lat: 41.8781, lon: -87.6298),
  PlaceModel(name: 'Toronto', admin1: 'Ontario', country: 'Canada', countryCode: 'CA', lat: 43.6532, lon: -79.3832),
  PlaceModel(name: 'Mexico City', admin1: 'Mexico City', country: 'Mexico', countryCode: 'MX', lat: 19.4326, lon: -99.1332),
  // South America
  PlaceModel(name: 'São Paulo', admin1: 'São Paulo', country: 'Brazil', countryCode: 'BR', lat: -23.5505, lon: -46.6333),
  PlaceModel(name: 'Buenos Aires', admin1: 'Buenos Aires', country: 'Argentina', countryCode: 'AR', lat: -34.6037, lon: -58.3816),
  // Europe
  PlaceModel(name: 'London', admin1: 'England', country: 'United Kingdom', countryCode: 'GB', lat: 51.5074, lon: -0.1278),
  PlaceModel(name: 'Paris', admin1: 'Île-de-France', country: 'France', countryCode: 'FR', lat: 48.8566, lon: 2.3522),
  PlaceModel(name: 'Berlin', admin1: 'Berlin', country: 'Germany', countryCode: 'DE', lat: 52.5200, lon: 13.4050),
  PlaceModel(name: 'Madrid', admin1: 'Madrid', country: 'Spain', countryCode: 'ES', lat: 40.4168, lon: -3.7038),
  PlaceModel(name: 'Rome', admin1: 'Lazio', country: 'Italy', countryCode: 'IT', lat: 41.9028, lon: 12.4964),
  PlaceModel(name: 'Moscow', admin1: 'Moscow', country: 'Russia', countryCode: 'RU', lat: 55.7558, lon: 37.6173),
  PlaceModel(name: 'Istanbul', admin1: 'Istanbul', country: 'Türkiye', countryCode: 'TR', lat: 41.0082, lon: 28.9784),
  // Africa
  PlaceModel(name: 'Cairo', admin1: 'Cairo', country: 'Egypt', countryCode: 'EG', lat: 30.0444, lon: 31.2357),
  PlaceModel(name: 'Lagos', admin1: 'Lagos', country: 'Nigeria', countryCode: 'NG', lat: 6.5244, lon: 3.3792),
  PlaceModel(name: 'Nairobi', admin1: 'Nairobi', country: 'Kenya', countryCode: 'KE', lat: -1.2921, lon: 36.8219),
  PlaceModel(name: 'Johannesburg', admin1: 'Gauteng', country: 'South Africa', countryCode: 'ZA', lat: -26.2041, lon: 28.0473),
  // Middle East
  PlaceModel(name: 'Dubai', admin1: 'Dubai', country: 'United Arab Emirates', countryCode: 'AE', lat: 25.2048, lon: 55.2708),
  PlaceModel(name: 'Riyadh', admin1: 'Riyadh', country: 'Saudi Arabia', countryCode: 'SA', lat: 24.7136, lon: 46.6753),
  // South Asia
  PlaceModel(name: 'Delhi', admin1: 'Delhi', country: 'India', countryCode: 'IN', lat: 28.6139, lon: 77.2090),
  PlaceModel(name: 'Mumbai', admin1: 'Maharashtra', country: 'India', countryCode: 'IN', lat: 19.0760, lon: 72.8777),
  PlaceModel(name: 'Chennai', admin1: 'Tamil Nadu', country: 'India', countryCode: 'IN', lat: 13.0827, lon: 80.2707),
  PlaceModel(name: 'Bengaluru', admin1: 'Karnataka', country: 'India', countryCode: 'IN', lat: 12.9716, lon: 77.5946),
  PlaceModel(name: 'Kolkata', admin1: 'West Bengal', country: 'India', countryCode: 'IN', lat: 22.5726, lon: 88.3639),
  PlaceModel(name: 'Hyderabad', admin1: 'Telangana', country: 'India', countryCode: 'IN', lat: 17.3850, lon: 78.4867),
  PlaceModel(name: 'Dhaka', admin1: 'Dhaka', country: 'Bangladesh', countryCode: 'BD', lat: 23.8103, lon: 90.4125),
  PlaceModel(name: 'Karachi', admin1: 'Sindh', country: 'Pakistan', countryCode: 'PK', lat: 24.8607, lon: 67.0011),
  PlaceModel(name: 'Colombo', admin1: 'Western Province', country: 'Sri Lanka', countryCode: 'LK', lat: 6.9271, lon: 79.8612),
  // East & South-East Asia
  PlaceModel(name: 'Bangkok', admin1: 'Bangkok', country: 'Thailand', countryCode: 'TH', lat: 13.7563, lon: 100.5018),
  PlaceModel(name: 'Singapore', admin1: '', country: 'Singapore', countryCode: 'SG', lat: 1.3521, lon: 103.8198),
  PlaceModel(name: 'Jakarta', admin1: 'Jakarta', country: 'Indonesia', countryCode: 'ID', lat: -6.2088, lon: 106.8456),
  PlaceModel(name: 'Manila', admin1: 'Metro Manila', country: 'Philippines', countryCode: 'PH', lat: 14.5995, lon: 120.9842),
  PlaceModel(name: 'Hong Kong', admin1: '', country: 'Hong Kong', countryCode: 'HK', lat: 22.3193, lon: 114.1694),
  PlaceModel(name: 'Shanghai', admin1: 'Shanghai', country: 'China', countryCode: 'CN', lat: 31.2304, lon: 121.4737),
  PlaceModel(name: 'Beijing', admin1: 'Beijing', country: 'China', countryCode: 'CN', lat: 39.9042, lon: 116.4074),
  PlaceModel(name: 'Seoul', admin1: 'Seoul', country: 'South Korea', countryCode: 'KR', lat: 37.5665, lon: 126.9780),
  PlaceModel(name: 'Tokyo', admin1: 'Tokyo', country: 'Japan', countryCode: 'JP', lat: 35.6762, lon: 139.6503),
  // Oceania
  PlaceModel(name: 'Sydney', admin1: 'New South Wales', country: 'Australia', countryCode: 'AU', lat: -33.8688, lon: 151.2093),
  PlaceModel(name: 'Melbourne', admin1: 'Victoria', country: 'Australia', countryCode: 'AU', lat: -37.8136, lon: 144.9631),
  PlaceModel(name: 'Auckland', admin1: 'Auckland', country: 'New Zealand', countryCode: 'NZ', lat: -36.8485, lon: 174.7633),
];
