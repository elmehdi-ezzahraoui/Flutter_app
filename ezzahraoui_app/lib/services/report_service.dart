import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/report_model.dart';

/// Service CRUD + Realtime pour la table `reports` de Supabase.
class ReportService {
  static final ReportService instance = ReportService._internal();
  ReportService._internal();

  final _client = Supabase.instance.client;

  // ─── Lecture ────────────────────────────────────────────────────────────────

  Future<List<ReportModel>> fetchAll() async {
    final data = await _client
        .from('reports')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => ReportModel.fromJson(e)).toList();
  }

  Future<List<ReportModel>> fetchByStatus(ReportStatus status) async {
    final data = await _client
        .from('reports')
        .select()
        .eq('status', status.name)
        .order('upvotes', ascending: false);
    return (data as List).map((e) => ReportModel.fromJson(e)).toList();
  }

  // ─── Création ───────────────────────────────────────────────────────────────

  /// Insère un nouveau signalement et retourne l'objet créé.
  Future<ReportModel> create({
    required String title,
    String? description,
    required String category,
    required double latitude,
    required double longitude,
    String? imageUrl,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final payload = ReportModel(
      id: '',
      userId: userId,
      title: title,
      description: description,
      category: category,
      latitude: latitude,
      longitude: longitude,
      status: ReportStatus.signale,
      upvotes: 0,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    ).toInsertJson();

    final data =
        await _client.from('reports').insert(payload).select().single();
    return ReportModel.fromJson(data);
  }

  // ─── Mise à jour du statut ───────────────────────────────────────────────────

  Future<void> updateStatus(String id, ReportStatus status) async {
    await _client.from('reports').update({
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ─── Like / Upvote ─────────────────────────────────────────────────────────

  /// Incrémente le compteur upvotes via RPC atomique (ou fallback direct) et retourne le nouveau total.
  Future<int> upvote(String reportId) async {
    try {
      final result = await _client.rpc('increment_upvote', params: {
        'p_report_id': reportId,
      });
      return (result as int?) ?? 0;
    } catch (_) {
      // Fallback si la fonction RPC increment_upvote n'a pas encore été créée dans Supabase
      try {
        final current = await _client
            .from('reports')
            .select('upvotes')
            .eq('id', reportId)
            .maybeSingle();
        final currentUpvotes = (current?['upvotes'] as int?) ?? 0;
        final newUpvotes = currentUpvotes + 1;
        await _client
            .from('reports')
            .update({
              'upvotes': newUpvotes,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', reportId);
        return newUpvotes;
      } catch (e) {
        rethrow;
      }
    }
  }

  // ─── Realtime ────────────────────────────────────────────────────────────────

  /// Écoute les INSERT/UPDATE de la table et émet la liste mise à jour.
  StreamSubscription<List<Map<String, dynamic>>> subscribeToReports(
    void Function(List<ReportModel> reports) onData,
  ) {
    return _client
        .from('reports')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen(
          (data) {
            final reports = data.map((e) => ReportModel.fromJson(e)).toList();
            onData(reports);
          },
          onError: (error) {
            // Empêche les exceptions non interceptées lors des déconnexions/heartbeats
          },
        );
  }

  // ─── Suppression ─────────────────────────────────────────────────────────────

  Future<void> delete(String id) async {
    await _client.from('reports').delete().eq('id', id);
  }
}
