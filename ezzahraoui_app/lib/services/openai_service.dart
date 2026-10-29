import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/report_model.dart';

// ─── Modèle de message du chat ───────────────────────────────────────────────

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  /// Si non-null, ce message déclenche la création d'un signalement.
  final ReportDraft? reportDraft;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.reportDraft,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Signalement parsé à partir de la réponse du bot.
class ReportDraft {
  final String title;
  final String category;
  final String? description;

  const ReportDraft({
    required this.title,
    required this.category,
    this.description,
  });

  factory ReportDraft.fromJson(Map<String, dynamic> json) {
    return ReportDraft(
      title: json['title'] as String? ?? 'Signalement',
      category: json['category'] as String? ?? 'autre',
      description: json['description'] as String?,
    );
  }
}

// ─── Service IA ───────────────────────────────────────────────────────────────

class OpenAiService {
  static const String _defaultApiKey = String.fromEnvironment('AI_API_KEY');

  static final OpenAiService instance = OpenAiService._internal();

  OpenAiService._internal() {
    _apiKey = _defaultApiKey;
    _resetHistory();
  }

  late String _apiKey;
  String get apiKey => _apiKey;

  bool get isGroq => _apiKey.startsWith('gsk_');

  String get providerName => isGroq ? 'Groq' : 'OpenAI';

  String get modelName =>
      isGroq ? 'meta-llama/llama-4-scout-17b-16e-instruct' : 'gpt-4o-mini';

  final List<Map<String, String>> _apiMessages = [];

  void setApiKey(String key) => _apiKey = key.trim();
  void resetApiKeyToDefault() => _apiKey = _defaultApiKey;

  void _resetHistory() {
    _apiMessages.clear();
    _apiMessages.add({
      'role': 'system',
      'content': '''Tu es EcoBot 🌿, l'assistant IA de la plateforme EcoCity — une application citoyenne de signalement et résolution des problèmes environnementaux.

Ton rôle :
1. SIGNALEMENT : Si l'utilisateur décrit un problème écologique (dépôt sauvage, poubelle débordante, pollution, déchets...), tu dois TOUJOURS répondre avec ce JSON exact (et rien d'autre avant le JSON) :
   REPORT_DRAFT:{"title":"...", "category":"...", "description":"..."}
   Ensuite, sur une nouvelle ligne, confirme en langage naturel en français.
   Les catégories disponibles : ${kReportCategories.join(', ')}

2. GUIDE TRI : Si l'utilisateur demande où recycler, trier, ou dispose d'un déchet particulier, guide-le clairement avec des conseils pratiques.

3. ORIENTATION : Si l'utilisateur veut trouver des points de collecte, dis-lui que tu vas afficher les résultats sur la carte.

4. GÉNÉRAL : Pour toute autre question, réponds en tant qu'assistant écologique bienveillant.

Tu réponds TOUJOURS en français. Sois concis, utile, et engageant.''',
    });
  }

  void clearConversation() => _resetHistory();

  /// Retourne [ChatMessage] avec éventuellement un [ReportDraft] extrait.
  Future<ChatMessage> sendMessageEco(String userMessage) async {
    final trimmed = userMessage.trim();
    if (trimmed.isEmpty) {
      return ChatMessage(text: '', isUser: false);
    }

    if (_apiKey.isEmpty) {
      throw Exception(
        'Aucune clé API configurée. Ajoutez "AI_API_KEY" dans supabase_config.json.',
      );
    }

    _apiMessages.add({'role': 'user', 'content': trimmed});

    final endpoint = isGroq
        ? 'https://api.groq.com/openai/v1/chat/completions'
        : 'https://api.openai.com/v1/chat/completions';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': modelName,
          'messages': _apiMessages,
          'temperature': 0.6,
        }),
      );

      final responseString = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(responseString) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final content =
              (choices[0]['message']?['content'] as String?)?.trim() ?? '';
          _apiMessages.add({'role': 'assistant', 'content': content});

          return _parseResponse(content);
        }
        return ChatMessage(text: 'Aucune réponse reçue.', isUser: false);
      } else {
        if (_apiMessages.isNotEmpty &&
            _apiMessages.last['role'] == 'user') {
          _apiMessages.removeLast();
        }
        _handleApiError(response.statusCode, responseString);
        // unreachable but Dart needs it
        throw Exception('Erreur API inconnue');
      }
    } catch (e) {
      if (_apiMessages.isNotEmpty && _apiMessages.last['role'] == 'user') {
        _apiMessages.removeLast();
      }
      rethrow;
    }
  }

  /// Compatibilité avec l'ancien code : retourne simplement le texte.
  Future<String> sendMessage(String userMessage) async {
    final msg = await sendMessageEco(userMessage);
    return msg.text;
  }

  // ─── Parsing ─────────────────────────────────────────────────────────────────

  ChatMessage _parseResponse(String content) {
    const prefix = 'REPORT_DRAFT:';
    if (content.contains(prefix)) {
      final prefixIdx = content.indexOf(prefix);
      final jsonStart = prefixIdx + prefix.length;

      // Cherche la fin du JSON (accolade fermante)
      int depth = 0;
      int jsonEnd = -1;
      for (int i = jsonStart; i < content.length; i++) {
        if (content[i] == '{') depth++;
        if (content[i] == '}') {
          depth--;
          if (depth == 0) {
            jsonEnd = i + 1;
            break;
          }
        }
      }

      if (jsonEnd > jsonStart) {
        try {
          final jsonStr = content.substring(jsonStart, jsonEnd);
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final draft = ReportDraft.fromJson(json);

          // Texte affiché = tout ce qui suit le JSON
          final textAfter = content.substring(jsonEnd).trim();
          final displayText = textAfter.isNotEmpty
              ? textAfter
              : '✅ Signalement enregistré : **${draft.title}** (${draft.category}).\n\nLe point apparaît sur la carte en rouge.';

          return ChatMessage(
            text: displayText,
            isUser: false,
            reportDraft: draft,
          );
        } catch (_) {
          // Parsing failed → retourne le texte brut
        }
      }
    }

    return ChatMessage(text: content, isUser: false);
  }

  void _handleApiError(int statusCode, String responseString) {
    try {
      final errorData = jsonDecode(responseString) as Map<String, dynamic>;
      final errorObj = errorData['error'] as Map<String, dynamic>?;
      final code = errorObj?['code']?.toString() ?? '';
      final rawMsg = errorObj?['message']?.toString() ?? 'Erreur inconnue';

      if (statusCode == 401 || code == 'invalid_api_key') {
        throw Exception(
          'Clé API $providerName invalide (Code 401). Mettez à jour votre clé.',
        );
      } else if (statusCode == 429 ||
          code == 'insufficient_quota' ||
          code == 'rate_limit_exceeded') {
        throw Exception(
          'Limite $providerName atteinte. Réessayez dans un instant.',
        );
      } else {
        throw Exception('Erreur $providerName ($statusCode) : $rawMsg');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur serveur ($statusCode)');
    }
  }
}
