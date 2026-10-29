// ignore_for_file: deprecated_member_use
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
  return _EcoStubMapView(
    userLat: userLat,
    userLng: userLng,
    reports: reports,
    onReportTap: onReportTap,
    onReportLike: onReportLike,
  );
}

class _EcoStubMapView extends StatelessWidget {
  final double userLat;
  final double userLng;
  final List<ReportModel> reports;
  final void Function(ReportModel)? onReportTap;
  final void Function(ReportModel)? onReportLike;

  const _EcoStubMapView({
    required this.userLat,
    required this.userLng,
    required this.reports,
    this.onReportTap,
    this.onReportLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0FDF4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.map_rounded,
                      color: Color(0xFF059669), size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EcoCity Map',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF065F46),
                      ),
                    ),
                    Text(
                      '${reports.length} signalement(s) actifs',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: reports.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🌿', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text(
                          'Aucun signalement pour l\'instant',
                          style: TextStyle(
                              color: Color(0xFF6B7280), fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final r = reports[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: Text(r.status.emoji,
                              style: const TextStyle(fontSize: 22)),
                          title: Text(r.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(r.category),
                          trailing: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => onReportLike?.call(r),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '👍 ${r.upvotes}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ),
                          onTap: () => onReportTap?.call(r),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
