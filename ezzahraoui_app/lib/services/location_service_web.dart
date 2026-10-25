// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

class UserLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String label;
  final String? city;
  final String? neighborhood;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.label = 'Position GPS détectée',
    this.city,
    this.neighborhood,
  });
}

Future<Map<String, String?>> _reverseGeocode(double lat, double lng) async {
  // 1. Tenter OpenStreetMap Nominatim avec accept-language=fr (sans headers interdits)
  try {
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1&accept-language=fr';
    final responseText = await html.HttpRequest.getString(url).timeout(
      const Duration(seconds: 4),
    );
    final data = jsonDecode(responseText) as Map<String, dynamic>;
    final address = data['address'] as Map<String, dynamic>?;
    if (address != null) {
      final city = address['city'] ??
          address['town'] ??
          address['village'] ??
          address['municipality'] ??
          address['county'];
      final neighborhood = address['neighbourhood'] ??
          address['suburb'] ??
          address['quarter'] ??
          address['residential'] ??
          address['city_district'] ??
          address['road'];
      if (city != null || neighborhood != null) {
        return {
          'city': city?.toString(),
          'neighborhood': neighborhood?.toString(),
        };
      }
    }
  } catch (e) {
    html.window.console.warn('Nominatim reverse geocode notice: $e');
  }

  // 2. Repli vers BigDataCloud (CORS 100% ouvert)
  try {
    final url =
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=fr';
    final responseText = await html.HttpRequest.getString(url).timeout(
      const Duration(seconds: 3),
    );
    final data = jsonDecode(responseText) as Map<String, dynamic>;
    final city = data['city'] ?? data['locality'] ?? data['principalSubdivision'];
    final neighborhood = data['locality'] != city ? data['locality'] : null;
    return {
      'city': city?.toString(),
      'neighborhood': neighborhood?.toString(),
    };
  } catch (e) {
    html.window.console.warn('BigDataCloud notice: $e');
  }

  return {'city': null, 'neighborhood': null};
}

Future<html.Geoposition> _getBrowserPosition() {
  final completer = Completer<html.Geoposition>();
  final geo = html.window.navigator.geolocation;

  // Tentative 1 : avec haute précision (GPS si disponible)
  geo.getCurrentPosition(
    enableHighAccuracy: true,
    timeout: const Duration(seconds: 4),
    maximumAge: const Duration(minutes: 5),
  ).then((pos) {
    if (!completer.isCompleted) {
      completer.complete(pos);
    }
  }).catchError((_) {
    // Tentative 2 immédiate : précision standard (WiFi / IP, indispensable sur PC Windows)
    geo.getCurrentPosition(
      enableHighAccuracy: false,
      timeout: const Duration(seconds: 6),
      maximumAge: const Duration(minutes: 5),
    ).then((pos) {
      if (!completer.isCompleted) {
        completer.complete(pos);
      }
    }).catchError((err) {
      if (!completer.isCompleted) {
        completer.completeError(err);
      }
    });
  });

  return completer.future;
}

Future<UserLocation> fetchCurrentLocation() async {
  try {
    final pos = await _getBrowserPosition();
    final coords = pos.coords;

    if (coords != null && coords.latitude != null && coords.longitude != null) {
      final lat = coords.latitude!.toDouble();
      final lng = coords.longitude!.toDouble();
      final acc = coords.accuracy?.toDouble();

      // Résolution ville et quartier en arrière-plan sans bloquer
      String? city;
      String? neighborhood;
      try {
        final geo = await _reverseGeocode(lat, lng);
        city = geo['city'];
        neighborhood = geo['neighborhood'];
      } catch (_) {}

      String label = 'Position GPS en direct';
      if (city != null && neighborhood != null) {
        label = '$city • $neighborhood';
      } else if (city != null) {
        label = city;
      }

      return UserLocation(
        latitude: lat,
        longitude: lng,
        accuracy: acc,
        label: label,
        city: city,
        neighborhood: neighborhood,
      );
    }
  } catch (e) {
    html.window.console.warn('Erreur localisation navigateur: $e');
  }

  // Si le navigateur a refusé la géolocalisation ou erreur matérielle
  return const UserLocation(
    latitude: 33.589886,
    longitude: -7.603869,
    accuracy: 20.0,
    label: 'Position par défaut (Casablanca)',
    city: 'Casablanca',
    neighborhood: 'Centre-ville',
  );
}
