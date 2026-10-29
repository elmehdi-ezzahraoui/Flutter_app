// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

import '../models/report_model.dart';

Widget buildEcoMapView({
  required double userLat,
  required double userLng,
  required List<ReportModel> reports,
  required String apiKey,
  void Function(ReportModel)? onReportTap,
  void Function(ReportModel)? onReportLike,
}) {
  return _EcoWebMapView(
    userLat: userLat,
    userLng: userLng,
    reports: reports,
    apiKey: apiKey,
    onReportTap: onReportTap,
    onReportLike: onReportLike,
  );
}

class _EcoWebMapView extends StatefulWidget {
  final double userLat;
  final double userLng;
  final List<ReportModel> reports;
  final String apiKey;
  final void Function(ReportModel)? onReportTap;
  final void Function(ReportModel)? onReportLike;

  const _EcoWebMapView({
    required this.userLat,
    required this.userLng,
    required this.reports,
    required this.apiKey,
    this.onReportTap,
    this.onReportLike,
  });

  @override
  State<_EcoWebMapView> createState() => _EcoWebMapViewState();
}

class _EcoWebMapViewState extends State<_EcoWebMapView> {
  late String _viewId;
  StreamSubscription? _msgSub;

  @override
  void initState() {
    super.initState();
    _listenToWindowMessages();
    _registerView();
  }

