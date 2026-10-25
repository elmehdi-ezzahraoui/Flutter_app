// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../theme/app_design.dart';

Widget buildPlatformMapView({
  required double latitude,
  required double longitude,
  required String apiKey,
  String? city,
  String? neighborhood,
  VoidCallback? onOpenExternal,
}) {
  return Container(
    color: Colors.grey.shade100,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              size: 56,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            city != null ? '$city ${neighborhood != null ? "• $neighborhood" : ""}' : 'Carte Interactive',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Latitude : ${latitude.toStringAsFixed(5)}\nLongitude : ${longitude.toStringAsFixed(5)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onOpenExternal,
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Ouvrir dans Google Maps'),
          ),
        ],
      ),
    ),
  );
}
