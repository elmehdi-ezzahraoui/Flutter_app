// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildPlatformMapView({
  required double latitude,
  required double longitude,
  required String apiKey,
  VoidCallback? onOpenExternal,
}) {
  return _WebGoogleMapView(
    latitude: latitude,
    longitude: longitude,
    apiKey: apiKey,
  );
}

class _WebGoogleMapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String apiKey;

  const _WebGoogleMapView({
    required this.latitude,
    required this.longitude,
    required this.apiKey,
  });

  @override
  State<_WebGoogleMapView> createState() => _WebGoogleMapViewState();
}

class _WebGoogleMapViewState extends State<_WebGoogleMapView> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _registerView();
  }

  @override
  void didUpdateWidget(covariant _WebGoogleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.apiKey != widget.apiKey) {
      setState(() {
        _registerView();
      });
    }
  }

  void _registerView() {
    _viewId = 'google-map-${DateTime.now().microsecondsSinceEpoch}';
    final lat = widget.latitude;
    final lng = widget.longitude;
    final key = widget.apiKey;

    final srcdoc = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <style>
    html, body {
      height: 100%;
      margin: 0;
      padding: 0;
      overflow: hidden;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }
    #map {
      height: 100%;
      width: 100%;
    }
    .map-badge {
      position: absolute;
      bottom: 20px;
      left: 12px;
      z-index: 1000;
      background: rgba(30, 27, 75, 0.85);
      color: white;
      padding: 6px 14px;
      border-radius: 20px;
      font-size: 11.5px;
      font-weight: 500;
      backdrop-filter: blur(6px);
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      border: 1px solid rgba(255,255,255,0.15);
      pointer-events: none;
    }
    .custom-pin {
      width: 20px;
      height: 20px;
      background: #4F46E5;
      border: 3px solid white;
      border-radius: 50%;
      box-shadow: 0 0 10px rgba(79, 70, 229, 0.8);
    }
  </style>
</head>
<body>
  <div id="map"></div>
  <div id="badge" class="map-badge">📍 Position GPS en direct</div>

  <script>
    let mapInitialized = false;

    // Moteur interactif universel (Leaflet / OpenStreetMap)
    function loadLeafletMap(statusText) {
      if (mapInitialized) return;
      mapInitialized = true;

      const badge = document.getElementById('badge');
      if (badge && statusText) badge.innerText = statusText;

      const map = L.map('map', { zoomControl: true }).setView([$lat, $lng], 16);
      L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '© OpenStreetMap • Google Maps'
      }).addTo(map);

      const customIcon = L.divIcon({
        className: 'custom-pin',
        iconSize: [20, 20],
        iconAnchor: [10, 10]
      });

      const marker = L.marker([$lat, $lng], { icon: customIcon }).addTo(map);
      marker.bindPopup(
        '<div style="font-family: sans-serif; padding: 4px; font-size: 13px;">' +
        '<b style="color: #1E1B4B;">📍 Votre Position Actuelle</b><br>' +
        '<span style="color: #6B7280; font-size: 12px;">Lat : $lat<br>Lng : $lng</span>' +
        '</div>'
      ).openPopup();
    }

    // Gestionnaire en cas d'erreur de clé Google Maps
    window.gm_authFailure = function() {
      console.warn("Google Maps ApiNotActivatedMapError. Basculement fluide vers la carte interactive...");
      loadLeafletMap('📍 Position GPS en direct');
    };

    // Chargement de Google Maps si la clé est fournie
    if ("$key".length > 10) {
      window.initGoogleMap = function() {
        try {
          mapInitialized = true;
          const pos = { lat: $lat, lng: $lng };
          const map = new google.maps.Map(document.getElementById('map'), {
            zoom: 16,
            center: pos,
            mapTypeControl: true,
            streetViewControl: true,
            fullscreenControl: true,
            zoomControl: true,
          });

          const marker = new google.maps.Marker({
            position: pos,
            map: map,
            title: "Votre Position Actuelle",
            animation: google.maps.Animation.DROP,
          });

          const infoWindow = new google.maps.InfoWindow({
            content: '<div style="padding: 6px; font-family: sans-serif; font-size: 13px;">' +
                     '<strong style="color: #1e1b4b;">📍 Votre Position Actuelle</strong><br>' +
                     '<span style="color: #64748b;">Lat : $lat, Lng : $lng</span>' +
                     '</div>'
          });

          infoWindow.open(map, marker);
          marker.addListener("click", () => infoWindow.open(map, marker));

          const badge = document.getElementById('badge');
          if (badge) badge.innerText = '🗺️ Google Maps Actif';
        } catch (e) {
          loadLeafletMap('📍 Position GPS en direct');
        }
      };

      const gScript = document.createElement('script');
      gScript.src = "https://maps.googleapis.com/maps/api/js?key=$key&loading=async&callback=initGoogleMap";
      gScript.async = true;
      gScript.onerror = function() {
        loadLeafletMap('📍 Position GPS en direct');
      };
      document.head.appendChild(gScript);

      // Si Google Maps ne répond pas ou est bloqué (ApiNotActivatedMapError) après 1.8s, afficher la carte
      setTimeout(function() {
        if (!mapInitialized) {
          loadLeafletMap('📍 Position GPS en direct');
        }
      }, 1800);
    } else {
      loadLeafletMap('📍 Position GPS en direct');
    }
  </script>
</body>
</html>
''';

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..srcdoc = srcdoc;
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