  @override
  void didUpdateWidget(covariant _EcoWebMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() => _registerView());
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    super.dispose();
  }

  void _listenToWindowMessages() {
    _msgSub = html.window.onMessage.listen((event) {
      try {
        final data = event.data;
        String? type;
        String? id;
        if (data is String) {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            type = decoded['type']?.toString();
            id = decoded['id']?.toString();
          }
        }
        if (id != null && type != null) {
          final report = widget.reports.where((r) => r.id == id).firstOrNull;
          if (report != null) {
            if (type == 'report_like') {
              if (widget.onReportLike != null) {
                widget.onReportLike!(report);
              } else {
                widget.onReportTap?.call(report);
              }
            } else if (type == 'report_tap' || type == 'report_detail') {
              widget.onReportTap?.call(report);
            }
          }
        }
      } catch (_) {}
    });
  }

  /// Sérialise les reports en JSON pour injection dans le HTML.
  String _buildMarkersJson() {
    final list = widget.reports.map((r) {
      return {
        'id': r.id,
        'title': r.title,
        'category': r.category,
        'description': r.description ?? '',
        'lat': r.latitude,
        'lng': r.longitude,
        'color': r.status.hexColor,
        'emoji': r.status.emoji,
        'status': r.status.label,
        'upvotes': r.upvotes,
      };
    }).toList();
    return jsonEncode(list);
  }

  void _registerView() {
    _viewId = 'eco-map-${DateTime.now().microsecondsSinceEpoch}';
    final lat = widget.userLat;
    final lng = widget.userLng;
    final markersJson = _buildMarkersJson();

    final srcdoc = '''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <style>
    html, body { height: 100%; margin: 0; padding: 0; overflow: hidden; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
    #map { height: 100%; width: 100%; }
    .eco-popup { font-size: 13px; min-width: 200px; }
    .eco-popup h3 { margin: 0 0 4px; color: #111827; font-size: 14px; }
    .eco-popup .badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 600; margin-bottom: 6px; }
    .eco-popup .cat { color: #6B7280; font-size: 11.5px; margin-bottom: 4px; }
    .eco-popup .desc { color: #374151; font-size: 12.5px; line-height: 1.4; }
    .eco-popup .upvote { margin-top: 8px; font-size: 11px; color: #EF4444; font-weight: 600; }
    .pulse-dot {
      width: 16px; height: 16px; border-radius: 50%;
      border: 3px solid white;
      box-shadow: 0 0 0 0 rgba(255,255,255,0.7);
      animation: pulse 2s infinite;
    }
    @keyframes pulse {
      0% { box-shadow: 0 0 0 0 rgba(79,70,229,0.7); }
      70% { box-shadow: 0 0 0 10px rgba(79,70,229,0); }
      100% { box-shadow: 0 0 0 0 rgba(79,70,229,0); }
    }
  </style>
</head>
<body>
  <div id="map"></div>
  <script>
    const markers = $markersJson;
    const userLat = $lat;
    const userLng = $lng;

    // Centre sur la moyenne des marqueurs ou sur l'utilisateur
    let centerLat = userLat, centerLng = userLng;
    if (markers.length > 0) {
      const avgLat = markers.reduce((a,b) => ({lat: a.lat+b.lat}), {lat:0}).lat / markers.length;
      const avgLng = markers.reduce((a,b) => ({lng: a.lng+b.lng}), {lng:0}).lng / markers.length;
      // Reste centré sur l'utilisateur
    }

    const map = L.map('map', { zoomControl: true }).setView([centerLat, centerLng], 14);

    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© OpenStreetMap'
    }).addTo(map);

    // Marqueur position utilisateur (bleu pulsant)
    const userIcon = L.divIcon({
      html: '<div class="pulse-dot" style="background:#4F46E5;"></div>',
      className: '',
      iconSize: [16, 16],
      iconAnchor: [8, 8]
    });
    L.marker([userLat, userLng], { icon: userIcon })
      .addTo(map)
      .bindPopup('<div style="font-size:13px"><b>📍 Votre Position</b><br><span style="color:#6B7280;font-size:11px">' + userLat.toFixed(5) + ', ' + userLng.toFixed(5) + '</span></div>');

    // Marqueurs des signalements
    markers.forEach(function(r) {
      const markerIcon = L.divIcon({
        html: '<div style="background:' + r.color + ';width:22px;height:22px;border-radius:50%;border:3px solid white;box-shadow:0 2px 8px rgba(0,0,0,0.35);cursor:pointer;"></div>',
        className: '',
        iconSize: [22, 22],
        iconAnchor: [11, 11]
      });

      let popupContent = '<div class="eco-popup" style="font-family:sans-serif;min-width:210px;padding:4px;">';
      popupContent += '<div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px;">';
      popupContent += '<span class="badge" style="background:' + r.color + '22;color:' + r.color + ';padding:2px 8px;border-radius:12px;font-size:11px;font-weight:bold;">' + r.emoji + ' ' + r.status + '</span>';
      popupContent += '<span style="font-size:11px;color:#6B7280;">' + r.category + '</span>';
      popupContent += '</div>';
      popupContent += '<h3 style="margin:0 0 6px 0;font-size:14px;color:#111827;font-weight:bold;">' + r.title + '</h3>';
      if (r.description) popupContent += '<div style="margin:0 0 10px 0;font-size:12px;color:#4B5563;line-height:1.4;">' + r.description + '</div>';
      
      popupContent += '<div style="display:flex;gap:8px;margin-top:10px;">';
      popupContent += '<button onclick="window.parent.postMessage(JSON.stringify({type:\'report_like\',id:\'' + r.id + '\'}),\'*\');" style="flex:1;cursor:pointer;background:#EF4444;color:white;border:none;border-radius:8px;padding:8px 10px;font-size:12px;font-weight:bold;display:inline-flex;align-items:center;justify-content:center;gap:4px;box-shadow:0 2px 6px rgba(239,68,68,0.35);">👍 Voter (' + r.upvotes + ')</button>';
      popupContent += '<button onclick="window.parent.postMessage(JSON.stringify({type:\'report_detail\',id:\'' + r.id + '\'}),\'*\');" style="cursor:pointer;background:#F3F4F6;color:#374151;border:1px solid #D1D5DB;border-radius:8px;padding:8px 10px;font-size:12px;font-weight:600;">Détails</button>';
      popupContent += '</div>';
      popupContent += '</div>';

      const m = L.marker([r.lat, r.lng], { icon: markerIcon })
        .addTo(map)
        .bindPopup(popupContent, { maxWidth: 280 });

      m.on('click', function() {
        window.parent.postMessage(JSON.stringify({type: 'report_tap', id: r.id}), '*');
      });
    });

    // Ajuster le zoom pour afficher tous les marqueurs
    if (markers.length > 0) {
      try {
        const allPoints = markers.map(m => [m.lat, m.lng]);
        allPoints.push([userLat, userLng]);
        const bounds = L.latLngBounds(allPoints);
        map.fitBounds(bounds, { padding: [40, 40], maxZoom: 15 });
      } catch(e) {}
    }
  </script>
</body>
</html>''';

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
