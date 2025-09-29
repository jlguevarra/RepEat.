import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? userData;
  final String apiKey;
  final String apiType;

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

class AppColors {
  static const Color primaryColor = Colors.deepPurple;
  static const Color backgroundColor = Color(0xFFF8F8F8);
  static const Color userBubbleColor = Colors.deepPurple;
  static const Color assistantBubbleColor = Colors.white;
  static const Color textFieldColor = Colors.white;
  static const Color hintColor = Colors.grey;
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  List<Map<String, dynamic>> _chatMessages = [];
  bool isChatLoading = false;

  final String _geminiModel = 'gemini-pro-latest';
  late AnimationController _dotsController;
  GenerativeModel? _model;
  ChatSession? _chat;

  @override
  void initState() {
    super.initState();
    _chatMessages.add({
      'role': 'assistant',
      'content':
      'Hello! I\'m your nutrition expert assistant. How can I help with your meal planning?',
      'timestamp': DateTime.now(),
    });

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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

  // MODIFIED: Added instruction to prevent Markdown formatting
  String _buildSystemPrompt() {
    final profile = widget.userData;
    String basePrompt =
        'You are a helpful and friendly nutrition expert for a fitness app called RepEat. Keep responses concise and informative.';

    String profileInfo = '';
    if (profile != null) {
      profileInfo = '''

Personalize all responses based on this user profile:
- Goal: ${profile['goal'] ?? 'Not specified'}
- Diet Preference: ${profile['diet_preference'] ?? 'Not specified'}
- Allergies: ${profile['allergies']?.isNotEmpty == true ? profile['allergies'] : 'None'}''';
    }

    // This is the new, crucial instruction
    String formattingRule =
        '\n\nImportant: Do not use any Markdown formatting like asterisks for bolding or lists. Respond in plain, formal text only.';

    return basePrompt + profileInfo + formattingRule;
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
        _chatMessages[assistantIndex]['content'] =
        'Sorry, I\'m having a bit of trouble right now. Please try again.';
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
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildTypingIndicator() {
    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _dotsController,
            builder: (context, child) {
              final double offset = -6.0 *
                  (0.5 -
                      (_dotsController.value - (0.33 * index))
                          .abs()
                          .clamp(0.0, 0.5) *
                          2)
                      .abs();
              return Transform.translate(
                offset: Offset(0, offset),
                child: child,
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.0),
              child: CircleAvatar(
                radius: 3.5,
                backgroundColor: AppColors.hintColor,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, int index) {
    final isUser = message['role'] == 'user';
    final content = message['content'] ?? '';

    final bubbleAlignment =
    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor =
    isUser ? AppColors.userBubbleColor : AppColors.assistantBubbleColor;
    final textColor = isUser ? Colors.white : Colors.black87;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft:
      isUser ? const Radius.circular(20) : const Radius.circular(4),
      bottomRight:
      isUser ? const Radius.circular(4) : const Radius.circular(20),
    );

    return FadeInUp(
      from: 20,
      duration: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: bubbleAlignment,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: content.isEmpty
                ? _buildTypingIndicator()
                : SelectableText(
              content,
              style: TextStyle(color: textColor, fontSize: 16, height: 1.4),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 20,
              right: isUser ? 20 : 0,
              bottom: 10,
            ),
            child: Text(
              DateFormat('h:mm a').format(message['timestamp']),
              style: const TextStyle(fontSize: 12, color: AppColors.hintColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  focusNode: _inputFocus,
                  controller: _chatController,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 5,
                  onSubmitted: (_) => _handleSendPressed(),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    hintText: 'Ask a nutrition question...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: AppColors.hintColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.send_rounded, size: 26),
              color: AppColors.primaryColor,
              onPressed: isChatLoading ? null : _handleSendPressed,
              disabledColor: Colors.grey,
            ),
          ],
        ),
      ),
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
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('AI Nutrition Assistant'),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 16),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_chatMessages[index], index);
              },
            ),
          ),
          _buildInputBar(),
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