import 'dart:async';

class UserLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String label;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.label = 'Position par défaut (Casablanca)',
  });
}

Future<UserLocation> fetchCurrentLocation() async {
  // Coordonnées par défaut (EMSI Casablanca)
  return const UserLocation(
    latitude: 33.589886,
    longitude: -7.603869,
    accuracy: 10.0,
    label: 'EMSI Casablanca (Par défaut)',
  );
}
