import 'dart:async';

import 'package:flutter/material.dart';

import '../models/report_model.dart';
import '../services/report_service.dart';
import '../services/location_service.dart';
import '../theme/app_design.dart';
import '../widgets/eco_map_view.dart';
import 'report_form_page.dart';
class EcoMapPage extends StatefulWidget {
  const EcoMapPage({super.key});

  @override
  State<EcoMapPage> createState() => _EcoMapPageState();
}

class _EcoMapPageState extends State<EcoMapPage>
    with SingleTickerProviderStateMixin {
  final ReportService _reportService = ReportService.instance;
  final LocationService _locationService = LocationService.instance;

  List<ReportModel> _reports = [];
  StreamSubscription? _realtimeSub;
  final Set<String> _likedReportIds = {};
  bool _showListView = false;

  double _userLat = 33.589886;
  double _userLng = -7.603869;

  ReportStatus? _filterStatus; // null = tous
  bool _isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLocation();
    _loadInitialReports();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialReports() async {
    try {
      final reports = await _reportService.fetchAll();
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLocation() async {
    try {
      final loc = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _userLat = loc.latitude;
          _userLng = loc.longitude;
        });
      }
    } catch (_) {}
  }

  void _subscribeRealtime() {
    _realtimeSub = _reportService.subscribeToReports((reports) {
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    });
  }

  List<ReportModel> get _filteredReports {
    if (_filterStatus == null) return _reports;
    return _reports.where((r) => r.status == _filterStatus).toList();
  }

  int _countByStatus(ReportStatus s) =>
      _reports.where((r) => r.status == s).length;

  Future<void> _upvote(ReportModel report) async {
    if (_likedReportIds.contains(report.id)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez déjà voté pour ce signalement'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    try {
      final newCount = await _reportService.upvote(report.id);
      if (mounted) {
        setState(() {
          _likedReportIds.add(report.id);
          final idx = _reports.indexWhere((r) => r.id == report.id);
          if (idx >= 0) {
            _reports[idx] = _reports[idx].copyWith(upvotes: newCount);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur like : $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(ReportModel report, ReportStatus newStatus) async {
    try {
      await _reportService.updateStatus(report.id, newStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur mise à jour : $e')),
        );
      }
    }
  }

  void _openReportForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportFormPage(
          initialLat: _userLat,
          initialLng: _userLng,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildStatsBar(),
            _buildFilterBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: kPrimary))
                  : _showListView
                      ? _buildReportsListView()
                      : Stack(
                          children: [
                            EcoMapView(
                              userLat: _userLat,
                              userLng: _userLng,
                              reports: _filteredReports,
                              apiKey: _locationService.apiKey,
                              onReportTap: _showReportDetail,
                              onReportLike: _upvote,
                            ),
                            // Légende
                            Positioned(
                              top: 12,
                              right: 12,
                              child: _buildLegend(),
                            ),
                            // Compteur temps réel
                            Positioned(
                              top: 12,
                              left: 12,
                              child: _buildRealtimeBadge(),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildReportsListView() {
    if (_filteredReports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌿', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Aucun signalement trouvé',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _filteredReports.length,
      itemBuilder: (context, index) {
        final r = _filteredReports[index];
        final isLiked = _likedReportIds.contains(r.id);
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            onTap: () => _showReportDetail(r),
            leading: Text(r.status.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(
              r.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${r.category} • ${_formatDate(r.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            trailing: InkWell(
              onTap: () => _upvote(r),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isLiked ? const Color(0xFFEF4444) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                      size: 14,
                      color: isLiked ? Colors.white : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${r.upvotes}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isLiked ? Colors.white : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF06B6D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🗺️ EcoCity Map',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Carte écologique en temps réel',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            _showListView ? Icons.map_rounded : Icons.view_list_rounded,
            color: Colors.white,
          ),
          tooltip: _showListView ? 'Voir la carte' : 'Voir la liste',
          onPressed: () => setState(() => _showListView = !_showListView),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Actualiser',
          onPressed: () => _subscribeRealtime(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          _statChip('🔴', _countByStatus(ReportStatus.signale), 'Signalés'),
          const SizedBox(width: 8),
          _statChip('🟠', _countByStatus(ReportStatus.en_cours), 'En cours'),
          const SizedBox(width: 8),
          _statChip('🟢', _countByStatus(ReportStatus.resolu), 'Résolus'),
          const Spacer(),
          Text(
            '${_reports.length} total',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String emoji, int count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      (null, 'Tous', Icons.public_rounded),
      (ReportStatus.signale, 'Signalés', Icons.circle),
      (ReportStatus.en_cours, 'En cours', Icons.pending_rounded),
      (ReportStatus.resolu, 'Résolus', Icons.check_circle_rounded),
    ];

    return Container(
      height: 40,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final (status, label, icon) = filters[i];
          final isActive = _filterStatus == status;
          return FilterChip(
            selected: isActive,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13,
                    color: isActive ? Colors.white : const Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? Colors.white : const Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
            selectedColor: const Color(0xFF0F766E),
            backgroundColor: const Color(0xFFF3F4F6),
            checkmarkColor: Colors.white,
            showCheckmark: false,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onSelected: (_) => setState(() => _filterStatus = status),
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Légende',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          for (final s in ReportStatus.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Text(
                    s.label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF4B5563)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRealtimeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Temps réel',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF065F46),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: _openReportForm,
      backgroundColor: const Color(0xFF059669),
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add_location_alt_rounded),
      label: const Text(
        'Signaler',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showReportDetail(ReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReportDetailSheet(
        report: report,
        isLiked: _likedReportIds.contains(report.id),
        onUpvote: () => _upvote(report),
        onStatusChange: (s) => _updateStatus(report, s),
      ),
    );
  }
}

// ─── Bottom Sheet : Détail d'un signalement ─────────────────────────────────

class ReportDetailSheet extends StatefulWidget {
  final ReportModel report;
  final bool isLiked;
  final VoidCallback onUpvote;
  final void Function(ReportStatus) onStatusChange;

  const ReportDetailSheet({
    super.key,
    required this.report,
    this.isLiked = false,
    required this.onUpvote,
    required this.onStatusChange,
  });

  @override
  State<ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<ReportDetailSheet> {
  late bool _liked;
  late int _upvotes;

  @override
  void initState() {
    super.initState();
    _liked = widget.isLiked;
    _upvotes = widget.report.upvotes;
  }

  void _handleLike() {
    if (_liked) return;
    setState(() {
      _liked = true;
      _upvotes++;
    });
    widget.onUpvote();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Statut badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(report.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${report.status.emoji} ${report.status.label}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(report.status),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  report.category,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Titre
          Text(
            report.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),

          if (report.description != null && report.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              report.description!,
              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
            ),
          ],

          const SizedBox(height: 12),

          // Coordonnées
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text(
                '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Date
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text(
                _formatDate(report.createdAt),
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              // Like / Upvote
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _liked ? Colors.white : const Color(0xFFEF4444),
                    backgroundColor: _liked ? const Color(0xFFEF4444) : Colors.transparent,
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _liked ? null : _handleLike,
                  icon: Icon(
                    _liked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                    size: 16,
                  ),
                  label: Text(
                    '$_upvotes vote${_upvotes > 1 ? 's' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Changer le statut
              if (report.status != ReportStatus.resolu)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _nextStatusColor(report.status),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      widget.onStatusChange(_nextStatus(report.status));
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(
                      _nextStatusLabel(report.status),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(ReportStatus s) {
    switch (s) {
      case ReportStatus.signale:
        return const Color(0xFFEF4444);
      case ReportStatus.en_cours:
        return const Color(0xFFF97316);
      case ReportStatus.resolu:
        return const Color(0xFF22C55E);
    }
  }

  ReportStatus _nextStatus(ReportStatus s) {
    switch (s) {
      case ReportStatus.signale:
        return ReportStatus.en_cours;
      case ReportStatus.en_cours:
        return ReportStatus.resolu;
      case ReportStatus.resolu:
        return ReportStatus.resolu;
    }
  }

  String _nextStatusLabel(ReportStatus s) {
    switch (s) {
      case ReportStatus.signale:
        return '🟠 Prendre en charge';
      case ReportStatus.en_cours:
        return '🟢 Marquer résolu';
      case ReportStatus.resolu:
        return '✅ Résolu';
    }
  }

  Color _nextStatusColor(ReportStatus s) {
    switch (s) {
      case ReportStatus.signale:
        return const Color(0xFFF97316);
      case ReportStatus.en_cours:
        return const Color(0xFF22C55E);
      case ReportStatus.resolu:
        return const Color(0xFF22C55E);
    }
  }
}

String _formatDate(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
