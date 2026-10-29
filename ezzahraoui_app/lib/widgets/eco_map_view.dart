import 'package:flutter/material.dart';

import '../models/report_model.dart';
import 'eco_map_view_web.dart'
    if (dart.library.io) 'eco_map_view_stub.dart';

export 'eco_map_view_web.dart'
    if (dart.library.io) 'eco_map_view_stub.dart';

/// Widget carte EcoCity affichant les marqueurs colorés.
class EcoMapView extends StatelessWidget {
  final double userLat;
  final double userLng;
  final List<ReportModel> reports;
  final String apiKey;
  final void Function(ReportModel)? onReportTap;
  final void Function(ReportModel)? onReportLike;

  const EcoMapView({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.reports,
    required this.apiKey,
    this.onReportTap,
    this.onReportLike,
  });

  @override
  Widget build(BuildContext context) {
    return buildEcoMapView(
      userLat: userLat,
      userLng: userLng,
      reports: reports,
      apiKey: apiKey,
      onReportTap: onReportTap,
      onReportLike: onReportLike,
    );
  }
}
