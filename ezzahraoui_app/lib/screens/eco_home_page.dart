// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';
import '../models/report_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';
import '../theme/app_design.dart';
import 'chatbot_page.dart';
import 'eco_map_page.dart';
import 'notifications_page.dart';
import 'report_form_page.dart';

class EcoCityHomePage extends StatefulWidget {
  const EcoCityHomePage({super.key});

  @override
  State<EcoCityHomePage> createState() => _EcoCityHomePageState();
}

class _EcoCityHomePageState extends State<EcoCityHomePage> {
  final ReportService _reportService = ReportService.instance;
  List<ReportModel> _reports = [];
  StreamSubscription? _realtimeSub;

  final NotificationService _notifService = NotificationService.instance;
  List<NotificationModel> _notifications = [];
  StreamSubscription? _notifSub;
  final Set<String> _likedReportIds = {};
  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _subscribeRealtime();
    _subscribeNotifications();
  }

  Future<void> _loadInitialData() async {
    try {
      final reports = await _reportService.fetchAll();
      if (mounted) setState(() => _reports = reports);
    } catch (_) {}
    try {
      final notifs = await _notifService.fetchAll();
      if (mounted) setState(() => _notifications = notifs);
    } catch (_) {}
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _notifSub?.cancel();
    super.dispose();
  }

  void _subscribeRealtime() {
    _realtimeSub = _reportService.subscribeToReports((reports) {
      if (mounted) setState(() => _reports = reports);
    });
  }

  void _subscribeNotifications() {
    _notifSub = _notifService.subscribe((notifs) {
      if (mounted) setState(() => _notifications = notifs);
    });
  }

  int get _signalesCount =>
      _reports.where((r) => r.status == ReportStatus.signale).length;
  int get _enCoursCount =>
      _reports.where((r) => r.status == ReportStatus.en_cours).length;
  int get _resolusCount =>
      _reports.where((r) => r.status == ReportStatus.resolu).length;

  List<ReportModel> get _topReports {
    final sorted = [..._reports]
      ..sort((a, b) => b.upvotes.compareTo(a.upvotes));
    return sorted.take(5).toList();
  }

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
          SnackBar(content: Text('Erreur vote : $e')),
        );
      }
    }
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
        onStatusChange: (s) async {
          await _reportService.updateStatus(report.id, s);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      drawer: _buildDrawer(context),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  if (_notifications.isNotEmpty) ...[
                    _buildNotificationsBanner(),
                    const SizedBox(height: 24),
                  ],
                  _buildActionCards(),
                  const SizedBox(height: 24),
                  _buildTopReports(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSliverAppBar() {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final name = email.isNotEmpty ? email.split('@').first : 'Citoyen';

    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF065F46),
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                );
                final notifs = await _notifService.fetchAll();
                if (mounted) setState(() => _notifications = notifs);
              },
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF064E3B), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4), width: 2),
                        ),
                        child: const Center(
                          child: Text('🌿', style: TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour, $name 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Contribuez à une ville plus propre',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Realtime badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF86EFAC),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_reports.length} signalement(s) actifs en temps réel',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '🔴',
            '$_signalesCount',
            'Signalés',
            const Color(0xFFFEE2E2),
            const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            '🟠',
            '$_enCoursCount',
            'En cours',
            const Color(0xFFFFF7ED),
            const Color(0xFFF97316),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            '🟢',
            '$_resolusCount',
            'Résolus',
            const Color(0xFFDCFCE7),
            const Color(0xFF22C55E),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label,
      Color bgColor, Color textColor) {
    return AnimatedEntry(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsBanner() {
    final latest = _notifications.first;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _unreadCount > 0 ? const Color(0xFFFBBF24) : const Color(0xFFE5E7EB),
          width: _unreadCount > 0 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            );
            final notifs = await _notifService.fetchAll();
            if (mounted) setState(() => _notifications = notifs);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _unreadCount > 0
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _unreadCount > 0 ? '🔔' : '📬',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              latest.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_unreadCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$_unreadCount non lue${_unreadCount > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (latest.body != null && latest.body!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          latest.body!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accès rapide',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        // EcoBot card
        _ActionCard(
          emoji: '🌿',
          title: 'EcoBot — Assistant IA',
          subtitle: 'Signalez un problème en 2 secondes par voix ou texte',
          gradient: const [Color(0xFF065F46), Color(0xFF059669)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatbotPage()),
          ),
        ),
        const SizedBox(height: 10),
        // EcoMap card
        _ActionCard(
          emoji: '🗺️',
          title: 'EcoCity Map — Carte Interactive',
          subtitle:
              'Consultez et suivez les signalements en temps réel',
          gradient: const [Color(0xFF0F766E), Color(0xFF06B6D4)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EcoMapPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildTopReports() {
    if (_topReports.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🔥 Signalements prioritaires',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EcoMapPage()),
              ),
              child: const Text('Voir tout →',
                  style: TextStyle(color: Color(0xFF059669))),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...(_topReports.map((r) => _ReportListTile(
              report: r,
              isLiked: _likedReportIds.contains(r.id),
              onLike: () => _upvote(r),
              onTap: () => _showReportDetail(r),
            ))),
      ],
    );
  }

  Widget _buildFab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: FloatingActionButton.extended(
              heroTag: 'fab_ecobot',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatbotPage()),
              ),
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              icon: const Text('🌿', style: TextStyle(fontSize: 18)),
              label: const Text('EcoBot',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FloatingActionButton.extended(
              heroTag: 'fab_signal',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportFormPage(
                    initialLat: 33.589886,
                    initialLng: -7.603869,
                  ),
                ),
              ),
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Signaler',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF059669)]),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EcoCity',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '🌿 Plateforme citoyenne écologique',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF86EFAC),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_reports.length} signalements',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_rounded, color: Color(0xFF059669)),
            title: const Text('Accueil'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Text('🌿',
                style: TextStyle(fontSize: 20)),
            title: const Text('EcoBot — Assistant IA'),
            subtitle: const Text('Signalement intelligent',
                style: TextStyle(fontSize: 11)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatbotPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.map_rounded, color: Color(0xFF0F766E)),
            title: const Text('EcoCity Map'),
            subtitle: const Text('Carte temps réel',
                style: TextStyle(fontSize: 11)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EcoMapPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_location_alt_rounded,
                color: Color(0xFFEF4444)),
            title: const Text('Nouveau Signalement'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportFormPage(
                      initialLat: 33.589886, initialLng: -7.603869),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_rounded,
                color: Color(0xFFF59E0B)),
            title: const Text('Notifications'),
            trailing: _unreadCount > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
              final notifs = await _notifService.fetchAll();
              if (mounted) setState(() => _notifications = notifs);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: kPrimary),
            title: const Text('Se déconnecter'),
            onTap: () async {
              Navigator.pop(context);
              await const AuthService().signOut();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Widget : Carte d'action colorée ────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedEntry(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white54, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Widget : Ligne de signalement ─────────────────────────────────────────

class _ReportListTile extends StatelessWidget {
  final ReportModel report;
  final bool isLiked;
  final VoidCallback? onLike;
  final VoidCallback? onTap;

  const _ReportListTile({
    required this.report,
    this.isLiked = false,
    this.onLike,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: onTap,
        leading: Text(report.status.emoji,
            style: const TextStyle(fontSize: 24)),
        title: Text(
          report.title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          report.category,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        trailing: InkWell(
          onTap: onLike,
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
                  '${report.upvotes}',
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
  }
}
