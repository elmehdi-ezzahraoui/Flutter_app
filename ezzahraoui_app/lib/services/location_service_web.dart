// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

class UserLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String label;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.label = 'Position GPS détectée',
  });
}

Future<UserLocation> fetchCurrentLocation() async {
  final completer = Completer<UserLocation>();

  try {
    final geolocation = html.window.navigator.geolocation;
    geolocation.getCurrentPosition(
      enableHighAccuracy: true,
      timeout: const Duration(seconds: 10),
      maximumAge: const Duration(minutes: 5),
    ).then((pos) {
      final coords = pos.coords;
      if (coords != null) {
        final lat = coords.latitude?.toDouble() ?? 33.589886;
        final lng = coords.longitude?.toDouble() ?? -7.603869;
        final acc = coords.accuracy?.toDouble();

        completer.complete(
          UserLocation(
            latitude: lat,
            longitude: lng,
            accuracy: acc,
            label: 'Position GPS détectée',
          ),
        );
      } else {
        completer.complete(
          const UserLocation(
            latitude: 33.589886,
            longitude: -7.603869,
            accuracy: 15.0,
            label: 'Casablanca (Position approximative)',
          ),
        );
      }
    }).catchError((error) {
      completer.complete(
        const UserLocation(
          latitude: 33.589886,
          longitude: -7.603869,
          accuracy: 20.0,
          label: 'Casablanca (Position par défaut)',
        ),
      );
    });
  } catch (_) {
    completer.complete(
      const UserLocation(
        latitude: 33.589886,
        longitude: -7.603869,
        accuracy: 20.0,
        label: 'Casablanca (Position par défaut)',
      ),
    );
  }

  return completer.future;
}
