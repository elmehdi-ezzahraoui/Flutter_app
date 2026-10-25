import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/openai_service.dart';
import '../theme/app_design.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final OpenAiService _openAiService = OpenAiService.instance;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _lastError;

  final List<String> _quickSuggestions = [
    '👋 Présente-toi et tes fonctionnalités',
    '💻 Comment optimiser les performances Flutter ?',
    '🎓 Explique-moi le patron MVC en informatique',
    '🚀 Propose-moi une idée de projet mobile',
  ];

  @override
  void initState() {
    super.initState();
    // Message de bienvenue initial
    _messages.add(
      ChatMessage(
        text:
            'Bonjour El-Mehdi ! 👋\nJe suis votre assistant IA personnel. Comment puis-je vous aider aujourd\'hui ?',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  Future<void> _handleSendMessage([String? prefilledText]) async {
    final query = prefilledText ?? _textController.text;
    final trimmed = query.trim();
    if (trimmed.isEmpty || _isLoading) return;

    if (prefilledText == null) {
      _textController.clear();
    }

    setState(() {
      _lastError = null;
      _messages.add(ChatMessage(text: trimmed, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await _openAiService.sendMessage(trimmed);
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: reply, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        final errorText = e.toString().replaceFirst('Exception: ', '');
        setState(() {
          _lastError = errorText;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Texte copié dans le presse-papiers'),
        backgroundColor: kPrimaryDark,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showClearConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Effacer la conversation'),
        content: const Text(
          'Voulez-vous vraiment réinitialiser cette discussion ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _openAiService.clearConversation();
              setState(() {
                _messages.clear();
                _lastError = null;
                _messages.add(
                  ChatMessage(
                    text:
                        'Discussion réinitialisée. En quoi puis-je vous être utile ? 😊',
                    isUser: false,
                  ),
                );
              });
            },
            child: const Text('Effacer'),
          ),
        ],
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
            // Liste des messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                itemCount:
                    _messages.length +
                    (_isLoading ? 1 : 0) +
                    (_lastError != null ? 1 : 0),
                itemBuilder: (context, index) {
                  // Message standard
                  if (index < _messages.length) {
                    final msg = _messages[index];
                    return _buildMessageBubble(msg);
                  }

                  // Indicateur de chargement
                  if (_isLoading && index == _messages.length) {
                    return _buildLoadingBubble();
                  }

                  // Message d'erreur s'il existe
                  if (_lastError != null) {
                    return _buildErrorCard(_lastError!);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),

            // Suggestions rapides (visibles si début de discussion)
            if (_messages.length <= 2 && !_isLoading) _buildSuggestionsBar(),

            // Zone de saisie
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryDark, kPrimary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [kAccent, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: kPrimaryDark,
                  size: 24,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Assistant IA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _openAiService.isGroq
                      ? 'Groq (GPT OSS 120B) • Ultra Rapide'
                      : 'OpenAI (GPT-4o Mini) • En ligne',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          tooltip: 'Effacer la discussion',
          onPressed: _showClearConfirmDialog,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final timeStr =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 16,
                color: kPrimary,
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [kPrimaryDark, kPrimary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: isUser
                    ? null
                    : Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.text,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: isUser ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 10,
                          color: isUser ? Colors.white60 : Colors.black38,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _copyToClipboard(message.text),
                          child: const Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(left: 8, bottom: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: kPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 16,
              color: kPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kPrimary,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'L\'assistant réfléchit...',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Erreur de communication',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsBar() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickSuggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = _quickSuggestions[index];
          return ActionChip(
            backgroundColor: Colors.white,
            side: BorderSide(color: kPrimary.withOpacity(0.25)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            label: Text(
              suggestion,
              style: const TextStyle(
                fontSize: 12,
                color: kPrimaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () => _handleSendMessage(suggestion),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Posez votre question...',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _handleSendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kPrimary, kPrimaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _isLoading ? null : () => _handleSendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}
