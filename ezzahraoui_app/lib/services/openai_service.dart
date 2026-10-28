import 'dart:convert';

import 'package:http/http.dart' as http;

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

class OpenAiService {
  // Clé chargée depuis l'environnement (--dart-define-from-file=supabase_config.json)
  static const String _defaultApiKey = String.fromEnvironment('AI_API_KEY');

  // Instance partagée (Singleton)
  static final OpenAiService instance = OpenAiService._internal();

  //Stockage dans l'instance
  OpenAiService._internal() {
    _apiKey = _defaultApiKey;
    _resetHistory();
  }

  late String _apiKey;
  String get apiKey => _apiKey;

  bool get isGroq => _apiKey.startsWith('gsk_');

  String get providerName => isGroq ? 'Groq' : 'OpenAI';

  String get modelName => isGroq ? 'openai/gpt-oss-120b' : 'gpt-4o-mini';

  final List<Map<String, String>> _apiMessages = [];

  void setApiKey(String key) {
    _apiKey = key.trim();
  }

  void resetApiKeyToDefault() {
    _apiKey = _defaultApiKey;
  }

  void _resetHistory() {
    _apiMessages.clear();
    _apiMessages.add({
      'role': 'system',
      'content':
          'Tu es un assistant IA intelligent, rapide et bienveillant dans l\'application de EZ-ZAHRAOUI El-Mehdi (étudiant en Génie Informatique à l\'EMSI). '
          'Tu réponds de façon claire, polie et concise en français. Tu peux aider avec du code (Flutter, Dart, Python, web, mobile), des études, ou des questions générales.',
    });
  }

  void clearConversation() {
    _resetHistory();
  }

  Future<String> sendMessage(String userMessage) async {
    final trimmed = userMessage.trim();
    if (trimmed.isEmpty) return '';

    if (_apiKey.isEmpty) {
      throw Exception(
        'Aucune clé API n’est configurée. Ajoutez "AI_API_KEY" dans votre fichier "supabase_config.json" '
        'ou cliquez sur l’icône ⚙️ en haut à droite pour la saisir.',
      );
    }

    _apiMessages.add({'role': 'user', 'content': trimmed});

    final endpoint = isGroq
        ? 'https://api.groq.com/openai/v1/chat/completions'
        : 'https://api.openai.com/v1/chat/completions';

    final model = modelName;

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': _apiMessages,
          'temperature': 0.7,
        }),
      );

      final responseBytes = response.bodyBytes;
      final responseString = utf8.decode(responseBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(responseString) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final firstChoice = choices[0] as Map<String, dynamic>;
          final message = firstChoice['message'] as Map<String, dynamic>?;
          final content = (message?['content'] as String?)?.trim() ?? '';

          // Ajouter la réponse du bot à l'historique
          _apiMessages.add({'role': 'assistant', 'content': content});

          return content;
        }
        return 'Aucune réponse reçue du modèle.';
      } else {
        // En cas d'erreur API, retirer le dernier message utilisateur de l'historique
        if (_apiMessages.isNotEmpty && _apiMessages.last['role'] == 'user') {
          _apiMessages.removeLast();
        }

        try {
          final errorData = jsonDecode(responseString) as Map<String, dynamic>;
          final errorObj = errorData['error'] as Map<String, dynamic>?;
          final code = errorObj?['code']?.toString() ?? '';
          final rawMsg = errorObj?['message']?.toString() ?? 'Erreur inconnue';

          if (response.statusCode == 401 || code == 'invalid_api_key') {
            throw Exception(
              'Clé API $providerName invalide ou révoquée (Code 401). '
              'Veuillez mettre à jour votre clé API en cliquant sur l’icône ⚙️ en haut.',
            );
          } else if (response.statusCode == 429 ||
              code == 'insufficient_quota' ||
              code == 'rate_limit_exceeded') {
            throw Exception(
              'Limite de requêtes ou quota $providerName atteint. '
              'Veuillez patienter un instant avant de réessayer.',
            );
          } else {
            throw Exception(
              'Erreur $providerName (${response.statusCode}) : $rawMsg',
            );
          }
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception(
            'Erreur serveur (${response.statusCode}) : $responseString',
          );
        }
      }
    } catch (e) {
      if (_apiMessages.isNotEmpty && _apiMessages.last['role'] == 'user') {
        _apiMessages.removeLast();
      }
      rethrow;
    }
  }
}
