import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? userData;
  final String apiKey; // OpenRouter API Key
  final String apiType; // Should now be 'openrouter'

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

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  List<Map<String, dynamic>> _chatMessages = [];
  bool isChatLoading = false;
  bool _sentProfile = false;

  // ✅ Free models with fallback (you can reorder these)
  final List<String> _freeModels = const [
    'mistralai/mistral-7b-instruct:free',
    'openchat/openchat-7b:free',
    'nousresearch/nous-hermes-2-mistral-7b:free',
  ];

  @override
  void initState() {
    super.initState();
    _chatMessages.add({
      'role': 'assistant',
      'content':
      'Hello! I\'m your nutrition expert assistant. How can I help you with your meal planning today?',
      'timestamp': DateTime.now(),
    });
  }

  /// Adds an empty assistant message we'll stream into and returns its index.
  int _addAssistantPlaceholder() {
    setState(() {
      _chatMessages.add({
        'role': 'assistant',
        'content': '',
        'timestamp': DateTime.now(),
      });
    });
    return _chatMessages.length - 1;
  }

  /// ✅ Main AI request handler with fallback, writing into a prepared bubble
  Future<void> _sendToAIWithStreaming(String message) async {
    final int assistantIndex = _addAssistantPlaceholder();

    for (int i = 0; i < _freeModels.length; i++) {
      try {
        await _streamResponseFromOpenRouter(
          message: message,
          model: _freeModels[i],
          assistantIndex: assistantIndex,
        );
        return; // success -> stop trying more models
      } catch (e) {
        debugPrint('Model ${_freeModels[i]} failed: $e');
        if (i == _freeModels.length - 1) {
          // last fallback failed
          setState(() {
            _chatMessages[assistantIndex]['content'] =
            'All free models are busy or unavailable right now. Please try again in a bit.';
          });
        }
      }
    }
  }

  /// ✅ Streaming response from OpenRouter API into an existing assistant bubble
  Future<void> _streamResponseFromOpenRouter({
    required String message,
    required String model,
    required int assistantIndex,
  }) async {
    const String endpoint = 'https://openrouter.ai/api/v1/chat/completions';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${widget.apiKey}',
      'HTTP-Referer': 'https://your-app.com',
      'X-Title': 'RepEat Nutrition Assistant',
    };

    final body = {
      'model': model,
      'stream': true, // ✅ Enable streaming
      'messages': [
        {
          'role': 'system',
          'content':
          'You are a helpful and friendly nutrition expert assistant for a fitness app called RepEat.'
        },
        // Only inject profile context on the very first user turn we send
        {
          'role': 'user',
          'content': _sentProfile ? message : _buildChatPrompt(message)
        }
      ],
      'temperature': 0.7,
      'max_tokens': 1024,
    };

    final request = http.Request('POST', Uri.parse(endpoint))
      ..headers.addAll(headers)
      ..body = jsonEncode(body);

    final streamed = await request.send();

    if (streamed.statusCode != 200) {
      throw Exception('Streaming failed: ${streamed.statusCode}');
    }

    _sentProfile = true;

    // Listen to SSE stream and progressively append deltas
    final stream = streamed.stream.transform(utf8.decoder);

    await for (final chunk in stream) {
      // The stream can deliver multiple SSE events per chunk
      for (var rawLine in chunk.split('\n')) {
        final line = rawLine.trim();
        if (line.isEmpty) continue;
        if (!line.startsWith('data:')) continue;

        final data = line.substring(5).trim(); // after "data:"
        if (data == '[DONE]') return;

        try {
          final Map<String, dynamic> jsonData = jsonDecode(data);

          // OpenRouter uses OpenAI-compatible streaming ("delta")
          final delta = jsonData['choices']?[0]?['delta'];
          final String? piece = delta?['content'];

          if (piece != null && piece.isNotEmpty) {
            setState(() {
              _chatMessages[assistantIndex]['content'] += piece;
            });
            _scrollToBottom();
          }
        } catch (e) {
          // Sometimes a keepalive or non-JSON can appear; ignore parse errors
          debugPrint('Streaming parse error: $e');
        }
      }
    }
  }

  /// ✅ Build chat prompt with user profile (only first time)
  String _buildChatPrompt(String message) {
    if (widget.userData == null) return message;

    return '''
User Profile:
- Goal: ${widget.userData!['goal'] ?? 'Not specified'}
- Diet Preference: ${widget.userData!['diet_preference'] ?? 'Not specified'}
- Allergies: ${widget.userData!['allergies']?.isNotEmpty == true ? widget.userData!['allergies'] : 'None'}

User Question: "$message"

Please provide helpful, accurate, and personalized nutrition advice based on the user's profile.
Keep responses concise but informative (150-300 words). Focus on practical suggestions.
''';
  }

  /// ✅ Handles sending chat message and starting stream
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
      // Currently only OpenRouter is supported
      if (widget.apiType.toLowerCase() == 'openrouter') {
        await _sendToAIWithStreaming(trimmed);
      } else {
        setState(() {
          _chatMessages.add({
            'role': 'assistant',
            'content': 'Unsupported API: ${widget.apiType}',
            'timestamp': DateTime.now(),
          });
        });
      }
    } catch (e) {
      setState(() {
        _chatMessages.add({
          'role': 'assistant',
          'content': 'Error: ${e.toString()}',
          'timestamp': DateTime.now(),
        });
      });
    } finally {
      setState(() {
        isChatLoading = false;
      });
      _scrollToBottom();
    }
  }

  /// ✅ Scroll to latest message
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

  /// ✅ Message bubble UI
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    final content = message['content'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.restaurant, size: 16, color: Colors.white),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.deepPurple : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    content.isEmpty ? 'Typing...' : content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                if (message['timestamp'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('HH:mm').format(message['timestamp']),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            const CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 16),
            ),
        ],
      ),
    );
  }

  /// ✅ Send action
  void _handleSendPressed() {
    if (!isChatLoading && _chatController.text.trim().isNotEmpty) {
      final text = _chatController.text;
      _chatController.clear();
      _sendChatMessage(text);
      // Keep keyboard open for faster chatting
      _inputFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Nutrition Assistant'),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                return _buildMessageBubble(_chatMessages[index]);
              },
            ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ✅ Multi-line expanding TextField
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 44,
                      maxHeight: 140, // grows up to ~6 lines
                    ),
                    child: Scrollbar(
                      child: TextField(
                        focusNode: _inputFocus,
                        controller: _chatController,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 1,
                        maxLines: null, // allow natural expansion
                        decoration: InputDecoration(
                          hintText:
                          'Ask about nutrition, recipes, or meal planning...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        // Keep Enter for newline; sending is via the button
                        onSubmitted: (_) {
                          // Many keyboards won’t trigger onSubmitted in multiline; send via button
                        },
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
    super.dispose();
  }
}
