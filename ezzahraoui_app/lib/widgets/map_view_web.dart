// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildPlatformMapView({
  required double latitude,
  required double longitude,
  required String apiKey,
  String? city,
  String? neighborhood,
  VoidCallback? onOpenExternal,
}) {
  return _WebGoogleMapView(
    latitude: latitude,
    longitude: longitude,
    apiKey: apiKey,
    city: city,
    neighborhood: neighborhood,
  );
}

class _WebGoogleMapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String apiKey;
  final String? city;
  final String? neighborhood;

  const _WebGoogleMapView({
    required this.latitude,
    required this.longitude,
    required this.apiKey,
    this.city,
    this.neighborhood,
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
        oldWidget.apiKey != widget.apiKey ||
        oldWidget.city != widget.city ||
        oldWidget.neighborhood != widget.neighborhood) {
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
    let leafletLoaded = false;

    // Moteur interactif universel (Leaflet / OpenStreetMap)
    function loadLeafletMap(statusText) {
      if (leafletLoaded) return;
      leafletLoaded = true;

      const mapContainer = document.getElementById('map');
      if (mapContainer) {
        mapContainer.innerHTML = '';
        mapContainer.className = '';
        mapContainer.removeAttribute('style');
        mapContainer.style.height = '100%';
        mapContainer.style.width = '100%';
      }

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

      const cityVal = "${widget.city ?? ''}";
      const neighVal = "${widget.neighborhood ?? ''}";
      let locationHeader = '<b style="color: #1E1B4B; font-size: 13.5px;">📍 Votre Position Actuelle</b>';
      if (cityVal.length > 0) {
        locationHeader += '<div style="margin-top: 4px; font-weight: 600; color: #4F46E5; font-size: 13px;">🏙️ ' + cityVal;
        if (neighVal.length > 0) {
          locationHeader += ' • ' + neighVal;
        }
        locationHeader += '</div>';
      }

      const marker = L.marker([$lat, $lng], { icon: customIcon }).addTo(map);
      marker.bindPopup(
        '<div style="font-family: sans-serif; padding: 4px; font-size: 13px;">' +
        locationHeader +
        '<div style="color: #6B7280; font-size: 11.5px; margin-top: 4px;">Lat : $lat<br>Lng : $lng</div>' +
        '</div>'
      ).openPopup();
    }

    // 1. Capture instantanée de la console pour les erreurs de clé / facturation Google Maps
    const originalConsoleError = console.error;
    console.error = function() {
      originalConsoleError.apply(console, arguments);
      for (let i = 0; i < arguments.length; i++) {
        const msg = String(arguments[i]);
        if (msg.includes('Google Maps') || msg.includes('MapError') || msg.includes('BillingNotEnabled')) {
          loadLeafletMap('📍 Position GPS en direct');
          break;
        }
      }
    };

    // 2. Gestionnaire standard d'authentification Google Maps
    window.gm_authFailure = function() {
      console.warn("Échec d'authentification Google Maps. Basculement fluide vers la carte interactive...");
      loadLeafletMap('📍 Position GPS en direct');
    };

    // 3. Intercepteur automatique de l'écran gris (vérifie toutes les 100ms = 0,1 seconde)
    const grayScreenChecker = setInterval(function() {
      if (leafletLoaded) {
        clearInterval(grayScreenChecker);
        return;
      }
      
      const bodyText = (document.body && document.body.innerText) ? document.body.innerText : '';
      const mapElem = document.getElementById('map');
      const mapHtml = (mapElem && mapElem.innerHTML) ? mapElem.innerHTML : '';
      
      const hasGrayError = 
        document.querySelector('.gm-err-container') !== null ||
        document.querySelector('.dismissButton') !== null ||
        document.querySelector('[src*="icon_error"]') !== null ||
        bodyText.includes('Petit problème') ||
        bodyText.includes("ne s'est pas chargé") ||
        bodyText.includes('Oops! Something went wrong') ||
        bodyText.includes('For development purposes only') ||
        mapHtml.includes('gm-err');

      if (hasGrayError) {
        clearInterval(grayScreenChecker);
        loadLeafletMap('📍 Position GPS en direct');
      }
    }, 100);

    // Timeout de sécurité au bout de 1s
    setTimeout(function() {
      clearInterval(grayScreenChecker);
      if (!leafletLoaded && (!mapInitialized || document.querySelector('.gm-err-container'))) {
        loadLeafletMap('📍 Position GPS en direct');
      }
    }, 1000);

    // Chargement de Google Maps si la clé est fournie
    if ("$key".length > 10) {
      window.initGoogleMap = function() {
        try {
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

          const cityVal = "${widget.city ?? ''}";
          const neighVal = "${widget.neighborhood ?? ''}";
          let gInfoContent = '<div style="padding: 6px; font-family: sans-serif; font-size: 13px;">' +
                             '<strong style="color: #1e1b4b;">📍 Votre Position Actuelle</strong>';
          if (cityVal.length > 0) {
            gInfoContent += '<br><span style="color: #4F46E5; font-weight: 600;">🏙️ ' + cityVal;
            if (neighVal.length > 0) {
              gInfoContent += ' • ' + neighVal;
            }
            gInfoContent += '</span>';
          }
          gInfoContent += '<br><span style="color: #64748b; font-size: 11.5px;">Lat : $lat, Lng : $lng</span></div>';

          const infoWindow = new google.maps.InfoWindow({
            content: gInfoContent
          });

          infoWindow.open(map, marker);
          marker.addListener("click", () => infoWindow.open(map, marker));

          const badge = document.getElementById('badge');
          if (badge) badge.innerText = '🗺️ Google Maps Actif';
          mapInitialized = true;
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
    } else {
      // Pas de clé API → Leaflet directement, sans attendre Google Maps
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
