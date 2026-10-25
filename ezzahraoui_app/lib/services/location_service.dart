import 'location_service_stub.dart'
    if (dart.library.html) 'location_service_web.dart' as platform_location;

export 'location_service_stub.dart'
    if (dart.library.html) 'location_service_web.dart';

class LocationService {
  // Clé d'environnement passée via --dart-define-from-file=supabase_config.json
  static const String _envApiKey = String.fromEnvironment('MAPS_API_KEY');

  static final LocationService instance = LocationService._internal();

  LocationService._internal() {
    _apiKey = _envApiKey;
  }

  late String _apiKey;
  String get apiKey => _apiKey;

  void setApiKey(String key) {
    _apiKey = key.trim();
  }

  void resetApiKeyToDefault() {
    _apiKey = _envApiKey;
  }

  Future<platform_location.UserLocation> getCurrentLocation() {
    return platform_location.fetchCurrentLocation();
  }
}
