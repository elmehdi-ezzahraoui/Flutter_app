import 'package:flutter/material.dart';
import 'map_view_stub.dart'
    if (dart.library.html) 'map_view_web.dart' as platform_map;

class GoogleMapView extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String apiKey;
  final VoidCallback? onOpenExternal;

  const GoogleMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.apiKey,
    this.onOpenExternal,
  });

  @override
  Widget build(BuildContext context) {
    return platform_map.buildPlatformMapView(
      latitude: latitude,
      longitude: longitude,
      apiKey: apiKey,
      onOpenExternal: onOpenExternal,
    );
  }
}
