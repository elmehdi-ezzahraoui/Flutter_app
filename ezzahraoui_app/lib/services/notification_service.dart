import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final _client = Supabase.instance.client;

  // Récupérer toutes les notifications pour l'utilisateur courant (personnelles ou globales)
  Future<List<NotificationModel>> fetchAll() async {
    final userId = _client.auth.currentUser?.id;
    try {
      final query = _client.from('notifications').select();
      final data = userId != null
          ? await query.or('user_id.eq.$userId,user_id.is.null').order('created_at', ascending: false)
          : await query.order('created_at', ascending: false);
      return (data as List).map((e) => NotificationModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Erreur fetchAll notifications : $e');
      return [];
    }
  }

  // Nombre de notifications non-lues
  Future<int> unreadCount() async {
    final userId = _client.auth.currentUser?.id;
    try {
      final query = _client.from('notifications').select('id').eq('is_read', false);
      final data = userId != null
          ? await query.or('user_id.eq.$userId,user_id.is.null')
          : await query;
      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Marquer une notification comme lue
  Future<void> markAsRead(String id) async {
    try {
      await _client.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (e) {
      debugPrint('Erreur markAsRead : $e');
    }
  }

  // Marquer toutes comme lues
  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    try {
      final query = _client.from('notifications').update({'is_read': true}).eq('is_read', false);
      if (userId != null) {
        await query.or('user_id.eq.$userId,user_id.is.null');
      } else {
        await query;
      }
    } catch (e) {
      debugPrint('Erreur markAllAsRead : $e');
    }
  }

  // Supprimer une notification
  Future<void> delete(String id) async {
    try {
      await _client.from('notifications').delete().eq('id', id);
    } catch (e) {
      debugPrint('Erreur delete notification : $e');
    }
  }

  // Stream temps réel des notifications
  StreamSubscription<List<Map<String, dynamic>>> subscribe(
    void Function(List<NotificationModel>) onData,
  ) {
    try {
      return _client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen(
            (data) {
              final userId = _client.auth.currentUser?.id;
              final list = data
                  .where((e) {
                    final uid = e['user_id'];
                    return uid == null || uid == userId;
                  })
                  .map((e) => NotificationModel.fromJson(e))
                  .toList();
              onData(list);
            },
            onError: (error) {
              // Empêche les exceptions non interceptées lors des déconnexions/heartbeats
            },
          );
    } catch (_) {
      return Stream<List<Map<String, dynamic>>>.empty().listen((_) {});
    }
  }

  // Créer les notifications lors d'un nouveau signalement
  Future<void> notifyNewReport(String reportId, String reportTitle) async {
    final userId = _client.auth.currentUser?.id;

    // 1. Notification de confirmation pour l'auteur du signalement
    if (userId != null) {
      try {
        await _client.from('notifications').insert({
          'user_id': userId,
          'type': 'new_report',
          'title': '✅ Signalement publié',
          'body': 'Votre signalement "$reportTitle" a été ajouté avec succès.',
          'report_id': reportId,
          'is_read': false,
        });
      } catch (e) {
        debugPrint('Erreur insertion notification auteur : $e');
      }
    }

    // 2. Notification pour les autres utilisateurs (via RPC ou fallback direct)
    try {
      await _client.rpc('notify_users_new_report', params: {
        'p_report_id': reportId,
        'p_report_title': reportTitle,
      });
    } catch (e) {
      debugPrint('RPC notify_users_new_report non disponible, fallback broadcast : $e');
      try {
        await _client.from('notifications').insert({
          'type': 'new_report',
          'title': '🔴 Nouveau signalement',
          'body': reportTitle,
          'report_id': reportId,
          'is_read': false,
        });
      } catch (e2) {
        debugPrint('Erreur fallback notification : $e2');
      }
    }
  }
}
