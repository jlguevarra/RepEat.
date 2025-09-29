import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? userData;
  final String apiKey; // This will be your Google Gemini API Key
  final String apiType; // This should be 'gemini'

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userData,
    required this.apiKey,
    required this.apiType,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  List<Map<String, dynamic>> _chatMessages = [];
  bool isChatLoading = false;

  // MODIFIED: This is the final, correct model name for YOUR account.
  final String _geminiModel = 'gemini-flash-latest';

  late AnimationController _dotsController;
  GenerativeModel? _model;
  ChatSession? _chat;

  @override
  void initState() {
    super.initState();
    _chatMessages.add({
      'role': 'assistant',
      'content': 'Hello! I\'m your nutrition expert assistant. How can I help you?',
      'timestamp': DateTime.now(),
    });

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _initializeChat();
  }

  void _initializeChat() {
    _model = GenerativeModel(
      model: _geminiModel,
      apiKey: widget.apiKey,
      systemInstruction: Content.system(_buildSystemPrompt()),
    );

    _chat = _model!.startChat();
  }

  String _buildSystemPrompt() {
    final profile = widget.userData;
    if (profile == null) {
      return 'You are a helpful and friendly nutrition expert for a fitness app called RepEat. Keep responses concise and informative.';
    }
    return '''
You are a helpful and friendly nutrition expert for a fitness app called RepEat.
Personalize all responses based on this user profile:
- Goal: ${profile['goal'] ?? 'Not specified'}
- Diet Preference: ${profile['diet_preference'] ?? 'Not specified'}
- Allergies: ${profile['allergies']?.isNotEmpty == true ? profile['allergies'] : 'None'}
''';
  }

  int _addAssistantPlaceholder() {
    setState(() {
      _chatMessages.add({
        'role': 'assistant',
        'content': '',
        'timestamp': DateTime.now(),
      });
    });
    _scrollToBottom();
    return _chatMessages.length - 1;
  }

  Future<void> _streamResponseFromGemini(String message) async {
    final assistantIndex = _addAssistantPlaceholder();

    try {
      final stream = _chat!.sendMessageStream(Content.text(message));
      StringBuffer responseBuffer = StringBuffer();

      await for (final response in stream) {
        final text = response.text;
        if (text != null) {
          responseBuffer.write(text);
          setState(() {
            _chatMessages[assistantIndex]['content'] = responseBuffer.toString();
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      setState(() {
        _chatMessages[assistantIndex]['content'] = 'DEBUG INFO:\n${e.toString()}';
      });
      debugPrint('Gemini API Error: $e');
    }
  }

  Future<void> _sendChatMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      isChatLoading = true;
      _chatMessages.add({
        'role': 'user',
        'content': trimmed,
        'timestamp': DateTime.now(),
      });
    });

    _scrollToBottom();

    try {
      if (widget.apiType.toLowerCase() == 'gemini') {
        await _streamResponseFromGemini(trimmed);
      } else {
        _chatMessages.add({
          'role': 'assistant',
          'content': 'Error: API type "${widget.apiType}" is not supported.',
          'timestamp': DateTime.now()
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isChatLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        int dotCount = ((DateTime.now().millisecond ~/ 300) % 4);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(dotCount, (index) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                '.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    final content = message['content'] ?? '';

    final alignment = isUser ? MainAxisAlignment.end : MainAxisAlignment.start;
    final bubbleColor = isUser ? Colors.deepPurple : Colors.grey[200];
    final textColor = isUser ? Colors.white : Colors.black;

    return Row(
      mainAxisAlignment: alignment,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser)
          const Padding(
            padding: EdgeInsets.only(left: 8.0, right: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.deepPurple,
              child:
              Icon(Icons.restaurant, size: 16, color: Colors.white),
            ),
          ),
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content.isEmpty
                    ? _buildTypingIndicator()
                    : SelectableText(content, style: TextStyle(color: textColor)),
                if (message['timestamp'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('HH:mm').format(message['timestamp']),
                      style: TextStyle(
                        fontSize: 10,
                        color: isUser ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isUser)
          const Padding(
            padding: EdgeInsets.only(right: 8.0, left: 8.0),
            child: CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 16),
            ),
          ),
      ],
    );
  }

  void _handleSendPressed() {
    if (!isChatLoading && _chatController.text.trim().isNotEmpty) {
      final text = _chatController.text;
      _chatController.clear();
      _sendChatMessage(text);
      _inputFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Nutrition Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_chatMessages[index]);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 44,
                      maxHeight: 100,
                    ),
                    child: Scrollbar(
                      child: TextField(
                        focusNode: _inputFocus,
                        controller: _chatController,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 1,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Ask about nutrition, recipe, etc...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor:
                  isChatLoading ? Colors.grey : Colors.deepPurple,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: isChatLoading ? null : _handleSendPressed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    _dotsController.dispose();
    super.dispose();
  }
}